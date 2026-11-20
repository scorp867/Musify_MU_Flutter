import 'dart:async';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/audio/native_playback_session_bridge.dart';
import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/config/device_identity_service.dart';
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/network/spotify/ap_resolve_service.dart';
import 'package:musify_mu/core/network/spotify/auth/auth_session_provider.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_refresher.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/application/auth_event.dart';
import 'package:musify_mu/features/auth/data/spotify_profile_fetcher.dart';
import 'package:musify_mu/features/auth/domain/entities/spotify_user.dart';
import 'package:musify_mu/features/connect/application/lifecycle/connect_session_coordinator.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/application/sorting/device_picker_sorting_database.dart';
import 'package:musify_mu/features/connect/application/volume/remote_volume_controller.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_volume_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/dodo_service_client.dart';
import 'package:musify_mu/features/connect/domain/interfaces/audio_route_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/connect_native_gateway.dart';
import 'package:musify_mu/features/connect/domain/interfaces/device_environment_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/local_discovery_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/system_volume_port.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final class _CoordinatorFakeTransport implements EsperantoTransport {
  final List<String> singleMethods = <String>[];

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    singleMethods.add(method);
    return Uint8List(0);
  }

  @override
  Stream<Uint8List> callStream(
    String service,
    String method,
    Uint8List payload,
  ) {
    return const Stream<Uint8List>.empty();
  }

  @override
  Uint8List callSync(String service, String method, Uint8List payload) {
    return Uint8List(0);
  }
}

final class _CoordinatorFakeAuthSessionProvider implements AuthSessionProvider {
  final List<String> bootLog;
  String activeClientId = AuthClientProfileConfig.webPlayerClientId;

  _CoordinatorFakeAuthSessionProvider(this.bootLog);

  @override
  Future<String?> getAccessToken() async {
    bootLog.add('step3:getAccessToken');
    return 'access_token_xyz';
  }

  @override
  Future<String?> getClientToken() async {
    bootLog.add('step3:getClientToken');
    return 'client_token_xyz';
  }

  @override
  Future<String?> refreshAccessToken() async => 'access_token_xyz';

  @override
  Future<String?> forceRefreshClientToken() async => 'client_token_xyz';

  @override
  Future<String> getActiveClientId() async {
    bootLog.add('step3:getActiveClientId');
    return activeClientId;
  }

  @override
  Future<AuthClientProfile> getActiveClientProfile() async =>
      AuthClientProfile.webPlayer;

  @override
  Future<AuthClientProfileConfig> getActiveClientProfileConfig() async =>
      AuthClientProfileConfig.webPlayerDefault;
}

final class _CoordinatorFakeDeviceEnvironmentPort
    implements DeviceEnvironmentPort {
  final List<String> bootLog;

  _CoordinatorFakeDeviceEnvironmentPort(this.bootLog);

  @override
  Future<DeviceEnvironmentInfo> getDeviceEnvironment() async {
    bootLog.add('step1:getDeviceEnvironment');
    return DeviceEnvironmentInfo(
      androidId: 'pixel_9_pro_android_id_77',
      deviceName: 'Pixel 9 Pro',
      brand: 'google',
      model: 'Pixel 9 Pro',
      osVersion: '15',
      sdkInt: 35,
      appVersionName: '1.4.0',
      appVersionCode: 140,
      deviceTypeWire: 'SMARTPHONE',
      maxMusicVolumeSteps: 25,
      currentMusicVolumeRatio: 0.5,
      hasBluetoothConnectPermission: true,
      hasNearbyWifiPermission: true,
    );
  }

  @override
  Future<ConnectPermissionStatus> requestConnectPermissions() async =>
      const ConnectPermissionStatus(bluetoothConnect: true, nearbyWifi: true);

  @override
  Future<bool> openAppSettings() async => true;
}

