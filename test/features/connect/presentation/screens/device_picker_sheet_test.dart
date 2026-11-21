// 1:1 Spotify 9.1.92.3058 DevicePickerSheet widget & interaction test suite
// (`lxs.java`, `r3h0.java`, `ohb1.java`, `frl1.java`, `btl1.java`, `ka0.java`,
// `ltl1.java`, `ekp0.java`, `f4a.java`, `qk20.java`, `cup.java`, `c8r.java`).

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
import 'package:musify_mu/features/connect/data/proto/group.pb.dart'
    as group_pb;
import 'package:musify_mu/features/connect/data/proto/group.pbenum.dart'
    as group_pbenum;
import 'package:musify_mu/features/connect/domain/interfaces/audio_route_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/device_environment_port.dart';
import 'package:musify_mu/features/connect/presentation/screens/device_picker_sheet.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_volume_slider.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_context_menu_sheet.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_picker_active_card.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_picker_footer.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_picker_row.dart';
import 'package:musify_mu/features/connect/presentation/widgets/grouped_devices_section.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:musify_mu/features/player/domain/models/bitrate_level.dart';
import 'package:musify_mu/features/player/domain/models/hifi_status.dart';
import 'package:musify_mu/features/player/domain/models/playback_quality.dart';

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
  final Map<String, List<Uint8List>> singlePayloads =
      <String, List<Uint8List>>{};

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    singleMethods.add(method);
    singlePayloads.putIfAbsent(method, () => <Uint8List>[]).add(payload);
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
    this.nextGrantedStatus,
  });

  bool hasBluetoothConnect;
  bool hasNearbyWifi;
  ConnectPermissionStatus? nextGrantedStatus;
  int requestCount = 0;
  int openSettingsCount = 0;

  @override
  Future<DeviceEnvironmentInfo> getDeviceEnvironment() async {
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
    requestCount += 1;
    if (nextGrantedStatus case final granted?) {
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
    openSettingsCount += 1;
    return true;
  }
}

final class _FakeAudioRoutePort implements AudioRoutePort {
  final StreamController<List<LocalAudioPeripheral>> _controller =
      StreamController<List<LocalAudioPeripheral>>.broadcast();
  List<LocalAudioPeripheral> currentPeripherals = const [];
  int openSwitcherCount = 0;

  @override
  Future<List<LocalAudioPeripheral>> getPeripherals() async =>
      currentPeripherals;

  @override
  Stream<List<LocalAudioPeripheral>> watchPeripherals() => _controller.stream;

  @override
  Future<bool> openSystemOutputSwitcher() async {
    openSwitcherCount += 1;
    return true;
  }

  Future<void> close() => _controller.close();
}

final class _SheetHarness {
  _SheetHarness._({
    required this.transport,
    required this.sortingDb,
    required this.volumeController,
    required this.controller,
  });

