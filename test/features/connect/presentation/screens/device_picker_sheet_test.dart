import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/theme/app_theme.dart';
import 'package:musify_mu/core/audio/native_playback_session_bridge.dart';
import 'package:musify_mu/core/config/device_identity_service.dart';
import 'package:musify_mu/core/network/spotify/ap_resolve_service.dart';
import 'package:musify_mu/core/network/spotify/auth/auth_session_provider.dart';
import 'package:musify_mu/features/connect/application/lifecycle/connect_session_coordinator.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/application/sorting/device_picker_sorting_database.dart';
import 'package:musify_mu/features/connect/application/volume/remote_volume_controller.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_volume_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/dodo_service_client.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart'
    as common_pb;
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pbenum.dart'
    as common_pbenum;
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pb.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pbenum.dart'
    as connect_pbenum;
import 'package:musify_mu/features/connect/data/proto/group.pb.dart'
    as group_pb;
import 'package:musify_mu/features/connect/data/proto/group.pbenum.dart'
    as group_pbenum;
import 'package:musify_mu/features/connect/domain/interfaces/audio_route_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/connect_native_gateway.dart';
import 'package:musify_mu/features/connect/domain/interfaces/device_environment_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/local_discovery_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/system_volume_port.dart';
import 'package:musify_mu/features/connect/presentation/screens/device_picker_sheet.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_volume_slider.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_list_tile.dart';
import 'package:musify_mu/features/connect/presentation/widgets/group_device_tile.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';

final class _SheetFakeTransport implements EsperantoTransport {
  final StreamController<Uint8List> stateStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> volumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> localVolumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> dodoStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> installStreamController =
      StreamController<Uint8List>.broadcast();

  final List<String> singleMethods = <String>[];
  final Map<String, List<Uint8List>> singlePayloads = <String, List<Uint8List>>{};
  Future<Uint8List> Function(String service, String method, Uint8List payload)?
      onCallSingle;

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    singleMethods.add(method);
    singlePayloads.putIfAbsent(method, () => <Uint8List>[]).add(payload);
    if (onCallSingle case final handler?) {
      return handler(service, method, payload);
    }
    if (method == 'Transfer') {
      return Uint8List.fromList(
        common_pb.StatusResponse(
          status: common_pbenum.Status.OK,
        ).writeToBuffer(),
      );
    }
    return Uint8List.fromList(
      common_pb.StatusResponse(
        status: common_pbenum.Status.OK,
      ).writeToBuffer(),
    );
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
    if (service == ConnectServiceClient.serviceName &&
        method == 'InstallSpotify') {
      return installStreamController.stream;
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
    await installStreamController.close();
  }
}

final class _FakeDeviceEnvironmentPort implements DeviceEnvironmentPort {
  _FakeDeviceEnvironmentPort({
    this.hasBluetoothConnect = true,
    this.hasNearbyWifi = true,
    ConnectPermissionStatus? nextGrantedStatus,
  }) : _nextGrantedStatus = nextGrantedStatus;

  bool hasBluetoothConnect;
  bool hasNearbyWifi;
  ConnectPermissionStatus? _nextGrantedStatus;
  int getDeviceEnvironmentCallCount = 0;
  int requestConnectPermissionsCallCount = 0;
  int openAppSettingsCallCount = 0;

  set nextGrantedStatus(ConnectPermissionStatus status) {
    _nextGrantedStatus = status;
  }

  @override
  Future<DeviceEnvironmentInfo> getDeviceEnvironment() async {
    getDeviceEnvironmentCallCount += 1;
    return DeviceEnvironmentInfo(
      androidId: 'a1b2c3d4e5f60718',
      deviceName: 'Pixel 9 Pro',
      brand: 'google',
      model: 'Pixel 9 Pro',
      osVersion: '15',
      sdkInt: 35,
      appVersionName: '1.0.0',
      appVersionCode: 1,
      deviceTypeWire: 'SMARTPHONE',
      maxMusicVolumeSteps: 25,
      currentMusicVolumeRatio: 0.5,
      hasBluetoothConnectPermission: hasBluetoothConnect,
      hasNearbyWifiPermission: hasNearbyWifi,
    );
  }

  @override
  Future<ConnectPermissionStatus> requestConnectPermissions() async {
    requestConnectPermissionsCallCount += 1;
    if (_nextGrantedStatus case final granted?) {
      hasBluetoothConnect = granted.bluetoothConnect;
      hasNearbyWifi = granted.nearbyWifi;
      return granted;
    }
    return ConnectPermissionStatus(
      bluetoothConnect: hasBluetoothConnect,
      nearbyWifi: hasNearbyWifi,
    );
  }

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCallCount += 1;
    return true;
  }
}

final class _FakeAudioRoutePort implements AudioRoutePort {
  final StreamController<List<LocalAudioPeripheral>> _peripheralsController =
      StreamController<List<LocalAudioPeripheral>>.broadcast();
  List<LocalAudioPeripheral> currentPeripherals = const <LocalAudioPeripheral>[];
  int openSystemOutputSwitcherCallCount = 0;

