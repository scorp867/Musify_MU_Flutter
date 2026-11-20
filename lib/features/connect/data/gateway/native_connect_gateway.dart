import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:musify_mu/core/audio/musify_ffi_bindings.dart';
import 'package:musify_mu/features/connect/domain/interfaces/connect_native_gateway.dart';

final class _PendingRpcCall {
  final Completer<ConnectAsyncCallResult> completer;
  final Timer timer;

  const _PendingRpcCall({
    required this.completer,
    required this.timer,
  });
}

/// Reusable non-blocking FFI dispatcher for `musify_connect_call_async`.
///
/// Marshals Esperanto RPC requests onto the native C++ Connect worker pool and
/// correlates asynchronous `[request_id, status_code, payload_bytes]` replies
/// delivered on a dedicated Dart [ReceivePort], eliminating UI-isolate
/// `libcurl` blocking.
final class NativeConnectRpcDispatcher {
  static const Duration defaultTimeout = Duration(seconds: 30);

  final MusifyFfiBindings _ffi;
  final Pointer<Void> _connectHandle;
  final Duration _defaultTimeout;
  final bool Function() _isHandleAlive;

  final ReceivePort _replyPort = ReceivePort('musify_connect_rpc_reply');
  StreamSubscription<Object?>? _replySub;
  final Map<int, _PendingRpcCall> _pending = <int, _PendingRpcCall>{};

  int _nextRequestId = 1;
  bool _disposed = false;

  NativeConnectRpcDispatcher({
    required MusifyFfiBindings ffi,
    required Pointer<Void> connectHandle,
    Duration defaultTimeout = NativeConnectRpcDispatcher.defaultTimeout,
    bool Function()? isHandleAlive,
  })  : _ffi = ffi,
        _connectHandle = connectHandle,
        _defaultTimeout = defaultTimeout,
        _isHandleAlive = switch (isHandleAlive) {
          final predicate? => predicate,
          null => _alwaysAlive,
        } {
    if (connectHandle == nullptr) {
      _replyPort.close();
      throw ArgumentError.value(
        connectHandle,
        'connectHandle',
        'Native Connect handle must not be nullptr',
      );
    }
    _replySub = _replyPort.listen(_onReply);
  }

  static bool _alwaysAlive() => true;

  bool get isDisposed => _disposed;

  /// Native reply port used to correlate `musify_connect_call_async` replies.
  SendPort get replySendPort => _replyPort.sendPort;

  @visibleForTesting
  int get pendingCount => _pending.length;

