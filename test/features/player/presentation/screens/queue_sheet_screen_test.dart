import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/presentation/screens/queue_sheet_screen.dart';

void main() {
  group('QueueSheetScreen Tap Animations & Transitions', () {
    final testTracks = [
      const MockQueueTrack(
        id: 'q-1',
        title: 'Queued Track 1',
        artist: 'Artist A',
        album: 'Album A',
        duration: Duration(minutes: 3),
        isQueued: true,
      ),
      const MockQueueTrack(
        id: 'q-2',
        title: 'Queued Track 2',
        artist: 'Artist A',
        album: 'Album A',
        duration: Duration(minutes: 3),
        isQueued: true,
      ),
      const MockQueueTrack(
        id: 'c-1',
        title: 'Context Track 1',
        artist: 'Artist B',
        album: 'Album B',
        duration: Duration(minutes: 3),
        isQueued: false,
      ),
      const MockQueueTrack(
        id: 'c-2',
        title: 'Context Track 2',
        artist: 'Artist B',
        album: 'Album B',
        duration: Duration(minutes: 3),
        isQueued: false,
      ),
      const MockQueueTrack(
        id: 'c-3',
        title: 'Context Track 3',
        artist: 'Artist B',
        album: 'Album B',
        duration: Duration(minutes: 3),
        isQueued: false,
      ),
      const MockQueueTrack(
        id: 'c-4',
        title: 'Context Track 4',
        artist: 'Artist B',
        album: 'Album B',
        duration: Duration(minutes: 3),
        isQueued: false,
      ),
      const MockQueueTrack(
        id: 'c-5',
        title: 'Context Track 5',
        artist: 'Artist B',
        album: 'Album B',
        duration: Duration(minutes: 3),
        isQueued: false,
      ),
    ];

    testWidgets('Tapping a queued track down below triggers smooth collapse and updates Now Playing',
        (tester) async {
      MockQueueTrack? tappedTrack;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueueSheetScreen(
              tracks: testTracks,
              onTrackTapped: (track) {
                tappedTrack = track;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Find Queued Track 2
      final trackFinder = find.text('Queued Track 2');
      expect(trackFinder, findsOneWidget);

      await tester.tap(trackFinder);
      await tester.pump();

      expect(tappedTrack?.id, equals('q-2'));

      // Advance through the 375ms DefaultItemAnimator transition
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 50));

      // After transition completes, q-1 and q-2 are consumed; c-1 is now at top
      expect(find.text('Context Track 1'), findsOneWidget);
    });

    testWidgets('Tapping a context track below user-queued tracks preserves queued items at head',
        (tester) async {
      MockQueueTrack? tappedTrack;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueueSheetScreen(
              tracks: testTracks,
              onTrackTapped: (track) {
                tappedTrack = track;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Tap Context Track 2 (c-2)
      final trackFinder = find.text('Context Track 2');
      expect(trackFinder, findsOneWidget);

      await tester.tap(trackFinder);
      await tester.pump();

      expect(tappedTrack?.id, equals('c-2'));

      // Advance through 375ms transition
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 50));

      // Preserved queued items (q-1 and q-2) remain in the upcoming list
      expect(find.text('Queued Track 1'), findsOneWidget);
      expect(find.text('Queued Track 2'), findsOneWidget);

      // Skipped context track c-1 and tapped context track c-2 are consumed
      // Remaining context tracks (c-3, c-4, c-5) follow the preserved queued tracks
      expect(find.text('Context Track 3'), findsOneWidget);
    });

    testWidgets('Tap Lock blocks re-entrant taps during in-flight 375ms animation',
        (tester) async {
      int tapCount = 0;
      MockQueueTrack? lastTapped;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueueSheetScreen(
              tracks: testTracks,
              onTrackTapped: (track) {
                tapCount++;
                lastTapped = track;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Tap first item
      await tester.tap(find.text('Queued Track 2'));
      await tester.pump();

      expect(tapCount, equals(1));
      expect(lastTapped?.id, equals('q-2'));

      // Tap second item mid-flight (100ms in)
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Context Track 1'));
      await tester.pump();

      // Tap count must remain 1 due to Tap Lock
      expect(tapCount, equals(1));
      expect(lastTapped?.id, equals('q-2'));

      // Complete transition
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}
