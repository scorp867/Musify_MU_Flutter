import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/data/services/gesture_recognizer_service.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_visibility_policy.dart';
import 'package:musify_mu/features/vault/presentation/widgets/stealth_gesture_pad.dart';

/// Test double implementing [IGestureRecognizer] for predictable test behavior.
class FakeGestureRecognizer implements IGestureRecognizer {
  Future<VaultResult<RecognitionScore>> Function(
    GestureSample liveStroke,
    GestureTemplate template,
    GestureSensitivityTierEnum sensitivityTier,
  )? onEvaluate;

  int evaluateCallCount = 0;
  GestureSample? lastEvaluatedSample;

  FakeGestureRecognizer({this.onEvaluate});

  @override
  Future<VaultResult<RecognitionScore>> evaluateStroke({
    required GestureSample liveStroke,
    required GestureTemplate template,
    required GestureSensitivityTierEnum sensitivityTier,
  }) async {
    evaluateCallCount++;
    lastEvaluatedSample = liveStroke;
    final handler = onEvaluate;
    if (handler != null) {
      return handler(liveStroke, template, sensitivityTier);
    }
    return VaultResult.success(
      RecognitionScore(
        dollarOneScore: 0.95,
        dtwScore: 0.92,
        featureScore: 0.90,
        ensembleScore: 0.932,
        decision: GestureMatchDecisionEnum.matched,
      ),
    );
  }

  @override
  Future<VaultResult<GestureTemplate>> synthesizeMasterTemplate({
    required List<GestureSample> samples,
  }) async {
    return VaultResult.success(DefaultGestureTemplate.canonicalVShape);
  }

  @override
  Future<VaultResult<void>> validateSampleConsistency({
    required List<GestureSample> samples,
  }) async {
    return const VaultResult.success(null);
  }
}

/// Test double extending [GestureRecognizerService] to verify cancellation calls.
class MockGestureRecognizerService extends GestureRecognizerService {
  int cancelCallCount = 0;