final class _CoordinatorFakeAudioRoutePort implements AudioRoutePort {
  final StreamController<List<LocalAudioPeripheral>> controller =
      StreamController<List<LocalAudioPeripheral>>.broadcast();

  @override
  Future<List<LocalAudioPeripheral>> getPeripherals() async =>
      <LocalAudioPeripheral>[
        LocalAudioPeripheral(
          id: kBuiltInSpeakerPeripheralId,
          name: 'This phone',
          isActive: true,
          connectionType: OutputPeripheralConnectionType.builtInSpeaker,
        ),
      ];

  @override
  Stream<List<LocalAudioPeripheral>> watchPeripherals() => controller.stream;

  @override
  Future<bool> openSystemOutputSwitcher() async => true;

  Future<void> close() => controller.close();
}

final class _CoordinatorFakeSystemVolumePort implements SystemVolumePort {
  final List<String> bootLog;
  final StreamController<SystemVolumeEvent> controller =
      StreamController<SystemVolumeEvent>.broadcast();

  _CoordinatorFakeSystemVolumePort(this.bootLog);

  @override
  Future<SystemVolumeSnapshot> getLocalVolume() async {
    bootLog.add('step7:getLocalVolume');
    return SystemVolumeSnapshot(volume: 32768, steps: 25, currentStep: 12);
  }

  @override
  Future<bool> setLocalVolume({required int volume, bool showUi = false}) async =>
      true;

  @override
  Future<bool> configureRemoteHardwareVolume({
    required bool enabled,
    required bool supportsVolume,
    required int volumeSteps,
    required int currentVolume,
  }) async =>
      true;

  @override
  Future<bool> updateRemoteHardwareVolume({required int currentVolume}) async =>
      true;

  @override
  Stream<SystemVolumeEvent> watchEvents() => controller.stream;

  Future<void> close() => controller.close();
}

final class _CoordinatorFakeLocalDiscoveryPort implements LocalDiscoveryPort {
  final List<String> bootLog;
  final StreamController<List<DiscoveredNsdService>> controller =
      StreamController<List<DiscoveredNsdService>>.broadcast();
  int startDiscoveryCalls = 0;
  int stopDiscoveryCalls = 0;

  _CoordinatorFakeLocalDiscoveryPort(this.bootLog);

  @override
  Future<void> startDiscovery() async {
    startDiscoveryCalls += 1;
    bootLog.add('step8:startDiscovery');
  }

  @override
  Future<void> stopDiscovery() async {
    stopDiscoveryCalls += 1;
    bootLog.add('teardown:stopDiscovery');
  }

  @override
  Future<List<DiscoveredNsdService>> getDiscoveredServices() async =>
      <DiscoveredNsdService>[
        DiscoveredNsdService(
          serviceName: 'LivingRoom-Speaker',
          host: '192.168.1.44',
          port: 8009,
          cPath: '/zc',
          version: '2.12.0',
          stack: 'libspotify',
        ),
      ];

  @override
  Stream<List<DiscoveredNsdService>> watchDiscoveredServices() =>
      controller.stream;

  Future<void> close() => controller.close();
}

final class _CoordinatorFakeNativeGateway implements ConnectNativeGateway {
  final List<String> bootLog;
  final StreamController<Uint8List> localVolumeController =
      StreamController<Uint8List>.broadcast();
  final StreamController<String> diagnosticController =
      StreamController<String>.broadcast();

  int startReturnCode = 0;
  Uint8List? lastStartDeviceInfoBytes;
  int stopCalls = 0;
  String? lastSpclientUrl;
  String? lastDealerWsUrl;
  final List<ConnectReconnectReason> reconnectReasons =
      <ConnectReconnectReason>[];
  final List<bool> networkAvailableCalls = <bool>[];
  final List<String> nsdUpdates = <String>[];

  _CoordinatorFakeNativeGateway(this.bootLog);