  @override
  Future<List<LocalAudioPeripheral>> getPeripherals() async {
    return currentPeripherals;
  }

  @override
  Stream<List<LocalAudioPeripheral>> watchPeripherals() {
    return _peripheralsController.stream;
  }

  @override
  Future<bool> openSystemOutputSwitcher() async {
    openSystemOutputSwitcherCallCount += 1;
    return true;
  }

  Future<void> close() async {
    await _peripheralsController.close();
  }
}

final class _FakeAuthSessionProvider implements AuthSessionProvider {
  @override
  Future<String?> getAccessToken() async => 'fake-access-token';

  @override
  Future<String?> getClientToken() async => 'fake-client-token';

  @override
  Future<String?> refreshAccessToken() async => 'fake-access-token';

  @override
  Future<String?> forceRefreshClientToken() async => 'fake-client-token';

  @override
  Future<String> getActiveClientId() async =>
      AuthClientProfileConfig.webPlayerDefault.clientId;

  @override
  Future<AuthClientProfile> getActiveClientProfile() async =>
      AuthClientProfile.webPlayer;

  @override
  Future<AuthClientProfileConfig> getActiveClientProfileConfig() async =>
      AuthClientProfileConfig.webPlayerDefault;
}

final class _FakeSystemVolumePort implements SystemVolumePort {
  @override
  Future<SystemVolumeSnapshot> getLocalVolume() async {
    return SystemVolumeSnapshot(volume: 32768, steps: 25, currentStep: 12);
  }

  @override
  Future<bool> setLocalVolume({
    required int volume,
    bool showUi = false,
  }) async =>
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
  Future<bool> updateRemoteHardwareVolume({
    required int currentVolume,
  }) async =>
      true;

  @override
  Stream<SystemVolumeEvent> watchEvents() =>
      const Stream<SystemVolumeEvent>.empty();
}

final class _FakeLocalDiscoveryPort implements LocalDiscoveryPort {
  @override
  Future<void> startDiscovery() async {}

  @override
  Future<void> stopDiscovery() async {}

  @override
  Future<List<DiscoveredNsdService>> getDiscoveredServices() async =>
      const <DiscoveredNsdService>[];

  @override
  Stream<List<DiscoveredNsdService>> watchDiscoveredServices() =>
      const Stream<List<DiscoveredNsdService>>.empty();
}

final class _FakeConnectNativeGateway implements ConnectNativeGateway {
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
  }) async {
    return ConnectAsyncCallResult(statusCode: 0, payloadBytes: Uint8List(0));
  }

  @override
  Stream<Uint8List> get localVolumeStream => const Stream<Uint8List>.empty();

  @override
  Stream<String> get diagnosticStream => const Stream<String>.empty();

  @override
  void dispose() {}
}

final class _FakePlaybackSessionBridge extends Fake
    implements NativePlaybackSessionBridge {
  @override
  Future<void> syncSessionToNative() async {}

  @override
  Future<void> clearNativeAuthSession() async {}

  @override
  void dispose() {}
}

final class _SheetHarness {
  _SheetHarness._({
    required this.transport,
    required this.sortingDb,
    required this.volumeClient,
    required this.volumeController,
    required this.controller,
  });

  factory _SheetHarness() {
    final transport = _SheetFakeTransport();
    final sortingDb = DevicePickerSortingDatabase.forTesting(
      NativeDatabase.memory(),
    );
    final volumeClient = ConnectVolumeServiceClient(transport);
    final volumeController = RemoteVolumeController(
      volumeClient: volumeClient,
      throttleWindow: Duration.zero,
      suppressionWindow: Duration.zero,
      localDebounceWindow: Duration.zero,
    );
    final controller = ConnectMobiusController(
      connectServiceClient: ConnectServiceClient(transport),
      volumeServiceClient: volumeClient,
      dodoServiceClient: DodoServiceClient(transport),
      sortingDatabase: sortingDb,
      remoteVolumeController: volumeController,
      commandIdGenerator: () => 'abcdef0123456789abcdef0123456789',
    );
    controller.start();
    return _SheetHarness._(
      transport: transport,
      sortingDb: sortingDb,
      volumeClient: volumeClient,
      volumeController: volumeController,
      controller: controller,
    );
  }

  final _SheetFakeTransport transport;
  final DevicePickerSortingDatabase sortingDb;
  final ConnectVolumeServiceClient volumeClient;
  final RemoteVolumeController volumeController;
  final ConnectMobiusController controller;

