import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/presentation/widgets/peek_scroll_view.dart';
import 'package:musify_mu/features/player/presentation/widgets/pull_to_dismiss_scaffold.dart';
import 'package:musify_mu/features/player/presentation/widgets/spotify_scroll_physics.dart';

class _FakeDismissController implements PullToDismissController {
  double _dragOffset = 0.0;
  bool _dismissed = false;

  @override
  double get dragOffsetY => _dragOffset;

  @override
  bool get isDismissing => _dismissed;

  @override
  void onPullDelta(double delta) {
    _dragOffset += delta;
  }

  @override
  void onPullEnd(double velocity) {}

  @override
  void dismiss() {
    _dismissed = true;
  }
}

void main() {
  group('AndroidEdgeEffect (AOSP Port Unit Tests)', () {
    test('onPullDistance advances and contracts proportionally', () {
      final effect = AndroidEdgeEffect()..setSize(400, 800);

      expect(effect.isFinished, isTrue);
      expect(effect.distance, 0.0);

      // User pulls into overscroll by 10%
      final consumed1 = effect.onPullDistance(0.10, 0.5);
      expect(consumed1, closeTo(0.10, 0.0001));
      expect(effect.distance, closeTo(0.10, 0.0001));
      expect(effect.state, AndroidEdgeEffect.statePull);
      expect(effect.isFinished, isFalse);

      // User pulls further by 5%
      final consumed2 = effect.onPullDistance(0.05, 0.5);
      expect(consumed2, closeTo(0.05, 0.0001));
      expect(effect.distance, closeTo(0.15, 0.0001));

      // User reverses finger drag by 6% (opposite direction before lifting)
      final consumedReverse = effect.onPullDistance(-0.06, 0.5);
      expect(consumedReverse, closeTo(-0.06, 0.0001));
      expect(effect.distance, closeTo(0.09, 0.0001));
      expect(effect.isFinished, isFalse);

      // User reverses further past origin
      final consumedFullReverse = effect.onPullDistance(-0.15, 0.5);
      expect(consumedFullReverse, closeTo(-0.09, 0.0001)); // Only 0.09 consumed
      expect(effect.distance, 0.0);
      expect(effect.isFinished, isTrue);
    });

    test('onRelease rebounds underdamped spring to zero without hanging or runaway', () {
      final effect = AndroidEdgeEffect()..setSize(400, 800);
      int now = 1000000;

      // Pull to 20% stretch
      effect.onPullDistance(0.20, 0.5, now);
      expect(effect.distance, closeTo(0.20, 0.0001));

      // Release touch
      effect.onRelease(now);
      expect(effect.state, AndroidEdgeEffect.stateRecede);

      // Simulate VSync 60fps frames (16.6ms intervals)
      for (int i = 0; i < 60; i++) {
        now += 16;
        effect.updateSpring(now);
        if (effect.isFinished) break;
      }

      // Must settle completely to 0.0 and finish
      expect(effect.isFinished, isTrue);
      expect(effect.distance, 0.0);
      expect(effect.velocity, 0.0);
    });

    test('onAbsorb absorbs impact velocity and converges to zero', () {
      final effect = AndroidEdgeEffect()..setSize(400, 800);
      int now = 2000000;

      // Absorb fling at 1500 px/s
      effect.onAbsorb(1500, now);
      expect(effect.state, AndroidEdgeEffect.stateRecede);
      expect(effect.velocity, closeTo(1500 * 13.0, 0.0001));

      // Simulate VSync frames
      for (int i = 0; i < 90; i++) {
        now += 16;
        effect.updateSpring(now);
        if (effect.isFinished) break;
      }

      expect(effect.isFinished, isTrue);
      expect(effect.distance, 0.0);
      expect(effect.velocity, 0.0);
    });

    test('dampStretchVector computes correct logarithmic/exponential curve', () {
      final effect = AndroidEdgeEffect();

      expect(effect.dampStretchVector(0.0), 0.0);

      // Value at 0.1 normalized overscroll
      final d1 = effect.dampStretchVector(0.1);
      expect(d1, greaterThan(0.0));
      expect(d1, lessThan(0.1));

      // Preserves sign
      final dNeg = effect.dampStretchVector(-0.1);
      expect(dNeg, closeTo(-d1, 0.00001));
    });
  });

  group('SpotifyStretchController', () {
    testWidgets('computes bidirectional stretch correctly and rebounds to zero',
        (tester) async {
      final vsync = tester;
      final controller = SpotifyStretchController(vsync: vsync);

      expect(controller.overscroll, 0.0);

      // Pull top -> negative overscroll
      controller.pull(-0.1);
      expect(controller.overscroll, lessThan(0.0));

      controller.finish();
      expect(controller.overscroll, 0.0);

      // Pull bottom -> positive overscroll
      controller.pull(0.1);
      expect(controller.overscroll, greaterThan(0.0));

      // Trigger release / spring end
      controller.scrollEnd(0.0);
      await tester.pumpAndSettle();
      expect(controller.overscroll, 0.0);

      controller.dispose();
    });
  });

  group('PeekScrollView', () {
    testWidgets('mounts cleanly without null-check crashes during initial layout',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeekScrollView(
              dismissController: _FakeDismissController(),
              header: const Text('Header'),
              mainContent: const Text('MainContent'),
              peekingCard: const Text('PeekingCard'),
              expandedCards: const [
                Text('ExpandedCard1'),
                Text('ExpandedCard2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Header'), findsOneWidget);
      expect(find.text('MainContent'), findsOneWidget);
      expect(find.text('PeekingCard'), findsOneWidget);
    });

    testWidgets('handles vertical drag gestures without unhandled exceptions',
        (tester) async {
      final controller = _FakeDismissController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeekScrollView(
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
            ),
          ),
        ),
      );

      // Drag up to scroll peeking card into view
      await tester.drag(find.text('MainContent'), const Offset(0, -150));
      await tester.pumpAndSettle();

      // Drag down to scroll back towards top
      await tester.drag(find.text('MainContent'), const Offset(0, 150));
      await tester.pumpAndSettle();

      expect(find.text('Header'), findsOneWidget);
    });

    testWidgets('overscroll at bottom rebounds to 0 after lifting finger in PeekScrollView',
        (tester) async {
      final controller = _FakeDismissController();
      final key = GlobalKey<PeekScrollViewState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeekScrollView(
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
            ),
          ),
        ),
      );

      // Scroll all the way to bottom
      await tester.drag(find.text('MainContent'), const Offset(0, -1000));
      await tester.pumpAndSettle();

      final indicatorState = tester.state<SpotifyStretchOverscrollIndicatorState>(
        find.byType(SpotifyStretchOverscrollIndicator),
      );
      expect(indicatorState.controller.overscroll, 0.0);

      // Drag up past bottom to stretch
      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Card1')));
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();

      expect(indicatorState.controller.overscroll, greaterThan(0.0));

      // Lift finger
      await gesture.up();
      await tester.pump();

      await tester.pumpAndSettle();

      expect(indicatorState.controller.overscroll, 0.0);
    });

    testWidgets(
        'dragging in opposite direction contracts stretch without scrolling content until stretch reaches 0',
        (tester) async {
      final controller = _FakeDismissController();
      final key = GlobalKey<PeekScrollViewState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeekScrollView(
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
            ),
          ),
        ),
      );

      // Scroll all the way to bottom
      await tester.drag(find.text('MainContent'), const Offset(0, -1000));
      await tester.pumpAndSettle();

      final scrollController = key.currentState!.scrollController;
      final maxOffset = scrollController.position.maxScrollExtent;
      expect(scrollController.position.pixels, equals(maxOffset));

      final indicatorState =
          tester.state<SpotifyStretchOverscrollIndicatorState>(
        find.byType(SpotifyStretchOverscrollIndicator),
      );
      expect(indicatorState.controller.overscroll, 0.0);

      // 1. Drag UP past bottom to stretch by 80px:
      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Card1')));
      await gesture.moveBy(const Offset(0, -80));
      await tester.pump();

      final initialStretch = indicatorState.controller.overscroll;
      expect(initialStretch, greaterThan(0.0));
      // Content position MUST remain locked at maxScrollExtent!
      expect(scrollController.position.pixels, equals(maxOffset));

      // 2. Drag DOWN in opposite direction by 40px (partial reversal):
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();

      final contractedStretch = indicatorState.controller.overscroll;
      // Stretch contracted!
      expect(contractedStretch, lessThan(initialStretch));
      expect(contractedStretch, greaterThan(0.0));
      // Content position MUST STILL be locked at maxScrollExtent (zero scroll while contracting)!
      expect(scrollController.position.pixels, equals(maxOffset));

      // 3. Drag DOWN further past original stretch (e.g. 80px more):
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump();

      // Stretch is now fully collapsed to 0:
      expect(indicatorState.controller.overscroll, 0.0);
      // NOW content scrolls back up:
      expect(scrollController.position.pixels, lessThan(maxOffset));

      // Release
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('SpotifyStretchOverscrollIndicator', () {
    testWidgets('renders child and handles scroll notifications smoothly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpotifyStretchOverscrollIndicator(
              axisDirection: AxisDirection.down,
              child: SingleChildScrollView(
                physics: ClampingScrollPhysics(),
                child: SizedBox(height: 1200, child: Text('Scrollable')),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Scrollable'), findsOneWidget);

      // Drag past top to trigger overscroll
      await tester.drag(
        find.text('Scrollable'),
        const Offset(0, 100),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Settle rebound
      await tester.pumpAndSettle();
      expect(find.text('Scrollable'), findsOneWidget);
    });
  });
}
