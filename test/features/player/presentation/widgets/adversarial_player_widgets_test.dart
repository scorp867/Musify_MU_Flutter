import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:musify_mu/features/connect/presentation/widgets/connect_state_icon.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:musify_mu/features/player/domain/models/now_playing_view_model.dart';
import 'package:musify_mu/features/player/presentation/widgets/queue_controls_layout.dart';

// Barrel exports under test
import 'package:musify_mu/features/player/presentation/widgets/player_controls.dart'
    as controls_barrel;
import 'package:musify_mu/features/player/presentation/widgets/player_sheets.dart'
    as sheets_barrel;

// Isolated widget modules under test
import 'package:musify_mu/features/player/presentation/widgets/player_seek_bar.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_playback_controls.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_utility_row.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_secondary_controls.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_options_sheet.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_track_details_sheet.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_sheet_header.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_sheet_detail_row.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildBoilerplate(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            child: child,
          ),
        ),
      ),
    );
  }

  group('Requirement R2: Barrel Export Completeness & Fidelity', () {
    testWidgets('player_controls.dart barrel exports all 4 controls widgets', (tester) async {
      await tester.pumpWidget(
        buildBoilerplate(
          Column(
            children: [
              controls_barrel.PlayerSeekBar(
                onDragPositionChanged: (_) {},
              ),
              const controls_barrel.PlayerPlaybackControls(),
              controls_barrel.PlayerUtilityRow(
                onQueue: () {},
              ),
              controls_barrel.PlayerSecondaryControls(
                shuffleEnabled: false,
                repeatEnabled: false,
                onShuffle: () {},
                onRepeat: () {},
                onQueue: () {},
                onLyrics: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.byType(controls_barrel.PlayerSeekBar), findsOneWidget);
      expect(find.byType(controls_barrel.PlayerPlaybackControls), findsOneWidget);
      expect(find.byType(controls_barrel.PlayerUtilityRow), findsOneWidget);
      expect(find.byType(controls_barrel.PlayerSecondaryControls), findsOneWidget);
    });

    testWidgets('player_sheets.dart barrel exports all 4 sheet widgets', (tester) async {
      await tester.pumpWidget(
        buildBoilerplate(
          Column(
            children: [
              const sheets_barrel.PlayerSheetHeader(title: 'Test Header'),
              const sheets_barrel.PlayerSheetDetailRow(label: 'Key', value: 'Val'),
              sheets_barrel.PlayerOptionsSheet(
                onShowDetails: () {},
                onShowQueue: () {},
              ),
              const sheets_barrel.PlayerTrackDetailsSheet(
                title: 'Song',
                artist: 'Artist',
                album: 'Album',
              ),
            ],
          ),
        ),
      );

      expect(find.byType(sheets_barrel.PlayerSheetHeader), findsAtLeastNWidgets(1));
      expect(find.byType(sheets_barrel.PlayerSheetDetailRow), findsAtLeastNWidgets(1));
      expect(find.byType(sheets_barrel.PlayerOptionsSheet), findsOneWidget);
      expect(find.byType(sheets_barrel.PlayerTrackDetailsSheet), findsOneWidget);
    });
  });

  group('Item 162: PlayerSeekBar Adversarial Boundary Stress Tests', () {
    testWidgets('Zero duration boundary (duration = Duration.zero)', (tester) async {
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerSeekBar(
            duration: Duration.zero,
            position: Duration.zero,
            onDragPositionChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('0:00'), findsNWidgets(2));

      // Attempt to drag on zero-duration slider
      await tester.drag(find.byType(Slider), const Offset(40, 0));
      await tester.pump();
      // Should not crash and handle zero duration gracefully
    });

    testWidgets('Negative position boundary (position = -10s)', (tester) async {
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerSeekBar(
            duration: const Duration(minutes: 3),
            position: const Duration(seconds: -10),
            onDragPositionChanged: (_) {},
          ),
        ),
      );

      // Negative position must be clamped to Duration.zero (0:00)
      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('3:00'), findsOneWidget);
    });

    testWidgets('Position exceeds duration boundary (pos = 5m, dur = 3m)', (tester) async {
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerSeekBar(
            duration: const Duration(minutes: 3),
            position: const Duration(minutes: 5),
            onDragPositionChanged: (_) {},
          ),
        ),
      );

      // Must be bounded to duration (3:00)
      expect(find.text('3:00'), findsNWidgets(2));
    });

    testWidgets('Long duration boundary (24 hours playback)', (tester) async {
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerSeekBar(
            duration: const Duration(hours: 24),
            position: const Duration(hours: 12, minutes: 34, seconds: 56),
            onDragPositionChanged: (_) {},
          ),
        ),
      );

      expect(find.text('12:34:56'), findsOneWidget);
      expect(find.text('24:00:00'), findsOneWidget);
    });

    testWidgets('Drag position takes precedence over playback position during scrubbing', (tester) async {
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerSeekBar(
            duration: const Duration(minutes: 4),
            position: const Duration(minutes: 1),
            dragPosition: const Duration(minutes: 2, seconds: 30),
            onDragPositionChanged: (_) {},
          ),
        ),
      );

      // Should display drag position (2:30), not playback position (1:00)
      expect(find.text('2:30'), findsOneWidget);
      expect(find.text('4:00'), findsOneWidget);
    });

    testWidgets('Scrubbing triggers onDragPositionChanged and onChangeEnd triggers onSeek', (tester) async {
      Duration? latestDrag;
      Duration? seekTarget;

      await tester.pumpWidget(
        buildBoilerplate(
          PlayerSeekBar(
            duration: const Duration(minutes: 4),
            position: const Duration(minutes: 1),
            onDragPositionChanged: (pos) => latestDrag = pos,
            onSeek: (pos) => seekTarget = pos,
          ),
        ),
      );

      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      // Tap at the center of the slider
      await tester.tap(slider);
      await tester.pump();

      expect(latestDrag, isNull); // After tap (changeEnd), drag resets to null
      expect(seekTarget, isNotNull);
      expect(seekTarget!.inSeconds, greaterThan(0));
    });

    testWidgets('Buffered position boundaries: negative, zero, and exceeding duration', (tester) async {
      // 1. Zero buffered
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerSeekBar(
            duration: const Duration(minutes: 3),
            position: Duration.zero,
            bufferedPosition: Duration.zero,
            onDragPositionChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(Slider), findsOneWidget);

      // 2. Negative buffered
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerSeekBar(
            duration: const Duration(minutes: 3),
            position: Duration.zero,
            bufferedPosition: const Duration(seconds: -5),
            onDragPositionChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(Slider), findsOneWidget);

      // 3. Exceeding duration
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerSeekBar(
            duration: const Duration(minutes: 3),
            position: Duration.zero,
            bufferedPosition: const Duration(minutes: 10),
            onDragPositionChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('Flow controller animation sync and clean disposal without ticker leaks', (tester) async {
      // 1. Initial state paused: not animating
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerSeekBar(
            transportPhase: NowPlayingTransportPhase.paused,
            onDragPositionChanged: (_) {},
          ),
        ),
      );

      // 2. Transition to bufferingUnplayedSegment: starts animation
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerSeekBar(
            transportPhase: NowPlayingTransportPhase.bufferingUnplayedSegment,
            onDragPositionChanged: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // 3. Transition to playing: stops animation
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerSeekBar(
            transportPhase: NowPlayingTransportPhase.playing,
            onDragPositionChanged: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // 4. Back to bufferingUnplayedSegment
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerSeekBar(
            transportPhase: NowPlayingTransportPhase.bufferingUnplayedSegment,
            onDragPositionChanged: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 5. Unmount widget while animating: ensures dispose() cleans up AnimationController
      await tester.pumpWidget(
        buildBoilerplate(
          const SizedBox(child: Text('Unmounted')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unmounted'), findsOneWidget);
      // If controller was not disposed cleanly, the framework throws an active Ticker exception here.
    });
  });

  group('Item 163: PlayerPlaybackControls Adversarial Stress Tests', () {
    testWidgets('Transport phase toggles play/pause icon correctly', (tester) async {
      // Paused -> shows play icon
      await tester.pumpWidget(
        buildBoilerplate(
          const PlayerPlaybackControls(
            transportPhase: NowPlayingTransportPhase.paused,
          ),
        ),
      );
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);

      // Playing -> shows pause icon
      await tester.pumpWidget(
        buildBoilerplate(
          const PlayerPlaybackControls(
            transportPhase: NowPlayingTransportPhase.playing,
          ),
        ),
      );
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);

      // Buffering unplayed segment -> shows pause icon
      await tester.pumpWidget(
        buildBoilerplate(
          const PlayerPlaybackControls(
            transportPhase: NowPlayingTransportPhase.bufferingUnplayedSegment,
          ),
        ),
      );
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('Rapid taps on Play/Pause button do not corrupt state or drop counts', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerPlaybackControls(
            transportPhase: NowPlayingTransportPhase.paused,
            onPlayPause: () => tapCount++,
          ),
        ),
      );

      final playBtn = find.byIcon(Icons.play_arrow_rounded);
      expect(playBtn, findsOneWidget);

      for (int i = 0; i < 25; i++) {
        await tester.tap(playBtn, warnIfMissed: false);
      }
      await tester.pump();

      expect(tapCount, 25);
    });

    testWidgets('Skip previous and skip next disabled states prevent callbacks and dim color', (tester) async {
      int prevTaps = 0;
      int nextTaps = 0;

      await tester.pumpWidget(
        buildBoilerplate(
          PlayerPlaybackControls(
            canSkipPrevious: false,
            canSkipNext: false,
            onPrevious: () => prevTaps++,
            onNext: () => nextTaps++,
          ),
        ),
      );

      // Find buttons by tooltip
      final prevBtn = find.byTooltip('Previous track');
      final nextBtn = find.byTooltip('Next track');

      await tester.tap(prevBtn);
      await tester.tap(nextBtn);
      await tester.pump();

      expect(prevTaps, 0);
      expect(nextTaps, 0);

      final prevIcon = tester.widget<Icon>(find.descendant(of: prevBtn, matching: find.byType(Icon)));
      final nextIcon = tester.widget<Icon>(find.descendant(of: nextBtn, matching: find.byType(Icon)));

      expect(prevIcon.color, Colors.white38);
      expect(nextIcon.color, Colors.white38);
    });

    testWidgets('Skip previous and skip next enabled states trigger callbacks', (tester) async {
      int prevTaps = 0;
      int nextTaps = 0;

      await tester.pumpWidget(
        buildBoilerplate(
          PlayerPlaybackControls(
            canSkipPrevious: true,
            canSkipNext: true,
            onPrevious: () => prevTaps++,
            onNext: () => nextTaps++,
          ),
        ),
      );

      await tester.tap(find.byTooltip('Previous track'));
      await tester.tap(find.byTooltip('Next track'));
      await tester.pump();

      expect(prevTaps, 1);
      expect(nextTaps, 1);
    });

    testWidgets('Shuffle and Repeat modes render active indicators and tooltips', (tester) async {
      int shuffleTaps = 0;
      int repeatTaps = 0;

      // 1. None state
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerPlaybackControls(
            shuffleMode: QueueShuffleMode.none,
            repeatMode: QueueRepeatMode.none,
            onShuffle: () => shuffleTaps++,
            onRepeat: () => repeatTaps++,
          ),
        ),
      );

      expect(find.byTooltip('Enable shuffle'), findsOneWidget);
      expect(find.byTooltip('Enable repeat'), findsOneWidget);

      await tester.tap(find.byTooltip('Enable shuffle'));
      await tester.tap(find.byTooltip('Enable repeat'));
      await tester.pump();

      expect(shuffleTaps, 1);
      expect(repeatTaps, 1);

      // 2. Active shuffle + Repeat all state
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerPlaybackControls(
            shuffleMode: QueueShuffleMode.all,
            repeatMode: QueueRepeatMode.all,
            onShuffle: () => shuffleTaps++,
            onRepeat: () => repeatTaps++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250)); // let animation settle

      expect(find.byTooltip('Disable shuffle'), findsOneWidget);
      expect(find.byTooltip('Repeat all'), findsOneWidget);

      // 3. Repeat one state
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerPlaybackControls(
            shuffleMode: QueueShuffleMode.none,
            repeatMode: QueueRepeatMode.one,
            onShuffle: () => shuffleTaps++,
            onRepeat: () => repeatTaps++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byTooltip('Repeat one'), findsOneWidget);
    });

    testWidgets('Null callbacks do not crash when controls are tapped', (tester) async {
      await tester.pumpWidget(
        buildBoilerplate(
          const PlayerPlaybackControls(
            onPlayPause: null,
            onNext: null,
            onPrevious: null,
            onShuffle: null,
            onRepeat: null,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.tap(find.byTooltip('Enable shuffle'));
      await tester.tap(find.byTooltip('Enable repeat'));
      await tester.pump();
      // Passes if no exception thrown
    });
  });

  group('Item 164: PlayerUtilityRow Adversarial Tests', () {
    testWidgets('Queue button triggers onQueue callback', (tester) async {
      int queueCalls = 0;
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerUtilityRow(
            onQueue: () => queueCalls++,
          ),
        ),
      );

      final queueBtn = find.byTooltip('Queue');
      expect(queueBtn, findsOneWidget);

      await tester.tap(queueBtn);
      await tester.pump();

      expect(queueCalls, 1);
    });

    testWidgets('Devices button triggers onDevice callback when provided', (tester) async {
      int deviceCalls = 0;
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerUtilityRow(
            onQueue: () {},
            onDevice: () => deviceCalls++,
          ),
        ),
      );

      final devBtn = find.byTooltip('Devices');
      expect(devBtn, findsOneWidget);

      await tester.tap(devBtn);
      await tester.pump();

      expect(deviceCalls, 1);
    });

    testWidgets('Devices button with null onDevice executes safe no-op without error', (tester) async {
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerUtilityRow(
            onQueue: () {},
            onDevice: null,
          ),
        ),
      );

      final devBtn = find.byTooltip('Devices');
      expect(devBtn, findsOneWidget);

      await tester.tap(devBtn);
      await tester.pump();
      // No exception thrown
    });

    // 1:1 Connect entrypoint wiring verification (p199p/nhr.java:513-567,
    // p199p/qsq.java, p199p/ac0.java:51).
    testWidgets(
      'Item 179: connectController opens DevicePickerSheet and tints Devices icon dynamically',
      (tester) async {
        final transport = _UtilityRowFakeTransport();
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
        addTearDown(() async {
          await tester.runAsync(() async {
            await controller.close();
            await volumeController.dispose();
            await sortingDb.close();
            await transport.close();
          });
        });

        await tester.pumpWidget(
          buildBoilerplate(
            PlayerUtilityRow(
              onQueue: () {},
              connectController: controller,
            ),
          ),
        );

        // Local built-in active -> ConnectIconIdle (subdued).
        transport.emitCluster(selfActive: true);
        await tester.pump();
        await tester.pump();
        ConnectStateIcon stateIcon = tester.widget<ConnectStateIcon>(
          find.descendant(
            of: find.byTooltip('Devices'),
            matching: find.byType(ConnectStateIcon),
          ),
        );
        expect(stateIcon.iconState, isA<ConnectIconIdle>());
        expect(stateIcon.idleColor, equals(ConnectEncoreTheme.textSubdued));

        // Remote active -> ConnectIconActive (kSpotifyConnectGreen).
        transport.emitCluster(selfActive: false, remoteActive: true);
        await tester.pump();
        await tester.pump();
        stateIcon = tester.widget<ConnectStateIcon>(
          find.descendant(
            of: find.byTooltip('Devices'),
            matching: find.byType(ConnectStateIcon),
          ),
        );
        expect(stateIcon.iconState, isA<ConnectIconActive>());
        expect(stateIcon.activeColor, equals(kSpotifyConnectGreen));

        // Back to local built-in -> ConnectIconIdle.
        transport.emitCluster(selfActive: true, remoteActive: false);
        await tester.pump();
        await tester.pump();
        stateIcon = tester.widget<ConnectStateIcon>(
          find.descendant(
            of: find.byTooltip('Devices'),
            matching: find.byType(ConnectStateIcon),
          ),
        );
        expect(stateIcon.iconState, isA<ConnectIconIdle>());

        // Tapping Devices when onDevice is null opens DevicePickerSheet.
        await tester.tap(find.byTooltip('Devices'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(DevicePickerSheet), findsOneWidget);
      },
    );

    testWidgets(
      'Item 179: explicit onDevice callback overrides connectController sheet trigger',
      (tester) async {
        final transport = _UtilityRowFakeTransport();
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
        addTearDown(() async {
          await tester.runAsync(() async {
            await controller.close();
            await volumeController.dispose();
            await sortingDb.close();
            await transport.close();
          });
        });

        int overrideCalls = 0;
        await tester.pumpWidget(
          buildBoilerplate(
            PlayerUtilityRow(
              onQueue: () {},
              onDevice: () => overrideCalls++,
              connectController: controller,
            ),
          ),
        );

        await tester.tap(find.byTooltip('Devices'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(overrideCalls, 1);
        expect(find.byType(DevicePickerSheet), findsNothing);
      },
    );
  });

  group('Item 165: PlayerSecondaryControls Adversarial Tests', () {
    testWidgets('Renders all four secondary actions with correct labels and states', (tester) async {
      int shuffleCount = 0;
      int repeatCount = 0;
      int queueCount = 0;
      int lyricsCount = 0;

      // 1. Inactive state
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerSecondaryControls(
            shuffleEnabled: false,
            repeatEnabled: false,
            onShuffle: () => shuffleCount++,
            onRepeat: () => repeatCount++,
            onQueue: () => queueCount++,
            onLyrics: () => lyricsCount++,
          ),
        ),
      );

      expect(find.text('Shuffle'), findsOneWidget);
      expect(find.text('Repeat'), findsOneWidget);
      expect(find.text('Queue'), findsOneWidget);
      expect(find.text('Lyrics'), findsOneWidget);

      await tester.tap(find.text('Shuffle'));
      await tester.tap(find.text('Repeat'));
      await tester.tap(find.text('Queue'));
      await tester.tap(find.text('Lyrics'));
      await tester.pump();

      expect(shuffleCount, 1);
      expect(repeatCount, 1);
      expect(queueCount, 1);
      expect(lyricsCount, 1);

      // 2. Active repeat state changes label to 'Repeat one'
      await tester.pumpWidget(
        buildBoilerplate(
          PlayerSecondaryControls(
            shuffleEnabled: true,
            repeatEnabled: true,
            onShuffle: () {},
            onRepeat: () {},
            onQueue: () {},
            onLyrics: () {},
          ),
        ),
      );

      expect(find.text('Repeat one'), findsOneWidget);
      expect(find.byIcon(Icons.repeat_one_rounded), findsOneWidget);
    });
  });

  group('Item 169 & 170: PlayerSheetHeader and PlayerSheetDetailRow Tests', () {
    testWidgets('PlayerSheetHeader displays title and close button pops navigator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: ctx,
                    builder: (_) => const PlayerSheetHeader(title: 'Modal Title'),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Modal Title'), findsOneWidget);

      final closeBtn = find.byTooltip('Close');
      expect(closeBtn, findsOneWidget);

      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(find.text('Modal Title'), findsNothing);
    });

    testWidgets('PlayerSheetDetailRow formats label and value with text overflow handling', (tester) async {
      await tester.pumpWidget(
        buildBoilerplate(
          const PlayerSheetDetailRow(
            label: 'Artist',
            value: 'Very Long Artist Name That Might Wrap Over Multiple Lines In Edge Cases',
          ),
        ),
      );

      expect(find.text('Artist'), findsOneWidget);
      expect(
        find.text('Very Long Artist Name That Might Wrap Over Multiple Lines In Edge Cases'),
        findsOneWidget,
      );
    });
  });

  group('Item 167: PlayerOptionsSheet Modal Presentation Tests', () {
    testWidgets('PlayerOptionsSheet navigates to Details and Queue with modal pop', (tester) async {
      bool detailsCalled = false;
      bool queueCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: ctx,
                    builder: (_) => PlayerOptionsSheet(
                      onShowDetails: () => detailsCalled = true,
                      onShowQueue: () => queueCalled = true,
                    ),
                  );
                },
                child: const Text('Show Options'),
              ),
            ),
          ),
        ),
      );

      // 1. Open sheet and tap Track Details
      await tester.tap(find.text('Show Options'));
      await tester.pumpAndSettle();

      expect(find.text('Track options'), findsOneWidget);
      expect(find.text('Track details'), findsOneWidget);
      expect(find.text('Open queue'), findsOneWidget);

      await tester.tap(find.text('Track details'));
      await tester.pumpAndSettle();

      expect(detailsCalled, isTrue);
      expect(find.text('Track options'), findsNothing); // Popped

      // 2. Open sheet and tap Open queue
      await tester.tap(find.text('Show Options'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open queue'));
      await tester.pumpAndSettle();

      expect(queueCalled, isTrue);
      expect(find.text('Track options'), findsNothing); // Popped
    });
  });

  group('Item 168: PlayerTrackDetailsSheet Metadata & Duration Purity Tests', () {
    testWidgets('Renders all metadata when title, artist, album, and duration are populated', (tester) async {
      await tester.pumpWidget(
        buildBoilerplate(
          const PlayerTrackDetailsSheet(
            title: 'Blinding Lights',
            artist: 'The Weeknd',
            album: 'After Hours',
            duration: Duration(minutes: 3, seconds: 20),
          ),
        ),
      );

      expect(find.text('Track details'), findsOneWidget);
      expect(find.text('Blinding Lights'), findsOneWidget);
      expect(find.text('The Weeknd'), findsOneWidget);
      expect(find.text('After Hours'), findsOneWidget);
      expect(find.text('3:20'), findsOneWidget);
    });

    testWidgets('Duration row is completely omitted when duration is null (AST Layer 2 pattern match verification)', (tester) async {
      await tester.pumpWidget(
        buildBoilerplate(
          const PlayerTrackDetailsSheet(
            title: 'Live Stream',
            artist: 'Broadcaster',
            album: 'Live Radio',
            duration: null,
          ),
        ),
      );

      expect(find.text('Track details'), findsOneWidget);
      expect(find.text('Live Stream'), findsOneWidget);
      expect(find.text('Broadcaster'), findsOneWidget);
      expect(find.text('Live Radio'), findsOneWidget);
      expect(find.text('Duration'), findsNothing);
    });

    testWidgets('Empty artist and album fallback to Unknown Artist and Unknown Album', (tester) async {
      await tester.pumpWidget(
        buildBoilerplate(
          const PlayerTrackDetailsSheet(
            title: 'Untitled Track',
            artist: '',
            album: '',
            duration: Duration(seconds: 45),
          ),
        ),
      );

      expect(find.text('Untitled Track'), findsOneWidget);
      expect(find.text('Unknown Artist'), findsOneWidget);
      expect(find.text('Unknown Album'), findsOneWidget);
      expect(find.text('0:45'), findsOneWidget);
    });
  });
}

final class _UtilityRowFakeTransport implements EsperantoTransport {
  final StreamController<Uint8List> stateStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> volumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> localVolumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> dodoStreamController =
      StreamController<Uint8List>.broadcast();

  void emitCluster({
    required bool selfActive,
    bool remoteActive = false,
  }) {
    final response = connect_pb.StateResponse(
      isActive: false,
      devices: <connect_pb.StateResponse_Device>[
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
        connect_pb.StateResponse_Device(
          isSelf: false,
          isActive: remoteActive,
          isLocal: true,
          supportsLogout: true,
          supportsVolume: true,
          connectStateIdentifier: 'remote-1',
          localIdentifier: 'local-remote-1',
          name: 'Living Room Speaker',
          state: 'LOGGED_IN',
          type: 'SPEAKER',
          volume: 32768,
          volumeSteps: 24,
          capabilities: '[]',
        ),
      ],
      isSyncedWithBackend: true,
    );
    stateStreamController.add(Uint8List.fromList(response.writeToBuffer()));
  }

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
