// Item 178 MiniPlayer Connect wiring tests (p199p/edi0.java:207,
// p199p/bdi0.java:146, p199p/hjn0.java, p199p/nfc0.java:93-109).

import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/di/injection.dart';
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
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';
import 'package:musify_mu/features/connect/presentation/screens/device_picker_sheet.dart';
import 'package:musify_mu/features/connect/presentation/widgets/active_device_banner.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_list_tile.dart';
import 'package:musify_mu/features/player/application/scroll/now_playing_scroll_bloc.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:musify_mu/features/player/presentation/screens/player_screen.dart';
import 'package:musify_mu/features/player/presentation/widgets/mini_player.dart';

final class _MiniPlayerFakeTransport implements EsperantoTransport {
  final StreamController<Uint8List> stateStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> volumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> localVolumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> dodoStreamController =
      StreamController<Uint8List>.broadcast();
  Completer<Uint8List>? transferCompleter;

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    if (method == 'Transfer') {
      if (transferCompleter case final completer?) {
        return completer.future;
      }
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

final class _MiniPlayerConnectHarness {
  _MiniPlayerConnectHarness._({
    required this.transport,
    required this.sortingDb,
    required this.volumeController,
    required this.controller,
  });

  factory _MiniPlayerConnectHarness() {
    final transport = _MiniPlayerFakeTransport();
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
    return _MiniPlayerConnectHarness._(
      transport: transport,
      sortingDb: sortingDb,
      volumeController: volumeController,
      controller: controller,
    );
  }

  final _MiniPlayerFakeTransport transport;
  final DevicePickerSortingDatabase sortingDb;
  final RemoteVolumeController volumeController;
  final ConnectMobiusController controller;

  void emitCluster({
    required bool selfActive,
    String? remoteName,
    bool remoteActive = false,
  }) {
    final devices = <connect_pb.StateResponse_Device>[
      connect_pb.StateResponse_Device(
        isSelf: true,
        isActive: selfActive,
        isLocal: true,
        supportsLogout: false,
        supportsVolume: true,
        connectStateIdentifier: 'self-1',
        localIdentifier: 'local-self-1',
        name: 'My Phone',
        state: 'LOGGED_IN',
        type: 'SMARTPHONE',
        volume: 32768,
        volumeSteps: 24,
        capabilities: '[]',
      ),
      if (remoteName != null)
        connect_pb.StateResponse_Device(
          isSelf: false,
          isActive: remoteActive,
          isLocal: true,
          supportsLogout: true,
          supportsVolume: true,
          connectStateIdentifier: 'remote-1',
          localIdentifier: 'local-remote-1',
          name: remoteName,
          state: 'LOGGED_IN',
          type: 'SPEAKER',
          volume: 32768,
          volumeSteps: 24,
          capabilities: '[]',
        ),
    ];
    final response = connect_pb.StateResponse(
      isActive: false,
      devices: devices,
      isSyncedWithBackend: true,
    );
    transport.stateStreamController.add(
      Uint8List.fromList(response.writeToBuffer()),
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

  setUp(() async {
    await getIt.reset();
    getIt.registerFactory<NowPlayingScrollController>(
      NowPlayingScrollController.new,
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget wrapHost(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 390,
            child: child,
          ),
        ),
      ),
    );
  }

  group('Item 178: MiniPlayer Connect Wiring', () {
    testWidgets(
      'renders cleanly with connectController: null and matches local built-in height',
      (tester) async {
        final harness = _MiniPlayerConnectHarness();
        addTearDown(() => tester.runAsync(harness.dispose));

        await tester.pumpWidget(
          wrapHost(
            const MiniPlayer(
              title: 'Midnight City',
              artist: 'M83',
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(ActiveDeviceBanner), findsNothing);
        expect(
          find.byKey(const ValueKey<String>('mini_player_connect_button')),
          findsOneWidget,
        );
        final baselineHeight = tester.getSize(find.byType(MiniPlayer)).height;

        await tester.pumpWidget(
          wrapHost(
            MiniPlayer(
              title: 'Midnight City',
              artist: 'M83',
              connectController: harness.controller,
            ),
          ),
        );
        harness.emitCluster(selfActive: true);
        await tester.pump();
        await tester.pump();

        expect(find.byType(ActiveDeviceBanner), findsNothing);
        final withLocalBuiltInHeight =
            tester.getSize(find.byType(MiniPlayer)).height;
        expect(withLocalBuiltInHeight, equals(baselineHeight));
      },
    );

    testWidgets(
      'shows compact ActiveDeviceBanner for remote active device without overflow',
      (tester) async {
        final harness = _MiniPlayerConnectHarness();
        addTearDown(() => tester.runAsync(harness.dispose));

        await tester.pumpWidget(
          wrapHost(
            MiniPlayer(
              title: 'Midnight City',
              artist: 'M83',
              connectController: harness.controller,
            ),
          ),
        );

        harness.emitCluster(
          selfActive: false,
          remoteName: 'Living Room Speaker',
          remoteActive: true,
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(ActiveDeviceBanner), findsOneWidget);
        expect(find.text('Listening on Living Room Speaker'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'shows compact ActiveDeviceBanner for external local peripheral and TransferInProgress',
      (tester) async {
        final harness = _MiniPlayerConnectHarness();
        addTearDown(() => tester.runAsync(harness.dispose));

        await tester.pumpWidget(
          wrapHost(
            MiniPlayer(
              title: 'Midnight City',
              artist: 'M83',
              connectController: harness.controller,
            ),
          ),
        );

        harness.emitCluster(selfActive: true);
        harness.controller.dispatch(
          PeripheralsUpdatedEvent(<LocalAudioPeripheral>[
            LocalAudioPeripheral(
              id: 'bt-1',
              name: 'WH-1000XM5',
              isActive: true,
              connectionType: OutputPeripheralConnectionType.bluetooth,
              isConnected: true,
            ),
          ]),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(ActiveDeviceBanner), findsOneWidget);
        expect(find.text('Listening on WH-1000XM5'), findsOneWidget);

        // Emit TransferInProgress via pending transfer.
        harness.emitCluster(
          selfActive: true,
          remoteName: 'Kitchen Speaker',
          remoteActive: false,
        );
        harness.transport.transferCompleter = Completer<Uint8List>();
        harness.controller.dispatch(
          TransferToDeviceRequested(deviceIdentifier: 'remote-1'),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(ActiveDeviceBanner), findsOneWidget);
        expect(find.text('Connecting to Kitchen Speaker...'), findsOneWidget);

        harness.transport.transferCompleter?.complete(
          Uint8List.fromList(
            common_pb.StatusResponse(
              status: common_pbenum.Status.OK,
            ).writeToBuffer(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(harness.controller.currentState.transferState, isA<TransferSucceeded>());
      },
    );

    testWidgets(
      'tapping compact ActiveDeviceBanner opens DevicePickerSheet modal',
      (tester) async {
        final harness = _MiniPlayerConnectHarness();
        addTearDown(() => tester.runAsync(harness.dispose));

        await tester.pumpWidget(
          wrapHost(
            MiniPlayer(
              title: 'Midnight City',
              artist: 'M83',
              connectController: harness.controller,
            ),
          ),
        );

        harness.emitCluster(
          selfActive: false,
          remoteName: 'Living Room Speaker',
          remoteActive: true,
        );
        await tester.pump();
        await tester.pump();

        await tester.tap(find.byType(ActiveDeviceBanner));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DevicePickerSheet), findsOneWidget);
      },
    );

    testWidgets(
      'tapping MiniPlayer opens PlayerScreen with forwarded connectController',
      (tester) async {
        final harness = _MiniPlayerConnectHarness();
        addTearDown(() => tester.runAsync(harness.dispose));

        await tester.pumpWidget(
          wrapHost(
            MiniPlayer(
              title: 'Midnight City',
              artist: 'M83',
              connectController: harness.controller,
            ),
          ),
        );

        harness.emitCluster(
          selfActive: false,
          remoteName: 'Studio Monitor',
          remoteActive: true,
        );
        await tester.pump();
        await tester.pump();

        await tester.tap(find.text('Midnight City'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(PlayerScreen), findsOneWidget);
        final screen = tester.widget<PlayerScreen>(find.byType(PlayerScreen));
        expect(identical(screen.connectController, harness.controller), isTrue);
        expect(
          find.descendant(
            of: find.byType(PlayerScreen),
            matching: find.text('Listening on Studio Monitor'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'always-visible mini_player_connect_button opens DevicePickerSheet and highlights in kSpotifyConnectGreen with mini_player_active_output_indicator when ConnectOutputStatusPolicy.isConnectOutputActive(state) is true',
      (tester) async {
        final harness = _MiniPlayerConnectHarness();
        addTearDown(() => tester.runAsync(harness.dispose));

        await tester.pumpWidget(
          wrapHost(
            MiniPlayer(
              title: 'Midnight City',
              artist: 'M83',
              connectController: harness.controller,
            ),
          ),
        );

        // Local built-in speaker active -> isConnectOutputActive is false
        harness.emitCluster(selfActive: true);
        await tester.pump();
        await tester.pump();

        expect(
          ConnectOutputStatusPolicy.instance.isConnectOutputActive(
            harness.controller.currentState,
          ),
          isFalse,
        );

        final connectButtonFinder = find.byKey(
          const ValueKey<String>('mini_player_connect_button'),
        );
        final activeIndicatorFinder = find.byKey(
          const ValueKey<String>('mini_player_active_output_indicator'),
        );

        expect(connectButtonFinder, findsOneWidget);
        expect(activeIndicatorFinder, findsNothing);

        final inactiveButton = tester.widget<IconButton>(connectButtonFinder);
        final inactiveIcon = inactiveButton.icon as Icon;
        expect(inactiveIcon.color, isNot(equals(kSpotifyConnectGreen)));

        // Tapping always-visible Connect button opens DevicePickerSheet even when local built-in is active
        await tester.tap(connectButtonFinder);
        await tester.pumpAndSettle();
        expect(find.byType(DevicePickerSheet), findsOneWidget);

        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        expect(find.byType(DevicePickerSheet), findsNothing);

        // Remote Connect device active -> isConnectOutputActive is true
        harness.emitCluster(
          selfActive: false,
          remoteName: 'Studio Speaker',
          remoteActive: true,
        );
        await tester.pump();
        await tester.pump();

        expect(
          ConnectOutputStatusPolicy.instance.isConnectOutputActive(
            harness.controller.currentState,
          ),
          isTrue,
        );

        expect(connectButtonFinder, findsOneWidget);
        expect(activeIndicatorFinder, findsOneWidget);

        final activeButton = tester.widget<IconButton>(connectButtonFinder);
        final activeIcon = activeButton.icon as Icon;
        expect(activeIcon.color, equals(kSpotifyConnectGreen));

        final indicatorIcon = tester.widget<Icon>(activeIndicatorFinder);
        expect(indicatorIcon.color, equals(kSpotifyConnectGreen));

        final artistText = tester.widget<Text>(find.text('M83'));
        expect(artistText.style?.color, equals(kSpotifyConnectGreen));

        // Tapping highlighted Connect button opens DevicePickerSheet
        await tester.tap(connectButtonFinder);
        await tester.pumpAndSettle();
        expect(find.byType(DevicePickerSheet), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(DevicePickerSheet),
            matching: find.text('Listening on Studio Speaker'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
