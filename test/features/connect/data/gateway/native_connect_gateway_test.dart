import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/audio/musify_ffi_bindings.dart';
import 'package:musify_mu/features/connect/data/gateway/native_connect_gateway.dart';
import 'package:musify_mu/features/connect/domain/interfaces/connect_native_gateway.dart';

final class _RecordedAsyncEnqueue {
  final int serviceId;
  final String method;
  final Uint8List payload;
  final int requestId;
  final int replyPort;

  const _RecordedAsyncEnqueue({
    required this.serviceId,
    required this.method,
    required this.payload,
    required this.requestId,
    required this.replyPort,
  });
}

final class _GatewayFakeFfiBindings extends Fake implements MusifyFfiBindings {
  final Pointer<Void> expectedHandle;
  final List<_RecordedAsyncEnqueue> asyncCalls = <_RecordedAsyncEnqueue>[];

  int localVolumePort = -1;
  int diagnosticPort = -1;
  int localVolumePortSetCount = 0;
  int diagnosticPortSetCount = 0;

  Uint8List? lastStartBytes;
  int startReturnCode = 0;
  int stopCalls = 0;

  String? lastSpclientUrl;
  String? lastDealerWsUrl;
  int setEndpointsReturnCode = 0;

  int? lastReconnectReason;
  int reconnectReturnCode = 0;

  int? lastNetworkAvailable;
  String? lastNsdJson;
  int updateNsdReturnCode = 0;

  int? lastLocalVolume;
  int? lastLocalVolumeSteps;
  int? lastLocalVolumeReason;
  int setLocalVolumeReturnCode = 0;

  int nextEnqueueCode = 0;
  void Function(_RecordedAsyncEnqueue call)? onAsyncEnqueued;

  _GatewayFakeFfiBindings(this.expectedHandle);

  @override
  void connectSetLocalVolumePort(Pointer<Void> h, int port) {
    expect(h, equals(expectedHandle));
    localVolumePort = port;
    localVolumePortSetCount += 1;
  }

  @override
  void connectSetDiagnosticPort(Pointer<Void> h, int dartPort) {
    expect(h, equals(expectedHandle));
    diagnosticPort = dartPort;
    diagnosticPortSetCount += 1;
  }

  @override
  int connectStart(
    Pointer<Void> h,
    Pointer<Uint8> deviceInfoBytes,
    int len,
  ) {
    expect(h, equals(expectedHandle));
    if (deviceInfoBytes != nullptr && len > 0) {
      lastStartBytes = Uint8List.fromList(deviceInfoBytes.asTypedList(len));
    } else {
      lastStartBytes = Uint8List(0);
    }
    return startReturnCode;
  }

  @override
  void connectStop(Pointer<Void> h) {
    expect(h, equals(expectedHandle));
    stopCalls += 1;
  }

  @override
  int connectSetEndpoints(
    Pointer<Void> h,
    Pointer<Utf8> spclientBaseUrl,
    Pointer<Utf8> dealerWsUrl,
  ) {
    expect(h, equals(expectedHandle));
    lastSpclientUrl = spclientBaseUrl.toDartString();
    lastDealerWsUrl = dealerWsUrl.toDartString();
    return setEndpointsReturnCode;
  }

  @override
  int connectReconnect(Pointer<Void> h, int reasonCode) {
    expect(h, equals(expectedHandle));
    lastReconnectReason = reasonCode;
    return reconnectReturnCode;
  }

  @override
  void connectSetNetworkAvailable(Pointer<Void> h, int isAvailable) {
    expect(h, equals(expectedHandle));
    lastNetworkAvailable = isAvailable;
  }

  @override
  int connectUpdateNsdServices(
    Pointer<Void> h,
    Pointer<Utf8> servicesJsonUtf8,
  ) {
    expect(h, equals(expectedHandle));
    lastNsdJson = servicesJsonUtf8.toDartString();
    return updateNsdReturnCode;
  }

  @override
  int connectSetLocalVolume(
    Pointer<Void> h,
    int volume0To65535,
    int volumeSteps,
    int reasonCode,
  ) {
    expect(h, equals(expectedHandle));
    lastLocalVolume = volume0To65535;
    lastLocalVolumeSteps = volumeSteps;
    lastLocalVolumeReason = reasonCode;
    return setLocalVolumeReturnCode;
  }

  @override
  int connectCallAsync(
    Pointer<Void> h,
    int serviceId,
    Pointer<Utf8> method,
    Pointer<Uint8> payload,
    int payloadLen,
    int requestId,
    int replyPort,
  ) {
    expect(h, equals(expectedHandle));
    final copied = payload != nullptr && payloadLen > 0
        ? Uint8List.fromList(payload.asTypedList(payloadLen))
        : Uint8List(0);
    final call = _RecordedAsyncEnqueue(
      serviceId: serviceId,
      method: method.toDartString(),
      payload: copied,
      requestId: requestId,
      replyPort: replyPort,
    );
    asyncCalls.add(call);
    if (nextEnqueueCode == 0) {
      onAsyncEnqueued?.call(call);
    }
    return nextEnqueueCode;
  }
}

