library;

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../../../core/audio/musify_ffi_bindings.dart';
import '../../../../core/audio/musify_native_audio_engine.dart';
import '../../../connect/data/gateway/native_connect_gateway.dart';
import '../../../connect/domain/interfaces/connect_native_gateway.dart';
import 'esperanto_transport.dart';

typedef _NativeServiceCallFn = Pointer<Uint8> Function(
  Pointer<Void> handle,
  Pointer<Utf8> method,
  Pointer<Uint8> payload,
  Int32Len len,
  Pointer<Int32> outLen,
  Pointer<Int32> outStatus,
);

typedef Int32Len = int;

/// 1:1 replica of Spotify NativeTransport (com.spotify.esperanto.esperantoimpl.NativeTransport.java).
///
/// Thin FFI bridge routing ContextPlayer, ConnectService, ConnectVolumeService,
/// and DodoService binary protobuf RPCs and ReceivePort stream subscriptions to
/// `libmusify_audio.so`.
///
/// Connect `callSingle` RPCs are dispatched asynchronously through
/// `musify_connect_call_async` via [NativeConnectRpcDispatcher] so `libcurl`
/// HTTP requests never block the Flutter UI isolate.
class NativeEsperantoTransport implements EsperantoTransport {
  static const String contextPlayerService =
      'spotify.player.esperanto.proto.ContextPlayer';
  static const String connectService =
      'spotify.connect.esperanto.proto.ConnectService';
  static const String connectVolumeService =
      'spotify.connect.esperanto.proto.ConnectVolumeService';
  static const String dodoService =
      'spotify.connect.esperanto.proto.DodoService';

  final MusifyFfiBindings _ffi;
  final Pointer<Void> _nThis;
  final Pointer<Void> _connectHandle;
  final NativeConnectRpcDispatcher _connectRpcDispatcher;
  final Set<NativeConnectGateway> _attachedGateways = <NativeConnectGateway>{};
  final List<StreamSubscription<Object?>> _portSubscriptions =
      <StreamSubscription<Object?>>[];

  bool _isInvalidated = false;
  bool _isDestroyed = false;

  final ReceivePort _statePort = ReceivePort('cpi_state');
  final ReceivePort _queuePort = ReceivePort('cpi_queue');
  final ReceivePort _errorPort = ReceivePort('cpi_error');

  final ReceivePort _connectStatePort = ReceivePort('connect_state');
  final ReceivePort _volumePort = ReceivePort('connect_volume');
  final ReceivePort _localVolumePort = ReceivePort('connect_local_volume');
  final ReceivePort _dodoPort = ReceivePort('connect_dodo');
  final ReceivePort _installSpotifyPort =
      ReceivePort('connect_install_spotify');

  final StreamController<Uint8List> _stateController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _queueController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _errorController =
      StreamController<Uint8List>.broadcast();

  final StreamController<Uint8List> _connectStateController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _volumeController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _localVolumeController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _dodoController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _installSpotifyController =
      StreamController<Uint8List>.broadcast();

  Uint8List? _lastStateBytes;
  Uint8List? _lastQueueBytes;
  Uint8List? _lastConnectStateBytes;
  Uint8List? _lastVolumeBytes;
  Uint8List? _lastLocalVolumeBytes;
  Uint8List? _lastDodoBytes;
  Uint8List? _lastInstallSpotifyBytes;

