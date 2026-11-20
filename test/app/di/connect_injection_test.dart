// 1:1 DI & bootstrap verification tests for lib/app/di/connect_injection.dart
// (ConnectNativeGateway, ConnectSessionCoordinator, ConnectOutputStatusPolicy,
// DeviceInfoPayloadBuilder, Android platform adapters, qr0.java, p199p/azq.java).

import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:musify_mu/app/di/connect_injection.dart';
import 'package:musify_mu/core/audio/native_playback_session_bridge.dart';
import 'package:musify_mu/core/config/device_identity_service.dart';
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/network/spotify/ap_resolve_service.dart';
import 'package:musify_mu/core/network/spotify/auth/auth_session_provider.dart';
import 'package:musify_mu/features/connect/application/lifecycle/connect_session_coordinator.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/application/sorting/device_picker_sorting_database.dart';
import 'package:musify_mu/features/connect/application/volume/remote_volume_controller.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_volume_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/dodo_service_client.dart';
import 'package:musify_mu/features/connect/data/platform/android_audio_route_adapter.dart';
import 'package:musify_mu/features/connect/data/platform/android_device_environment_adapter.dart';
import 'package:musify_mu/features/connect/data/platform/android_local_discovery_adapter.dart';
import 'package:musify_mu/features/connect/data/platform/android_system_volume_adapter.dart';
import 'package:musify_mu/features/connect/domain/interfaces/audio_route_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/connect_native_gateway.dart';
import 'package:musify_mu/features/connect/domain/interfaces/device_environment_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/local_discovery_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/system_volume_port.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';
import 'package:musify_mu/features/connect/domain/services/device_info_payload_builder.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';

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

final class _FakeConnectNativeGateway implements ConnectNativeGateway {
  final StreamController<Uint8List> _localVolumeController =
      StreamController<Uint8List>.broadcast();
  final StreamController<String> _diagnosticController =
      StreamController<String>.broadcast();

  @override
  int start(Uint8List deviceInfoBytes) => 0;

  @override
  void stop() {}

  @override
  int setEndpoints({
    required String spclientBaseUrl,
    required String dealerWsUrl,
  }) =>
      0;

  @override
  int reconnect(ConnectReconnectReason reason) => 0;

  @override
  void setNetworkAvailable(bool isAvailable) {}

  @override
  int updateNsdServices(String servicesJsonUtf8) => 0;

  @override
  int setLocalVolume({
    required int volume0To65535,
    required int volumeSteps,
    required ConnectLocalVolumeReason reason,
  }) =>
      0;

  @override
  Future<ConnectAsyncCallResult> callServiceAsync({
    required ConnectEsperantoServiceId serviceId,
    required String method,
    required Uint8List payload,
  }) async =>
      ConnectAsyncCallResult(statusCode: 0, payloadBytes: Uint8List(0));

  @override
  Stream<Uint8List> get localVolumeStream => _localVolumeController.stream;

  @override
  Stream<String> get diagnosticStream => _diagnosticController.stream;

  @override
  void dispose() {
    unawaited(_localVolumeController.close());
    unawaited(_diagnosticController.close());
  }
}

final class _FakeAuthSessionProvider implements AuthSessionProvider {
  @override
  Future<String?> getAccessToken() async => 'token';

  @override
  Future<String?> getClientToken() async => 'client_token';

  @override
  Future<String?> refreshAccessToken() async => 'token';

  @override
  Future<String?> forceRefreshClientToken() async => 'client_token';

  @override
  Future<String> getActiveClientId() async =>
      AuthClientProfileConfig.webPlayerClientId;

  @override
  Future<AuthClientProfile> getActiveClientProfile() async =>
      AuthClientProfile.webPlayer;

  @override
  Future<AuthClientProfileConfig> getActiveClientProfileConfig() async =>
      AuthClientProfileConfig.webPlayerDefault;
}

