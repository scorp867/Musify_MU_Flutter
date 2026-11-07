library;

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../../../../core/audio/musify_ffi_bindings.dart';
import '../../../../core/audio/musify_native_audio_engine.dart';
import 'esperanto_transport.dart';

/// 1:1 replica of Spotify NativeTransport (com.spotify.esperanto.esperantoimpl.NativeTransport.java).
///
/// Thin FFI bridge delegating all command handling, queue management, state emission,
/// restrictions evaluation, track routing (`RoutingTrackPlayer`), head chunk streaming,
/// CDN storage resolution, and Widevine DRM licensing to `libmusify_audio.so`.
class NativeEsperantoTransport implements EsperantoTransport {
  final MusifyFfiBindings _ffi;
  final Pointer<Void> _nThis;
  bool _isInvalidated = false;

  final ReceivePort _statePort = ReceivePort('cpi_state');
  final ReceivePort _queuePort = ReceivePort('cpi_queue');
  final ReceivePort _errorPort = ReceivePort('cpi_error');

  final StreamController<Uint8List> _stateController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _queueController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _errorController =
      StreamController<Uint8List>.broadcast();

  Uint8List? _lastStateBytes;
  Uint8List? _lastQueueBytes;

  factory NativeEsperantoTransport(
    MusifyNativeAudioEngine engine, {
    MusifyFfiBindings? ffi,
  }) {
    final resolvedFfi = switch (ffi) {
      final providedFfi? => providedFfi,
      null => MusifyFfiBindings.instance,
    };
    resolvedFfi.initDartApiDl(NativeApi.initializeApiDLData);
    final handle = resolvedFfi.cpiCreate(engine.handle);
    if (handle == nullptr) {
      throw StateError('musify_cpi_create returned nullptr');
    }
    return NativeEsperantoTransport._(resolvedFfi, handle);
  }

  NativeEsperantoTransport._(this._ffi, this._nThis) {
    _ffi.cpiSetStateChangedPort(_nThis, _statePort.sendPort.nativePort);
    _ffi.cpiSetQueueChangedPort(_nThis, _queuePort.sendPort.nativePort);
    _ffi.cpiSetErrorPort(_nThis, _errorPort.sendPort.nativePort);

    _statePort.listen((Object? data) {
      if (data case final Uint8List bytes) {
        _lastStateBytes = bytes;
        if (!_stateController.isClosed) {
          _stateController.add(bytes);
        }
      }
    });

    _queuePort.listen((Object? data) {
      if (data case final Uint8List bytes) {
        _lastQueueBytes = bytes;
        if (!_queueController.isClosed) {
          _queueController.add(bytes);
        }
      }
    });

    _errorPort.listen((Object? data) {
      if (data case final Uint8List bytes) {
        if (!_errorController.isClosed) {
          _errorController.add(bytes);
        }
      }
    });

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
      return _createReplayingStream(
        _stateController.stream,
        () => _lastStateBytes,
      );
    }
    if (method == 'GetQueue') {
      return _createReplayingStream(
        _queueController.stream,
        () => _lastQueueBytes,
      );
    }
    if (method == 'GetError') return _errorController.stream;
    return const Stream<Uint8List>.empty();
  }

  @override
  Uint8List callSync(String service, String method, Uint8List payload) {
    if (_isInvalidated) {
      throw StateError(
        'callSync() invoked after invalidation: $service.$method',
      );
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
  // Initial snapshot synchronization
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
      if (getLatest() case final latest?) {
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
    if (_isInvalidated) return;
    invalidate();
    _ffi.cpiSetStateChangedPort(_nThis, 0);
    _ffi.cpiSetQueueChangedPort(_nThis, 0);
    _ffi.cpiSetErrorPort(_nThis, 0);
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
