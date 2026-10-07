import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/presentation/widgets/peek_scroll_view.dart';
import 'package:musify_mu/features/player/presentation/widgets/pull_to_dismiss_scaffold.dart';

void main() {
  group('PullToDismissScaffold Scrim Interaction and Multi-pointer Tests', () {
    testWidgets('scrim is not exposed when dragOffsetY is 0', (tester) async {
      PullToDismissController? capturedController;

      await tester.pumpWidget(
        MaterialApp(
          home: PullToDismissScaffold(
            builder: (context, controller) {
              capturedController = controller;
              return const SizedBox.expand(
                child: Text('PlayerSheetContent'),
              );
            },
          ),
        ),
      );

      expect(find.text('PlayerSheetContent'), findsOneWidget);
      expect(capturedController!.dragOffsetY, 0.0);

      // Verify no scrim positioned overlay exists when sheet is at offset 0
      final scrimFinder = find.byWidgetPredicate(
        (w) => w is Positioned && w.top == 0 && w.height != null,
      );
      expect(scrimFinder, findsNothing);
    });

    testWidgets('dragging exposed scrim continues dragging the player sheet',
        (tester) async {
      PullToDismissController? capturedController;

      await tester.pumpWidget(
        MaterialApp(
          home: PullToDismissScaffold(
            dismissDistanceThreshold: 200.0,
            builder: (context, controller) {
              capturedController = controller;
              return const SizedBox.expand(
                child: Text('PlayerSheetContent'),
              );
            },
          ),
        ),
      );

      // Pull down the sheet by 80px via controller
      capturedController!.onPullDelta(80.0);
      await tester.pump();

      expect(capturedController!.dragOffsetY, 80.0);

      // Now the scrim is exposed at the top from y = 0 to y = 80.
      // Touch down on the scrim at y = 40 (inside scrim area) and drag DOWN by 60px:
      final scrimGesture = await tester.startGesture(const Offset(200, 40));
      await scrimGesture.moveBy(const Offset(0, 60));
      await tester.pump();

      // Scrim drag directly increased sheet offset!
      expect(capturedController!.dragOffsetY, 140.0);

      // Drag UP on scrim by 30px:
      await scrimGesture.moveBy(const Offset(0, -30));
      await tester.pump();

      expect(capturedController!.dragOffsetY, 110.0);

      // Release scrim drag (below 200px threshold, so it snaps back to 0):
      await scrimGesture.up();
      await tester.pumpAndSettle();

      expect(capturedController!.dragOffsetY, 0.0);
    });

    testWidgets(
        'multi-pointer handoff from sheet to scrim keeps drag active without premature snap-back',
        (tester) async {
      PullToDismissController? capturedController;

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (context) => PullToDismissScaffold(
                dismissDistanceThreshold: 150.0,
                builder: (context, controller) {
                  capturedController = controller;
                  return SizedBox.expand(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (d) =>
                          controller.onPullDelta(d.primaryDelta ?? 0),
                      onVerticalDragEnd: (d) =>
                          controller.onPullEnd(d.primaryVelocity ?? 0),
                      child: const Text('SheetTouchTarget'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Pointer 1 drags sheet down by 80px:
      final sheetGesture =
          await tester.startGesture(tester.getCenter(find.text('SheetTouchTarget')));
      await sheetGesture.moveBy(const Offset(0, 80));
      await tester.pump();

      expect(capturedController!.dragOffsetY, 80.0);

      // Pointer 2 touches down ON THE EXPOSED SCRIM (y = 40):
      final scrimGesture = await tester.startGesture(const Offset(200, 40));
      await tester.pump();

      // Pointer 1 lifts from the sheet:
      await sheetGesture.up();
      await tester.pump();

      // Crucial check: Sheet MUST NOT snap back or dismiss while Pointer 2 is still held on scrim!
      expect(capturedController!.dragOffsetY, 80.0);
      expect(capturedController!.isDismissing, isFalse);

      // Pointer 2 continues dragging scrim DOWN past the 150px threshold:
      await scrimGesture.moveBy(const Offset(0, 90));
      await tester.pump();

      expect(capturedController!.dragOffsetY, 170.0);

      // Pointer 2 releases:
      await scrimGesture.up();
      await tester.pumpAndSettle();

      // Threshold was exceeded, so route dismisses:
      expect(capturedController!.isDismissing, isTrue);
    });

    testWidgets('tapping exposed scrim outside player sheet dismisses the route',
        (tester) async {
      PullToDismissController? capturedController;

      await tester.pumpWidget(
        MaterialApp(
          home: PullToDismissScaffold(
            builder: (context, controller) {
              capturedController = controller;
              return const SizedBox.expand(
                child: Text('PlayerSheetContent'),
              );
            },
          ),
        ),
      );

      // Pull down sheet by 100px so scrim is visible
      capturedController!.onPullDelta(100.0);
      await tester.pump();

      expect(capturedController!.dragOffsetY, 100.0);
      expect(capturedController!.isDismissing, isFalse);

      // Tap on the scrim at y = 50 (movement < 18px):
      final scrimTap = await tester.startGesture(const Offset(200, 50));
      await tester.pump(const Duration(milliseconds: 50));
      await scrimTap.up();
      await tester.pump();

      // Tap immediately initiates dismiss:
      expect(capturedController!.isDismissing, isTrue);

      await tester.pumpAndSettle();
    });

    testWidgets(
        'only 1 pointer is active on the scrim at a time and movement is not doubled when multiple pointers move',
        (tester) async {
      PullToDismissController? capturedController;

      await tester.pumpWidget(
        MaterialApp(
          home: PullToDismissScaffold(
            dismissDistanceThreshold: 300.0,
            builder: (context, controller) {
              capturedController = controller;
              return const SizedBox.expand(
                child: Text('PlayerSheetContent'),
              );
            },
          ),
        ),
      );

      // Pull down sheet by 100px so scrim is exposed
      capturedController!.onPullDelta(100.0);
      await tester.pump();
      expect(capturedController!.dragOffsetY, 100.0);

      // Pointer 1 touches down on scrim at y = 40
      final pointer1 = await tester.startGesture(const Offset(100, 40));
      await tester.pump();

      // Pointer 2 touches down on scrim at y = 60
      final pointer2 = await tester.startGesture(const Offset(250, 60));
      await tester.pump();

      // Both pointers move down by 30px
      await pointer1.moveBy(const Offset(0, 30));
      await pointer2.moveBy(const Offset(0, 30));
      await tester.pump();

      // Movement MUST NOT be doubled (30 + 30 = 60); only the active pointer (pointer 2) applies 30px!
      expect(capturedController!.dragOffsetY, 130.0);

      // Pointer 2 lifts; control passes back to pointer 1
      await pointer2.up();
      await tester.pump();

      expect(capturedController!.dragOffsetY, 130.0);

      // Pointer 1 moves up by 25px (upward motion)
      await pointer1.moveBy(const Offset(0, -25));
      await tester.pump();

      expect(capturedController!.dragOffsetY, 105.0);

      // Pointer 1 lifts after upward motion: expands back to 0.0!
      await pointer1.up();
      await tester.pumpAndSettle();

      expect(capturedController!.dragOffsetY, 0.0);
    });

    testWidgets(
        'dragging down deeply then reversing up by 10px expands to offset 0 instead of collapsing',
        (tester) async {
      PullToDismissController? capturedController;

      await tester.pumpWidget(
        MaterialApp(
          home: PullToDismissScaffold(
            builder: (context, controller) {
              capturedController = controller;
              return const SizedBox.expand(
                child: Text('PlayerSheetContent'),
              );
            },
          ),
        ),
      );

      // 1. Drag down deeply (e.g. 500px down on 600px screen)
      capturedController!.onPullDelta(500.0);
      await tester.pump();
      expect(capturedController!.dragOffsetY, 500.0);

      // 2. Drag on scrim upward by 10px (without lifting pointer)
      final gesture = await tester.startGesture(const Offset(200, 200));
      await gesture.moveBy(const Offset(0, -10));
      await tester.pump();

      expect(capturedController!.dragOffsetY, 490.0);

      // 3. Release pointer: because the last movement was UPWARD, it expands to 0.0!
      await gesture.up();
      await tester.pumpAndSettle();

      expect(capturedController!.dragOffsetY, 0.0);
      expect(capturedController!.isDismissing, isFalse);
    });

    testWidgets(
        'dragging down and releasing with downward motion collapses the sheet',
        (tester) async {
      PullToDismissController? capturedController;

      await tester.pumpWidget(
        MaterialApp(
          home: PullToDismissScaffold(
            builder: (context, controller) {
              capturedController = controller;
              return const SizedBox.expand(
                child: Text('PlayerSheetContent'),
              );
            },
          ),
        ),
      );

      // Pull down 100px
      capturedController!.onPullDelta(100.0);
      await tester.pump();

      // Drag down by 20px on scrim
      final gesture = await tester.startGesture(const Offset(200, 50));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();

      expect(capturedController!.dragOffsetY, 120.0);

      // Release: downward motion collapses and dismisses!
      await gesture.up();
      await tester.pumpAndSettle();

      expect(capturedController!.isDismissing, isTrue);
    });

    testWidgets(
        'dragging down sheet then dragging back up near top settles cleanly to 0 without dipping down',
        (tester) async {
      PullToDismissController? capturedController;
      final key = GlobalKey<PeekScrollViewState>();

      await tester.pumpWidget(
        MaterialApp(
          home: PullToDismissScaffold(
            builder: (context, controller) {
              capturedController = controller;
              return PeekScrollView(
                key: key,
                dismissController: controller,
                header: const Text('Header'),
                mainContent: const SizedBox(
                  height: 400,
                  child: Text('MainContent'),
                ),
                peekingCard: const SizedBox(
                  height: 100,
                  child: Text('PeekingCard'),
                ),
                expandedCards: const [
                  SizedBox(height: 600, child: Text('Card1')),
                ],
              );
            },
          ),
        ),
      );

      // Start drag at center of MainContent
      final gesture = await tester.startGesture(tester.getCenter(find.text('MainContent')));
      // Drag down by 200px
      await gesture.moveBy(const Offset(0, 200));
      await tester.pump();
      expect(capturedController!.dragOffsetY, 200.0);

      // Drag back up by 190px (dragOffsetY becomes 10px)
      await gesture.moveBy(const Offset(0, -190));
      await tester.pump();
      expect(capturedController!.dragOffsetY, 10.0);

      // Release finger
      await gesture.up();
      // Pump one frame - must decrease smoothly towards 0.0, never dip down
      await tester.pump(const Duration(milliseconds: 16));
      expect(capturedController!.dragOffsetY, lessThanOrEqualTo(10.0));

      await tester.pumpAndSettle();
      expect(capturedController!.dragOffsetY, 0.0);
      expect(capturedController!.isDismissing, isFalse);
    });
  });
}
