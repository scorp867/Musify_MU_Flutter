// 1:1 Spotify `now_playing_bar` MiniPlayer & Connect wiring widget tests.

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
import 'package:musify_mu/features/connect/presentation/icons/connect_encore_icons.dart';
import 'package:musify_mu/features/connect/presentation/screens/device_picker_sheet.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_state_icon.dart';
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
    )..start();
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

  Widget wrapHost(
    Widget child, {
    double textScale = 1.0,
    double width = 390,
  }) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 844),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: width,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  group('Spotify now_playing_bar MiniPlayer 1:1 Fidelity & Connect Wiring', () {
    testWidgets(
      'matches exact 56dp default_size, 68dp scaled_font_height (>=1.5x), and 96dp large_size heights',
      (tester) async {
        // 1. Default 56dp
        await tester.pumpWidget(
          wrapHost(
            const MiniPlayer(
              title: 'Midnight City',
              artist: 'M83',
            ),
          ),
        );
        await tester.pump();

        final surfaceFinder = find.byKey(
          const ValueKey<String>('now_playing_bar_surface'),
        );
        expect(
          tester.getSize(surfaceFinder).height,
          equals(ConnectEncoreTheme.miniPlayerDefaultHeight),
        );
        expect(
          find.byKey(const ValueKey<String>('mini_player_two_line_local_mode')),
          findsOneWidget,
        );

        // 2. Scaled font >= 1.5x -> 68dp
        await tester.pumpWidget(
          wrapHost(
            const MiniPlayer(
              title: 'Midnight City',
              artist: 'M83',
            ),
            textScale: 1.6,
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          tester.getSize(surfaceFinder).height,
          equals(ConnectEncoreTheme.miniPlayerScaledFontHeight),
        );

        // 3. Explicit large_size -> 96dp + outline halo + bottom-sheet mode
        await tester.pumpWidget(
          wrapHost(
            const MiniPlayer(
              title: 'Midnight City',
              artist: 'M83',
              visualConfig: MiniPlayerVisualConfig(
                sizeMode: MiniPlayerSizeMode.largeSize,
                bottomSheetMode: true,
                showOutlineHalo: true,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          tester.getSize(surfaceFinder).height,
          equals(ConnectEncoreTheme.miniPlayerLargeHeight),
        );
        final halo = tester.widget<AnimatedOpacity>(
          find.byKey(const ValueKey<String>('mini_player_outline_halo')),
        );
        expect(halo.opacity, equals(1.0));
      },
    );

    testWidgets(
      'switches smoothly between 2-line local mode and 1-line Connect mode with constant 56dp height',
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

        final surfaceFinder = find.byKey(
          const ValueKey<String>('now_playing_bar_surface'),
        );

        // Local built-in speaker active -> 2-line mode, idle Connect icon.
        harness.emitCluster(selfActive: true);
        await tester.pump();
        await tester.pump();

        expect(
          find.byKey(const ValueKey<String>('mini_player_two_line_local_mode')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('mini_player_connect_label')),
          findsNothing,
        );
        final localHeight = tester.getSize(surfaceFinder).height;
        expect(localHeight, equals(56.0));

        // Remote speaker active -> 1-line "Title • Artist" + overlaid green ConnectDeviceLabel (still 56dp!).
        harness.emitCluster(
          selfActive: false,
          remoteName: 'Living Room Speaker',
          remoteActive: true,
        );
        await tester.pump();
        await tester.pump();

        expect(
          find.byKey(
            const ValueKey<String>('mini_player_single_line_connect_mode'),
          ),
          findsOneWidget,
        );
        expect(find.text('Living Room Speaker'), findsOneWidget);
        expect(tester.getSize(surfaceFinder).height, equals(56.0));
        final activeIcon = tester.widget<ConnectStateIcon>(
          find.descendant(
            of: find.byKey(const ValueKey<String>('mini_player_connect_button')),
            matching: find.byType(ConnectStateIcon),
          ),
        );
        expect(activeIcon.iconState, isA<ConnectIconActive>());
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'shows Bluetooth peripheral label and white pulsing Connecting... during TransferInProgress',
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

        expect(find.text('WH-1000XM5'), findsOneWidget);

        // Initiate transfer -> Connecting...
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

        expect(find.text('Connecting...'), findsOneWidget);
        final connectingIcon = tester.widget<ConnectStateIcon>(
          find.descendant(
            of: find.byKey(const ValueKey<String>('mini_player_connect_button')),
            matching: find.byType(ConnectStateIcon),
          ),
        );
        expect(connectingIcon.iconState, isA<ConnectIconConnecting>());

        harness.transport.transferCompleter?.complete(
          Uint8List.fromList(
            common_pb.StatusResponse(
              status: common_pbenum.Status.OK,
            ).writeToBuffer(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(
          harness.controller.currentState.transferState,
          isA<TransferSucceeded>(),
        );
      },
    );

    testWidgets(
      'renders conditional badges, promo disclosure, video slot, skippable ad, Encore AddTo & PlayPause',
      (tester) async {
        var skippedAd = false;
        var played = false;
        var nextTapped = false;

        await tester.pumpWidget(
          wrapHost(
            MiniPlayer(
              title: 'Episode 1',
              artist: 'Podcast Host',
              isPlaying: false,
              mediaSlot: MiniPlayerVideoSlot(
                videoBuilder: (_) => const SizedBox(
                  key: ValueKey<String>('fake_video_frame'),
                ),
              ),
              badges: const MiniPlayerTrackBadges(
                isQueued: true,
                isEnhanced: true,
                playbackSpeedLabel: '1.5x',
                listenAlongLabel: 'Jam',
              ),
              adConfig: MiniPlayerAdConfig(
                canSkip: true,
                onSkip: () => skippedAd = true,
              ),
              onPlayPause: () => played = true,
              onNext: () => nextTapped = true,
            ),
          ),
        );
        await tester.pump();

        expect(find.byKey(const ValueKey<String>('mini_player_video_surface')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('mini_player_queued_badge')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('mini_player_enhanced_badge')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('mini_player_speed_badge')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('mini_player_listen_along_badge')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('mini_player_skippable_ad_button')), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey<String>('mini_player_skippable_ad_button')));
        await tester.pump();
        expect(skippedAd, isTrue);

        // Tap Play/Pause button
        await tester.tap(find.byKey(const ValueKey<String>('mini_player_play_pause_button')));
        await tester.pump();
        expect(played, isTrue);

        // Horizontal swipe left -> skips next
        await tester.fling(
          find.byKey(const ValueKey<String>('now_playing_bar_surface')),
          const Offset(-140, 0),
          600,
        );
        await tester.pump();
        expect(nextTapped, isTrue);

        // Non-ad mode exposes Encore Add-To button (+ -> checkAltFill in #1ED760)
        await tester.pumpWidget(
          wrapHost(
            const MiniPlayer(
              title: 'Episode 1',
              artist: 'Podcast Host',
              promoConfig: MiniPlayerPromoConfig(),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Includes promotional content'), findsOneWidget);

        final addToFinder = find.byKey(const ValueKey<String>('mini_player_add_to_button'));
        expect(
          tester.widget<ConnectEncoreIcon>(
            find.descendant(of: addToFinder, matching: find.byType(ConnectEncoreIcon)),
          ).icon,
          equals(ConnectEncoreIcons.plusAlt24),
        );
        await tester.tap(addToFinder);
        await tester.pump();
        final savedIcon = tester.widget<ConnectEncoreIcon>(
          find.descendant(of: addToFinder, matching: find.byType(ConnectEncoreIcon)),
        );
        expect(savedIcon.icon, equals(ConnectEncoreIcons.checkAltFill24));
        expect(savedIcon.color, equals(ConnectEncoreTheme.brightAccent));
      },
    );

    testWidgets(
      'tapping Connect button opens DevicePickerSheet and tapping bar opens PlayerScreen with forwarded controller',
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

        // 1. Connect button -> DevicePickerSheet
        await tester.tap(
          find.byKey(const ValueKey<String>('mini_player_connect_button')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(DevicePickerSheet), findsOneWidget);
        expect(find.text('Connect'), findsOneWidget);

        Navigator.of(
          tester.element(find.byType(DevicePickerSheet)),
        ).pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(DevicePickerSheet), findsNothing);

        // 2. Tap track info -> opens PlayerScreen with forwarded controller
        await tester.tap(
          find.byKey(const ValueKey<String>('mini_player_single_line_title_artist')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(PlayerScreen), findsOneWidget);
        final screen = tester.widget<PlayerScreen>(find.byType(PlayerScreen));
        expect(identical(screen.connectController, harness.controller), isTrue);
      },
    );
  });
}