  factory NativeEsperantoTransport(
    MusifyNativeAudioEngine engine, {
    MusifyFfiBindings? ffi,
    Duration connectRpcTimeout = NativeConnectRpcDispatcher.defaultTimeout,
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
    final connectHandle = resolvedFfi.connectCreate(handle);
    if (connectHandle == nullptr) {
      resolvedFfi.cpiDestroy(handle);
      throw StateError('musify_connect_create returned nullptr');
    }
    return NativeEsperantoTransport._(
      resolvedFfi,
      handle,
      connectHandle,
      connectRpcTimeout,
    );
  }

  NativeEsperantoTransport._(
    this._ffi,
    this._nThis,
    this._connectHandle,
    Duration connectRpcTimeout,
  ) : _connectRpcDispatcher = NativeConnectRpcDispatcher(
          ffi: _ffi,
          connectHandle: _connectHandle,
          defaultTimeout: connectRpcTimeout,
        ) {
    _ffi.cpiSetStateChangedPort(_nThis, _statePort.sendPort.nativePort);
    _ffi.cpiSetQueueChangedPort(_nThis, _queuePort.sendPort.nativePort);
    _ffi.cpiSetErrorPort(_nThis, _errorPort.sendPort.nativePort);

    _ffi.connectSetStatePort(
      _connectHandle,
      _connectStatePort.sendPort.nativePort,
    );
    _ffi.connectSetVolumePort(
      _connectHandle,
      _volumePort.sendPort.nativePort,
    );
    _ffi.connectSetLocalVolumePort(
      _connectHandle,
      _localVolumePort.sendPort.nativePort,
    );
    _ffi.connectSetDodoPort(
      _connectHandle,
      _dodoPort.sendPort.nativePort,
    );
    _ffi.connectSetInstallSpotifyPort(
      _connectHandle,
      _installSpotifyPort.sendPort.nativePort,
    );

    _bindPort(_statePort, _stateController, (bytes) {
      _lastStateBytes = bytes;
    });
    _bindPort(_queuePort, _queueController, (bytes) {
      _lastQueueBytes = bytes;
    });
    _bindPort(_errorPort, _errorController);
    _bindPort(_connectStatePort, _connectStateController, (bytes) {
      _lastConnectStateBytes = bytes;
    });
    _bindPort(_volumePort, _volumeController, (bytes) {
      _lastVolumeBytes = bytes;
    });
    _bindPort(_localVolumePort, _localVolumeController, (bytes) {
      _lastLocalVolumeBytes = bytes;
    });
    _bindPort(_dodoPort, _dodoController, (bytes) {
      _lastDodoBytes = bytes;
    });
    _bindPort(_installSpotifyPort, _installSpotifyController, (bytes) {
      _lastInstallSpotifyBytes = bytes;
    });

    _refreshCachedState();
    _refreshCachedQueue();
  }

  /// Native `ConnectSubsystem` bundle pointer owned by this transport.
  Pointer<Void> get connectHandle => _connectHandle;

  /// Active FFI bindings table used by this transport.
  MusifyFfiBindings get ffiBindings => _ffi;

  bool get isInvalidated => _isInvalidated;

  bool get isDestroyed => _isDestroyed;

  /// Broadcast stream of raw `LocalVolumeResponse` payloads delivered on the
  /// transport's bound native `local_volume_port`.
  Stream<Uint8List> get localVolumeStream => _localVolumeController.stream;

  /// Creates a [NativeConnectGateway] sharing this transport's native Connect
  /// handle and `local_volume_port` broadcast stream so both Esperanto
  /// `ConnectVolumeService.LocalVolume` and `ConnectNativeGateway.localVolumeStream`
  /// receive every native volume event without port collision.
  ///
  /// Any gateway created via this method is automatically disposed prior to
  /// `musify_connect_destroy` if [destroy] runs before `gateway.dispose()`.
  NativeConnectGateway createConnectGateway({
    Duration rpcTimeout = NativeConnectGateway.defaultRpcTimeout,
  }) {
    if (_isInvalidated || _isDestroyed) {
      throw StateError('createConnectGateway() called after invalidation');
    }
    NativeConnectGateway? created;
    created = NativeConnectGateway.sharedLocalVolume(
      connectHandle: _connectHandle,
      localVolumeStream: _localVolumeController.stream,
      ffi: _ffi,
      isHandleAlive: () => !_isDestroyed,
      onDispose: () {
        if (created case final gw?) {
          _attachedGateways.remove(gw);
        }
      },
      rpcTimeout: rpcTimeout,
    );
    _attachedGateways.add(created);
    return created;
  }

  @visibleForTesting
  SendPort get cpiStateSendPort => _statePort.sendPort;

  @visibleForTesting
  SendPort get cpiQueueSendPort => _queuePort.sendPort;

  @visibleForTesting
  SendPort get cpiErrorSendPort => _errorPort.sendPort;

  @visibleForTesting
  SendPort get connectStateSendPort => _connectStatePort.sendPort;

  @visibleForTesting
  SendPort get volumeSendPort => _volumePort.sendPort;

  @visibleForTesting
  SendPort get localVolumeSendPort => _localVolumePort.sendPort;

  @visibleForTesting
  SendPort get dodoSendPort => _dodoPort.sendPort;

  @visibleForTesting
  SendPort get installSpotifySendPort => _installSpotifyPort.sendPort;

  @visibleForTesting
  SendPort get connectRpcReplySendPort => _connectRpcDispatcher.replySendPort;

  void _bindPort(
    ReceivePort port,
    StreamController<Uint8List> controller, [
    void Function(Uint8List bytes)? updateLatest,
  ]) {
    final subscription = port.listen((Object? data) {
      if (_isDestroyed) return;
      if (data case final Uint8List bytes) {
        if (updateLatest != null) {
          updateLatest(bytes);
        }
        if (!controller.isClosed) {
          controller.add(bytes);
        }
      }
    });
    _portSubscriptions.add(subscription);
  }

  int connectStart([Uint8List? deviceInfoBytes]) {
    if (_isInvalidated) {
      throw StateError('connectStart() called after invalidation');
    }
    if (deviceInfoBytes == null || deviceInfoBytes.isEmpty) {
      return _ffi.connectStart(_connectHandle, nullptr, 0);
    }
    final ptr = calloc<Uint8>(deviceInfoBytes.length);
    ptr.asTypedList(deviceInfoBytes.length).setAll(0, deviceInfoBytes);
    try {
      return _ffi.connectStart(_connectHandle, ptr, deviceInfoBytes.length);
    } finally {
      calloc.free(ptr);
    }
  }

  void connectStop() {
    if (_isInvalidated) {
      throw StateError('connectStop() called after invalidation');
    }
    _ffi.connectStop(_connectHandle);
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
    if (_isContextPlayerService(service)) {
      return _dispatchCommand(method, payload);
    }
    if (ConnectEsperantoServiceId.tryFromServiceName(service)
        case final serviceId?) {
      final result = await _connectRpcDispatcher.callAsync(
        serviceId: serviceId,
        method: method,
        payload: payload,
      );
      return _unwrapConnectStatus(
        service,
        method,
        result.statusCode,
        result.payloadBytes,
      );
    }
    throw UnsupportedError('Unknown Esperanto service: $service.$method');
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
    if (_isContextPlayerService(service)) {
      if (method == 'GetState') {
        return _ReplayingBroadcastStream(
          _stateController.stream,
          () => _lastStateBytes,
          () => _isDestroyed,
        );
      }
      if (method == 'GetQueue') {
        return _ReplayingBroadcastStream(
          _queueController.stream,
          () => _lastQueueBytes,
          () => _isDestroyed,
        );
      }
      if (method == 'GetError') {
        return _errorController.stream;
      }
      throw UnsupportedError('Unknown ContextPlayer stream: $service.$method');
    }
    if (_isConnectService(service)) {
      if (method == 'State') {
        final initial = _callConnectNative(
          _ffi.connectServiceCall,
          service,
          'State',
          payload,
        );
        _lastConnectStateBytes = initial;
        return _ReplayingBroadcastStream(
          _connectStateController.stream,
          () => _lastConnectStateBytes,
          () => _isDestroyed,
        );
      }
      if (method == 'InstallSpotify') {
        final initial = _callConnectNative(
          _ffi.connectServiceCall,
          service,
          'InstallSpotify',
          payload,
        );
        _lastInstallSpotifyBytes = initial;
        return _ReplayingBroadcastStream(
          _installSpotifyController.stream,
          () => _lastInstallSpotifyBytes,
          () => _isDestroyed,
        );
      }
      throw UnsupportedError('Unknown ConnectService stream: $service.$method');
    }
    if (_isConnectVolumeService(service)) {
      if (method == 'Volume') {
        final initial = _callConnectNative(
          _ffi.connectVolumeServiceCall,
          service,
          'Volume',
          payload,
        );
        _lastVolumeBytes = initial;
        return _ReplayingBroadcastStream(
          _volumeController.stream,
          () => _lastVolumeBytes,
          () => _isDestroyed,
        );
      }
      if (method == 'LocalVolume') {
        final initial = _callConnectNative(
          _ffi.connectVolumeServiceCall,
          service,
          'LocalVolume',
          payload,
        );
        _lastLocalVolumeBytes = initial;
        return _ReplayingBroadcastStream(
          _localVolumeController.stream,
          () => _lastLocalVolumeBytes,
          () => _isDestroyed,
        );
      }
      throw UnsupportedError(
        'Unknown ConnectVolumeService stream: $service.$method',
      );
    }
    if (_isDodoService(service)) {
      if (method == 'DodoSub' || method == 'Dodos' || method == 'Sub') {
        final initial = _callConnectNative(
          _ffi.dodoServiceCall,
          service,
          method,
          payload,
        );
        _lastDodoBytes = initial;
        return _ReplayingBroadcastStream(
          _dodoController.stream,
          () => _lastDodoBytes,
          () => _isDestroyed,
        );
      }
      throw UnsupportedError('Unknown DodoService stream: $service.$method');
    }
    throw UnsupportedError(
      'Unknown Esperanto stream service: $service.$method',
    );
  }

  @override
  Uint8List callSync(String service, String method, Uint8List payload) {
    if (_isInvalidated) {
      throw StateError(
        'callSync() invoked after invalidation: $service.$method',
      );
    }
    if (_isContextPlayerService(service)) {
      if (method == 'GetState') {
        if (_lastStateBytes case final stateBytes?) {
          return stateBytes;
        }
        return Uint8List(0);
      }
      if (method == 'GetQueue') {
        if (_lastQueueBytes case final queueBytes?) {
          return queueBytes;
        }
        return Uint8List(0);
      }
      throw UnsupportedError(
        'Unknown ContextPlayer sync method: $service.$method',
      );
    }
    if (_isConnectService(service)) {
      return _callConnectNative(
        _ffi.connectServiceCall,
        service,
        method,
        payload,
      );
    }
    if (_isConnectVolumeService(service)) {
      return _callConnectNative(
        _ffi.connectVolumeServiceCall,
        service,
        method,
        payload,
      );
    }
    if (_isDodoService(service)) {
      return _callConnectNative(
        _ffi.dodoServiceCall,
        service,
        method,
        payload,
      );
    }
    throw UnsupportedError('Unknown Esperanto sync service: $service.$method');
  }

  static bool _isContextPlayerService(String service) =>
      service == contextPlayerService || service == 'ContextPlayer';

  static bool _isConnectService(String service) =>
      service == connectService || service == 'ConnectService';

  static bool _isConnectVolumeService(String service) =>
      service == connectVolumeService || service == 'ConnectVolumeService';

  static bool _isDodoService(String service) =>
      service == dodoService || service == 'DodoService';

  // ---------------------------------------------------------------------------
  // Command dispatch to C++ ContextPlayerImpl & ConnectServices via FFI
  // ---------------------------------------------------------------------------

  Uint8List _unwrapConnectStatus(
    String service,
    String method,
    int status,
    Uint8List resultBytes,
  ) {
    if (status == 5) {
      throw UnsupportedError('Unknown Esperanto method: $service.$method');
    }
    if (status == 6) {
      throw FormatException(
        'Malformed protobuf payload for $service.$method',
      );
    }
    if (status != 0 && resultBytes.isEmpty) {
      if (status == 2) {
        throw ArgumentError('Invalid arguments for $service.$method');
      }
      throw StateError(
        'Esperanto native call failed for $service.$method (status=$status)',
      );
    }
    return resultBytes;
  }

  Uint8List _callConnectNative(
    _NativeServiceCallFn fn,
    String service,
    String method,
    Uint8List payload,
  ) {
    Pointer<Utf8> methodPtr = nullptr;
    Pointer<Int32> outLenPtr = nullptr;
    Pointer<Int32> outStatusPtr = nullptr;
    Pointer<Uint8> payloadPtr = nullptr;

    try {
      methodPtr = method.toNativeUtf8();
      outLenPtr = calloc<Int32>();
      outStatusPtr = calloc<Int32>();
      if (payload.isNotEmpty) {
        payloadPtr = calloc<Uint8>(payload.length);
        payloadPtr.asTypedList(payload.length).setAll(0, payload);
      }

      final bytesPtr = fn(
        _connectHandle,
        methodPtr,
        payloadPtr,
        payload.length,
        outLenPtr,
        outStatusPtr,
      );
      final int len = outLenPtr.value;
      final int status = outStatusPtr.value;
      final Uint8List resultBytes;
      if (bytesPtr != nullptr) {
        try {
          if (len > 0) {
            final copy = Uint8List(len);
            copy.setAll(0, bytesPtr.asTypedList(len));
            resultBytes = copy;
          } else {
            resultBytes = Uint8List(0);
          }
        } finally {
          _ffi.freeBytes(bytesPtr);
        }
      } else {
        resultBytes = Uint8List(0);
      }

      return _unwrapConnectStatus(service, method, status, resultBytes);
    } finally {
      if (payloadPtr != nullptr) calloc.free(payloadPtr);
      if (outStatusPtr != nullptr) calloc.free(outStatusPtr);
      if (outLenPtr != nullptr) calloc.free(outLenPtr);
      if (methodPtr != nullptr) calloc.free(methodPtr);
    }
  }

  Uint8List _dispatchCommand(String method, Uint8List payload) {
    Pointer<Utf8> methodPtr = nullptr;
    Pointer<Uint8> payloadPtr = nullptr;
    try {
      methodPtr = method.toNativeUtf8();
      if (payload.isEmpty) {
        _ffi.cpiHandleCommand(_nThis, methodPtr, nullptr, 0);
      } else {
        payloadPtr = calloc<Uint8>(payload.length);
        payloadPtr.asTypedList(payload.length).setAll(0, payload);
        _ffi.cpiHandleCommand(
          _nThis,
          methodPtr,
          payloadPtr,
          payload.length,
        );
      }
    } finally {
      if (payloadPtr != nullptr) calloc.free(payloadPtr);
      if (methodPtr != nullptr) calloc.free(methodPtr);
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
      if (bytesPtr != nullptr) {
        try {
          if (len > 0) {
            final bytes = Uint8List(len);
            bytes.setAll(0, bytesPtr.asTypedList(len));
            _lastStateBytes = bytes;
            if (!_stateController.isClosed) {
              _stateController.add(bytes);
            }
          }
        } finally {
          _ffi.freeBytes(bytesPtr);
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
      if (bytesPtr != nullptr) {
        try {
          if (len > 0) {
            final bytes = Uint8List(len);
            bytes.setAll(0, bytesPtr.asTypedList(len));
            _lastQueueBytes = bytes;
            if (!_queueController.isClosed) {
              _queueController.add(bytes);
            }
          }
        } finally {
          _ffi.freeBytes(bytesPtr);
        }
      }
    } finally {
      calloc.free(outLenPtr);
    }
  }

  // ---------------------------------------------------------------------------
  // Disposal (1:1 with NativeTransport.destroy() / invalidate())
  // ---------------------------------------------------------------------------

  void invalidate() {
    _isInvalidated = true;
  }

  void destroy() {
    if (_isDestroyed) return;

    // Dispose any attached gateways while _connectHandle is still alive so they
    // can cleanly unbind their diagnostic ports prior to connectDestroy().
    final gateways = List<NativeConnectGateway>.of(_attachedGateways);
    _attachedGateways.clear();
    for (final gateway in gateways) {
      gateway.dispose();
    }

    _isDestroyed = true;
    invalidate();

    _connectRpcDispatcher.dispose();

    _lastStateBytes = null;
    _lastQueueBytes = null;
    _lastConnectStateBytes = null;
    _lastVolumeBytes = null;
    _lastLocalVolumeBytes = null;
    _lastDodoBytes = null;
    _lastInstallSpotifyBytes = null;

    final subs = List<StreamSubscription<Object?>>.of(_portSubscriptions);
    _portSubscriptions.clear();
    for (final sub in subs) {
      unawaited(sub.cancel());
    }

    // Destroy ConnectSubsystem bundle strictly BEFORE ContextPlayerImpl (_nThis)
    // because ConnectSubsystem holds ContextPlayerImpl& and removes its listener on stop().
    _ffi.connectSetStatePort(_connectHandle, 0);
    _ffi.connectSetVolumePort(_connectHandle, 0);
    _ffi.connectSetLocalVolumePort(_connectHandle, 0);
    _ffi.connectSetDodoPort(_connectHandle, 0);
    _ffi.connectSetInstallSpotifyPort(_connectHandle, 0);
    _connectStatePort.close();
    _volumePort.close();
    _localVolumePort.close();
    _dodoPort.close();
    _installSpotifyPort.close();
    unawaited(_connectStateController.close());
    unawaited(_volumeController.close());
    unawaited(_localVolumeController.close());
    unawaited(_dodoController.close());
    unawaited(_installSpotifyController.close());
    _ffi.connectDestroy(_connectHandle);

    _ffi.cpiSetStateChangedPort(_nThis, 0);
    _ffi.cpiSetQueueChangedPort(_nThis, 0);
    _ffi.cpiSetErrorPort(_nThis, 0);
    _statePort.close();
    _queuePort.close();
    _errorPort.close();
    unawaited(_stateController.close());
    unawaited(_queueController.close());
    unawaited(_errorController.close());
    _ffi.cpiDestroy(_nThis);
  }

  void dispose() => destroy();
}

final class _ReplayingBroadcastStream extends Stream<Uint8List> {
  _ReplayingBroadcastStream(
    this._source,
    this._getLatest,
    this._isDestroyed,
  );

  final Stream<Uint8List> _source;
  final Uint8List? Function() _getLatest;
  final bool Function() _isDestroyed;

  @override
  bool get isBroadcast => true;

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    StreamSubscription<Uint8List>? sourceSub;
    final perSubController = StreamController<Uint8List>();

    perSubController.onListen = () {
      if (_isDestroyed()) {
        unawaited(perSubController.close());
        return;
      }
      if (_getLatest() case final latest?) {
        perSubController.add(latest);
      }
      sourceSub = _source.listen(
        perSubController.add,
        onError: perSubController.addError,
        onDone: () {
          sourceSub = null;
          if (!perSubController.isClosed) {
            unawaited(perSubController.close());
          }
        },
      );
    };

    perSubController.onCancel = () {
      if (sourceSub case final sub?) {
        sourceSub = null;
        return sub.cancel();
      }
      return null;
    };

    return perSubController.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
