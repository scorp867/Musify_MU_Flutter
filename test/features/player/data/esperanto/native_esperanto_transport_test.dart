// 1:1 Esperanto Native Transport & Connect FFI Routing Tests (Items 131-132, Wave 2 Async RPCs)

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/audio/musify_ffi_bindings.dart';
import 'package:musify_mu/core/audio/musify_native_audio_engine.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart';
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pb.dart';
import 'package:musify_mu/features/connect/data/proto/es_dodos_messages.pb.dart';
import 'package:musify_mu/features/connect/data/proto/es_volume_messages.pb.dart';
import 'package:musify_mu/features/player/data/esperanto/native_esperanto_transport.dart';

class _FakeEngine extends Fake implements MusifyNativeAudioEngine {
  _FakeEngine(this._handle);

  final Pointer<Void> _handle;

  @override
  Pointer<Void> get handle => _handle;
}

class _RecordedCall {
  _RecordedCall(this.service, this.method, this.payload);

  final String service;
  final String method;
  final Uint8List payload;
}

class _MockNativeResponse {
  _MockNativeResponse(this.status, this.bytes);

  final int status;
  final Uint8List bytes;
}

class _FakeFfiBindings extends Fake implements MusifyFfiBindings {
  final List<String> lifecycleLog = <String>[];
  final List<_RecordedCall> serviceCalls = <_RecordedCall>[];
  final Set<int> allocatedAddresses = <int>{};
  final Set<int> freedAddresses = <int>{};

  bool failConnectCreate = false;
  bool failCpiCreate = false;
  Uint8List? initialCpiState;
  Uint8List? initialCpiQueue;

  int cpiStatePort = 0;
  int cpiQueuePort = 0;
  int cpiErrorPort = 0;

  int connectStatePort = 0;
  int volumePort = 0;
  int localVolumePort = 0;
  int dodoPort = 0;
  int installSpotifyPort = 0;
  int diagnosticPort = 0;

  int connectStartCalls = 0;
  Uint8List? lastConnectStartBytes;
  int connectStopCalls = 0;

  SendPort? rpcReplySendPort;

  final Pointer<Void> cpiHandle = Pointer<Void>.fromAddress(0x11110);
  final Pointer<Void> connectHandle = Pointer<Void>.fromAddress(0x22220);

  _MockNativeResponse Function(String service, String method, Uint8List payload)?
      handler;

  @override
  int initDartApiDl(Pointer<Void> data) {
    lifecycleLog.add('initDartApiDl');
    return 0;
  }

  @override
  Pointer<Void> cpiCreate(Pointer<Void> engineHandle) {
    lifecycleLog.add('cpiCreate');
    return failCpiCreate ? nullptr : cpiHandle;
  }

  @override
  void cpiDestroy(Pointer<Void> h) {
    lifecycleLog.add('cpiDestroy');
  }

  @override
  Pointer<Void> connectCreate(Pointer<Void> cpiHandleArg) {
    lifecycleLog.add('connectCreate');
    expect(cpiHandleArg, equals(cpiHandle));
    return failConnectCreate ? nullptr : connectHandle;
  }

  @override
  void connectDestroy(Pointer<Void> h) {
    lifecycleLog.add('connectDestroy');
    expect(h, equals(connectHandle));
  }

  @override
  int connectStart(
    Pointer<Void> h,
    Pointer<Uint8> deviceInfoBytes,
    int len,
  ) {
    expect(h, equals(connectHandle));
    connectStartCalls += 1;
    if (deviceInfoBytes != nullptr && len > 0) {
      lastConnectStartBytes =
          Uint8List.fromList(deviceInfoBytes.asTypedList(len));
    } else {
      lastConnectStartBytes = Uint8List(0);
    }
    return 0;
  }

  @override
  void connectStop(Pointer<Void> h) {
    expect(h, equals(connectHandle));
    connectStopCalls += 1;
  }

  @override
  void cpiSetStateChangedPort(Pointer<Void> h, int port) {
    cpiStatePort = port;
    lifecycleLog.add('cpiSetStateChangedPort:$port');
  }

  @override
  void cpiSetQueueChangedPort(Pointer<Void> h, int port) {
    cpiQueuePort = port;
    lifecycleLog.add('cpiSetQueueChangedPort:$port');
  }

  @override
  void cpiSetErrorPort(Pointer<Void> h, int port) {
    cpiErrorPort = port;
    lifecycleLog.add('cpiSetErrorPort:$port');
  }

  @override
  void connectSetStatePort(Pointer<Void> h, int port) {
    connectStatePort = port;
    lifecycleLog.add('connectSetStatePort:$port');
  }

  @override
  void connectSetVolumePort(Pointer<Void> h, int port) {
    volumePort = port;
    lifecycleLog.add('connectSetVolumePort:$port');
  }

  @override
  void connectSetLocalVolumePort(Pointer<Void> h, int port) {
    localVolumePort = port;
    lifecycleLog.add('connectSetLocalVolumePort:$port');
  }