final class _FakePlaybackSessionBridge extends Fake
    implements NativePlaybackSessionBridge {
  @override
  Future<void> syncSessionToNative() async {}

  @override
  Future<void> clearNativeAuthSession() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('setupConnectInjection', () {
    test(
      'registers all Connect domain services, platform adapters, and application singletons lazily without opening DB or streams',
      () async {
        final sl = GetIt.asNewInstance();
        final transport = _FakeConnectTransport();
        sl.registerSingleton<EsperantoTransport>(transport);

        setupConnectInjection(sl);

        expect(sl.isRegistered<DeviceIdentityService>(), isTrue);
        expect(sl.isRegistered<ApResolveService>(), isTrue);
        expect(sl.isRegistered<DeviceInfoPayloadBuilder>(), isTrue);
        expect(sl.isRegistered<ConnectOutputStatusPolicy>(), isTrue);
        expect(sl.isRegistered<DeviceEnvironmentPort>(), isTrue);
        expect(sl.isRegistered<AudioRoutePort>(), isTrue);
        expect(sl.isRegistered<SystemVolumePort>(), isTrue);
        expect(sl.isRegistered<LocalDiscoveryPort>(), isTrue);
        expect(sl.isRegistered<ConnectServiceClient>(), isTrue);
        expect(sl.isRegistered<ConnectVolumeServiceClient>(), isTrue);
        expect(sl.isRegistered<DodoServiceClient>(), isTrue);
        expect(sl.isRegistered<DevicePickerSortingDatabase>(), isTrue);
        expect(sl.isRegistered<RemoteVolumeController>(), isTrue);
        expect(sl.isRegistered<ConnectMobiusController>(), isTrue);
        // ConnectSessionCoordinator requires ConnectNativeGateway + AuthSessionProvider + NativePlaybackSessionBridge
        expect(sl.isRegistered<ConnectSessionCoordinator>(), isFalse);

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
      'resolves domain services, platform adapters, and application singletons with identity parity and disposes cleanly on reset',
      () async {
        final sl = GetIt.asNewInstance();
        final transport = _FakeConnectTransport();
        sl.registerSingleton<EsperantoTransport>(transport);

        setupConnectInjection(sl);

        expect(sl<DeviceInfoPayloadBuilder>(), same(DeviceInfoPayloadBuilder.instance));
        expect(sl<ConnectOutputStatusPolicy>(), same(ConnectOutputStatusPolicy.instance));
        expect(sl<DeviceEnvironmentPort>(), isA<AndroidDeviceEnvironmentAdapter>());
        expect(sl<AudioRoutePort>(), isA<AndroidAudioRouteAdapter>());
        expect(sl<SystemVolumePort>(), isA<AndroidSystemVolumeAdapter>());
        expect(sl<LocalDiscoveryPort>(), isA<AndroidLocalDiscoveryAdapter>());

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
        expect(mobiusController.hasAudioRouteBinding, isFalse);
        expect(
          identical(mobiusController.remoteVolumeController, volumeController),
          isTrue,
        );

        // Without ConnectNativeGateway, RemoteVolumeController auto-starts for standalone tests.
        expect(volumeController.isStarted, isTrue);
        expect(transport.volumeSubscribed, isTrue);
        expect(transport.localVolumeSubscribed, isTrue);
        expect(transport.stateSubscribed, isFalse);

        await sl.reset();

        expect(mobiusController.isClosed, isTrue);
        expect(volumeController.isDisposed, isTrue);
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
      'wires ConnectNativeGateway, AudioRoutePort, SystemVolumePort, and ConnectSessionCoordinator when native gateway and auth dependencies are registered',
      () async {
        final sl = GetIt.asNewInstance();
        final transport = _FakeConnectTransport();
        final gateway = _FakeConnectNativeGateway();
        final memoryDb = DevicePickerSortingDatabase.forTesting(
          NativeDatabase.memory(),
        );
        sl.registerSingleton<EsperantoTransport>(transport);
        sl.registerSingleton<ConnectNativeGateway>(
          gateway,
          dispose: (gw) => gw.dispose(),
        );
        sl.registerSingleton<AuthSessionProvider>(_FakeAuthSessionProvider());
        sl.registerSingleton<NativePlaybackSessionBridge>(
          _FakePlaybackSessionBridge(),
        );
        sl.registerSingleton<RuntimeContext>(
          RuntimeContext(country: 'US', catalogue: 'premium'),
        );
        sl.registerSingleton<DevicePickerSortingDatabase>(
          memoryDb,
          dispose: (db) => db.close(),
        );

        setupConnectInjection(sl);

        expect(sl.isRegistered<ConnectSessionCoordinator>(), isTrue);

        final volumeController = sl<RemoteVolumeController>();
        final mobiusController = sl<ConnectMobiusController>();
        final coordinator = sl<ConnectSessionCoordinator>();

        // When ConnectNativeGateway is registered, both controllers defer start()
        // to ConnectSessionCoordinator (auth-gated boot) and bind platform ports.
        expect(volumeController.isStarted, isFalse);
        expect(mobiusController.isStarted, isFalse);
        expect(mobiusController.hasAudioRouteBinding, isTrue);
        expect(coordinator.state, equals(const ConnectSessionIdle()));
        expect(coordinator.isDisposed, isFalse);

        await sl.reset();

        expect(coordinator.isDisposed, isTrue);
        expect(coordinator.state, equals(const ConnectSessionDisposed()));
        expect(mobiusController.isClosed, isTrue);
        expect(volumeController.isDisposed, isTrue);

        await transport.close();
      },
    );
  });
}