  ConnectSessionCoordinator createCoordinator({
    DeviceEnvironmentPort? deviceEnvironmentPort,
    AudioRoutePort? audioRoutePort,
    Duration pickerRefreshInterval = const Duration(hours: 1),
  }) {
    return ConnectSessionCoordinator(
      authSessionProvider: _FakeAuthSessionProvider(),
      deviceIdentityService: DeviceIdentityService(),
      apResolveService: ApResolveService(),
      deviceEnvironmentPort: switch (deviceEnvironmentPort) {
        final provided? => provided,
        null => _FakeDeviceEnvironmentPort(),
      },
      audioRoutePort: switch (audioRoutePort) {
        final provided? => provided,
        null => _FakeAudioRoutePort(),
      },
      systemVolumePort: _FakeSystemVolumePort(),
      localDiscoveryPort: _FakeLocalDiscoveryPort(),
      nativeGateway: _FakeConnectNativeGateway(),
      playbackSessionBridge: _FakePlaybackSessionBridge(),
      connectController: controller,
      remoteVolumeController: volumeController,
      sortingDatabase: sortingDb,
      observeAppLifecycle: false,
      isAndroidOverride: false,
      pickerRefreshInterval: pickerRefreshInterval,
    );
  }

  Future<void> dispose() async {
    await controller.close();
    await volumeController.dispose();
    await sortingDb.close();
    await transport.close();
  }
}

