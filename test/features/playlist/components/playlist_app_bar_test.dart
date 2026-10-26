import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/playlist/presentation/components/playlist_app_bar.dart';

void main() {
  group('PlaylistAppBar Button Alignment and Animation Tests', () {
    testWidgets('Back and More buttons are positioned at edges, NOT centered', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaylistAppBar(
              title: 'Test Playlist',
              scrollOffset: 0.0,
              headerHeight: 300.0,
              dominantColor: const Color(0xFF1DB954),
              onBackTapped: () {},
              onSearchTapped: () {},
              onSearchClosed: () {},
              onMoreTapped: () {},
            ),
          ),
        ),
      );

      final backIcon = find.byIcon(Icons.arrow_back);
      final moreIcon = find.byIcon(Icons.more_vert);

      expect(backIcon, findsOneWidget);
      expect(moreIcon, findsOneWidget);

      final backPosition = tester.getTopLeft(backIcon);
      final morePosition = tester.getTopRight(moreIcon);

      // Width is 400. Back button should be within first 50 pixels (not centered at 200).
      expect(backPosition.dx, lessThan(50.0));
      // More button should be within last 50 pixels.
      expect(morePosition.dx, greaterThan(350.0));
    });

    testWidgets('Title opacity is 0.0 below 70% threshold and fades in after 70%', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      // Test at 50% scroll (below 70%)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaylistAppBar(
              title: 'Test Playlist',
              scrollOffset: 150.0,
              headerHeight: 300.0,
              dominantColor: const Color(0xFF1DB954),
              onBackTapped: () {},
              onSearchTapped: () {},
              onSearchClosed: () {},
              onMoreTapped: () {},
            ),
          ),
        ),
      );

      final titleFinder = find.text('Test Playlist');
      expect(titleFinder, findsOneWidget);
      final opacityWidgetBefore = tester.widget<Opacity>(
        find.ancestor(of: titleFinder, matching: find.byType(Opacity)),
      );
      expect(opacityWidgetBefore.opacity, equals(0.0));

      // Test at 85% scroll (above 70%)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaylistAppBar(
              title: 'Test Playlist',
              scrollOffset: 255.0,
              headerHeight: 300.0,
              dominantColor: const Color(0xFF1DB954),
              onBackTapped: () {},
              onSearchTapped: () {},
              onSearchClosed: () {},
              onMoreTapped: () {},
            ),
          ),
        ),
      );

      final opacityWidgetAfter = tester.widget<Opacity>(
        find.ancestor(of: titleFinder, matching: find.byType(Opacity)),
      );
      expect(opacityWidgetAfter.opacity, greaterThan(0.0));
    });
  });
}
