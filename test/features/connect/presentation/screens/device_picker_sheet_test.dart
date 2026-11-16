import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/theme/app_theme.dart';
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
  Future<Uint8List> Function(String service, String method, Uint8List payload)?
      onCallSingle;

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    singleMethods.add(method);
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
  int volume = 32768,
  int volumeSteps = 24,
  group_pb.GroupData? groupData,
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
    connectStateIdentifier: id,
    localIdentifier: resolvedLocalId,
    name: name,
    state: state,
    type: type,
    volume: volume,
    volumeSteps: volumeSteps,
    capabilities: '[]',
    groupData: groupData,
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
  });
}