  /// Enqueues an asynchronous Connect Esperanto RPC on the native worker pool
  /// and resolves when the matching `request_id` reply arrives on [_replyPort].
  Future<ConnectAsyncCallResult> callAsync({
    required ConnectEsperantoServiceId serviceId,
    required String method,
    required Uint8List payload,
    Duration? timeout,
  }) {
    if (_disposed || !_isHandleAlive()) {
      return Future<ConnectAsyncCallResult>.error(
        StateError(
          'NativeConnectRpcDispatcher is disposed: ${serviceId.serviceName}.$method',
        ),
      );
    }
    if (method.trim().isEmpty) {
      return Future<ConnectAsyncCallResult>.error(
        ArgumentError.value(method, 'method', 'RPC method must be non-empty'),
      );
    }

    final effectiveTimeout = switch (timeout) {
      final override? => override,
      null => _defaultTimeout,
    };

    final requestId = _nextRequestId;
    _nextRequestId += 1;

    final completer = Completer<ConnectAsyncCallResult>();
    final timer = Timer(effectiveTimeout, () {
      final timedOut = _pending.remove(requestId);
      if (timedOut != null && !timedOut.completer.isCompleted) {
        timedOut.completer.completeError(
          TimeoutException(
            'Connect async RPC timed out after '
            '${effectiveTimeout.inMilliseconds}ms: '
            '${serviceId.serviceName}.$method (requestId=$requestId)',
            effectiveTimeout,
          ),
        );
      }
    });

    _pending[requestId] = _PendingRpcCall(completer: completer, timer: timer);

    Pointer<Utf8> methodPtr = nullptr;
    Pointer<Uint8> payloadPtr = nullptr;
    var enqueued = false;

    try {
      methodPtr = method.toNativeUtf8();
      if (payload.isNotEmpty) {
        payloadPtr = calloc<Uint8>(payload.length);
        payloadPtr.asTypedList(payload.length).setAll(0, payload);
      }

      final enqueueCode = _ffi.connectCallAsync(
        _connectHandle,
        serviceId.id,
        methodPtr,
        payloadPtr,
        payload.length,
        requestId,
        _replyPort.sendPort.nativePort,
      );

      if (enqueueCode == -1) {
        throw ArgumentError(
          'Invalid arguments for musify_connect_call_async: '
          '${serviceId.serviceName}.$method',
        );
      }
      if (enqueueCode == -2) {
        throw StateError(
          'ConnectSubsystem is destroyed or stopping: '
          '${serviceId.serviceName}.$method',
        );
      }
      if (enqueueCode != 0) {
        throw StateError(
          'musify_connect_call_async failed for '
          '${serviceId.serviceName}.$method (code=$enqueueCode)',
        );
      }
      enqueued = true;
    } catch (error, stackTrace) {
      final removed = _pending.remove(requestId);
      if (removed != null) {
        removed.timer.cancel();
      }
      return Future<ConnectAsyncCallResult>.error(error, stackTrace);
    } finally {
      if (!enqueued) {
        final removed = _pending.remove(requestId);
        if (removed != null) {
          removed.timer.cancel();
        }
      }
      if (payloadPtr != nullptr) {
        calloc.free(payloadPtr);
      }
      if (methodPtr != nullptr) {
        calloc.free(methodPtr);
      }
    }

    return completer.future;
  }

  void _onReply(Object? message) {
    if (_disposed) return;

    if (message is! List<Object?> || message.length != 3) {
      dev.log(
        'NativeConnectRpcDispatcher: malformed reply envelope: $message',
        name: 'NativeConnectGateway',
      );
      return;
    }

    final Object? rawRequestId = message[0];
    final Object? rawStatusCode = message[1];
    final Object? rawPayload = message[2];

    if (rawRequestId is! int) {
      dev.log(
        'NativeConnectRpcDispatcher: non-int request_id in reply: $rawRequestId',
        name: 'NativeConnectGateway',
      );
      return;
    }

    final pending = _pending.remove(rawRequestId);
    if (pending == null) {
      return;
    }
    pending.timer.cancel();

    if (pending.completer.isCompleted) {
      return;
    }

    if (rawStatusCode is! int) {
      pending.completer.completeError(
        FormatException(
          'Invalid Connect async RPC status_code type: '
          '${rawStatusCode.runtimeType}',
        ),
      );
      return;
    }

    final Uint8List payloadBytes;
    if (rawPayload is Uint8List) {
      payloadBytes = rawPayload;
    } else if (rawPayload == null) {
      payloadBytes = Uint8List(0);
    } else {
      pending.completer.completeError(
        FormatException(
          'Invalid Connect async RPC payload type: ${rawPayload.runtimeType}',
        ),
      );
      return;
    }

    pending.completer.complete(
      ConnectAsyncCallResult(
        statusCode: rawStatusCode,
        payloadBytes: payloadBytes,
      ),
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    final pendingEntries = List<_PendingRpcCall>.of(_pending.values);
    _pending.clear();
    for (final entry in pendingEntries) {
      entry.timer.cancel();
      if (!entry.completer.isCompleted) {
        entry.completer.completeError(
          StateError('Connect async RPC aborted: dispatcher disposed'),
        );
      }
    }

    if (_replySub case final sub?) {
      _replySub = null;
      unawaited(sub.cancel());
    }
    _replyPort.close();
  }
}

/// Concrete [ConnectNativeGateway] backed by `libmusify_audio.so` FFI bindings
/// (`#47 §2`, `#47 §5`).
///
/// Supports both standalone construction (binding `local_volume_port` and
/// `diagnostic_port` directly) and [NativeConnectGateway.sharedLocalVolume]
/// when co-hosted with `NativeEsperantoTransport` on the same native
/// `ConnectSubsystem` handle so the single native `local_volume_port` slot is
/// never overwritten.
final class NativeConnectGateway implements ConnectNativeGateway {
  static const Duration defaultRpcTimeout =
      NativeConnectRpcDispatcher.defaultTimeout;