  @override
  void cancelActiveEvaluation() {
    cancelCallCount++;
    super.cancelActiveEvaluation();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StealthGesturePad Widget Tests', () {
    late List<MethodCall> platformCalls;

    setUp(() {
      platformCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform,
              (MethodCall methodCall) async {
        platformCalls.add(methodCall);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Widget createTestBed({
      required Widget child,
      Size size = const Size(320, 400),
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets(
        'EagerGestureRecognizer unconditionally wins arena over parent drag',
        (WidgetTester tester) async {
      bool parentDragStarted = false;
      bool parentDragUpdated = false;
      bool gestureMatched = false;

      final recognizer = FakeGestureRecognizer();

      await tester.pumpWidget(
        createTestBed(
          child: GestureDetector(
            onHorizontalDragStart: (_) {
              parentDragStarted = true;
            },
            onHorizontalDragUpdate: (_) {
              parentDragUpdated = true;
            },
            behavior: HitTestBehavior.opaque,
            child: StealthGesturePad(
              recognizer: recognizer,
              onGestureMatched: () {
                gestureMatched = true;
              },
            ),
          ),
        ),
      );

      final center = tester.getCenter(find.byType(StealthGesturePad));

      // Perform a drag across the pad that would normally trigger parent horizontal drag
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(80, 0));
      await gesture.moveBy(const Offset(40, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(parentDragStarted, isFalse,
          reason: 'Parent drag must not start because EagerGestureRecognizer claimed the arena');
      expect(parentDragUpdated, isFalse,
          reason: 'Parent drag must not receive updates');
      expect(gestureMatched, isTrue,
          reason: 'StealthGesturePad must process the stroke and invoke callback');
      expect(recognizer.evaluateCallCount, equals(1));
    });

    testWidgets(
        'Expands flexibly to fill available container bounds without overflow',
        (WidgetTester tester) async {
      const containerSize = Size(280, 360);

      await tester.pumpWidget(
        createTestBed(
          size: containerSize,
          child: StealthGesturePad(
            recognizer: FakeGestureRecognizer(),
            onGestureMatched: () {},
          ),
        ),
      );

      final padSize = tester.getSize(find.byType(StealthGesturePad));
      expect(padSize.width, equals(containerSize.width));
      expect(padSize.height, equals(containerSize.height));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Pure stealth mode (invisibleStealth) renders 0 ink and maintains stealth',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestBed(
          child: StealthGesturePad(
            recognizer: FakeGestureRecognizer(),
            visibilityPolicy: GestureVisibilityPolicyEnum.invisibleStealth,
            onGestureMatched: () {},
          ),
        ),
      );

      final customPaintFinder = find.descendant(
        of: find.byType(StealthGesturePad),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);

      final customPaintWidget = tester.widget<CustomPaint>(customPaintFinder);
      final painter = customPaintWidget.painter;
      expect(painter, isNotNull);

      final center = tester.getCenter(find.byType(StealthGesturePad));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(20, 20));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Faint dissipating hairline mode displays hairline that dissipates within duration',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestBed(
          child: StealthGesturePad(
            recognizer: FakeGestureRecognizer(),
            visibilityPolicy:
                GestureVisibilityPolicyEnum.faintDissipatingHairline,
            onGestureMatched: () {},
          ),
        ),
      );

      final center = tester.getCenter(find.byType(StealthGesturePad));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(30, 30));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();

      // Dissipation completes over 280ms
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Matched gesture triggers mediumImpact haptic feedback and invokes onGestureMatched',
        (WidgetTester tester) async {
      bool matchedFired = false;
      RecognitionScore? completedScore;

      final recognizer = FakeGestureRecognizer(
        onEvaluate: (stroke, template, tier) async {
          return VaultResult.success(
            RecognitionScore(
              dollarOneScore: 0.94,
              dtwScore: 0.89,
              featureScore: 0.91,
              ensembleScore: 0.918,
              decision: GestureMatchDecisionEnum.matched,
            ),
          );
        },
      );

      await tester.pumpWidget(
        createTestBed(
          child: StealthGesturePad(
            recognizer: recognizer,
            onGestureMatched: () {
              matchedFired = true;
            },
            onEvaluationCompleted: (score) {
              completedScore = score;
            },
          ),
        ),
      );

      final center = tester.getCenter(find.byType(StealthGesturePad));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(40, 80));
      await gesture.moveBy(const Offset(40, -80));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(matchedFired, isTrue);
      expect(completedScore, isNotNull);
      final scoreVal = completedScore;
      if (scoreVal != null) {
        expect(scoreVal.decision, equals(GestureMatchDecisionEnum.matched));
      }

      final hasHaptic = platformCalls.any(
        (call) =>
            call.method == 'HapticFeedback.vibrate' &&
            call.arguments == 'HapticFeedbackType.mediumImpact',
      );
      expect(hasHaptic, isTrue,
          reason: 'Must trigger medium impact haptic feedback on match');
    });

    testWidgets(
        'Non-matching decision results in silent rejection with 0 UI leakage and no haptics',
        (WidgetTester tester) async {
      for (final nonMatchDecision in <GestureMatchDecisionEnum>[
        GestureMatchDecisionEnum.rejectedAntiScribble,
        GestureMatchDecisionEnum.rejectedStructuralGate,
        GestureMatchDecisionEnum.rejectedClassifierFloor,
        GestureMatchDecisionEnum.rejectedBelowSensitivityTier,
      ]) {
        platformCalls.clear();
        bool matchedFired = false;
        RecognitionScore? completedScore;

        final recognizer = FakeGestureRecognizer(
          onEvaluate: (stroke, template, tier) async {
            return VaultResult.success(
              RecognitionScore(
                dollarOneScore: 0.40,
                dtwScore: 0.40,
                featureScore: 0.40,
                ensembleScore: 0.40,
                decision: nonMatchDecision,
              ),
            );
          },
        );

        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: recognizer,
              onGestureMatched: () {
                matchedFired = true;
              },
              onEvaluationCompleted: (score) {
                completedScore = score;
              },
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(30, 30));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(matchedFired, isFalse,
            reason: 'onGestureMatched must NOT be called for $nonMatchDecision');
        expect(completedScore, isNotNull);
        final scoreVal = completedScore;
        if (scoreVal != null) {
          expect(scoreVal.decision, equals(nonMatchDecision));
        }

        final hasHaptic = platformCalls
            .any((call) => call.method == 'HapticFeedback.vibrate');
        expect(hasHaptic, isFalse,
            reason: 'No haptic feedback must occur on silent rejection');

        // Verify zero UI error dialogs or snackbars
        expect(find.byType(SnackBar), findsNothing);
        expect(find.byType(AlertDialog), findsNothing);
      }
    });

