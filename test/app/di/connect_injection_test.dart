// 1:1 DI & bootstrap verification tests for lib/app/di/connect_injection.dart
// (ConnectSubsystem.cpp:74, ffi_bridge.cpp:854, qr0.java, p199p/azq.java).

import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:musify_mu/app/di/connect_injection.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/application/sorting/device_picker_sorting_database.dart';
import 'package:musify_mu/features/connect/application/volume/remote_volume_controller.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_volume_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/dodo_service_client.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:musify_mu/features/player/data/esperanto/native_esperanto_transport.dart';

final class _FakeConnectTransport implements EsperantoTransport {
  final StreamController<Uint8List> stateStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> volumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> localVolumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> dodoStreamController =
      StreamController<Uint8List>.broadcast();

  bool stateSubscribed = false;
  bool volumeSubscribed = false;
  bool localVolumeSubscribed = false;
  bool dodoSubscribed = false;

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    return Uint8List(0);
  }

  @override
  Stream<Uint8List> callStream(
    String service,
    String method,
    Uint8List payload,
  ) {
    if (service == ConnectServiceClient.serviceName && method == 'State') {
      stateSubscribed = true;
      return stateStreamController.stream;
    }
    if (service == ConnectVolumeServiceClient.serviceName &&
        method == 'Volume') {
      volumeSubscribed = true;
      return volumeStreamController.stream;
    }
    if (service == ConnectVolumeServiceClient.serviceName &&
        method == 'LocalVolume') {
      localVolumeSubscribed = true;
      return localVolumeStreamController.stream;
    }
    if (service == DodoServiceClient.serviceName && method == 'DodoSub') {
      dodoSubscribed = true;
      return dodoStreamController.stream;
    }
    return const Stream<Uint8List>.empty();
  }

  @override
  Uint8List callSync(String service, String method, Uint8List payload) {
    return Uint8List(0);
  }

  Future<void> close() async {
    await stateStreamController.close();
    await volumeStreamController.close();
    await localVolumeStreamController.close();
    await dodoStreamController.close();
  }
}

