library;

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../../../../core/audio/musify_ffi_bindings.dart';
import '../../../../core/audio/musify_native_audio_engine.dart';
import '../../../../core/media/extended_metadata_service.dart';
import '../../../../core/network/spotify/auth/auth_session_provider.dart';
import '../../../../core/network/spotify/auth/spotify_client_token.dart';
import '../../domain/models/context_track.dart';
import '../services/spotify_audio_stream_coordinator.dart';
import '../services/spotify_license_resolver.dart';
import '../services/spotify_storage_resolver.dart';
import 'esperanto_transport.dart';
import 'proto/es_context_track.pb.dart' as es_track;

/// 1:1 replica of Spotify NativeTransport (com.spotify.esperanto.esperantoimpl.NativeTransport.java).
///
/// This is a thin FFI bridge that delegates all command handling, queue management,
/// state emission, and restrictions evaluation to C++ ContextPlayerImpl
/// (matching liborbit-jni-spotify.so). Dart only handles:
/// - FFI call passthrough (callSingle, callStream, callSync)
/// - Invalidation guard
/// - NativePort subscriptions for state/queue/error streams
/// - Audio stream resolution (delegated to SpotifyAudioStreamCoordinator)
///
/// Line count target: ~70 lines (Spotify NativeTransport.java = 69 lines)
class NativeEsperantoTransport implements EsperantoTransport {
  final MusifyFfiBindings _ffi = MusifyFfiBindings.instance;
  final MusifyNativeAudioEngine _engine;
  final SpotifyAudioStreamCoordinator _streamCoordinator;

  Pointer<Void> _nThis = nullptr;
  bool _isInvalidated = false;

  /// NativePort receivers for C++ -> Dart async callbacks
  final ReceivePort _playTrackPort = ReceivePort('cpi_play_track');
  final ReceivePort _statePort = ReceivePort('cpi_state');
  final ReceivePort _queuePort = ReceivePort('cpi_queue');
  final ReceivePort _errorPort = ReceivePort('cpi_error');

  /// Broadcast controllers fed from NativePorts
  final StreamController<Uint8List> _stateController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _queueController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _errorController =
      StreamController<Uint8List>.broadcast();

  /// Cached last emitted protobuf binary states for replay on new stream subscriptions
  Uint8List? _lastStateBytes;
  Uint8List? _lastQueueBytes;

  NativeEsperantoTransport(
    this._engine, {
    ExtendedMetadataService? metadataService,
    SpotifyStorageResolver? storageResolver,
    SpotifyLicenseResolver? licenseResolver,
    AuthSessionProvider? authSessionProvider,
    SpotifyClientTokenFetcher? clientTokenFetcher,
    SpotifyAudioStreamCoordinator? streamCoordinator,
  })  : _streamCoordinator = switch (streamCoordinator) {
          final coordinator? => coordinator,
          null => SpotifyAudioStreamCoordinator(
              engine: _engine,
              metadataService: metadataService,
              storageResolver: storageResolver,
              licenseResolver: licenseResolver,
              authSessionProvider: authSessionProvider,
              clientTokenFetcher: clientTokenFetcher,
            ),
        } {
    // Initialize Dart DL API for NativePort messaging (1:1 JNI_OnLoad equivalent)
    _ffi.initDartApiDl(NativeApi.initializeApiDLData);

    // Create ContextPlayerImpl bound to the DI-provided AudioEngine
    _nThis = _ffi.cpiCreate(_engine.handle);

    // Register NativePort callbacks
    _ffi.cpiSetPlayTrackPort(_nThis, _playTrackPort.sendPort.nativePort);
    _ffi.cpiSetStateChangedPort(_nThis, _statePort.sendPort.nativePort);
    _ffi.cpiSetQueueChangedPort(_nThis, _queuePort.sendPort.nativePort);
    _ffi.cpiSetErrorPort(_nThis, _errorPort.sendPort.nativePort);

    // Wire NativePort streams
    _playTrackPort.listen(_onPlayTrackRequest);

    _statePort.listen((data) {
      if (data case final Uint8List bytes) {
        _lastStateBytes = bytes;
        if (!_stateController.isClosed) {
          _stateController.add(bytes);
        }
      }
    });

    _queuePort.listen((data) {
      if (data case final Uint8List bytes) {
        _lastQueueBytes = bytes;
        if (!_queueController.isClosed) {
          _queueController.add(bytes);
        }
      }
    });

    _errorPort.listen((data) {
      if (data case final Uint8List bytes) {
        if (!_errorController.isClosed) {
          _errorController.add(bytes);
        }
      }
    });

    // Wire JIT metadata resolution sync back to C++ ContextPlayerImpl
    _streamCoordinator.onTrackMetadataResolved = (updatedTrack) async {
      final trackProto = es_track.ContextTrack()
        ..uri = updatedTrack.uri
        ..uid = updatedTrack.uid;
      trackProto.metadata.addAll(updatedTrack.metadata);
      _dispatchCommand('UpdateTrack', trackProto.writeToBuffer());
    };

    // Emit initial state and queue
    _refreshCachedState();
    _refreshCachedQueue();
  }