  @override
  void connectSetDodoPort(Pointer<Void> h, int port) {
    dodoPort = port;
    lifecycleLog.add('connectSetDodoPort:$port');
  }

  @override
  void connectSetInstallSpotifyPort(Pointer<Void> h, int port) {
    installSpotifyPort = port;
    lifecycleLog.add('connectSetInstallSpotifyPort:$port');
  }

  @override
  void connectSetDiagnosticPort(Pointer<Void> h, int dartPort) {
    diagnosticPort = dartPort;
    lifecycleLog.add('connectSetDiagnosticPort:$dartPort');
  }

  @override
  Pointer<Uint8> cpiGetState(Pointer<Void> h, Pointer<Int32> outLen) {
    final initial = initialCpiState;
    if (initial == null || initial.isEmpty) {
      outLen.value = 0;
      return nullptr;
    }
    final buf = calloc<Uint8>(initial.length);
    buf.asTypedList(initial.length).setAll(0, initial);
    allocatedAddresses.add(buf.address);
    outLen.value = initial.length;
    return buf;
  }

  @override
  Pointer<Uint8> cpiGetQueue(Pointer<Void> h, Pointer<Int32> outLen) {
    final initial = initialCpiQueue;
    if (initial == null || initial.isEmpty) {
      outLen.value = 0;
      return nullptr;
    }
    final buf = calloc<Uint8>(initial.length);
    buf.asTypedList(initial.length).setAll(0, initial);
    allocatedAddresses.add(buf.address);
    outLen.value = initial.length;
    return buf;
  }

  @override
  int cpiHandleCommand(
    Pointer<Void> h,
    Pointer<Utf8> method,
    Pointer<Uint8> payload,
    int payloadLen,
  ) {
    final copied = payload != nullptr && payloadLen > 0
        ? Uint8List.fromList(payload.asTypedList(payloadLen))
        : Uint8List(0);
    serviceCalls.add(
      _RecordedCall('ContextPlayer', method.toDartString(), copied),
    );
    return 0;
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
    expect(h, equals(connectHandle));
    expect(replyPort, isNonZero);
    final service = switch (serviceId) {
      1 => 'ConnectService',
      2 => 'ConnectVolumeService',
      3 => 'DodoService',
      _ => throw ArgumentError('Unexpected Connect serviceId: $serviceId'),
    };
    final methodName = method.toDartString();
    final copiedPayload = payload != nullptr && payloadLen > 0
        ? Uint8List.fromList(payload.asTypedList(payloadLen))
        : Uint8List(0);
    serviceCalls.add(_RecordedCall(service, methodName, copiedPayload));

    final fn = handler;
    final res = fn != null
        ? fn(service, methodName, copiedPayload)
        : _MockNativeResponse(0, Uint8List(0));
    final port = rpcReplySendPort;
    if (port != null) {
      scheduleMicrotask(() {
        port.send(<Object?>[requestId, res.status, res.bytes]);
      });
    }
    return 0;
  }

  Pointer<Uint8> _dispatchService(
    String service,
    Pointer<Void> h,
    Pointer<Utf8> method,
    Pointer<Uint8> payload,
    int payloadLen,
    Pointer<Int32> outLen,
    Pointer<Int32> outStatus,
  ) {
    expect(h, equals(connectHandle));
    final methodName = method.toDartString();
    final copiedPayload = payload != nullptr && payloadLen > 0
        ? Uint8List.fromList(payload.asTypedList(payloadLen))
        : Uint8List(0);
    serviceCalls.add(_RecordedCall(service, methodName, copiedPayload));

    final fn = handler;
    final res = fn != null
        ? fn(service, methodName, copiedPayload)
        : _MockNativeResponse(0, Uint8List(0));
    outStatus.value = res.status;
    outLen.value = res.bytes.length;
    if (res.bytes.isEmpty) {
      return nullptr;
    }
    final buf = calloc<Uint8>(res.bytes.length);
    buf.asTypedList(res.bytes.length).setAll(0, res.bytes);
    allocatedAddresses.add(buf.address);
    return buf;
  }

  @override
  Pointer<Uint8> connectServiceCall(
    Pointer<Void> h,
    Pointer<Utf8> method,
    Pointer<Uint8> payload,
    int payloadLen,
    Pointer<Int32> outLen,
    Pointer<Int32> outStatus,
  ) =>
      _dispatchService(
        'ConnectService',
        h,
        method,
        payload,
        payloadLen,
        outLen,
        outStatus,
      );

  @override
  Pointer<Uint8> connectVolumeServiceCall(
    Pointer<Void> h,
    Pointer<Utf8> method,
    Pointer<Uint8> payload,
    int payloadLen,
    Pointer<Int32> outLen,
    Pointer<Int32> outStatus,
  ) =>
      _dispatchService(
        'ConnectVolumeService',
        h,
        method,
        payload,
        payloadLen,
        outLen,
        outStatus,
      );