  final MusifyFfiBindings _ffi;
  final Pointer<Void> _connectHandle;
  final bool Function() _isHandleAlive;
  final void Function()? _onDispose;
  final NativeConnectRpcDispatcher _rpcDispatcher;

  final bool _ownsLocalVolumePort;
  final ReceivePort? _localVolumePort;
  StreamSubscription<Object?>? _localVolumeSub;
  final StreamController<Uint8List>? _localVolumeController;
  final Stream<Uint8List> _localVolumeStream;

  final ReceivePort _diagnosticPort;
  StreamSubscription<Object?>? _diagnosticSub;
  final StreamController<String> _diagnosticController =
      StreamController<String>.broadcast();

  bool _localVolumePortBound = false;
  bool _diagnosticPortBound = false;
  bool _disposed = false;

  /// Creates a standalone [NativeConnectGateway] bound directly to
  /// [connectHandle], owning both `local_volume_port` and `diagnostic_port`.
  factory NativeConnectGateway({
    required Pointer<Void> connectHandle,
    MusifyFfiBindings? ffi,
    bool Function()? isHandleAlive,
    void Function()? onDispose,
    Duration rpcTimeout = defaultRpcTimeout,
  }) {
    if (connectHandle == nullptr) {
      throw ArgumentError.value(
        connectHandle,
        'connectHandle',
        'Native Connect handle must not be nullptr',
      );
    }
    final resolvedFfi = switch (ffi) {
      final providedFfi? => providedFfi,
      null => MusifyFfiBindings.instance,
    };
    final localVolumePort = ReceivePort('musify_gateway_local_volume');
    final localVolumeController = StreamController<Uint8List>.broadcast();
    final diagnosticPort = ReceivePort('musify_connect_diagnostics');

    return NativeConnectGateway._(
      ffi: resolvedFfi,
      connectHandle: connectHandle,
      isHandleAlive: switch (isHandleAlive) {
        final predicate? => predicate,
        null => _alwaysAlive,
      },
      onDispose: onDispose,
      rpcTimeout: rpcTimeout,
      ownsLocalVolumePort: true,
      localVolumePort: localVolumePort,
      localVolumeController: localVolumeController,
      localVolumeStream: localVolumeController.stream,
      diagnosticPort: diagnosticPort,
    );
  }

  /// Creates a [NativeConnectGateway] sharing an existing broadcast
  /// [localVolumeStream] (for example from `NativeEsperantoTransport`) without
  /// overwriting the single native `local_volume_port` slot.
  factory NativeConnectGateway.sharedLocalVolume({
    required Pointer<Void> connectHandle,
    required Stream<Uint8List> localVolumeStream,
    MusifyFfiBindings? ffi,
    bool Function()? isHandleAlive,
    void Function()? onDispose,
    Duration rpcTimeout = defaultRpcTimeout,
  }) {
    if (connectHandle == nullptr) {
      throw ArgumentError.value(
        connectHandle,
        'connectHandle',
        'Native Connect handle must not be nullptr',
      );
    }
    final resolvedFfi = switch (ffi) {
      final providedFfi? => providedFfi,
      null => MusifyFfiBindings.instance,
    };
    final diagnosticPort = ReceivePort('musify_connect_diagnostics');

    return NativeConnectGateway._(
      ffi: resolvedFfi,
      connectHandle: connectHandle,
      isHandleAlive: switch (isHandleAlive) {
        final predicate? => predicate,
        null => _alwaysAlive,
      },
      onDispose: onDispose,
      rpcTimeout: rpcTimeout,
      ownsLocalVolumePort: false,
      localVolumePort: null,
      localVolumeController: null,
      localVolumeStream: localVolumeStream,
      diagnosticPort: diagnosticPort,
    );
  }