  @override
  int start(Uint8List deviceInfoBytes) {
    bootLog.add('step6:nativeGateway.start');
    lastStartDeviceInfoBytes = deviceInfoBytes;
    return startReturnCode;
  }

  @override
  void stop() {
    stopCalls += 1;
    bootLog.add('teardown:nativeGateway.stop');
  }

  @override
  int setEndpoints({
    required String spclientBaseUrl,
    required String dealerWsUrl,
  }) {
    bootLog.add('step4:nativeGateway.setEndpoints');
    lastSpclientUrl = spclientBaseUrl;
    lastDealerWsUrl = dealerWsUrl;
    return 0;
  }

  @override
  int reconnect(ConnectReconnectReason reason) {
    reconnectReasons.add(reason);
    bootLog.add('reconnect:${reason.name}');
    return 0;
  }

  @override
  void setNetworkAvailable(bool isAvailable) {
    networkAvailableCalls.add(isAvailable);
    bootLog.add('step7:setNetworkAvailable:$isAvailable');
  }

  @override
  int updateNsdServices(String servicesJsonUtf8) {
    nsdUpdates.add(servicesJsonUtf8);
    bootLog.add('step8:updateNsdServices');
    return 0;
  }

  @override
  int setLocalVolume({
    required int volume0To65535,
    required int volumeSteps,
    required ConnectLocalVolumeReason reason,
  }) {
    bootLog.add('step7:setLocalVolume:${reason.name}:$volume0To65535');
    return 0;
  }

  @override
  Future<ConnectAsyncCallResult> callServiceAsync({
    required ConnectEsperantoServiceId serviceId,
    required String method,
    required Uint8List payload,
  }) async =>
      ConnectAsyncCallResult(statusCode: 0, payloadBytes: Uint8List(0));

  @override
  Stream<Uint8List> get localVolumeStream => localVolumeController.stream;

  @override
  Stream<String> get diagnosticStream => diagnosticController.stream;

  @override
  void dispose() {
    unawaited(localVolumeController.close());
    unawaited(diagnosticController.close());
  }
}

final class _CoordinatorFakeBridge extends Fake
    implements NativePlaybackSessionBridge {
  final List<String> bootLog;
  int syncCalls = 0;
  int clearCalls = 0;

  _CoordinatorFakeBridge(this.bootLog);

  @override
  Future<void> syncSessionToNative() async {
    syncCalls += 1;
    bootLog.add('step3:syncSessionToNative');
  }

  @override
  Future<void> clearNativeAuthSession() async {
    clearCalls += 1;
    bootLog.add('teardown:clearNativeAuthSession');
  }
}

final class _CoordinatorFakeConnectivity extends Fake implements Connectivity {
  final StreamController<List<ConnectivityResult>> controller =
      StreamController<List<ConnectivityResult>>.broadcast();
  List<ConnectivityResult> initialResults = <ConnectivityResult>[
    ConnectivityResult.wifi,
  ];

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => initialResults;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      controller.stream;

  Future<void> close() => controller.close();
}

final class _FakeApResolveHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    const body = '{"spclient":{"regional":["gew4-spclient.spotify.com:443"]},'
        '"dealer-g2":{"regional":["gew4-dealer.g2.spotify.com:443"]}}';
    return http.StreamedResponse(
      Stream<List<int>>.value(body.codeUnits),
      200,
    );
  }
}

final class _CoordinatorMinimalTokenStore extends Fake
    implements SpotifyTokenStore {
  @override
  Future<void> saveSpDc(String spDc) async {}

  @override
  Future<void> saveAccessToken(String token, {int lifetimeMs = 3600000}) async {}

  @override
  Future<void> clearAll() async {}
}

final class _CoordinatorMinimalRefresher extends Fake
    implements SpotifyTokenRefresher {
  @override
  Future<String?> refresh() async => 'token';
}