  @override
  Pointer<Uint8> dodoServiceCall(
    Pointer<Void> h,
    Pointer<Utf8> method,
    Pointer<Uint8> payload,
    int payloadLen,
    Pointer<Int32> outLen,
    Pointer<Int32> outStatus,
  ) =>
      _dispatchService(
        'DodoService',
        h,
        method,
        payload,
        payloadLen,
        outLen,
        outStatus,
      );

  @override
  void freeBytes(Pointer<Uint8> ptr) {
    if (ptr == nullptr) return;
    freedAddresses.add(ptr.address);
    calloc.free(ptr);
  }
}

NativeEsperantoTransport _createTransport(
  _FakeEngine engine,
  _FakeFfiBindings ffi,
) {
  final transport = NativeEsperantoTransport(engine, ffi: ffi);
  ffi.rpcReplySendPort = transport.connectRpcReplySendPort;
  return transport;
}

void main() {
  group('NativeEsperantoTransport (Items 131-132 & Wave 2 Async RPCs)', () {
    _FakeEngine? currentEngine;
    _FakeFfiBindings? currentFfi;

    _FakeEngine getEngine() {
      if (currentEngine case final e?) {
        return e;
      }
      throw StateError('engine not initialized');
    }

    _FakeFfiBindings getFfi() {
      if (currentFfi case final f?) {
        return f;
      }
      throw StateError('ffi not initialized');
    }

    setUp(() {
      currentEngine = _FakeEngine(Pointer<Void>.fromAddress(0xCAFE));
      currentFfi = _FakeFfiBindings();
    });

    test('destroys cpi handle if connectCreate returns nullptr', () {
      final engine = getEngine();
      final ffi = getFfi();
      ffi.failConnectCreate = true;
      expect(
        () => NativeEsperantoTransport(engine, ffi: ffi),
        throwsStateError,
      );
      expect(
        ffi.lifecycleLog,
        containsAllInOrder(['cpiCreate', 'connectCreate', 'cpiDestroy']),
      );
    });

    test('routes ConnectService, ConnectVolumeService, DodoService via async connectCallAsync, ContextPlayer calls, and frees native buffers', () async {
      final engine = getEngine();
      final ffi = getFfi();
      ffi.initialCpiState = Uint8List.fromList([0x08, 0x01]);
      ffi.handler = (service, method, payload) {
        if (service == 'ConnectService' && method == 'Transfer') {
          final req = TransferRequest.fromBuffer(payload);
          expect(req.connectDeviceIdentifier, equals('speaker-1'));
          expect(req.dodo, isTrue);
          return _MockNativeResponse(
            0,
            StatusResponse(status: Status.OK).writeToBuffer(),
          );
        }
        if (service == 'ConnectService' && method == 'NotifyAudioRouteChanged') {
          return _MockNativeResponse(0, Uint8List(0));
        }
        if (service == 'ConnectVolumeService' && method == 'VolumeSet') {
          final req = VolumeSetRequest.fromBuffer(payload);
          return _MockNativeResponse(
            0,
            StatusResponse(
              status: req.volume < 0 ? Status.INVALID_ARGUMENTS : Status.OK,
            ).writeToBuffer(),
          );
        }
        if (service == 'DodoService' && method == 'SwitchToDodo') {
          final req = SwitchToDodoRequest.fromBuffer(payload);
          expect(req.csId, equals('cs-99'));
          return _MockNativeResponse(
            0,
            StatusResponse(status: Status.OK).writeToBuffer(),
          );
        }
        return _MockNativeResponse(5, Uint8List(0));
      };

      final transport = _createTransport(engine, ffi);
      addTearDown(transport.destroy);

      final transferOut = await transport.callSingle(
        NativeEsperantoTransport.connectService,
        'Transfer',
        TransferRequest(
          connectDeviceIdentifier: 'speaker-1',
          dodo: true,
        ).writeToBuffer(),
      );
      expect(StatusResponse.fromBuffer(transferOut).status, equals(Status.OK));

      final routeOut = await transport.callSingle(
        NativeEsperantoTransport.connectService,
        'NotifyAudioRouteChanged',
        NotifyAudioRouteChangedRequest(audioOutputDeviceName: 'AirPods')
            .writeToBuffer(),
      );
      expect(routeOut, isEmpty);

      final volInvalidOut = await transport.callSingle(
        NativeEsperantoTransport.connectVolumeService,
        'VolumeSet',
        VolumeSetRequest(volume: -5).writeToBuffer(),
      );
      expect(
        StatusResponse.fromBuffer(volInvalidOut).status,
        equals(Status.INVALID_ARGUMENTS),
      );

      final dodoOut = await transport.callSingle(
        NativeEsperantoTransport.dodoService,
        'SwitchToDodo',
        SwitchToDodoRequest(csId: 'cs-99').writeToBuffer(),
      );
      expect(StatusResponse.fromBuffer(dodoOut).status, equals(Status.OK));

      await transport.callSingle(
        NativeEsperantoTransport.contextPlayerService,
        'Pause',
        Uint8List.fromList([1, 2, 3]),
      );
      expect(
        ffi.serviceCalls.any(
          (c) => c.service == 'ContextPlayer' && c.method == 'Pause',
        ),
        isTrue,
      );

      expect(ffi.allocatedAddresses, isNotEmpty);
      expect(ffi.freedAddresses, equals(ffi.allocatedAddresses));
    });

    test('callStream emits initial native snapshot and forwards ReceivePort updates', () async {
      final engine = getEngine();
      final ffi = getFfi();
      ffi.handler = (service, method, payload) {
        if (service == 'ConnectService' && method == 'State') {
          final req = StateRequest.fromBuffer(payload);
          return _MockNativeResponse(
            0,
            StateResponse(
              isRunning: true,
              localName: req.includeLocalDevice ? 'My Phone' : 'Filtered',
            ).writeToBuffer(),
          );
        }
        if (service == 'ConnectService' && method == 'InstallSpotify') {
          return _MockNativeResponse(
            0,
            InstallSpotifyStatusUpdate(
              currentState: InstallSpotifyState.DEVICE_NOT_SUPPORTED,
            ).writeToBuffer(),
          );
        }
        if (service == 'ConnectVolumeService' && method == 'Volume') {
          return _MockNativeResponse(
            0,
            VolumeResponse(volume: 32768).writeToBuffer(),
          );
        }
        if (service == 'ConnectVolumeService' && method == 'LocalVolume') {
          return _MockNativeResponse(
            0,
            LocalVolumeResponse(
              volume: 12000,
              reason: LocalVolumeResponse_Reason.USER,
            ).writeToBuffer(),
          );
        }
        if (service == 'DodoService' && method == 'DodoSub') {
          return _MockNativeResponse(
            0,
            DodoSubResponse(
              dodos: [SingleDodo(dodoId: 'd1', csId: 'c1', isPrimary: true)],
            ).writeToBuffer(),
          );
        }
        return _MockNativeResponse(5, Uint8List(0));
      };

      final transport = _createTransport(engine, ffi);
      addTearDown(transport.destroy);

      expect(ffi.connectStatePort, isNonZero);
      expect(ffi.volumePort, isNonZero);
      expect(ffi.localVolumePort, isNonZero);
      expect(ffi.dodoPort, isNonZero);
      expect(ffi.installSpotifyPort, isNonZero);

      final firstState = await transport
          .callStream(
            NativeEsperantoTransport.connectService,
            'State',
            StateRequest(includeLocalDevice: true).writeToBuffer(),
          )
          .first;
      expect(
        StateResponse.fromBuffer(firstState).localName,
        equals('My Phone'),
      );

      final firstVolume = await transport
          .callStream(
            NativeEsperantoTransport.connectVolumeService,
            'Volume',
            Uint8List(0),
          )
          .first;
      expect(VolumeResponse.fromBuffer(firstVolume).volume, equals(32768));

      final firstLocalVol = await transport
          .callStream(
            NativeEsperantoTransport.connectVolumeService,
            'LocalVolume',
            Uint8List(0),
          )
          .first;
      final decodedLocalVol = LocalVolumeResponse.fromBuffer(firstLocalVol);
      expect(decodedLocalVol.volume, equals(12000));
      expect(decodedLocalVol.reason, equals(LocalVolumeResponse_Reason.USER));

      final firstDodo = await transport
          .callStream(
            NativeEsperantoTransport.dodoService,
            'DodoSub',
            Uint8List(0),
          )
          .first;
      expect(
        DodoSubResponse.fromBuffer(firstDodo).dodos.single.dodoId,
        equals('d1'),
      );

      final installStatus = await transport
          .callStream(
            NativeEsperantoTransport.connectService,
            'InstallSpotify',
            InstallSpotifyRequest(connectDeviceIdentifier: 'd1').writeToBuffer(),
          )
          .first;
      expect(
        InstallSpotifyStatusUpdate.fromBuffer(installStatus).currentState,
        equals(InstallSpotifyState.DEVICE_NOT_SUPPORTED),
      );
    });

    test('fails fast with UnsupportedError, FormatException, and ArgumentError on error statuses', () async {
      final engine = getEngine();
      final ffi = getFfi();
      ffi.handler = (service, method, payload) {
        if (method == 'DecodeFail') return _MockNativeResponse(6, Uint8List(0));
        if (method == 'BadArg') return _MockNativeResponse(2, Uint8List(0));
        if (method == 'BadBufStatus') {
          return _MockNativeResponse(6, Uint8List.fromList([1, 2, 3]));
        }
        return _MockNativeResponse(5, Uint8List(0));
      };

      final transport = _createTransport(engine, ffi);
      addTearDown(transport.destroy);

      await expectLater(
        () => transport.callSingle('unknown.Service', 'Foo', Uint8List(0)),
        throwsUnsupportedError,
      );
      await expectLater(
        () => transport.callSingle(
          NativeEsperantoTransport.connectService,
          'MissingMethod',
          Uint8List(0),
        ),
        throwsUnsupportedError,
      );
      await expectLater(
        () => transport.callSingle(
          NativeEsperantoTransport.connectService,
          'DecodeFail',
          Uint8List(0),
        ),
        throwsFormatException,
      );
      await expectLater(
        () => transport.callSingle(
          NativeEsperantoTransport.connectService,
          'BadArg',
          Uint8List(0),
        ),
        throwsArgumentError,
      );
      await expectLater(
        () => transport.callSingle(
          NativeEsperantoTransport.connectService,
          'BadBufStatus',
          Uint8List(0),
        ),
        throwsFormatException,
      );
      expect(ffi.freedAddresses, equals(ffi.allocatedAddresses));

      expect(
        () => transport.callStream('unknown.Service', 'State', Uint8List(0)),
        throwsUnsupportedError,
      );
      expect(
        () => transport.callStream(
          NativeEsperantoTransport.connectService,
          'UnknownStream',
          Uint8List(0),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => transport.callSync('unknown.Service', 'State', Uint8List(0)),
        throwsUnsupportedError,
      );
      expect(
        () => transport.callSync(
          NativeEsperantoTransport.contextPlayerService,
          'Pause',
          Uint8List(0),
        ),
        throwsUnsupportedError,
      );
    });

    test('destroy() clears ports, disposes attached gateways, and destroys connectHandle strictly before cpiHandle', () {
      final engine = getEngine();
      final ffi = getFfi();
      final transport = _createTransport(engine, ffi);
      final gateway = transport.createConnectGateway();
      expect(gateway.isDisposed, isFalse);

      transport.connectStart();
      expect(ffi.connectStartCalls, equals(1));
      transport.connectStop();
      expect(ffi.connectStopCalls, equals(1));

      transport.destroy();

      expect(gateway.isDisposed, isTrue);
      expect(ffi.connectStatePort, equals(0));
      expect(ffi.volumePort, equals(0));
      expect(ffi.localVolumePort, equals(0));
      expect(ffi.dodoPort, equals(0));
      expect(ffi.installSpotifyPort, equals(0));
      expect(ffi.diagnosticPort, equals(0));

      final connectDestroyIdx = ffi.lifecycleLog.indexOf('connectDestroy');
      final cpiDestroyIdx = ffi.lifecycleLog.indexOf('cpiDestroy');
      expect(connectDestroyIdx, isNonNegative);
      expect(cpiDestroyIdx, isNonNegative);
      expect(connectDestroyIdx, lessThan(cpiDestroyIdx));

      expect(
        () => transport.callSingle(
          NativeEsperantoTransport.connectService,
          'PerformDiscovery',
          Uint8List(0),
        ),
        throwsStateError,
      );
      expect(
        () => transport.callStream(
          NativeEsperantoTransport.connectService,
          'State',
          Uint8List(0),
        ),
        throwsStateError,
      );
      expect(
        () => transport.callSync(
          NativeEsperantoTransport.connectService,
          'PerformDiscovery',
          Uint8List(0),
        ),
        throwsStateError,
      );
    });

    test('MusifyFfiBindings.fromLibrary throws ArgumentError when symbols are absent', () {
      expect(
        () => MusifyFfiBindings.fromLibrary(DynamicLibrary.process()),
        throwsArgumentError,
      );
    });

    test('callStream delivers onDone to all 8 active subscribers on destroy() and completes subscribe-after-destroy cleanly', () async {
      final engine = getEngine();
      final ffi = getFfi();
      ffi.initialCpiState = Uint8List.fromList([10, 11]);
      ffi.initialCpiQueue = Uint8List.fromList([20, 21]);
      ffi.handler = (service, method, payload) {
        if (service == 'ConnectService' && method == 'State') {
          return _MockNativeResponse(
            0,
            StateResponse(isRunning: true).writeToBuffer(),
          );
        }
        if (service == 'ConnectService' && method == 'InstallSpotify') {
          return _MockNativeResponse(
            0,
            InstallSpotifyStatusUpdate(
              currentState: InstallSpotifyState.PAIRING,
            ).writeToBuffer(),
          );
        }
        if (service == 'ConnectVolumeService' && method == 'Volume') {
          return _MockNativeResponse(
            0,
            VolumeResponse(volume: 1000).writeToBuffer(),
          );
        }
        if (service == 'ConnectVolumeService' && method == 'LocalVolume') {
          return _MockNativeResponse(
            0,
            LocalVolumeResponse(volume: 500).writeToBuffer(),
          );
        }
        if (service == 'DodoService' && method == 'DodoSub') {
          return _MockNativeResponse(0, DodoSubResponse().writeToBuffer());
        }
        return _MockNativeResponse(5, Uint8List(0));
      };

      final transport = _createTransport(engine, ffi);

      final preObtainedAfterDestroy = transport.callStream(
        NativeEsperantoTransport.connectService,
        'State',
        Uint8List(0),
      );

      final streams = <Stream<Uint8List>>[
        transport.callStream(
          NativeEsperantoTransport.contextPlayerService,
          'GetState',
          Uint8List(0),
        ),
        transport.callStream(
          NativeEsperantoTransport.contextPlayerService,
          'GetQueue',
          Uint8List(0),
        ),
        transport.callStream(
          NativeEsperantoTransport.contextPlayerService,
          'GetError',
          Uint8List(0),
        ),
        transport.callStream(
          NativeEsperantoTransport.connectService,
          'State',
          Uint8List(0),
        ),
        transport.callStream(
          NativeEsperantoTransport.connectService,
          'InstallSpotify',
          Uint8List(0),
        ),
        transport.callStream(
          NativeEsperantoTransport.connectVolumeService,
          'Volume',
          Uint8List(0),
        ),
        transport.callStream(
          NativeEsperantoTransport.connectVolumeService,
          'LocalVolume',
          Uint8List(0),
        ),
        transport.callStream(
          NativeEsperantoTransport.dodoService,
          'DodoSub',
          Uint8List(0),
        ),
      ];

      final doneFlags = List<bool>.filled(streams.length, false);
      final doneCompleters = List<Completer<void>>.generate(
        streams.length,
        (_) => Completer<void>(),
      );
      final subs = <StreamSubscription<Uint8List>>[];
      for (var i = 0; i < streams.length; i += 1) {
        subs.add(
          streams[i].listen(
            (_) {},
            onDone: () {
              doneFlags[i] = true;
              if (!doneCompleters[i].isCompleted) {
                doneCompleters[i].complete();
              }
            },
          ),
        );
      }

      transport.destroy();
      await Future.wait(doneCompleters.map((c) => c.future));
      expect(doneFlags, everyElement(isTrue));
      for (final sub in subs) {
        await sub.cancel();
      }

      final postEvents = <Uint8List>[];
      final postDone = Completer<void>();
      final postSub = preObtainedAfterDestroy.listen(
        postEvents.add,
        onDone: () {
          if (!postDone.isCompleted) {
            postDone.complete();
          }
        },
      );
      await postDone.future;
      expect(postEvents, isEmpty);
      await postSub.cancel();
    });

    test('multi-listener replay on a single callStream delivers snapshots and live SendPort updates across all replaying channels', () async {
      final engine = getEngine();
      final ffi = getFfi();
      ffi.initialCpiState = Uint8List.fromList([1, 2]);
      ffi.initialCpiQueue = Uint8List.fromList([3, 4]);
      ffi.handler = (service, method, payload) {
        if (service == 'ConnectService' && method == 'State') {
          return _MockNativeResponse(
            0,
            StateResponse(isRunning: true, localName: 'Initial').writeToBuffer(),
          );
        }
        if (service == 'ConnectVolumeService' && method == 'Volume') {
          return _MockNativeResponse(
            0,
            VolumeResponse(volume: 100).writeToBuffer(),
          );
        }
        if (service == 'ConnectVolumeService' && method == 'LocalVolume') {
          return _MockNativeResponse(
            0,
            LocalVolumeResponse(volume: 200).writeToBuffer(),
          );
        }
        if (service == 'DodoService' && method == 'DodoSub') {
          return _MockNativeResponse(
            0,
            DodoSubResponse(dodos: [SingleDodo(dodoId: 'd0')]).writeToBuffer(),
          );
        }
        return _MockNativeResponse(5, Uint8List(0));
      };

      final transport = _createTransport(engine, ffi);
      addTearDown(transport.destroy);

      final connectStateStream = transport.callStream(
        NativeEsperantoTransport.connectService,
        'State',
        Uint8List(0),
      );
      expect(connectStateStream.isBroadcast, isTrue);

      final listener1 = <Uint8List>[];
      final listener2 = <Uint8List>[];
      final sub1 = connectStateStream.listen(listener1.add);
      final sub2 = connectStateStream.listen(listener2.add);
      await Future<void>(() {});
      expect(listener1, hasLength(1));
      expect(listener2, hasLength(1));
      expect(
        StateResponse.fromBuffer(listener1.single).localName,
        equals('Initial'),
      );
      expect(
        StateResponse.fromBuffer(listener2.single).localName,
        equals('Initial'),
      );

      final updatedState =
          StateResponse(isRunning: true, localName: 'Updated').writeToBuffer();
      transport.connectStateSendPort.send(updatedState);
      await Future<void>(() {});
      expect(listener1, hasLength(2));
      expect(listener2, hasLength(2));
      expect(
        StateResponse.fromBuffer(listener1.last).localName,
        equals('Updated'),
      );
      expect(
        StateResponse.fromBuffer(listener2.last).localName,
        equals('Updated'),
      );

      await sub1.cancel();
      final updatedState2 =
          StateResponse(isRunning: true, localName: 'Updated2').writeToBuffer();
      transport.connectStateSendPort.send(updatedState2);
      await Future<void>(() {});
      expect(listener1, hasLength(2));
      expect(listener2, hasLength(3));
      expect(
        StateResponse.fromBuffer(listener2.last).localName,
        equals('Updated2'),
      );

      final listener3 = <Uint8List>[];
      final sub3 = connectStateStream.listen(listener3.add);
      await Future<void>(() {});
      expect(listener3, hasLength(1));
      expect(
        StateResponse.fromBuffer(listener3.single).localName,
        equals('Updated2'),
      );
      await sub2.cancel();
      await sub3.cancel();

      final channels = <({
        Stream<Uint8List> stream,
        SendPort sendPort,
        Uint8List initial,
        Uint8List live,
      })>[
        (
          stream: transport.callStream(
            NativeEsperantoTransport.contextPlayerService,
            'GetState',
            Uint8List(0),
          ),
          sendPort: transport.cpiStateSendPort,
          initial: Uint8List.fromList([1, 2]),
          live: Uint8List.fromList([1, 3]),
        ),
        (
          stream: transport.callStream(
            NativeEsperantoTransport.contextPlayerService,
            'GetQueue',
            Uint8List(0),
          ),
          sendPort: transport.cpiQueueSendPort,
          initial: Uint8List.fromList([3, 4]),
          live: Uint8List.fromList([3, 5]),
        ),
        (
          stream: transport.callStream(
            NativeEsperantoTransport.connectVolumeService,
            'Volume',
            Uint8List(0),
          ),
          sendPort: transport.volumeSendPort,
          initial: VolumeResponse(volume: 100).writeToBuffer(),
          live: VolumeResponse(volume: 400).writeToBuffer(),
        ),
        (
          stream: transport.callStream(
            NativeEsperantoTransport.connectVolumeService,
            'LocalVolume',
            Uint8List(0),
          ),
          sendPort: transport.localVolumeSendPort,
          initial: LocalVolumeResponse(volume: 200).writeToBuffer(),
          live: LocalVolumeResponse(volume: 500).writeToBuffer(),
        ),
        (
          stream: transport.callStream(
            NativeEsperantoTransport.dodoService,
            'DodoSub',
            Uint8List(0),
          ),
          sendPort: transport.dodoSendPort,
          initial: DodoSubResponse(dodos: [SingleDodo(dodoId: 'd0')])
              .writeToBuffer(),
          live: DodoSubResponse(dodos: [SingleDodo(dodoId: 'd1')])
              .writeToBuffer(),
        ),
      ];

      for (final ch in channels) {
        expect(ch.stream.isBroadcast, isTrue);
        final a = <Uint8List>[];
        final b = <Uint8List>[];
        final sa = ch.stream.listen(a.add);
        final sb = ch.stream.listen(b.add);
        await Future<void>(() {});
        expect(a, equals([ch.initial]));
        expect(b, equals([ch.initial]));

        ch.sendPort.send(ch.live);
        await Future<void>(() {});
        expect(a, equals([ch.initial, ch.live]));
        expect(b, equals([ch.initial, ch.live]));

        await sa.cancel();
        await sb.cancel();
      }
    });

    test('ignores late ReceivePort emissions after destroy() and runs full teardown when invalidate() precedes destroy()', () async {
      final engine = getEngine();
      final ffi = getFfi();
      ffi.handler = (service, method, payload) {
        if (service == 'ConnectService' && method == 'State') {
          return _MockNativeResponse(
            0,
            StateResponse(isRunning: true).writeToBuffer(),
          );
        }
        return _MockNativeResponse(5, Uint8List(0));
      };

      final transport1 = _createTransport(engine, ffi);
      final received = <Uint8List>[];
      final done = Completer<void>();
      final sub = transport1
          .callStream(
            NativeEsperantoTransport.connectService,
            'State',
            Uint8List(0),
          )
          .listen(
            received.add,
            onDone: () {
              if (!done.isCompleted) {
                done.complete();
              }
            },
          );
      await Future<void>(() {});

      final lateBytes = StateResponse(localName: 'Late').writeToBuffer();
      transport1.connectStateSendPort.send(lateBytes);
      transport1.destroy();
      await done.future;
      await Future<void>(() {});
      expect(received, hasLength(1));
      await sub.cancel();

      final ffi2 = _FakeFfiBindings();
      ffi2.handler = ffi.handler;
      final transport2 = _createTransport(engine, ffi2);
      final done2 = Completer<void>();
      final sub2 = transport2
          .callStream(
            NativeEsperantoTransport.connectService,
            'State',
            Uint8List(0),
          )
          .listen(
            (_) {},
            onDone: () {
              if (!done2.isCompleted) {
                done2.complete();
              }
            },
          );

      transport2.invalidate();
      expect(
        () => transport2.callSingle(
          NativeEsperantoTransport.connectService,
          'PerformDiscovery',
          Uint8List(0),
        ),
        throwsStateError,
      );
      expect(
        () => transport2.callStream(
          NativeEsperantoTransport.connectService,
          'State',
          Uint8List(0),
        ),
        throwsStateError,
      );
      expect(
        () => transport2.callSync(
          NativeEsperantoTransport.connectService,
          'PerformDiscovery',
          Uint8List(0),
        ),
        throwsStateError,
      );
      expect(transport2.connectStart, throwsStateError);
      expect(transport2.connectStop, throwsStateError);

      transport2.destroy();
      await done2.future;
      await sub2.cancel();

      expect(ffi2.connectStatePort, equals(0));
      expect(ffi2.volumePort, equals(0));
      expect(ffi2.localVolumePort, equals(0));
      expect(ffi2.dodoPort, equals(0));
      expect(ffi2.installSpotifyPort, equals(0));
      expect(ffi2.cpiStatePort, equals(0));
      expect(ffi2.cpiQueuePort, equals(0));
      expect(ffi2.cpiErrorPort, equals(0));

      final connectDestroyIdx = ffi2.lifecycleLog.indexOf('connectDestroy');
      final cpiDestroyIdx = ffi2.lifecycleLog.indexOf('cpiDestroy');
      expect(connectDestroyIdx, isNonNegative);
      expect(cpiDestroyIdx, greaterThan(connectDestroyIdx));

      final logCountBeforeRepeat = ffi2.lifecycleLog.length;
      transport2.destroy();
      expect(ffi2.lifecycleLog.length, equals(logCountBeforeRepeat));
    });

    test('routes ContextPlayer streams/callSync, Dodo aliases, non-empty error payloads, and connectStart bytes', () async {
      final engine = getEngine();
      final ffi = getFfi();
      ffi.handler = (service, method, payload) {
        if (service == 'ConnectService' && method == 'SendCommand') {
          return _MockNativeResponse(
            2,
            SendCommandResponse(contextPlayerError: -1).writeToBuffer(),
          );
        }
        if (service == 'ConnectService' && method == 'PerformDiscovery') {
          return _MockNativeResponse(0, Uint8List(0));
        }
        if (service == 'ConnectVolumeService' && method == 'Volume') {
          return _MockNativeResponse(
            0,
            VolumeResponse(volume: 777).writeToBuffer(),
          );
        }
        if (service == 'DodoService' && (method == 'Dodos' || method == 'Sub')) {
          return _MockNativeResponse(
            0,
            DodoSubResponse(dodos: [SingleDodo(dodoId: method)])
                .writeToBuffer(),
          );
        }
        return _MockNativeResponse(5, Uint8List(0));
      };

      final transport = _createTransport(engine, ffi);
      addTearDown(transport.destroy);

      final startBytes = Uint8List.fromList([0x0A, 0x01, 0x61]);
      expect(transport.connectStart(startBytes), equals(0));
      expect(ffi.lastConnectStartBytes, equals(startBytes));

      expect(
        transport.callSync('ContextPlayer', 'GetState', Uint8List(0)),
        isEmpty,
      );
      expect(
        transport.callSync('ContextPlayer', 'GetQueue', Uint8List(0)),
        isEmpty,
      );

      final liveCpiState = Uint8List.fromList([5, 6, 7]);
      final liveCpiQueue = Uint8List.fromList([8, 9]);
      final liveCpiError = Uint8List.fromList([0x45, 0x52]);
      final errReceived = <Uint8List>[];
      final errSub = transport
          .callStream('ContextPlayer', 'GetError', Uint8List(0))
          .listen(errReceived.add);

      transport.cpiStateSendPort.send(liveCpiState);
      transport.cpiQueueSendPort.send(liveCpiQueue);
      transport.cpiErrorSendPort.send(liveCpiError);
      await Future<void>(() {});

      expect(
        transport.callSync(
          NativeEsperantoTransport.contextPlayerService,
          'GetState',
          Uint8List(0),
        ),
        equals(liveCpiState),
      );
      expect(
        transport.callSync(
          NativeEsperantoTransport.contextPlayerService,
          'GetQueue',
          Uint8List(0),
        ),
        equals(liveCpiQueue),
      );
      expect(errReceived, equals([liveCpiError]));
      await errSub.cancel();

      expect(
        transport.callSync('ConnectService', 'PerformDiscovery', Uint8List(0)),
        isEmpty,
      );
      expect(
        VolumeResponse.fromBuffer(
          transport.callSync('ConnectVolumeService', 'Volume', Uint8List(0)),
        ).volume,
        equals(777),
      );
      expect(
        DodoSubResponse.fromBuffer(
          transport.callSync('DodoService', 'Sub', Uint8List(0)),
        ).dodos.single.dodoId,
        equals('Sub'),
      );

      final dodosAlias = await transport
          .callStream('DodoService', 'Dodos', Uint8List(0))
          .first;
      expect(
        DodoSubResponse.fromBuffer(dodosAlias).dodos.single.dodoId,
        equals('Dodos'),
      );
      final subAlias = await transport
          .callStream(NativeEsperantoTransport.dodoService, 'Sub', Uint8List(0))
          .first;
      expect(
        DodoSubResponse.fromBuffer(subAlias).dodos.single.dodoId,
        equals('Sub'),
      );

      final sendErrBytes = await transport.callSingle(
        NativeEsperantoTransport.connectService,
        'SendCommand',
        SendCommandRequest(
          connectDeviceIdentifier: 'dev',
          commandJson: '{}',
        ).writeToBuffer(),
      );
      expect(
        SendCommandResponse.fromBuffer(sendErrBytes).contextPlayerError,
        equals(-1),
      );
      expect(ffi.freedAddresses, equals(ffi.allocatedAddresses));
    });
  });
}
