import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/playlist/presentation/components/spotify_swipe_to_queue.dart';

void main() {
  group('SpotifySwipeToQueue Interaction Tests', () {
    testWidgets('Swipe past 25% threshold triggers onSwipeToQueue and snaps back', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      bool queued = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpotifySwipeToQueue(
              onSwipeToQueue: () {
                queued = true;
              },
              child: Container(
                key: const ValueKey('track_row'),
                width: 400,
                height: 60,
                color: Colors.black,
                child: const Text('Track Title'),
              ),
            ),
          ),
        ),
      );

      final trackRow = find.byKey(const ValueKey('track_row'));
      expect(trackRow, findsOneWidget);

      // Drag right by 120 pixels (30% of 400 width, which is > 25% threshold = 100 pixels)
      final gesture = await tester.startGesture(tester.getCenter(trackRow));
      await gesture.moveBy(const Offset(120, 0));
      await tester.pump();

      // Check transform is translated
      final transformFinder = find.ancestor(of: trackRow, matching: find.byType(Transform));
      final transformWidget = tester.widget<Transform>(transformFinder.first);
      final matrix = transformWidget.transform;
      // Translation X is at matrix[12]
      expect(matrix.storage[12], equals(120.0));

      // End gesture (finger up)
      await gesture.up();
      await tester.pump();

      // onSwipeToQueue should have been called
      expect(queued, isTrue);

      // Settle spring snap-back animation (220ms)
      await tester.pumpAndSettle();

      final transformWidgetSettled = tester.widget<Transform>(transformFinder.first);
      expect(transformWidgetSettled.transform.storage[12], equals(0.0));
    });

    testWidgets('Swipe below 25% threshold does not trigger onSwipeToQueue and snaps back', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      bool queued = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpotifySwipeToQueue(
              onSwipeToQueue: () {
                queued = true;
              },
              child: Container(
                key: const ValueKey('track_row'),
                width: 400,
                height: 60,
                color: Colors.black,
                child: const Text('Track Title'),
              ),
            ),
          ),
        ),
      );

      final trackRow = find.byKey(const ValueKey('track_row'));

      // Drag right by 60 pixels (15% of 400 width, which is < 25% threshold = 100 pixels)
      final gesture = await tester.startGesture(tester.getCenter(trackRow));
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();

      // End gesture (finger up)
      await gesture.up();
      await tester.pump();

      // onSwipeToQueue should NOT have been called
      expect(queued, isFalse);

      // Settle snap-back animation
      await tester.pumpAndSettle();

      final transformFinder = find.ancestor(of: trackRow, matching: find.byType(Transform));
      final transformWidgetSettled = tester.widget<Transform>(transformFinder.first);
      expect(transformWidgetSettled.transform.storage[12], equals(0.0));
    });

    testWidgets('Drag is clamped at 45% maximum width', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpotifySwipeToQueue(
              onSwipeToQueue: () {},
              child: Container(
                key: const ValueKey('track_row'),
                width: 400,
                height: 60,
                color: Colors.black,
                child: const Text('Track Title'),
              ),
            ),
          ),
        ),
      );

      final trackRow = find.byKey(const ValueKey('track_row'));

      // Drag right by 300 pixels (more than 45% of 400 = 180 pixels)
      final gesture = await tester.startGesture(tester.getCenter(trackRow));
      await gesture.moveBy(const Offset(300, 0));
      await tester.pump();

      final transformFinder = find.ancestor(of: trackRow, matching: find.byType(Transform));
      final transformWidget = tester.widget<Transform>(transformFinder.first);
      expect(transformWidget.transform.storage[12], equals(180.0)); // Exactly 45% of 400

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
