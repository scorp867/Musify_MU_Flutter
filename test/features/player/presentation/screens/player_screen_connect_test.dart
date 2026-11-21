// PlayerScreen Connect entrypoint & DevicePickerSheet wiring tests
// (`p199p/qsq.java`, `p199p/nhr.java`, `p199p/ac0.java`).

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
import 'package:musify_mu/features/connect/presentation/screens/device_picker_sheet.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_entrypoint_button.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_state_icon.dart';
import 'package:musify_mu/features/player/application/scroll/now_playing_scroll_bloc.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:musify_mu/features/player/presentation/screens/player_screen.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_utility_row.dart';

final class _PlayerScreenFakeTransport implements EsperantoTransport {
  final StreamController<Uint8List> stateStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> volumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> localVolumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> dodoStreamController =
      StreamController<Uint8List>.broadcast();

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
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

final class _PlayerScreenConnectHarness {
  _PlayerScreenConnectHarness._({
    required this.transport,
    required this.sortingDb,
    required this.volumeController,
    required this.controller,
  });

  factory _PlayerScreenConnectHarness() {
    final transport = _PlayerScreenFakeTransport();
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
    )..start();
    return _PlayerScreenConnectHarness._(
      transport: transport,
      sortingDb: sortingDb,
      volumeController: volumeController,
      controller: controller,
    );
  }

  final _PlayerScreenFakeTransport transport;
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

  Future<void> setViewportSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('PlayerScreen Spotify Connect Entrypoint Wiring', () {
    testWidgets(
      'connectController: null renders cleanly and Devices tap is a safe no-op',
      (tester) async {
        await setViewportSize(tester, const Size(390, 844));

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: const PlayerScreen(
              title: 'Starboy',
              artist: 'The Weeknd',
              album: 'Starboy',
              duration: Duration(minutes: 3, seconds: 50),
            ),
          ),
        );
        await tester.pump();

        final devicesButton = find.byTooltip('Devices');
        expect(devicesButton, findsOneWidget);

        await tester.tap(devicesButton);
        await tester.pump();

        expect(find.byType(DevicePickerSheet), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders Spotify qsq inline ConnectEntrypointButton label & active icon without overflow at 390x640 and 800x600',
      (tester) async {
        final harness = _PlayerScreenConnectHarness();
        addTearDown(() => tester.runAsync(harness.dispose));

        for (final size in const <Size>[Size(390, 640), Size(800, 600)]) {
          await setViewportSize(tester, size);

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark,
              home: PlayerScreen(
                title: 'Starboy',
                artist: 'The Weeknd',
                album: 'Starboy',
                duration: const Duration(minutes: 3, seconds: 50),
                connectController: harness.controller,
              ),
            ),
          );

          // Local built-in speaker active -> ConnectIconIdle, no inline label.
          harness.emitCluster(selfActive: true);
          await tester.pump();
          await tester.pump();

          final idleIcon = tester.widget<ConnectStateIcon>(
            find.descendant(
              of: find.byType(PlayerUtilityRow),
              matching: find.byType(ConnectStateIcon),
            ),
          );
          expect(idleIcon.iconState, isA<ConnectIconIdle>());
          expect(find.text('Studio Monitor'), findsNothing);

          // Remote speaker active -> ConnectIconActive (#1ED760) + inline label.
          harness.emitCluster(
            selfActive: false,
            remoteName: 'Studio Monitor',
            remoteActive: true,
          );
          await tester.pump();
          await tester.pump();

          final activeIcon = tester.widget<ConnectStateIcon>(
            find.descendant(
              of: find.byType(PlayerUtilityRow),
              matching: find.byType(ConnectStateIcon),
            ),
          );
          expect(activeIcon.iconState, isA<ConnectIconActive>());
          expect(activeIcon.activeColor, equals(kSpotifyConnectGreen));
          expect(find.text('Studio Monitor'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'tapping ConnectEntrypointButton in PlayerScreen opens DevicePickerSheet',
      (tester) async {
        final harness = _PlayerScreenConnectHarness();
        addTearDown(() => tester.runAsync(harness.dispose));
        await setViewportSize(tester, const Size(390, 844));

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: PlayerScreen(
              title: 'Starboy',
              artist: 'The Weeknd',
              album: 'Starboy',
              duration: const Duration(minutes: 3, seconds: 50),
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

        await tester.tap(find.byType(ConnectEntrypointButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(DevicePickerSheet), findsOneWidget);
        expect(find.text('Connect'), findsOneWidget);
      },
    );

    testWidgets(
      'PlayerScreen.show forwards connectController to pushed PlayerScreen',
      (tester) async {
        final harness = _PlayerScreenConnectHarness();
        addTearDown(() => tester.runAsync(harness.dispose));
        await setViewportSize(tester, const Size(390, 844));

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    PlayerScreen.show(
                      ctx,
                      title: 'Starboy',
                      artist: 'The Weeknd',
                      connectController: harness.controller,
                    );
                  },
                  child: const Text('Open Player'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Player'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(PlayerScreen), findsOneWidget);
        final pushed = tester.widget<PlayerScreen>(find.byType(PlayerScreen));
        expect(identical(pushed.connectController, harness.controller), isTrue);
      },
    );
  });
}