connect_pb.StateResponse_Device _protoDevice({
  required String id,
  required String name,
  String? localIdentifier,
  String type = 'SPEAKER',
  String state = 'LOGGED_IN',
  bool isSelf = false,
  bool isActive = false,
  bool isLocal = true,
  bool isGroup = false,
  bool supportsLogout = true,
  bool supportsVolume = true,
  bool supportsRename = false,
  int volume = 32768,
  int volumeSteps = 24,
  group_pb.GroupData? groupData,
  List<connect_pb.StateResponse_Incarnation> incarnations =
      const <connect_pb.StateResponse_Incarnation>[],
}) {
  final resolvedLocalId = switch (localIdentifier) {
    final value? => value,
    null => 'local-$id',
  };
  return connect_pb.StateResponse_Device(
    isSelf: isSelf,
    isActive: isActive,
    isLocal: isLocal,
    isGroup: isGroup,
    supportsLogout: supportsLogout,
    supportsVolume: supportsVolume,
    supportsRename: supportsRename,
    connectStateIdentifier: id,
    localIdentifier: resolvedLocalId,
    name: name,
    state: state,
    type: type,
    volume: volume,
    volumeSteps: volumeSteps,
    capabilities: '[]',
    groupData: groupData,
    incarnations: incarnations,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DevicePickerSheet', () {
    testWidgets('show() opens modal, triggers auto-refresh once, and closes cleanly', (
      tester,
    ) async {
      final harness = _SheetHarness();
      addTearDown(harness.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DevicePickerSheet.show(
                  context,
                  controller: harness.controller,
                ),
                child: const Text('Open Connect'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Connect'));
      await tester.pumpAndSettle();

      expect(find.byType(DevicePickerSheet), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
      expect(find.text('Listening on This device'), findsOneWidget);
      expect(
        harness.transport.singleMethods,
        containsAll(<String>[
          'RefreshCluster',
          'PerformDiscovery',
          'WakeSleepingClusterDevices',
        ]),
      );

      // Emitting a cluster update must NOT re-trigger autoRefreshOnOpen
      final refreshCallsBefore = harness.transport.singleMethods
          .where((m) => m == 'RefreshCluster')
          .length;
      harness.transport.stateStreamController.add(
        Uint8List.fromList(
          connect_pb.StateResponse(
            isActive: false,
            isSyncedWithBackend: true,
            devices: [
              _protoDevice(
                id: 'self-1',
                name: 'Pixel 9',
                type: 'SMARTPHONE',
                isSelf: true,
                isActive: true,
              ),
            ],
          ).writeToBuffer(),
        ),
      );
      await tester.pumpAndSettle();

      final refreshCallsAfter = harness.transport.singleMethods
          .where((m) => m == 'RefreshCluster')
          .length;
      expect(refreshCallsAfter, refreshCallsBefore);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(DevicePickerSheet), findsNothing);
    });

    testWidgets('pins active remote device at top, avoids duplicate keys, and splits "On other networks"', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final harness = _SheetHarness();
      addTearDown(harness.dispose);

      harness.transport.stateStreamController.add(
        Uint8List.fromList(
          connect_pb.StateResponse(
            isActive: true,
            isSyncedWithBackend: true,
            devices: [
              _protoDevice(
                id: 'self-phone',
                name: 'My Phone',
                type: 'SMARTPHONE',
                isSelf: true,
                isActive: false,
                isLocal: true,
              ),
              _protoDevice(
                id: 'local-spk',
                name: 'Bedroom Speaker',
                type: 'SPEAKER',
                isSelf: false,
                isActive: false,
                isLocal: true,
              ),
              _protoDevice(
                id: 'remote-tv',
                name: 'Studio TV',
                type: 'TV',
                isSelf: false,
                isActive: true,
                isLocal: false,
              ),
              _protoDevice(
                id: 'remote-pc',
                name: 'Office PC',
                type: 'COMPUTER',
                isSelf: false,
                isActive: false,
                isLocal: false,
              ),
            ],
          ).writeToBuffer(),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DevicePickerSheet(
              controller: harness.controller,
              autoRefreshOnOpen: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pinned active card is at top above "Select a device"
      final pinnedRect = tester.getRect(
        find.byKey(const ValueKey<String>('pinned_active_device_card')),
      );
      final selectHeaderRect = tester.getRect(find.text('Select a device'));
      expect(pinnedRect.bottom, lessThanOrEqualTo(selectHeaderRect.top));

      // Active remote device appears in pinned card and NOT duplicated in Select a device
      expect(find.byKey(const ValueKey<String>('active_device_remote-tv')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('device_remote-tv')), findsNothing);
      expect(find.text('Listening on Studio TV'), findsOneWidget);

      // Remote volume slider is shown inside pinned card
      expect(find.byType(ConnectVolumeSlider), findsOneWidget);

      // "On other networks" header appears before off-network Office PC
      expect(find.text('On other networks'), findsOneWidget);
      final localSpkRect = tester.getRect(
        find.byKey(const ValueKey<String>('device_local-spk')),
      );
      final otherNetRect = tester.getRect(find.text('On other networks'));
      final officePcRect = tester.getRect(
        find.byKey(const ValueKey<String>('device_remote-pc')),
      );
      expect(localSpkRect.bottom, lessThan(otherNetRect.top));
      expect(otherNetRect.bottom, lessThan(officePcRect.top));

      // Tapping inactive remote device -> Transfer RPC
      await tester.tap(find.byKey(const ValueKey<String>('device_local-spk')));
      await tester.pumpAndSettle();
      expect(harness.transport.singleMethods, contains('Transfer'));

      // Tapping active remote device -> Pull RPC
      await tester.tap(
        find.byKey(const ValueKey<String>('active_device_remote-tv')),
      );
      await tester.pumpAndSettle();
      expect(harness.transport.singleMethods, contains('Pull'));

      // Logout via device menu -> Logout RPC
      await tester.tap(find.byKey(const ValueKey<String>('device_menu_local-spk')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(harness.transport.singleMethods, contains('Logout'));
    });

    testWidgets('renders group active device with GroupDeviceTile controls and DeleteGroup action', (
      tester,
    ) async {
      final harness = _SheetHarness();
      addTearDown(harness.dispose);

      harness.transport.stateStreamController.add(
        Uint8List.fromList(
          connect_pb.StateResponse(
            isActive: true,
            isSyncedWithBackend: true,
            devices: [
              _protoDevice(
                id: 'group-1',
                name: 'Home Group',
                isGroup: true,
                isActive: true,
                isLocal: false,
                groupData: group_pb.GroupData(
                  devices: [
                    group_pb.GroupDevice(
                      identifiers: group_pb.GroupDeviceIdentifiers(
                        groupDeviceIdentifier: 'member-1',
                        localIdentifier: 'local-m1',
                      ),
                      name: 'Kitchen Mini',
                      type: 'SPEAKER',
                      capabilities: group_pb.GroupDeviceCapabilities(
                        removable: true,
                        removalDissolvesGroup: false,
                      ),
                      groupingStatus: group_pbenum.GroupingStatus.GROUPED,
                      volume: group_pb.GroupDeviceVolume(
                        volume: 32768,
                        volumeSteps: 24,
                      ),
                    ),
                  ],
                  capabilities: group_pb.GroupCapabilities(maxDevices: 4),
                ),
              ),
            ],
          ).writeToBuffer(),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DevicePickerSheet(
              controller: harness.controller,
              autoRefreshOnOpen: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GroupDeviceTile), findsOneWidget);
      expect(find.text('Kitchen Mini'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('group_remove_member-1')),
      );
      await tester.pumpAndSettle();
      expect(harness.transport.singleMethods, contains('RemoveDeviceFromGroup'));

      await tester.tap(find.byKey(const ValueKey<String>('delete_group_button')));
      await tester.pumpAndSettle();
      expect(harness.transport.singleMethods, contains('DeleteGroup'));
    });

    testWidgets('displays error banner and dismisses it cleanly', (tester) async {
      final harness = _SheetHarness();
      addTearDown(harness.dispose);

      harness.transport.onCallSingle = (service, method, payload) async {
        if (method == 'Transfer') {
          return Uint8List.fromList(
            common_pb.StatusResponse(
              status: common_pbenum.Status.BACKEND_FAILURE,
            ).writeToBuffer(),
          );
        }
        return Uint8List.fromList(
          common_pb.StatusResponse(
            status: common_pbenum.Status.OK,
          ).writeToBuffer(),
        );
      };

      harness.transport.stateStreamController.add(
        Uint8List.fromList(
          connect_pb.StateResponse(
            isActive: false,
            isSyncedWithBackend: true,
            devices: [
              _protoDevice(
                id: 'spk-fail',
                name: 'Patio Speaker',
                isActive: false,
                isLocal: false,
              ),
            ],
          ).writeToBuffer(),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DevicePickerSheet(
              controller: harness.controller,
              autoRefreshOnOpen: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('device_spk-fail')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('connect_error_banner')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('dismiss_connect_error_button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('connect_error_banner')),
        findsNothing,
      );
    });

    testWidgets('triggers InstallSpotify when tapping installable device', (
      tester,
    ) async {
      final harness = _SheetHarness();
      addTearDown(harness.dispose);

      harness.transport.stateStreamController.add(
        Uint8List.fromList(
          connect_pb.StateResponse(
            isActive: false,
            isSyncedWithBackend: true,
            devices: [
              _protoDevice(
                id: 'tv-install',
                name: 'Samsung TV',
                type: 'TV',
                state: 'NOT_INSTALLED',
                isActive: false,
                isLocal: false,
              ),
            ],
          ).writeToBuffer(),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DevicePickerSheet(
              controller: harness.controller,
              autoRefreshOnOpen: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('install_tv-install')));
      await tester.pump();

      harness.transport.installStreamController.add(
        Uint8List.fromList(
          connect_pb.InstallSpotifyStatusUpdate(
            currentState:
                connect_pbenum.InstallSpotifyState.LAUNCHING_APP_STORE,
          ).writeToBuffer(),
        ),
      );
      await tester.pump();

      expect(find.text('Opening app store...'), findsOneWidget);

      harness.transport.installStreamController.add(
        Uint8List.fromList(
          connect_pb.InstallSpotifyStatusUpdate(
            currentState: connect_pbenum.InstallSpotifyState.SUCCESS,
          ).writeToBuffer(),
        ),
      );
      await tester.runAsync(() => pumpEventQueue());
      await tester.pumpAndSettle();
      expect(find.text('Spotify installed'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders without overflow on compact (<600dp height) and narrow (320dp) viewports and disposes cleanly', (
      tester,
    ) async {
      final harness = _SheetHarness();
      addTearDown(harness.dispose);

      tester.view.physicalSize = const Size(320, 520);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      harness.transport.stateStreamController.add(
        Uint8List.fromList(
          connect_pb.StateResponse(
            isActive: true,
            isSyncedWithBackend: true,
            devices: [
              _protoDevice(
                id: 'self-1',
                name: 'My Phone',
                type: 'SMARTPHONE',
                isSelf: true,
                isActive: false,
              ),
              _protoDevice(
                id: 'spk-1',
                name: 'Long Named Living Room Soundbar Device',
                type: 'SPEAKER',
                isSelf: false,
                isActive: true,
                isLocal: false,
              ),
              _protoDevice(
                id: 'spk-2',
                name: 'Another Very Long Kitchen Speaker Name',
                type: 'SPEAKER',
                isSelf: false,
                isActive: false,
                isLocal: false,
              ),
            ],
          ).writeToBuffer(),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DevicePickerSheet(
              controller: harness.controller,
              autoRefreshOnOpen: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DeviceListTile), findsNWidgets(3));
      expect(tester.takeException(), isNull);

      // Unmount cleanly to confirm no pending timers or un-disposed controllers
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();
    });

    testWidgets('manages ScrollController null <-> non-null transitions and controller replacement in didUpdateWidget', (
      tester,
    ) async {
      final harness1 = _SheetHarness();
      final harness2 = _SheetHarness();
      final external1 = ScrollController();
      final external2 = ScrollController();
      final activeHarness = ValueNotifier<_SheetHarness>(harness1);
      final activeScroll = ValueNotifier<ScrollController?>(external1);
      addTearDown(() async {
        activeHarness.dispose();
        activeScroll.dispose();
        external1.dispose();
        external2.dispose();
        await harness1.dispose();
        await harness2.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ValueListenableBuilder<_SheetHarness>(
              valueListenable: activeHarness,
              builder: (context, harness, _) {
                return ValueListenableBuilder<ScrollController?>(
                  valueListenable: activeScroll,
                  builder: (context, scrollCtrl, _) {
                    return DevicePickerSheet(
                      controller: harness.controller,
                      autoRefreshOnOpen: true,
                      scrollController: scrollCtrl,
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(external1.hasClients, isTrue);
      expect(
        harness1.transport.singleMethods,
        containsAll(<String>[
          'RefreshCluster',
          'PerformDiscovery',
          'WakeSleepingClusterDevices',
        ]),
      );

      // external1 -> null (didUpdateWidget allocates owned controller)
      activeScroll.value = null;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(external1.hasClients, isFalse);

      // null -> external2 (didUpdateWidget disposes owned controller and binds external2)
      activeScroll.value = external2;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(external2.hasClients, isTrue);

      // Replace controller -> triggers autoRefreshOnOpen on harness2
      activeHarness.value = harness2;
      await tester.pumpAndSettle();
      expect(
        harness2.transport.singleMethods,
        containsAll(<String>[
          'RefreshCluster',
          'PerformDiscovery',
          'WakeSleepingClusterDevices',
        ]),
      );

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();
    });

    testWidgets('disambiguates colliding device/group keys and preserves cross-domain local devices', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final harness = _SheetHarness();
      addTearDown(harness.dispose);

      harness.transport.stateStreamController.add(
        Uint8List.fromList(
          connect_pb.StateResponse(
            isActive: true,
            isSyncedWithBackend: true,
            devices: [
              _protoDevice(
                id: 'shared-id',
                localIdentifier: 'active-loc',
                name: 'Active Group',
                isGroup: true,
                isActive: true,
                isLocal: false,
                groupData: group_pb.GroupData(
                  devices: [
                    group_pb.GroupDevice(
                      identifiers: group_pb.GroupDeviceIdentifiers(
                        groupDeviceIdentifier: 'dup-member',
                        localIdentifier: 'm-1',
                      ),
                      name: 'Member One',
                      type: 'SPEAKER',
                      capabilities: group_pb.GroupDeviceCapabilities(
                        removable: true,
                        removalDissolvesGroup: false,
                      ),
                      groupingStatus: group_pbenum.GroupingStatus.GROUPED,
                      volume: group_pb.GroupDeviceVolume(
                        volume: 32768,
                        volumeSteps: 24,
                      ),
                    ),
                    group_pb.GroupDevice(
                      identifiers: group_pb.GroupDeviceIdentifiers(
                        groupDeviceIdentifier: 'dup-member',
                        localIdentifier: 'm-2',
                      ),
                      name: 'Member Two',
                      type: 'SPEAKER',
                      capabilities: group_pb.GroupDeviceCapabilities(
                        removable: true,
                        removalDissolvesGroup: false,
                      ),
                      groupingStatus: group_pbenum.GroupingStatus.GROUPED,
                      volume: group_pb.GroupDeviceVolume(
                        volume: 32768,
                        volumeSteps: 24,
                      ),
                    ),
                  ],
                  capabilities: group_pb.GroupCapabilities(maxDevices: 4),
                ),
              ),
              _protoDevice(
                id: '',
                localIdentifier: 'shared-id',
                name: 'Cross-Domain Local',
                isActive: false,
                isLocal: true,
              ),
              _protoDevice(
                id: '',
                localIdentifier: 'dup-id',
                name: 'Dup Local',
                isActive: false,
                isLocal: true,
              ),
              _protoDevice(
                id: 'dup-id',
                localIdentifier: 'other-loc',
                name: 'Dup Remote',
                isActive: false,
                isLocal: false,
              ),
              _protoDevice(
                id: '',
                localIdentifier: '',
                name: 'No ID Speaker',
                isActive: false,
                isLocal: true,
              ),
              _protoDevice(
                id: '',
                localIdentifier: '',
                name: 'No ID Speaker',
                isActive: false,
                isLocal: false,
              ),
            ],
          ).writeToBuffer(),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: DevicePickerSheet(
              controller: harness.controller,
              autoRefreshOnOpen: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Cross-Domain Local'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('device_shared-id')), findsOneWidget);

      expect(find.text('Dup Local'), findsOneWidget);
      expect(find.text('Dup Remote'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('device_dup-id')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('device_dup-id#2')), findsOneWidget);

      expect(find.text('No ID Speaker'), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey<String>('device_name_No ID Speaker')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('device_name_No ID Speaker#2')),
        findsOneWidget,
      );

      expect(find.text('Member One'), findsOneWidget);
      expect(find.text('Member Two'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('group_dup-member')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('group_dup-member#2')), findsOneWidget);
    });

    testWidgets(
      'calls ConnectSessionCoordinator.onDevicePickerOpened() on mount and onDevicePickerClosed() on dispose',
      (tester) async {
        final harness = _SheetHarness();
        final coordinators = await tester.runAsync(
          () async => (
            harness.createCoordinator(
              pickerRefreshInterval: const Duration(seconds: 10),
            ),
            harness.createCoordinator(
              pickerRefreshInterval: const Duration(seconds: 10),
            ),
          ),
        );
        expect(coordinators, isNotNull);
        final (coordinator1, coordinator2) = switch (coordinators) {
          final pair? => pair,
          null => throw StateError('Expected test coordinators to be created'),
        };
        addTearDown(() async {
          await tester.runAsync(() async {
            await harness.dispose();
            await coordinator1.dispose();
            await coordinator2.dispose();
          });
        });

        expect(coordinator1.isDevicePickerOpen, isFalse);
        expect(coordinator2.isDevicePickerOpen, isFalse);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: DevicePickerSheet(
                controller: harness.controller,
                sessionCoordinator: coordinator1,
                autoRefreshOnOpen: true,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(coordinator1.isDevicePickerOpen, isTrue);
        expect(coordinator2.isDevicePickerOpen, isFalse);
        expect(
          harness.transport.singleMethods,
          containsAll(<String>[
            'PerformDiscovery',
            'RefreshCluster',
            'WakeSleepingClusterDevices',
          ]),
        );

        // Swap coordinator in didUpdateWidget: closes coordinator1 and opens coordinator2
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: DevicePickerSheet(
                controller: harness.controller,
                sessionCoordinator: coordinator2,
                autoRefreshOnOpen: true,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(coordinator1.isDevicePickerOpen, isFalse);
        expect(coordinator2.isDevicePickerOpen, isTrue);

        // Dispose DevicePickerSheet: calls onDevicePickerClosed() on coordinator2
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        await tester.pump();

        expect(coordinator1.isDevicePickerOpen, isFalse);
        expect(coordinator2.isDevicePickerOpen, isFalse);
      },
    );

    testWidgets(
      'renders Local Audio Output / Peripherals section and invokes AudioRoutePort.openSystemOutputSwitcher()',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final harness = _SheetHarness();
        final audioRoutePort = _FakeAudioRoutePort();
        addTearDown(() async {
          await audioRoutePort.close();
          await harness.dispose();
        });

        harness.transport.stateStreamController.add(
          Uint8List.fromList(
            connect_pb.StateResponse(
              isActive: true,
              isSyncedWithBackend: true,
              devices: [
                _protoDevice(
                  id: 'self-phone',
                  name: 'Pixel 9 Pro',
                  type: 'SMARTPHONE',
                  isSelf: true,
                  isActive: false,
                  isLocal: true,
                ),
                _protoDevice(
                  id: 'remote-spk',
                  name: 'Studio Speaker',
                  type: 'SPEAKER',
                  isSelf: false,
                  isActive: true,
                  isLocal: false,
                ),
              ],
            ).writeToBuffer(),
          ),
        );
        await tester.pump();

        harness.controller.dispatch(
          PeripheralsUpdatedEvent(<LocalAudioPeripheral>[
            LocalAudioPeripheral(
              id: kBuiltInSpeakerPeripheralId,
              name: kBuiltInSpeakerPeripheralId,
              isActive: false,
              isConnected: true,
              connectionType: OutputPeripheralConnectionType.builtInSpeaker,
              category: OutputPeripheralCategory.speaker,
            ),
            LocalAudioPeripheral(
              id: 'bt-xm5',
              name: 'WH-1000XM5',
              isActive: true,
              isConnected: true,
              connectionType: OutputPeripheralConnectionType.bluetooth,
              category: OutputPeripheralCategory.headphones,
            ),
          ]),
        );
        await tester.pump();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: DevicePickerSheet(
                controller: harness.controller,
                audioRoutePort: audioRoutePort,
                autoRefreshOnOpen: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('local_audio_output_section')),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey<String>('peripheral_$kBuiltInSpeakerPeripheralId'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('peripheral_bt-xm5')),
          findsOneWidget,
        );
        expect(find.text('WH-1000XM5'), findsWidgets);

        final switcherBtn = find.byKey(
          const ValueKey<String>('open_system_output_switcher_button'),
        );
        expect(switcherBtn, findsOneWidget);

        await tester.tap(switcherBtn);
        await tester.pumpAndSettle();
        expect(audioRoutePort.openSystemOutputSwitcherCallCount, 1);

        // Tapping an inactive peripheral while a remote device is active pulls playback
        // and opens the system output switcher.
        await tester.tap(
          find.byKey(
            const ValueKey<String>('peripheral_$kBuiltInSpeakerPeripheralId'),
          ),
        );
        await tester.pumpAndSettle();
        expect(harness.transport.singleMethods, contains('Pull'));
        expect(audioRoutePort.openSystemOutputSwitcherCallCount, 2);
      },
    );

    testWidgets(
      'renders Bluetooth & Local Network permission card when permissionStatus.anyMissing is true and wires grant and settings buttons',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final harness = _SheetHarness();
        final envPort = _FakeDeviceEnvironmentPort(
          hasBluetoothConnect: false,
          hasNearbyWifi: false,
        );
        addTearDown(harness.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: DevicePickerSheet(
                controller: harness.controller,
                deviceEnvironmentPort: envPort,
                autoRefreshOnOpen: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(envPort.getDeviceEnvironmentCallCount, 1);
        expect(
          find.byKey(const ValueKey<String>('connect_permissions_card')),
          findsOneWidget,
        );
        expect(
          find.text('Allow Bluetooth and local network access'),
          findsOneWidget,
        );

        // Tapping Settings button invokes openAppSettings()
        await tester.tap(
          find.byKey(
            const ValueKey<String>('open_connect_permission_settings_button'),
          ),
        );
        await tester.pumpAndSettle();
        expect(envPort.openAppSettingsCallCount, 1);

        // Tapping Allow access button invokes requestConnectPermissions()
        envPort.nextGrantedStatus = const ConnectPermissionStatus(
          bluetoothConnect: true,
          nearbyWifi: true,
        );
        harness.transport.singleMethods.clear();

        await tester.tap(
          find.byKey(
            const ValueKey<String>('grant_connect_permissions_button'),
          ),
        );
        await tester.pumpAndSettle();

        expect(envPort.requestConnectPermissionsCallCount, 1);
        expect(
          find.byKey(const ValueKey<String>('connect_permissions_card')),
          findsNothing,
        );
        expect(
          harness.transport.singleMethods,
          containsAll(<String>[
            'RefreshCluster',
            'PerformDiscovery',
            'WakeSleepingClusterDevices',
          ]),
        );
      },
    );

    testWidgets(
      '3-dot device overflow menu dispatches LogoutDeviceRequested, RenameDeviceRequested, and SetPreferredIncarnationRequested',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final harness = _SheetHarness();
        addTearDown(harness.dispose);

        const targetId = 'spk-overflow-1';
        harness.transport.stateStreamController.add(
          Uint8List.fromList(
            connect_pb.StateResponse(
              isActive: false,
              isSyncedWithBackend: true,
              devices: [
                _protoDevice(
                  id: 'self-1',
                  name: 'Pixel 9',
                  type: 'SMARTPHONE',
                  isSelf: true,
                  isActive: true,
                  isLocal: true,
                ),
                _protoDevice(
                  id: targetId,
                  name: 'Living Room Sonos',
                  type: 'SPEAKER',
                  isSelf: false,
                  isActive: false,
                  isLocal: true,
                  supportsLogout: true,
                  supportsRename: true,
                  incarnations: <connect_pb.StateResponse_Incarnation>[
                    connect_pb.StateResponse_Incarnation(
                      loginType: connect_pbenum.LoginType.CONNECT,
                      identifier: 'inc-connect-1',
                      preferred: true,
                      preferredReason: connect_pbenum
                          .ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_DEFAULT,
                      connectStateIdentifier: targetId,
                    ),
                    connect_pb.StateResponse_Incarnation(
                      loginType: connect_pbenum.LoginType.CAST,
                      identifier: 'inc-cast-1',
                      preferred: false,
                      preferredReason: connect_pbenum
                          .ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_DEFAULT,
                      connectStateIdentifier: targetId,
                    ),
                  ],
                ),
              ],
            ).writeToBuffer(),
          ),
        );
        await tester.pump();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(0.6),
                ),
                child: switch (child) {
                  final validChild? => validChild,
                  null => const SizedBox.shrink(),
                },
              );
            },
            home: Scaffold(
              body: DevicePickerSheet(
                controller: harness.controller,
                autoRefreshOnOpen: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final overflowButton = find.byKey(
          const ValueKey<String>('device_menu_$targetId'),
        );
        expect(overflowButton, findsOneWidget);

        // 1. Log out action
        await tester.tap(overflowButton);
        await tester.pumpAndSettle();

        final logoutMenuItem = find.byKey(
          const ValueKey<String>('device_menu_logout_$targetId'),
        );
        expect(logoutMenuItem, findsOneWidget);
        await tester.tap(logoutMenuItem);
        await tester.pumpAndSettle();

        expect(harness.transport.singleMethods, contains('Logout'));
        final logoutPayloads = harness.transport.singlePayloads['Logout'];
        expect(logoutPayloads, isNotNull);
        if (logoutPayloads case final payloads?) {
          final logoutReq = connect_pb.LogoutRequest.fromBuffer(payloads.last);
          expect(logoutReq.connectDeviceIdentifier, targetId);
        }

        // 2. Rename device action via dialog
        await tester.tap(overflowButton);
        await tester.pumpAndSettle();

        final renameMenuItem = find.byKey(
          const ValueKey<String>('device_menu_rename_$targetId'),
        );
        expect(renameMenuItem, findsOneWidget);
        await tester.tap(renameMenuItem);
        await tester.pumpAndSettle();

        final textFieldFinder = find.byKey(
          const ValueKey<String>('rename_device_text_field'),
        );
        final saveButtonFinder = find.byKey(
          const ValueKey<String>('rename_device_save_button'),
        );
        expect(textFieldFinder, findsOneWidget);
        expect(saveButtonFinder, findsOneWidget);

        await tester.enterText(textFieldFinder, 'Studio Reference Monitors');
        await tester.pumpAndSettle();
        await tester.tap(saveButtonFinder);
        await tester.pumpAndSettle();

        expect(harness.transport.singleMethods, contains('Rename'));
        final renamePayloads = harness.transport.singlePayloads['Rename'];
        expect(renamePayloads, isNotNull);
        if (renamePayloads case final payloads?) {
          final renameReq = connect_pb.RenameRequest.fromBuffer(payloads.last);
          expect(renameReq.deviceId, targetId);
          expect(renameReq.newName, 'Studio Reference Monitors');
        }

        // 3. Preferred incarnation selection
        await tester.tap(overflowButton);
        await tester.pumpAndSettle();

        final castIncarnationItem = find.byKey(
          const ValueKey<String>('device_menu_incarnation_${targetId}_CAST'),
        );
        expect(castIncarnationItem, findsOneWidget);
        await tester.tap(castIncarnationItem);
        await tester.pumpAndSettle();

        expect(
          harness.transport.singleMethods,
          contains('SetPreferredIncarnation'),
        );
        final incarnationPayloads =
            harness.transport.singlePayloads['SetPreferredIncarnation'];
        expect(incarnationPayloads, isNotNull);
        if (incarnationPayloads case final payloads?) {
          final incReq =
              connect_pb.SetPreferredIncarnationRequest.fromBuffer(payloads.last);
          expect(incReq.deviceId, targetId);
          expect(incReq.preferredLoginType, connect_pbenum.LoginType.CAST);
        }
      },
    );
  });
}