  NativeConnectGateway._({
    required MusifyFfiBindings ffi,
    required Pointer<Void> connectHandle,
    required bool Function() isHandleAlive,
    required void Function()? onDispose,
    required Duration rpcTimeout,
    required bool ownsLocalVolumePort,
    required ReceivePort? localVolumePort,
    required StreamController<Uint8List>? localVolumeController,
    required Stream<Uint8List> localVolumeStream,
    required ReceivePort diagnosticPort,
  })  : _ffi = ffi,
        _connectHandle = connectHandle,
        _isHandleAlive = isHandleAlive,
        _onDispose = onDispose,
        _rpcDispatcher = NativeConnectRpcDispatcher(
          ffi: ffi,
          connectHandle: connectHandle,
          defaultTimeout: rpcTimeout,
          isHandleAlive: isHandleAlive,
        ),
        _ownsLocalVolumePort = ownsLocalVolumePort,
        _localVolumePort = localVolumePort,
        _localVolumeController = localVolumeController,
        _localVolumeStream = localVolumeStream,
        _diagnosticPort = diagnosticPort {
    try {
      if (_ownsLocalVolumePort) {
        if (_localVolumePort case final port?) {
          _localVolumeSub = port.listen(_onLocalVolumeMessage);
          _ffi.connectSetLocalVolumePort(
            _connectHandle,
            port.sendPort.nativePort,
          );
          _localVolumePortBound = true;
        }
      }

      _diagnosticSub = _diagnosticPort.listen(_onDiagnosticMessage);
      _ffi.connectSetDiagnosticPort(
        _connectHandle,
        _diagnosticPort.sendPort.nativePort,
      );
      _diagnosticPortBound = true;
    } on Object {
      dispose();
      rethrow;
    }
  }

  static bool _alwaysAlive() => true;

  bool get isDisposed => _disposed;

  @visibleForTesting
  SendPort? get localVolumeSendPort {
    if (_localVolumePort case final port?) {
      return port.sendPort;
    }
    return null;
  }

  @visibleForTesting
  SendPort get diagnosticSendPort => _diagnosticPort.sendPort;

  @visibleForTesting
  SendPort get rpcReplySendPort => _rpcDispatcher.replySendPort;

  void _ensureAlive(String operation) {
    if (_disposed || !_isHandleAlive()) {
      throw StateError(
        'NativeConnectGateway.$operation() called after disposal',
      );
    }
  }

  void _onLocalVolumeMessage(Object? data) {
    if (_disposed) return;
    if (_localVolumeController case final controller?) {
      if (controller.isClosed) return;
      if (data case final Uint8List bytes) {
        controller.add(bytes);
      }
    }
  }

  void _onDiagnosticMessage(Object? data) {
    if (_disposed || _diagnosticController.isClosed) return;
    if (data case final String text) {
      _diagnosticController.add(text);
      return;
    }
    if (data case final Uint8List bytes) {
      try {
        _diagnosticController.add(utf8.decode(bytes));
      } on FormatException catch (error, stackTrace) {
        _diagnosticController.addError(error, stackTrace);
      }
    }
  }

  @override
  int start(Uint8List deviceInfoBytes) {
    _ensureAlive('start');
    if (deviceInfoBytes.isEmpty) {
      return _ffi.connectStart(_connectHandle, nullptr, 0);
    }
    final buffer = calloc<Uint8>(deviceInfoBytes.length);
    try {
      buffer.asTypedList(deviceInfoBytes.length).setAll(0, deviceInfoBytes);
      return _ffi.connectStart(_connectHandle, buffer, deviceInfoBytes.length);
    } finally {
      calloc.free(buffer);
    }
  }

  @override
  void stop() {
    _ensureAlive('stop');
    _ffi.connectStop(_connectHandle);
  }