  // ---------------------------------------------------------------------------
  // EsperantoTransport interface (1:1 com.spotify.esperanto.esperanto.Transport)
  // ---------------------------------------------------------------------------

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    if (_isInvalidated) {
      throw StateError(
        'callSingle() subscription scheduled after invalidation: $service.$method',
      );
    }
    return _dispatchCommand(method, payload);
  }

  @override
  Stream<Uint8List> callStream(
    String service,
    String method,
    Uint8List payload,
  ) {
    if (_isInvalidated) {
      throw StateError(
        'callStream() subscription scheduled after invalidation: $service.$method',
      );
    }
    if (method == 'GetState') {
      return _createReplayingStream(_stateController.stream, () => _lastStateBytes);
    }
    if (method == 'GetQueue') {
      return _createReplayingStream(_queueController.stream, () => _lastQueueBytes);
    }
    if (method == 'GetError') return _errorController.stream;
    return const Stream<Uint8List>.empty();
  }

  @override
  Uint8List callSync(String service, String method, Uint8List payload) {
    if (_isInvalidated) {
      throw StateError('callSync() invoked after invalidation: $service.$method');
    }
    if (method == 'GetState') {
      if (_lastStateBytes case final stateBytes?) {
        return stateBytes;
      }
    }
    if (method == 'GetQueue') {
      if (_lastQueueBytes case final queueBytes?) {
        return queueBytes;
      }
    }
    return Uint8List(0);
  }

  // ---------------------------------------------------------------------------
  // Command dispatch to C++ ContextPlayerImpl via FFI
  // ---------------------------------------------------------------------------

  Uint8List _dispatchCommand(String method, Uint8List payload) {
    final methodPtr = method.toNativeUtf8();
    try {
      if (payload.isEmpty) {
        _ffi.cpiHandleCommand(_nThis, methodPtr, nullptr, 0);
      } else {
        final payloadPtr = calloc<Uint8>(payload.length);
        payloadPtr.asTypedList(payload.length).setAll(0, payload);
        try {
          _ffi.cpiHandleCommand(
            _nThis,
            methodPtr,
            payloadPtr,
            payload.length,
          );
        } finally {
          calloc.free(payloadPtr);
        }
      }
    } finally {
      calloc.free(methodPtr);
    }
    return Uint8List(0);
  }

  // ---------------------------------------------------------------------------
  // C++ -> Dart: PlayTrack callback (resolve audio stream and load into engine)
  // ---------------------------------------------------------------------------

  Future<void> _onPlayTrackRequest(dynamic data) async {
    if (data case final Uint8List trackBytes when trackBytes.isNotEmpty) {
      try {
        final protoTrack = es_track.ContextTrack.fromBuffer(trackBytes);
        final track = ContextTrack(
          uri: protoTrack.uri,
          uid: protoTrack.uid,
          metadata: Map<String, String>.from(protoTrack.metadata),
        );

        final success = await _streamCoordinator.playTrack(track);
        _ffi.cpiOnTrackLoaded(_nThis, success);
      } catch (e, stack) {
        dev.log(
          'Failed to resolve/play track: $e',
          name: 'NativeEsperantoTransport',
          error: e,
          stackTrace: stack,
        );
        _ffi.cpiOnTrackLoaded(_nThis, false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _refreshCachedState() {
    final outLenPtr = calloc<Int32>();
    try {
      final bytesPtr = _ffi.cpiGetState(_nThis, outLenPtr);
      final len = outLenPtr.value;
      if (bytesPtr != nullptr && len > 0) {
        final bytes = Uint8List(len);
        bytes.setAll(0, bytesPtr.asTypedList(len));
        _ffi.freeBytes(bytesPtr);
        _lastStateBytes = bytes;
        if (!_stateController.isClosed) {
          _stateController.add(bytes);
        }
      }
    } finally {
      calloc.free(outLenPtr);
    }
  }

  void _refreshCachedQueue() {
    final outLenPtr = calloc<Int32>();
    try {
      final bytesPtr = _ffi.cpiGetQueue(_nThis, outLenPtr);
      final len = outLenPtr.value;
      if (bytesPtr != nullptr && len > 0) {
        final bytes = Uint8List(len);
        bytes.setAll(0, bytesPtr.asTypedList(len));
        _ffi.freeBytes(bytesPtr);
        _lastQueueBytes = bytes;
        if (!_queueController.isClosed) {
          _queueController.add(bytes);
        }
      }
    } finally {
      calloc.free(outLenPtr);
    }
  }

  Stream<Uint8List> _createReplayingStream(
    Stream<Uint8List> source,
    Uint8List? Function() getLatest,
  ) {
    StreamSubscription<Uint8List>? sub;
    final controller = StreamController<Uint8List>.broadcast();

    controller.onListen = () {
      final latest = getLatest();
      if (latest != null) {
        controller.add(latest);
      }
      sub = source.listen(
        controller.add,
        onError: controller.addError,
      );
    };

    controller.onCancel = () {
      sub?.cancel();
    };

    return controller.stream;
  }

  // ---------------------------------------------------------------------------
  // Disposal (1:1 with NativeTransport.destroy() / invalidate())
  // ---------------------------------------------------------------------------

  void invalidate() {
    _isInvalidated = true;
  }

  void destroy() {
    invalidate();
    _streamCoordinator.cancelPendingResolutions();
    _playTrackPort.close();
    _statePort.close();
    _queuePort.close();
    _errorPort.close();
    _stateController.close();
    _queueController.close();
    _errorController.close();
    _ffi.cpiDestroy(_nThis);
  }

  void dispose() => destroy();
}