final class _SpyNativeConnectTransport extends Fake
    implements NativeEsperantoTransport {
  final StreamController<Uint8List> stateStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> volumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> localVolumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> dodoStreamController =
      StreamController<Uint8List>.broadcast();

  int connectStartCalls = 0;
  bool throwOnConnectStart = false;

  @override
  int connectStart([Uint8List? deviceInfoBytes]) {
    if (throwOnConnectStart) {
      throw StateError('connectStart() called after invalidation');
    }
    connectStartCalls += 1;
    return 0;
  }

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    return Uint8List(0);
  }

  @override
  Stream<Uint8List> callStream(
    String service,
    String method,
    Uint8List payload,
  ) {
    if (service == ConnectServiceClient.serviceName && method == 'State') {
      return stateStreamController.stream;
    }
    if (service == ConnectVolumeServiceClient.serviceName &&
        method == 'Volume') {
      return volumeStreamController.stream;
    }
    if (service == ConnectVolumeServiceClient.serviceName &&
        method == 'LocalVolume') {
      return localVolumeStreamController.stream;
    }
    if (service == DodoServiceClient.serviceName && method == 'DodoSub') {
      return dodoStreamController.stream;
    }
    return const Stream<Uint8List>.empty();
  }

  @override
  Uint8List callSync(String service, String method, Uint8List payload) {
    return Uint8List(0);
  }

  Future<void> close() async {
    await stateStreamController.close();
    await volumeStreamController.close();
    await localVolumeStreamController.close();
    await dodoStreamController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('setupConnectInjection', () {
    test(
      'registers all 6 Connect singletons lazily without opening DB or streams',
      () async {
        final sl = GetIt.asNewInstance();
        final transport = _FakeConnectTransport();
        sl.registerSingleton<EsperantoTransport>(transport);

        setupConnectInjection(sl);

        expect(sl.isRegistered<ConnectServiceClient>(), isTrue);
        expect(sl.isRegistered<ConnectVolumeServiceClient>(), isTrue);
        expect(sl.isRegistered<DodoServiceClient>(), isTrue);
        expect(sl.isRegistered<DevicePickerSortingDatabase>(), isTrue);
        expect(sl.isRegistered<RemoteVolumeController>(), isTrue);
        expect(sl.isRegistered<ConnectMobiusController>(), isTrue);

        // Lazy registration must not subscribe to streams before resolution.
        expect(transport.stateSubscribed, isFalse);
        expect(transport.volumeSubscribed, isFalse);
        expect(transport.localVolumeSubscribed, isFalse);
        expect(transport.dodoSubscribed, isFalse);

        await sl.reset();
        await transport.close();
      },
    );

    test(
      'resolves all 6 singletons with identity parity and disposes cleanly on reset',
      () async {
        final sl = GetIt.asNewInstance();
        final transport = _FakeConnectTransport();
        sl.registerSingleton<EsperantoTransport>(transport);

        setupConnectInjection(sl);

        final connectClient = sl<ConnectServiceClient>();
        final volumeClient = sl<ConnectVolumeServiceClient>();
        final dodoClient = sl<DodoServiceClient>();
        final sortingDb = sl<DevicePickerSortingDatabase>();
        final volumeController = sl<RemoteVolumeController>();
        final mobiusController = sl<ConnectMobiusController>();

        expect(identical(connectClient, sl<ConnectServiceClient>()), isTrue);
        expect(
          identical(volumeClient, sl<ConnectVolumeServiceClient>()),
          isTrue,
        );
        expect(identical(dodoClient, sl<DodoServiceClient>()), isTrue);
        expect(
          identical(sortingDb, sl<DevicePickerSortingDatabase>()),
          isTrue,
        );
        expect(
          identical(volumeController, sl<RemoteVolumeController>()),
          isTrue,
        );
        expect(
          identical(mobiusController, sl<ConnectMobiusController>()),
          isTrue,
        );

        // autoStart: false keeps Mobius loop idle until explicit start.
        expect(mobiusController.isStarted, isFalse);
        expect(mobiusController.isClosed, isFalse);
        expect(
          identical(mobiusController.remoteVolumeController, volumeController),
          isTrue,
        );

        // Volume controller subscribes on construction; Connect loop does not.
        expect(transport.volumeSubscribed, isTrue);
        expect(transport.localVolumeSubscribed, isTrue);
        expect(transport.stateSubscribed, isFalse);

        await sl.reset();

        expect(mobiusController.isClosed, isTrue);
        await expectLater(
          () => sortingDb.recordConnection(deviceIdentifier: 'dev-1'),
          throwsStateError,
        );
        await expectLater(
          volumeController.stream,
          emitsDone,
        );

        await transport.close();
      },
    );

    test(
      'startConnectSubsystemIfSupported guards non-Android hosts and starts on Android',
      () async {
        final sl = GetIt.asNewInstance();
        final transport = _FakeConnectTransport();
        final memoryDb = DevicePickerSortingDatabase.forTesting(
          NativeDatabase.memory(),
        );
        sl.registerSingleton<EsperantoTransport>(transport);
        sl.registerSingleton<DevicePickerSortingDatabase>(
          memoryDb,
          dispose: (db) => db.close(),
        );

        setupConnectInjection(sl);

        final controller = sl<ConnectMobiusController>();
        expect(controller.isStarted, isFalse);

        // Non-Android host does not start Connect loop.
        startConnectSubsystemIfSupported(
          controller: controller,
          transport: transport,
          isAndroidOverride: false,
        );
        expect(controller.isStarted, isFalse);
        expect(transport.stateSubscribed, isFalse);

        // Android host starts ConnectMobiusController idempotently.
        startConnectSubsystemIfSupported(
          controller: controller,
          transport: transport,
          isAndroidOverride: true,
        );
        expect(controller.isStarted, isTrue);
        expect(transport.stateSubscribed, isTrue);
        expect(transport.dodoSubscribed, isTrue);

        // Second call is safe and idempotent.
        startConnectSubsystemIfSupported(
          controller: controller,
          transport: transport,
          isAndroidOverride: true,
        );
        expect(controller.isStarted, isTrue);

        await sl.reset();
        expect(controller.isClosed, isTrue);

        // Calling after close is a safe no-op (never throws StateError).
        startConnectSubsystemIfSupported(
          controller: controller,
          transport: transport,
          isAndroidOverride: true,
        );

        await transport.close();
      },
    );

    test(
      'startConnectSubsystemIfSupported skips native connectStart when already started or closed',
      () async {
        final sl = GetIt.asNewInstance();
        final nativeTransport = _SpyNativeConnectTransport();
        final memoryDb = DevicePickerSortingDatabase.forTesting(
          NativeDatabase.memory(),
        );
        sl.registerSingleton<EsperantoTransport>(nativeTransport);
        sl.registerSingleton<DevicePickerSortingDatabase>(
          memoryDb,
          dispose: (db) => db.close(),
        );

        setupConnectInjection(sl);
        final controller = sl<ConnectMobiusController>();

        startConnectSubsystemIfSupported(
          controller: controller,
          transport: nativeTransport,
          isAndroidOverride: false,
        );
        expect(nativeTransport.connectStartCalls, 0);
        expect(controller.isStarted, isFalse);

        startConnectSubsystemIfSupported(
          controller: controller,
          transport: nativeTransport,
          isAndroidOverride: true,
        );
        expect(nativeTransport.connectStartCalls, 1);
        expect(controller.isStarted, isTrue);

        // Already started -> must not invoke native connectStart() again.
        startConnectSubsystemIfSupported(
          controller: controller,
          transport: nativeTransport,
          isAndroidOverride: true,
        );
        expect(nativeTransport.connectStartCalls, 1);

        await sl.reset();
        expect(controller.isClosed, isTrue);
        nativeTransport.throwOnConnectStart = true;

        // Closed controller -> must not invoke connectStart() on invalidated transport.
        startConnectSubsystemIfSupported(
          controller: controller,
          transport: nativeTransport,
          isAndroidOverride: true,
        );
        expect(nativeTransport.connectStartCalls, 1);

        await nativeTransport.close();
      },
    );
  });
}