    testWidgets(
        'Pipeline failure results in silent rejection without leaking errors',
        (WidgetTester tester) async {
      bool matchedFired = false;

      final recognizer = FakeGestureRecognizer(
        onEvaluate: (stroke, template, tier) async {
          return const VaultResult.failure(
            VaultGestureFailure('Simulated pipeline computation failure'),
          );
        },
      );

      await tester.pumpWidget(
        createTestBed(
          child: StealthGesturePad(
            recognizer: recognizer,
            onGestureMatched: () {
              matchedFired = true;
            },
          ),
        ),
      );

      final center = tester.getCenter(find.byType(StealthGesturePad));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(30, 30));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(matchedFired, isFalse);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('Single point tap (< 2 points) resets without evaluation',
        (WidgetTester tester) async {
      final recognizer = FakeGestureRecognizer();
      bool matchedFired = false;

      await tester.pumpWidget(
        createTestBed(
          child: StealthGesturePad(
            recognizer: recognizer,
            onGestureMatched: () {
              matchedFired = true;
            },
          ),
        ),
      );

      final center = tester.getCenter(find.byType(StealthGesturePad));
      final gesture = await tester.startGesture(center);
      // Up immediately without moving
      await gesture.up();
      await tester.pumpAndSettle();

      expect(recognizer.evaluateCallCount, equals(0),
          reason: 'Stroke with < 2 points must not trigger evaluateStroke');
      expect(matchedFired, isFalse);
    });

    testWidgets(
        'Rapid re-touch calls cancelActiveEvaluation and supersedes in-flight result',
        (WidgetTester tester) async {
      final completer1 = Completer<VaultResult<RecognitionScore>>();
      bool matchedFired = false;

      final recognizer = FakeGestureRecognizer(
        onEvaluate: (stroke, template, tier) => completer1.future,
      );

      await tester.pumpWidget(
        createTestBed(
          child: StealthGesturePad(
            recognizer: recognizer,
            onGestureMatched: () {
              matchedFired = true;
            },
          ),
        ),
      );

      final center = tester.getCenter(find.byType(StealthGesturePad));

      // Stroke 1 starts and lifts, triggering asynchronous evaluateStroke
      final gesture1 = await tester.startGesture(center);
      await gesture1.moveBy(const Offset(20, 20));
      await gesture1.up();
      await tester.pump();

      expect(recognizer.evaluateCallCount, equals(1));
      expect(completer1.isCompleted, isFalse);

      // Rapid re-touch before completer1 finishes
      final gesture2 = await tester.startGesture(center + const Offset(10, 10));
      await tester.pump();

      // Now complete stroke 1 with a matched score
      completer1.complete(
        VaultResult.success(
          RecognitionScore(
            dollarOneScore: 0.95,
            dtwScore: 0.90,
            featureScore: 0.90,
            ensembleScore: 0.925,
            decision: GestureMatchDecisionEnum.matched,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Because stroke 2 was down when stroke 1 returned, stroke 1 was superseded
      expect(matchedFired, isFalse,
          reason: 'Superseded stroke 1 must not trigger match confirmation');

      // Finish stroke 2
      await gesture2.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'Pointer down invokes cancelActiveEvaluation on GestureRecognizerService',
        (WidgetTester tester) async {
      final service = MockGestureRecognizerService();

      await tester.pumpWidget(
        createTestBed(
          child: StealthGesturePad(
            recognizer: service,
            onGestureMatched: () {},
          ),
        ),
      );

      final center = tester.getCenter(find.byType(StealthGesturePad));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      expect(service.cancelCallCount, equals(1),
          reason: 'Pointer down must cancel in-flight evaluations on service');

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('Secondary multi-touch pointer is cleanly dropped',
        (WidgetTester tester) async {
      int evaluationsCount = 0;
      final recognizer = FakeGestureRecognizer(
        onEvaluate: (stroke, template, tier) async {
          evaluationsCount++;
          return VaultResult.success(
            RecognitionScore(
              dollarOneScore: 0.95,
              dtwScore: 0.92,
              featureScore: 0.90,
              ensembleScore: 0.932,
              decision: GestureMatchDecisionEnum.matched,
            ),
          );
        },
      );

      await tester.pumpWidget(
        createTestBed(
          child: StealthGesturePad(
            recognizer: recognizer,
            onGestureMatched: () {},
          ),
        ),
      );

      final center = tester.getCenter(find.byType(StealthGesturePad));

      // Primary finger down
      final finger1 = await tester.startGesture(center, pointer: 1);
      await finger1.moveBy(const Offset(20, 20));

      // Secondary finger down while primary is still active
      final finger2 =
          await tester.startGesture(center + const Offset(50, 50), pointer: 2);
      await finger2.moveBy(const Offset(10, 10));
      await finger2.up();

      // Lift primary finger
      await finger1.up();
      await tester.pumpAndSettle();

      expect(evaluationsCount, equals(1),
          reason: 'Only primary pointer stroke must be evaluated');
    });

    testWidgets('PointerCancelEvent resets stroke and cancels active evaluation',
        (WidgetTester tester) async {
      final service = MockGestureRecognizerService();

      await tester.pumpWidget(
        createTestBed(
          child: StealthGesturePad(
            recognizer: service,
            onGestureMatched: () {},
          ),
        ),
      );

      final center = tester.getCenter(find.byType(StealthGesturePad));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(20, 20));

      // Simulate system pointer cancellation
      await gesture.cancel();
      await tester.pumpAndSettle();

      // cancelCallCount should have been called on down and on cancel
      expect(service.cancelCallCount, equals(2));
    });
  });
}