  factory _SheetHarness({AudioRoutePort? audioRoutePort}) {
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
      audioRoutePort: audioRoutePort,
      commandIdGenerator: () => '11112222333344445555666677778888',
    )..start();
    return _SheetHarness._(
      transport: transport,
      sortingDb: sortingDb,
      volumeController: volumeController,
      controller: controller,
    );
  }

  final _SheetFakeTransport transport;
  final DevicePickerSortingDatabase sortingDb;
  final RemoteVolumeController volumeController;
  final ConnectMobiusController controller;

  void emitDevices(List<connect_pb.StateResponse_Device> devices) {
    transport.stateStreamController.add(
      Uint8List.fromList(
        connect_pb.StateResponse(
          isActive: devices.any((d) => d.isActive),
          isSyncedWithBackend: true,
          devices: devices,
        ).writeToBuffer(),
      ),
    );
  }

  Future<void> dispose() async {
    await controller.close();
    await volumeController.dispose();
    await sortingDb.close();
    await transport.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Spotify 9.1.92.3058 DevicePickerSheet', () {
    testWidgets(
      'renders exact Connect header, This phone active card, Normal quality pill, empty state, and Find Bluetooth devices footer',
      (tester) async {
        final routePort = _FakeAudioRoutePort();
        final harness = _SheetHarness(audioRoutePort: routePort);
        addTearDown(() async {
          await tester.runAsync(() async {
            await harness.dispose();
            await routePort.close();
          });
        });

        harness.emitDevices([
          connect_pb.StateResponse_Device(
            isSelf: true,
            isActive: true,
            isLocal: true,
            connectStateIdentifier: 'self-1',
            localIdentifier: 'local-self-1',
            name: 'Pixel 4 XL',
            state: 'LOGGED_IN',
            type: 'SMARTPHONE',
            volume: 32768,
            volumeSteps: 24,
            capabilities: '[]',
          ),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: DevicePickerSheet(
                controller: harness.controller,
                audioRoutePort: routePort,
                playbackQuality: const PlaybackQuality(
                  bitrateLevel: BitrateLevel.normal,
                  hifiStatus: HiFiStatus.none,
                ),
                autoRefreshOnOpen: false,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Connect'), findsOneWidget);
        expect(find.byType(DevicePickerActiveCard), findsOneWidget);
        expect(find.text('This phone'), findsOneWidget);
        expect(find.text('Normal'), findsOneWidget);
        expect(find.text('No devices found on this network'), findsOneWidget);
        expect(find.byType(DevicePickerFooter), findsOneWidget);
        expect(find.text('Find Bluetooth devices'), findsOneWidget);
        // Jam card hidden when onStartJam == null
        expect(find.text('Start a Jam'), findsNothing);

        // Tap Find Bluetooth devices -> calls AudioRoutePort.openSystemOutputSwitcher
        await tester.tap(
          find.byKey(const ValueKey<String>('footer_bluetooth_card')),
        );
        await tester.pump();
        expect(routePort.openSwitcherCount, equals(1));
      },
    );

    testWidgets(
      'renders elbow-connector peripheral subtitle, Bluetooth footer active state, and Lossless pill',
      (tester) async {
        final routePort = _FakeAudioRoutePort()
          ..currentPeripherals = <LocalAudioPeripheral>[
            LocalAudioPeripheral(
              id: 'bt-xm5',
              name: 'WH-1000XM5',
              isActive: true,
              connectionType: OutputPeripheralConnectionType.bluetooth,
              category: OutputPeripheralCategory.headphones,
              isConnected: true,
            ),
          ];
        final harness = _SheetHarness(audioRoutePort: routePort);
        addTearDown(() async {
          await tester.runAsync(() async {
            await harness.dispose();
            await routePort.close();
          });
        });

        harness.emitDevices([
          connect_pb.StateResponse_Device(
            isSelf: true,
            isActive: true,
            isLocal: true,
            connectStateIdentifier: 'self-1',
            localIdentifier: 'local-self-1',
            name: 'Pixel 4 XL',
            state: 'LOGGED_IN',
            type: 'SMARTPHONE',
            volume: 32768,
            volumeSteps: 24,
            capabilities: '[]',
          ),
        ]);
        harness.controller.dispatch(
          PeripheralsUpdatedEvent(<LocalAudioPeripheral>[
            LocalAudioPeripheral(
              id: 'bt-xm5',
              name: 'WH-1000XM5',
              isActive: true,
              connectionType: OutputPeripheralConnectionType.bluetooth,
              category: OutputPeripheralCategory.headphones,
              isConnected: true,
            ),
          ]),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: DevicePickerSheet(
                controller: harness.controller,
                audioRoutePort: routePort,
                playbackQuality: const PlaybackQuality(
                  bitrateLevel: BitrateLevel.hifi,
                  hifiStatus: HiFiStatus.on,
                ),
                autoRefreshOnOpen: false,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byKey(const ValueKey<String>('elbow_connector')), findsOneWidget);
        expect(find.text('WH-1000XM5'), findsOneWidget);
        expect(find.text('Lossless'), findsOneWidget);
        // Active Bluetooth switches label to "Bluetooth" in #1ED760 (`f4a.java:199-203`)
        expect(find.text('Bluetooth'), findsOneWidget);
        expect(find.text('Find Bluetooth devices'), findsNothing);
      },
    );

    testWidgets(
      'splits on-network and On other networks rows, opens context menu sheet for rename & forget',
      (tester) async {
        final harness = _SheetHarness();
        addTearDown(() => tester.runAsync(harness.dispose));

        harness.emitDevices([
          connect_pb.StateResponse_Device(
            isSelf: true,
            isActive: true,
            isLocal: true,
            connectStateIdentifier: 'self-1',
            localIdentifier: 'local-self-1',
            name: 'My Phone',
            state: 'LOGGED_IN',
            type: 'SMARTPHONE',
            volume: 32768,
            volumeSteps: 24,
            capabilities: '[]',
          ),
          connect_pb.StateResponse_Device(
            isSelf: false,
            isActive: false,
            isLocal: true,
            supportsRename: true,
            supportsLogout: true,
            connectStateIdentifier: 'local-spk',
            localIdentifier: 'loc-spk',
            name: 'Living Room Sonos',
            brandDisplayName: 'Sonos',
            state: 'LOGGED_IN',
            type: 'SPEAKER',
            volume: 32768,
            volumeSteps: 24,
            capabilities: '[]',
          ),
          connect_pb.StateResponse_Device(
            isSelf: false,
            isActive: false,
            isLocal: false,
            supportsLogout: true,
            connectStateIdentifier: 'remote-pc',
            localIdentifier: 'loc-pc',
            name: 'Office MacBook',
            state: 'LOGGED_IN',
            type: 'COMPUTER',
            volume: 32768,
            volumeSteps: 24,
            capabilities: '[]',
          ),
        ]);

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
        await tester.pump();
        await tester.pump();

        expect(find.byType(DevicePickerRow), findsNWidgets(2));
        expect(find.text('Living Room Sonos'), findsOneWidget);
        expect(find.text('On other networks'), findsOneWidget);
        expect(find.text('Office MacBook'), findsOneWidget);

        // Tap on-network row -> dispatches Transfer RPC
        await tester.tap(find.text('Living Room Sonos'));
        await tester.pump();
        expect(harness.transport.singleMethods, contains('Transfer'));

        // Open context menu via trailing `...` button -> tap Forget device -> Logout RPC
        await tester.tap(
          find.byKey(const ValueKey<String>('row_context_menu_connect_local-spk')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(DeviceContextMenuSheet), findsOneWidget);
        expect(find.text('Rename device'), findsOneWidget);
        expect(find.text('Forget device'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey<String>('context_action_logout')));
        await tester.pumpAndSettle();
        expect(harness.transport.singleMethods, contains('Logout'));
      },
    );

    testWidgets(
      'renders active remote device with ConnectVolumeSlider and expandable GroupedDevicesSection',
      (tester) async {
        final harness = _SheetHarness();
        addTearDown(() => tester.runAsync(harness.dispose));

        harness.emitDevices([
          connect_pb.StateResponse_Device(
            isSelf: false,
            isActive: true,
            isLocal: false,
            isGroup: true,
            supportsVolume: true,
            connectStateIdentifier: 'grp-1',
            localIdentifier: 'local-grp-1',
            name: 'Downstairs Group',
            state: 'LOGGED_IN',
            type: 'SPEAKER',
            volume: 40000,
            volumeSteps: 24,
            capabilities: '[]',
            groupData: group_pb.GroupData(
              capabilities: group_pb.GroupCapabilities(maxDevices: 6),
              devices: [
                group_pb.GroupDevice(
                  identifiers: group_pb.GroupDeviceIdentifiers(
                    groupDeviceIdentifier: 'mem-1',
                  ),
                  name: 'Kitchen Speaker',
                  type: 'SPEAKER',
                  modelDisplayName: 'Sonos One',
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
            ),
          ),
        ]);

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
        await tester.pump();
        await tester.pump();

        expect(find.text('Downstairs Group'), findsOneWidget);
        expect(find.byType(ConnectVolumeSlider), findsOneWidget);
        expect(find.byType(GroupedDevicesSection), findsOneWidget);
        expect(find.text('Kitchen Speaker'), findsOneWidget);

        // Collapse grouped speakers section
        await tester.tap(
          find.byKey(const ValueKey<String>('toggle_grouped_devices_button')),
        );
        await tester.pump();
        expect(find.byType(GroupedDevicesSection), findsNothing);
      },
    );

    testWidgets(
      'displays missing permissions prompt card and requests permissions via DeviceEnvironmentPort',
      (tester) async {
        final envPort = _FakeDeviceEnvironmentPort(
          hasBluetoothConnect: false,
          hasNearbyWifi: false,
          nextGrantedStatus: const ConnectPermissionStatus(
            bluetoothConnect: true,
            nearbyWifi: true,
          ),
        );
        final harness = _SheetHarness();
        addTearDown(() => tester.runAsync(harness.dispose));

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
        await tester.pump();
        await tester.pump();

        expect(
          find.byKey(const ValueKey<String>('connect_permissions_card')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('grant_connect_permissions_button')),
        );
        await tester.pump();
        await tester.pump();

        expect(envPort.requestCount, equals(1));
        expect(
          find.byKey(const ValueKey<String>('connect_permissions_card')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'DevicePickerSheet.show opens cleanly in standard (844dp) and compact (<600dp) viewports',
      (tester) async {
        final harness = _SheetHarness();
        addTearDown(() => tester.runAsync(harness.dispose));

        for (final size in const <Size>[Size(390, 844), Size(390, 520)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark,
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => TextButton(
                    onPressed: () => DevicePickerSheet.show(
                      ctx,
                      controller: harness.controller,
                      autoRefreshOnOpen: false,
                    ),
                    child: const Text('Open Picker'),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('Open Picker'));
          await tester.pumpAndSettle();

          expect(find.byType(DevicePickerSheet), findsOneWidget);
          expect(find.text('Connect'), findsOneWidget);
          expect(tester.takeException(), isNull);

          Navigator.of(
            tester.element(find.byType(DevicePickerSheet)),
          ).pop();
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
