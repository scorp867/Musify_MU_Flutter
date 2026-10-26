import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/ui/icons/spotify_encore_icons.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_header_type.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_metadata.dart';
import 'package:musify_mu/features/playlist/presentation/components/playlist_curation_chips_row.dart';
import 'package:musify_mu/features/playlist/presentation/components/playlist_editorial_header.dart';
import 'package:musify_mu/features/playlist/presentation/components/playlist_header_content.dart';
import 'package:musify_mu/features/playlist/presentation/components/playlist_user_header.dart';

void main() {
  group('Playlist Headers Dual-Layout Tests (Editorial vs User-Owned)', () {
    test('PlaylistMetadata correctly derives headerType', () {
      const editorialMeta = PlaylistMetadata(
        uri: 'spotify:playlist:37i9dQZF1DXcBWIGoYBM5M',
        name: "Today's Top Hits",
        ownerUsername: 'spotify',
        ownerName: 'Spotify',
      );
      expect(editorialMeta.isEditorial, isTrue);
      expect(editorialMeta.headerType, equals(PlaylistHeaderType.editorial));

      const userOwnedMeta = PlaylistMetadata(
        uri: 'spotify:playlist:user_playlist_123',
        name: 'My Roadtrip Mix',
        ownerUsername: 'test_user',
        canEdit: true,
      );
      expect(userOwnedMeta.isEditorial, isFalse);
      expect(userOwnedMeta.isUserOwned, isTrue);
      expect(userOwnedMeta.headerType, equals(PlaylistHeaderType.userOwned));

      const followedMeta = PlaylistMetadata(
        uri: 'spotify:playlist:other_playlist_456',
        name: 'Chill Vibes',
        ownerUsername: 'other_user',
        canEdit: false,
      );
      expect(followedMeta.isEditorial, isFalse);
      expect(followedMeta.isUserOwned, isFalse);
      expect(followedMeta.headerType, equals(PlaylistHeaderType.followed));
    });

    testWidgets('PlaylistEditorialHeader renders full-bleed artwork, 32sp title, Spotify badge, and saves count', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      const metadata = PlaylistMetadata(
        uri: 'spotify:playlist:37i9dQZF1DXcBWIGoYBM5M',
        name: "Today's Top Hits",
        description: 'The hottest 50. Cover: Tate McRae',
        ownerUsername: 'spotify',
        ownerName: 'Spotify',
        followersCount: 33669702,
        totalDurationMs: 10080000, // 2 hr 48 min
      );

      final searchController = TextEditingController();
      final searchFocusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlaylistEditorialHeader(
                metadata: metadata,
                trackCount: 50,
                scrollOffset: 0.0,
                searchController: searchController,
                searchFocusNode: searchFocusNode,
                onSearchChanged: (_) {},
                onClearSearch: () {},
              ),
            ),
          ),
        ),
      );

      // Verify Title
      final titleFinder = find.text("Today's Top Hits");
      expect(titleFinder, findsOneWidget);
      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.fontSize, equals(32));

      // Verify Editorial Description
      expect(find.text('The hottest 50. Cover: Tate McRae'), findsOneWidget);

      // Verify Spotify Creator row & Verified badge
      expect(find.text('Spotify'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is SpotifyIcon && w.paths.contains(SpotifyEncoreIcons.verifiedCheckPath),
        ),
        findsOneWidget,
      );

      // Verify Telemetry with saves and duration
      expect(find.textContaining('33.7M saves'), findsOneWidget);
      expect(find.textContaining('2 hr 48 min'), findsOneWidget);

      // Verify Search bar
      expect(
        find.byWidgetPredicate(
          (w) => w is SpotifyIcon && w.paths.contains(SpotifyEncoreIcons.searchPath),
        ),
        findsOneWidget,
      );
      expect(find.text('Find in playlist'), findsOneWidget);
    });

    testWidgets('PlaylistUserHeader renders centered artwork, 24sp title, user avatar, collaborator button, and duration only', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      const metadata = PlaylistMetadata(
        uri: 'spotify:playlist:user_123',
        name: 'Trial',
        ownerUsername: 'syed umair',
        ownerName: 'syed umair',
        canEdit: true,
        followersCount: 120, // Should be omitted for user owned
        totalDurationMs: 3180000, // 53 min
      );

      final searchController = TextEditingController();
      final searchFocusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlaylistUserHeader(
                metadata: metadata,
                trackCount: 15,
                scrollOffset: 0.0,
                searchController: searchController,
                searchFocusNode: searchFocusNode,
                onSearchChanged: (_) {},
                onClearSearch: () {},
                onAddCollaboratorTapped: () {},
              ),
            ),
          ),
        ),
      );

      // Verify Title (24sp)
      final titleFinder = find.text('Trial');
      expect(titleFinder, findsOneWidget);
      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.fontSize, equals(24));

      // Verify User Creator row
      expect(find.text('syed umair'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is SpotifyIcon && w.paths.contains(SpotifyEncoreIcons.userPath),
        ),
        findsOneWidget,
      );

      // Verify Collaborator (+) button
      expect(
        find.byWidgetPredicate(
          (w) => w is SpotifyIcon && w.paths.contains(SpotifyEncoreIcons.plusPath),
        ),
        findsWidgets,
      );

      // Verify Duration telemetry without public saves
      expect(find.textContaining('53 min'), findsOneWidget);
      expect(find.textContaining('saves'), findsNothing);
    });

    testWidgets('PlaylistHeaderContent dispatches to PlaylistEditorialHeader for editorial and PlaylistUserHeader for user', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      const editorialMeta = PlaylistMetadata(
        uri: 'spotify:playlist:editorial_1',
        name: 'RapCaviar',
        ownerUsername: 'spotify',
      );

      final searchController = TextEditingController();
      final searchFocusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlaylistHeaderContent(
                metadata: editorialMeta,
                trackCount: 50,
                scrollOffset: 0.0,
                searchController: searchController,
                searchFocusNode: searchFocusNode,
                onSearchChanged: (_) {},
                onClearSearch: () {},
                onAddCollaboratorTapped: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PlaylistEditorialHeader), findsOneWidget);
      expect(find.byType(PlaylistUserHeader), findsNothing);

      const userMeta = PlaylistMetadata(
        uri: 'spotify:playlist:user_mix',
        name: 'Late Night Study',
        ownerUsername: 'student',
        canEdit: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlaylistHeaderContent(
                metadata: userMeta,
                trackCount: 20,
                scrollOffset: 0.0,
                searchController: searchController,
                searchFocusNode: searchFocusNode,
                onSearchChanged: (_) {},
                onClearSearch: () {},
                onAddCollaboratorTapped: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PlaylistUserHeader), findsOneWidget);
      expect(find.byType(PlaylistEditorialHeader), findsNothing);
    });

    testWidgets('PlaylistCurationChipsRow hides completely for editorial and renders controls for owner', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // 1. Editorial playlist -> Should return empty widget (SizedBox.shrink)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaylistCurationChipsRow(
              isEditorial: true,
              canEdit: false,
              onAddTapped: () {},
              onEditTapped: () {},
              onDetailsTapped: () {},
              onSortTapped: () {},
            ),
          ),
        ),
      );

      expect(find.text('Add'), findsNothing);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Sort'), findsNothing);

      // 2. User owned playlist -> Should render Add, Edit, Name & details, Sort
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaylistCurationChipsRow(
              isEditorial: false,
              canEdit: true,
              onAddTapped: () {},
              onEditTapped: () {},
              onDetailsTapped: () {},
              onSortTapped: () {},
              currentSortName: 'Custom order',
            ),
          ),
        ),
      );

      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Name & details'), findsOneWidget);
      expect(find.text('Custom order'), findsOneWidget);
    });
  });
}