final class _CoordinatorMinimalProfileFetcher extends Fake
    implements SpotifyProfileFetcher {
  @override
  Future<SpotifyUser?> fetchProfile() async =>
      const SpotifyUser(id: 'user_1', displayName: 'User One', product: 'premium');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('ConnectSessionCoordinator', () {
    test('executes 8-step auth-gated boot on Authenticated, recovers on foreground & network restore, and tears down + wipes sorting DB on Unauthenticated', () async {
      final bootLog = <String>[];
      final prefs = await SharedPreferences.getInstance();
      final identityService = DeviceIdentityService(preferences: prefs);
      final apResolveService = ApResolveService(
        httpClient: _FakeApResolveHttpClient(),
        epochSecondsProvider: () => 1763578800,
      );
      final envPort = _CoordinatorFakeDeviceEnvironmentPort(bootLog);
      final audioRoutePort = _CoordinatorFakeAudioRoutePort();
      final systemVolumePort = _CoordinatorFakeSystemVolumePort(bootLog);
      final discoveryPort = _CoordinatorFakeLocalDiscoveryPort(bootLog);
      final nativeGateway = _CoordinatorFakeNativeGateway(bootLog);
      final bridge = _CoordinatorFakeBridge(bootLog);
      final connectivity = _CoordinatorFakeConnectivity();
      final transport = _CoordinatorFakeTransport();
      final sortingDb = DevicePickerSortingDatabase.forTesting(
        NativeDatabase.memory(),
      );
      final volumeController = RemoteVolumeController(
        volumeClient: ConnectVolumeServiceClient(transport),
        systemVolumePort: systemVolumePort,
        nativeGateway: nativeGateway,
        autoStart: false,
      );
      final connectController = ConnectMobiusController(
        connectServiceClient: ConnectServiceClient(transport),
        volumeServiceClient: ConnectVolumeServiceClient(transport),
        dodoServiceClient: DodoServiceClient(transport),
        sortingDatabase: sortingDb,
        remoteVolumeController: volumeController,
        audioRoutePort: audioRoutePort,
        autoStart: false,
      );
      final authBloc = AuthBloc(
        tokenStore: _CoordinatorMinimalTokenStore(),
        refresher: _CoordinatorMinimalRefresher(),
        profileFetcher: _CoordinatorMinimalProfileFetcher(),
        cacheManager: AppCacheManager(),
      );

      final coordinator = ConnectSessionCoordinator(
        authBloc: authBloc,
        authSessionProvider: _CoordinatorFakeAuthSessionProvider(bootLog),
        deviceIdentityService: identityService,
        apResolveService: apResolveService,
        deviceEnvironmentPort: envPort,
        audioRoutePort: audioRoutePort,
        systemVolumePort: systemVolumePort,
        localDiscoveryPort: discoveryPort,
        nativeGateway: nativeGateway,
        playbackSessionBridge: bridge,
        connectController: connectController,
        remoteVolumeController: volumeController,
        sortingDatabase: sortingDb,
        runtimeContext: RuntimeContext(country: 'US', catalogue: 'premium'),
        connectivity: connectivity,
        observeAppLifecycle: false,
        isAndroidOverride: true,
      );
      addTearDown(() async {
        await coordinator.dispose();
        await connectController.close();
        await volumeController.dispose();
        await sortingDb.close();
        await audioRoutePort.close();
        await systemVolumePort.close();
        await discoveryPort.close();
        await connectivity.close();
        nativeGateway.dispose();
        await authBloc.close();
      });

      // Initially unauthenticated -> ConnectSessionIdle, native start not called
      await coordinator.pendingOperations;
      expect(coordinator.state, equals(const ConnectSessionIdle()));
      expect(coordinator.isRunning, isFalse);
      expect(nativeGateway.lastStartDeviceInfoBytes, isNull);

      // Seed sorting database row so we can verify logout wipes it
      await sortingDb.recordConnection(deviceIdentifier: 'remote-speaker-1');
      expect(await sortingDb.getLastConnections(), hasLength(1));

      // Trigger login -> Authenticated
      authBloc.add(
        const AuthTokensCaptured(
          spDcCookie: 'AQB_COOKIE_123456',
          accessToken: 'BQD_TOKEN_123456',
        ),
      );
      await pumpEventQueue();
      await coordinator.pendingOperations;
      await pumpEventQueue();

      expect(coordinator.isRunning, isTrue);
      expect(coordinator.state, isA<ConnectSessionRunning>());
      if (coordinator.state case final ConnectSessionRunning running) {
        expect(running.userId, equals('user_1'));
        expect(
          DeviceIdentityService.isValidCanonicalDeviceId(running.deviceId),
          isTrue,
        );
        expect(
          running.endpoints.spclientBaseUrl,
          equals('https://gew4-spclient.spotify.com/'),
        );
      }

      // Verify exact 8-step ordering
      expect(
        bootLog,
        containsAllInOrder(<String>[
          'step1:getDeviceEnvironment',
          'step3:getAccessToken',
          'step3:getClientToken',
          'step3:syncSessionToNative',
          'step3:getActiveClientId',
          'step4:nativeGateway.setEndpoints',
          'step6:nativeGateway.start',
          'step7:setNetworkAvailable:true',
          'step7:getLocalVolume',
          'step7:setLocalVolume:system:32768',
          'step8:startDiscovery',
          'step8:updateNsdServices',
        ]),
      );
      expect(nativeGateway.lastStartDeviceInfoBytes, isNotNull);
      expect(nativeGateway.lastStartDeviceInfoBytes, isNotEmpty);
      expect(connectController.isStarted, isTrue);
      expect(volumeController.isStarted, isTrue);

      // Foreground recovery (AppLifecycleState.resumed)
      coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await coordinator.pendingOperations;
      await pumpEventQueue();
      expect(
        nativeGateway.reconnectReasons,
        contains(ConnectReconnectReason.foreground),
      );
      expect(transport.singleMethods, contains('RefreshCluster'));

      // Network offline -> online restoration
      connectivity.controller.add(<ConnectivityResult>[ConnectivityResult.none]);
      await pumpEventQueue();
      expect(nativeGateway.networkAvailableCalls.last, isFalse);

      connectivity.controller.add(<ConnectivityResult>[ConnectivityResult.wifi]);
      await pumpEventQueue();
      await coordinator.pendingOperations;
      await pumpEventQueue();
      expect(nativeGateway.networkAvailableCalls.last, isTrue);
      expect(
        nativeGateway.reconnectReasons,
        contains(ConnectReconnectReason.networkRestored),
      );

      // Logout -> Unauthenticated tears down all Connect subsystems and wipes sorting DB
      authBloc.add(const AuthLogoutRequested());
      await pumpEventQueue();
      await coordinator.pendingOperations;
      await pumpEventQueue();

      expect(coordinator.state, equals(const ConnectSessionIdle()));
      expect(coordinator.isRunning, isFalse);
      expect(connectController.isStarted, isFalse);
      expect(volumeController.isStarted, isFalse);
      expect(discoveryPort.stopDiscoveryCalls, greaterThanOrEqualTo(1));
      expect(nativeGateway.stopCalls, greaterThanOrEqualTo(1));
      expect(bridge.clearCalls, greaterThanOrEqualTo(1));
      expect(await sortingDb.getLastConnections(), isEmpty);
    });

    test('transitions to ConnectSessionFailed when nativeGateway.start returns negative error code', () async {
      final bootLog = <String>[];
      final prefs = await SharedPreferences.getInstance();
      final identityService = DeviceIdentityService(preferences: prefs);
      final apResolveService = ApResolveService(
        httpClient: _FakeApResolveHttpClient(),
      );
      final envPort = _CoordinatorFakeDeviceEnvironmentPort(bootLog);
      final audioRoutePort = _CoordinatorFakeAudioRoutePort();
      final systemVolumePort = _CoordinatorFakeSystemVolumePort(bootLog);
      final discoveryPort = _CoordinatorFakeLocalDiscoveryPort(bootLog);
      final nativeGateway = _CoordinatorFakeNativeGateway(bootLog)
        ..startReturnCode = -3;
      final bridge = _CoordinatorFakeBridge(bootLog);
      final connectivity = _CoordinatorFakeConnectivity();
      final transport = _CoordinatorFakeTransport();
      final sortingDb = DevicePickerSortingDatabase.forTesting(
        NativeDatabase.memory(),
      );
      final volumeController = RemoteVolumeController(
        volumeClient: ConnectVolumeServiceClient(transport),
        autoStart: false,
      );
      final connectController = ConnectMobiusController(
        connectServiceClient: ConnectServiceClient(transport),
        volumeServiceClient: ConnectVolumeServiceClient(transport),
        dodoServiceClient: DodoServiceClient(transport),
        sortingDatabase: sortingDb,
        remoteVolumeController: volumeController,
        autoStart: false,
      );
      final authBloc = AuthBloc(
        tokenStore: _CoordinatorMinimalTokenStore(),
        refresher: _CoordinatorMinimalRefresher(),
        profileFetcher: _CoordinatorMinimalProfileFetcher(),
        cacheManager: AppCacheManager(),
        initialUser: const SpotifyUser(id: 'user_fail', displayName: 'Fail User'),
      );

      final coordinator = ConnectSessionCoordinator(
        authBloc: authBloc,
        authSessionProvider: _CoordinatorFakeAuthSessionProvider(bootLog),
        deviceIdentityService: identityService,
        apResolveService: apResolveService,
        deviceEnvironmentPort: envPort,
        audioRoutePort: audioRoutePort,
        systemVolumePort: systemVolumePort,
        localDiscoveryPort: discoveryPort,
        nativeGateway: nativeGateway,
        playbackSessionBridge: bridge,
        connectController: connectController,
        remoteVolumeController: volumeController,
        sortingDatabase: sortingDb,
        connectivity: connectivity,
        observeAppLifecycle: false,
        isAndroidOverride: true,
      );
      addTearDown(() async {
        await coordinator.dispose();
        await connectController.close();
        await volumeController.dispose();
        await sortingDb.close();
        await audioRoutePort.close();
        await systemVolumePort.close();
        await discoveryPort.close();
        await connectivity.close();
        nativeGateway.dispose();
        await authBloc.close();
      });

      await coordinator.pendingOperations;
      expect(coordinator.state, isA<ConnectSessionFailed>());
      if (coordinator.state case final ConnectSessionFailed failed) {
        expect(failed.userId, equals('user_fail'));
        expect(failed.message, contains('-3'));
      }
    });

    test('onDevicePickerOpened and onDevicePickerClosed drive immediate discovery and periodic refresh timer', () async {
      final bootLog = <String>[];
      final prefs = await SharedPreferences.getInstance();
      final identityService = DeviceIdentityService(preferences: prefs);
      final apResolveService = ApResolveService(
        httpClient: _FakeApResolveHttpClient(),
      );
      final envPort = _CoordinatorFakeDeviceEnvironmentPort(bootLog);
      final audioRoutePort = _CoordinatorFakeAudioRoutePort();
      final systemVolumePort = _CoordinatorFakeSystemVolumePort(bootLog);
      final discoveryPort = _CoordinatorFakeLocalDiscoveryPort(bootLog);
      final nativeGateway = _CoordinatorFakeNativeGateway(bootLog);
      final bridge = _CoordinatorFakeBridge(bootLog);
      final connectivity = _CoordinatorFakeConnectivity();
      final transport = _CoordinatorFakeTransport();
      final sortingDb = DevicePickerSortingDatabase.forTesting(
        NativeDatabase.memory(),
      );
      final volumeController = RemoteVolumeController(
        volumeClient: ConnectVolumeServiceClient(transport),
        autoStart: false,
      );
      final connectController = ConnectMobiusController(
        connectServiceClient: ConnectServiceClient(transport),
        volumeServiceClient: ConnectVolumeServiceClient(transport),
        dodoServiceClient: DodoServiceClient(transport),
        sortingDatabase: sortingDb,
        remoteVolumeController: volumeController,
        autoStart: false,
      );
      final authBloc = AuthBloc(
        tokenStore: _CoordinatorMinimalTokenStore(),
        refresher: _CoordinatorMinimalRefresher(),
        profileFetcher: _CoordinatorMinimalProfileFetcher(),
        cacheManager: AppCacheManager(),
        initialUser: const SpotifyUser(id: 'user_picker', displayName: 'Picker User'),
      );

      final coordinator = ConnectSessionCoordinator(
        authBloc: authBloc,
        authSessionProvider: _CoordinatorFakeAuthSessionProvider(bootLog),
        deviceIdentityService: identityService,
        apResolveService: apResolveService,
        deviceEnvironmentPort: envPort,
        audioRoutePort: audioRoutePort,
        systemVolumePort: systemVolumePort,
        localDiscoveryPort: discoveryPort,
        nativeGateway: nativeGateway,
        playbackSessionBridge: bridge,
        connectController: connectController,
        remoteVolumeController: volumeController,
        sortingDatabase: sortingDb,
        connectivity: connectivity,
        observeAppLifecycle: false,
        isAndroidOverride: true,
        pickerRefreshInterval: const Duration(milliseconds: 35),
      );
      addTearDown(() async {
        await coordinator.dispose();
        await connectController.close();
        await volumeController.dispose();
        await sortingDb.close();
        await audioRoutePort.close();
        await systemVolumePort.close();
        await discoveryPort.close();
        await connectivity.close();
        nativeGateway.dispose();
        await authBloc.close();
      });

      await pumpEventQueue();
      await coordinator.pendingOperations;
      await pumpEventQueue();
      expect(coordinator.isRunning, isTrue);

      final secondPassCompleter = Completer<void>();
      var refreshClusterCount = 0;
      final sub = connectController.stream.listen((_) {});
      addTearDown(sub.cancel);

      transport.singleMethods.clear();
      coordinator.onDevicePickerOpened();
      expect(coordinator.isDevicePickerOpen, isTrue);
      await pumpEventQueue();

      // Immediate pass on picker open: PerformDiscovery, RefreshCluster, WakeSleepingClusterDevices
      expect(
        transport.singleMethods,
        equals(<String>[
          'PerformDiscovery',
          'RefreshCluster',
          'WakeSleepingClusterDevices',
        ]),
      );

      // Wait for periodic refresh timer tick
      final pollTimer = Timer(const Duration(milliseconds: 55), () {
        if (!secondPassCompleter.isCompleted) {
          secondPassCompleter.complete();
        }
      });
      addTearDown(pollTimer.cancel);
      await secondPassCompleter.future;
      await pumpEventQueue();

      refreshClusterCount = transport.singleMethods
          .where((m) => m == 'RefreshCluster')
          .length;
      expect(refreshClusterCount, greaterThanOrEqualTo(2));

      // Close picker -> timer cancels deterministically
      coordinator.onDevicePickerClosed();
      expect(coordinator.isDevicePickerOpen, isFalse);
      final countAtClose = transport.singleMethods.length;

      final afterCloseCompleter = Completer<void>();
      final afterCloseTimer = Timer(const Duration(milliseconds: 60), () {
        if (!afterCloseCompleter.isCompleted) {
          afterCloseCompleter.complete();
        }
      });
      addTearDown(afterCloseTimer.cancel);
      await afterCloseCompleter.future;
      await pumpEventQueue();
      expect(transport.singleMethods.length, equals(countAtClose));
    });
  });
}