void main() {
  final validHandle = Pointer<Void>.fromAddress(0x55550);

  group('NativeConnectRpcDispatcher', () {
    test('correlates out-of-order async replies, enforces timeouts, and aborts pending calls on dispose()', () async {
      final ffi = _GatewayFakeFfiBindings(validHandle);

      expect(
        () => NativeConnectRpcDispatcher(ffi: ffi, connectHandle: nullptr),
        throwsArgumentError,
      );

      final dispatcher = NativeConnectRpcDispatcher(
        ffi: ffi,
        connectHandle: validHandle,
      );
      addTearDown(dispatcher.dispose);

      // Enqueue two calls and complete them in reverse order
      final f1 = dispatcher.callAsync(
        serviceId: ConnectEsperantoServiceId.connectService,
        method: 'Transfer',
        payload: Uint8List.fromList([1, 2]),
      );
      final f2 = dispatcher.callAsync(
        serviceId: ConnectEsperantoServiceId.connectVolumeService,
        method: 'VolumeSet',
        payload: Uint8List.fromList([3, 4]),
      );
      expect(dispatcher.pendingCount, equals(2));
      expect(ffi.asyncCalls, hasLength(2));

      final id1 = ffi.asyncCalls[0].requestId;
      final id2 = ffi.asyncCalls[1].requestId;
      expect(id2, greaterThan(id1));

      dispatcher.replySendPort.send(<Object?>[
        id2,
        0,
        Uint8List.fromList([0xAA]),
      ]);
      dispatcher.replySendPort.send(<Object?>[
        id1,
        2,
        Uint8List.fromList([0xBB, 0xCC]),
      ]);

      final res2 = await f2;
      final res1 = await f1;
      expect(res2.isOk, isTrue);
      expect(res2.payloadBytes, equals(Uint8List.fromList([0xAA])));
      expect(res1.statusCode, equals(2));
      expect(res1.isOk, isFalse);
      expect(res1.payloadBytes, equals(Uint8List.fromList([0xBB, 0xCC])));
      expect(dispatcher.pendingCount, equals(0));

      // Timeout handling
      await expectLater(
        () => dispatcher.callAsync(
          serviceId: ConnectEsperantoServiceId.dodoService,
          method: 'SwitchToDodo',
          payload: Uint8List(0),
          timeout: const Duration(milliseconds: 20),
        ),
        throwsA(isA<TimeoutException>()),
      );
      expect(dispatcher.pendingCount, equals(0));

      // Enqueue error codes (-1 -> ArgumentError, -2 -> StateError)
      ffi.nextEnqueueCode = -1;
      await expectLater(
        () => dispatcher.callAsync(
          serviceId: ConnectEsperantoServiceId.connectService,
          method: 'Transfer',
          payload: Uint8List(0),
        ),
        throwsArgumentError,
      );

      ffi.nextEnqueueCode = -2;
      await expectLater(
        () => dispatcher.callAsync(
          serviceId: ConnectEsperantoServiceId.connectService,
          method: 'Transfer',
          payload: Uint8List(0),
        ),
        throwsStateError,
      );

      ffi.nextEnqueueCode = 0;
      await expectLater(
        () => dispatcher.callAsync(
          serviceId: ConnectEsperantoServiceId.connectService,
          method: '   ',
          payload: Uint8List(0),
        ),
        throwsArgumentError,
      );

      // Disposing with in-flight call aborts pending completer with StateError
      final inFlight = dispatcher.callAsync(
        serviceId: ConnectEsperantoServiceId.connectService,
        method: 'RefreshCluster',
        payload: Uint8List(0),
      );
      dispatcher.dispose();
      await expectLater(() => inFlight, throwsStateError);
    });
  });

  group('NativeConnectGateway', () {
    test('standalone gateway binds and unbinds local_volume_port and diagnostic_port and executes all FFI methods', () async {
      final ffi = _GatewayFakeFfiBindings(validHandle);
      SendPort? replyPort;
      ffi.onAsyncEnqueued = (call) {
        final port = replyPort;
        if (port != null) {
          scheduleMicrotask(() {
            port.send(<Object?>[
              call.requestId,
              0,
              Uint8List.fromList([7, 8, 9]),
            ]);
          });
        }
      };

      final gateway = NativeConnectGateway(
        connectHandle: validHandle,
        ffi: ffi,
      );
      replyPort = gateway.rpcReplySendPort;

      expect(ffi.localVolumePort, isPositive);
      expect(ffi.diagnosticPort, isPositive);

      final startBytes = Uint8List.fromList([10, 20, 30]);
      expect(gateway.start(startBytes), equals(0));
      expect(ffi.lastStartBytes, equals(startBytes));

      expect(
        gateway.setEndpoints(
          spclientBaseUrl: 'https://gew4-spclient.spotify.com/',
          dealerWsUrl: 'wss://gew4-dealer.g2.spotify.com:443/',
        ),
        equals(0),
      );
      expect(
        ffi.lastSpclientUrl,
        equals('https://gew4-spclient.spotify.com/'),
      );
      expect(
        ffi.lastDealerWsUrl,
        equals('wss://gew4-dealer.g2.spotify.com:443/'),
      );

      expect(
        gateway.reconnect(ConnectReconnectReason.foreground),
        equals(0),
      );
      expect(ffi.lastReconnectReason, equals(1));

      gateway.setNetworkAvailable(true);
      expect(ffi.lastNetworkAvailable, equals(1));
      gateway.setNetworkAvailable(false);
      expect(ffi.lastNetworkAvailable, equals(0));

      expect(
        gateway.updateNsdServices('[{"serviceName":"Spk","host":"10.0.0.2","port":8009}]'),
        equals(0),
      );
      expect(
        ffi.lastNsdJson,
        equals('[{"serviceName":"Spk","host":"10.0.0.2","port":8009}]'),
      );

      expect(
        gateway.setLocalVolume(
          volume0To65535: 32768,
          volumeSteps: 25,
          reason: ConnectLocalVolumeReason.user,
        ),
        equals(0),
      );
      expect(ffi.lastLocalVolume, equals(32768));
      expect(ffi.lastLocalVolumeSteps, equals(25));
      expect(ffi.lastLocalVolumeReason, equals(0));

      // Fail-fast RangeError on invalid volume or steps
      expect(
        () => gateway.setLocalVolume(
          volume0To65535: -1,
          volumeSteps: 25,
          reason: ConnectLocalVolumeReason.user,
        ),
        throwsRangeError,
      );
      expect(
        () => gateway.setLocalVolume(
          volume0To65535: 70000,
          volumeSteps: 25,
          reason: ConnectLocalVolumeReason.user,
        ),
        throwsRangeError,
      );
      expect(
        () => gateway.setLocalVolume(
          volume0To65535: 1000,
          volumeSteps: 0,
          reason: ConnectLocalVolumeReason.system,
        ),
        throwsRangeError,
      );

      final rpcResult = await gateway.callServiceAsync(
        serviceId: ConnectEsperantoServiceId.connectService,
        method: 'PerformDiscovery',
        payload: Uint8List(0),
      );
      expect(rpcResult.isOk, isTrue);
      expect(rpcResult.payloadBytes, equals(Uint8List.fromList([7, 8, 9])));

      // Verify localVolumeStream and diagnosticStream (String and UTF-8 bytes)
      final localVolEvents = <Uint8List>[];
      final diagEvents = <String>[];
      final volSub = gateway.localVolumeStream.listen(localVolEvents.add);
      final diagSub = gateway.diagnosticStream.listen(diagEvents.add);

      final volSendPort = gateway.localVolumeSendPort;
      expect(volSendPort, isNotNull);
      if (volSendPort != null) {
        volSendPort.send(Uint8List.fromList([1, 2, 3]));
      }
      gateway.diagnosticSendPort.send('{"event":"dealer_connected"}');
      gateway.diagnosticSendPort.send(
        Uint8List.fromList(utf8.encode('{"event":"put_state_ok"}')),
      );
      await pumpEventQueue();

      expect(localVolEvents, equals(<Uint8List>[Uint8List.fromList([1, 2, 3])]));
      expect(
        diagEvents,
        equals(<String>[
          '{"event":"dealer_connected"}',
          '{"event":"put_state_ok"}',
        ]),
      );

      await volSub.cancel();
      await diagSub.cancel();

      gateway.stop();
      expect(ffi.stopCalls, equals(1));

      gateway.dispose();
      expect(gateway.isDisposed, isTrue);
      expect(ffi.localVolumePort, equals(0));
      expect(ffi.diagnosticPort, equals(0));

      expect(() => gateway.start(Uint8List(0)), throwsStateError);
      expect(gateway.stop, throwsStateError);
    });

    test('sharedLocalVolume constructor does not overwrite native local_volume_port', () async {
      final ffi = _GatewayFakeFfiBindings(validHandle);
      final sharedController = StreamController<Uint8List>.broadcast();
      addTearDown(sharedController.close);

      var detachedCount = 0;
      final gateway = NativeConnectGateway.sharedLocalVolume(
        connectHandle: validHandle,
        localVolumeStream: sharedController.stream,
        ffi: ffi,
        onDispose: () {
          detachedCount += 1;
        },
      );

      expect(ffi.localVolumePortSetCount, equals(0));
      expect(ffi.diagnosticPortSetCount, equals(1));
      expect(ffi.diagnosticPort, isPositive);

      final received = <Uint8List>[];
      final sub = gateway.localVolumeStream.listen(received.add);
      sharedController.add(Uint8List.fromList([42]));
      await pumpEventQueue();
      expect(received, equals(<Uint8List>[Uint8List.fromList([42])]));
      await sub.cancel();

      gateway.dispose();
      expect(detachedCount, equals(1));
      expect(ffi.localVolumePortSetCount, equals(0));
      expect(ffi.diagnosticPort, equals(0));
    });
  });
}
