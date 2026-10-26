import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_item.dart';
import 'package:musify_mu/features/playlist/domain/models/track_item_metadata.dart';
import 'package:musify_mu/features/playlist/presentation/components/playlist_track_tile.dart';

void main() {
  group('PlaylistTrackTile Multi-Entity Rendering Tests', () {
    testWidgets('Renders Standard Music Track with 48x48 art, title, artists, badges', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      const item = PlaylistItem(
        uri: 'spotify:track:12345',
        uid: 'uid_1',
        rowPosition: 0,
        isDownloaded: true,
        trackMetadata: TrackItemMetadata(
          title: 'Starboy',
          uri: 'spotify:track:12345',
          artists: ['The Weeknd', 'Daft Punk'],
          albumName: 'Starboy',
          isExplicit: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaylistTrackTile(
              item: item,
              isActiveTrack: true,
              isPlaying: true,
              onTap: () {},
              onMoreTapped: () {},
              onSwipeToQueue: () {},
            ),
          ),
        ),
      );

      // Verify title and artist text
      expect(find.text('Starboy'), findsOneWidget);
      expect(find.text('The Weeknd, Daft Punk'), findsOneWidget);

      // Verify Explicit 'E' badge
      expect(find.text('E'), findsOneWidget);

      // Verify Downloaded icon
      expect(find.byIcon(Icons.arrow_circle_down), findsOneWidget);

      // Verify More options button
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('Renders Podcast Episode with 64x64 art, 2-line title, show subtitle, actions', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      const item = PlaylistItem(
        uri: 'spotify:episode:episode999',
        uid: 'uid_ep_1',
        rowPosition: 1,
        trackMetadata: TrackItemMetadata(
          title: 'The AI Revolution Explained',
          uri: 'spotify:episode:episode999',
          showName: 'Tech Insights Daily',
          description: 'A deep dive into advanced agentic frameworks and reasoning systems.',
          publishDate: 'Oct 24',
          durationMs: 1800000, // 30 mins
          playbackPositionMs: 600000, // 10 mins played
          isEpisode: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaylistTrackTile(
              item: item,
              isActiveTrack: false,
              isPlaying: false,
              onTap: () {},
              onMoreTapped: () {},
              onSwipeToQueue: () {},
            ),
          ),
        ),
      );

      // Verify Episode Title and Show Name
      expect(find.text('The AI Revolution Explained'), findsOneWidget);
      expect(find.text('Tech Insights Daily'), findsOneWidget);

      // Verify Description Excerpt
      expect(
        find.text('A deep dive into advanced agentic frameworks and reasoning systems.'),
        findsOneWidget,
      );

      // Verify 30 min duration formatting and date
      expect(find.textContaining('Oct 24'), findsOneWidget);
      expect(find.textContaining('30 min'), findsOneWidget);

      // Verify Episode Quick Action Bar: Play arrow, add, download, more
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.arrow_circle_down_outlined), findsOneWidget);
    });

    testWidgets('Renders Podcast Show with 64x64 art, show title, and Podcast subtitle', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      const item = PlaylistItem(
        uri: 'spotify:show:show456',
        uid: 'uid_show_1',
        rowPosition: 2,
        trackMetadata: TrackItemMetadata(
          title: 'Huberman Lab',
          uri: 'spotify:show:show456',
          albumName: 'Scicomm Media',
          description: 'Science and science-based tools for everyday life.',
          isShow: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaylistTrackTile(
              item: item,
              isActiveTrack: false,
              isPlaying: false,
              onTap: () {},
              onMoreTapped: () {},
              onSwipeToQueue: () {},
            ),
          ),
        ),
      );

      // Verify Show Title and "Podcast • Scicomm Media" subtitle
      expect(find.text('Huberman Lab'), findsOneWidget);
      expect(find.text('Podcast • Scicomm Media'), findsOneWidget);
      expect(
        find.text('Science and science-based tools for everyday life.'),
        findsOneWidget,
      );
    });
  });
}