  @override
  int setEndpoints({
    required String spclientBaseUrl,
    required String dealerWsUrl,
  }) {
    _ensureAlive('setEndpoints');
    Pointer<Utf8> spclientPtr = nullptr;
    Pointer<Utf8> dealerPtr = nullptr;
    try {
      spclientPtr = spclientBaseUrl.toNativeUtf8();
      dealerPtr = dealerWsUrl.toNativeUtf8();
      return _ffi.connectSetEndpoints(_connectHandle, spclientPtr, dealerPtr);
    } finally {
      if (dealerPtr != nullptr) calloc.free(dealerPtr);
      if (spclientPtr != nullptr) calloc.free(spclientPtr);
    }
  }

  @override
  int reconnect(ConnectReconnectReason reason) {
    _ensureAlive('reconnect');
    return _ffi.connectReconnect(_connectHandle, reason.wireCode);
  }

  @override
  void setNetworkAvailable(bool isAvailable) {
    _ensureAlive('setNetworkAvailable');
    _ffi.connectSetNetworkAvailable(_connectHandle, isAvailable ? 1 : 0);
  }

  @override
  int updateNsdServices(String servicesJsonUtf8) {
    _ensureAlive('updateNsdServices');
    Pointer<Utf8> jsonPtr = nullptr;
    try {
      jsonPtr = servicesJsonUtf8.toNativeUtf8();
      return _ffi.connectUpdateNsdServices(_connectHandle, jsonPtr);
    } finally {
      if (jsonPtr != nullptr) calloc.free(jsonPtr);
    }
  }

  @override
  int setLocalVolume({
    required int volume0To65535,
    required int volumeSteps,
    required ConnectLocalVolumeReason reason,
  }) {
    _ensureAlive('setLocalVolume');
    if (volume0To65535 < 0 || volume0To65535 > 65535) {
      throw RangeError.range(
        volume0To65535,
        0,
        65535,
        'volume0To65535',
        'Volume must be within [0, 65535]',
      );
    }
    if (volumeSteps < 1) {
      throw RangeError.value(
        volumeSteps,
        'volumeSteps',
        'Volume steps must be >= 1',
      );
    }
    return _ffi.connectSetLocalVolume(
      _connectHandle,
      volume0To65535,
      volumeSteps,
      reason.wireCode,
    );
  }

  @override
  Future<ConnectAsyncCallResult> callServiceAsync({
    required ConnectEsperantoServiceId serviceId,
    required String method,
    required Uint8List payload,
  }) {
    if (_disposed || !_isHandleAlive()) {
      return Future<ConnectAsyncCallResult>.error(
        StateError(
          'NativeConnectGateway.callServiceAsync() called after disposal: '
          '${serviceId.serviceName}.$method',
        ),
      );
    }
    return _rpcDispatcher.callAsync(
      serviceId: serviceId,
      method: method,
      payload: payload,
    );
  }

  @override
  Stream<Uint8List> get localVolumeStream => _localVolumeStream;

  @override
  Stream<String> get diagnosticStream => _diagnosticController.stream;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    if (_onDispose case final detach?) {
      detach();
    }

    if (_isHandleAlive()) {
      if (_diagnosticPortBound) {
        _diagnosticPortBound = false;
        _ffi.connectSetDiagnosticPort(_connectHandle, 0);
      }
      if (_ownsLocalVolumePort && _localVolumePortBound) {
        _localVolumePortBound = false;
        _ffi.connectSetLocalVolumePort(_connectHandle, 0);
      }
    }

    _rpcDispatcher.dispose();

    if (_diagnosticSub case final sub?) {
      _diagnosticSub = null;
      unawaited(sub.cancel());
    }
    _diagnosticPort.close();
    if (!_diagnosticController.isClosed) {
      unawaited(_diagnosticController.close());
    }

    if (_ownsLocalVolumePort) {
      if (_localVolumeSub case final sub?) {
        _localVolumeSub = null;
        unawaited(sub.cancel());
      }
      if (_localVolumePort case final port?) {
        port.close();
      }
      if (_localVolumeController case final controller?) {
        if (!controller.isClosed) {
          unawaited(controller.close());
        }
      }
    }
  }
}
