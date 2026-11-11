import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/data/services/gesture_recognizer_service.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_visibility_policy.dart';
import 'package:musify_mu/features/vault/presentation/widgets/stealth_gesture_pad.dart';

/// Test double implementing [IGestureRecognizer] for deterministic adversarial tests.
class AdversarialFakeGestureRecognizer implements IGestureRecognizer {
  Future<VaultResult<RecognitionScore>> Function(
    GestureSample liveStroke,
    GestureTemplate template,
    GestureSensitivityTierEnum sensitivityTier,
  )? onEvaluate;

  int evaluateCallCount = 0;
  final List<GestureSample> evaluatedSamples = <GestureSample>[];

  AdversarialFakeGestureRecognizer({this.onEvaluate});

  @override
  Future<VaultResult<RecognitionScore>> evaluateStroke({
    required GestureSample liveStroke,
    required GestureTemplate template,
    required GestureSensitivityTierEnum sensitivityTier,
  }) async {
    evaluateCallCount++;
    evaluatedSamples.add(liveStroke);
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

/// Test double extending [GestureRecognizerService] to track cancellation invocations.
class AdversarialMockGestureRecognizerService extends GestureRecognizerService {
  int cancelCallCount = 0;

  @override
  void cancelActiveEvaluation() {
    cancelCallCount++;
    super.cancelActiveEvaluation();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StealthGesturePad Adversarial & Empirical Stress Suite', () {
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
      Size size = const Size(320, 480),
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

    bool hasVibratedHaptic() {
      return platformCalls.any(
        (call) =>
            call.method == 'HapticFeedback.vibrate' &&
            call.arguments == 'HapticFeedbackType.mediumImpact',
      );
    }

    group('1. Rapid Multi-Pointer Stress & Concurrency Isolation', () {
      testWidgets(
          'Simultaneous multi-pointer deluge locks to primary pointer and drops secondary touches',
          (WidgetTester tester) async {
        int matchedCount = 0;
        final recognizer = AdversarialFakeGestureRecognizer();

        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: recognizer,
              onGestureMatched: () {
                matchedCount++;
              },
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));

        // Primary pointer touches down
        final pointer1 = await tester.startGesture(center, pointer: 1);
        await tester.pump();

        // 9 secondary pointers touch down concurrently while pointer 1 is active
        final secondaryPointers = <TestGesture>[];
        for (int p = 2; p <= 10; p++) {
          final extraPointer = await tester.startGesture(
            center + Offset(p * 5.0, p * 5.0),
            pointer: p,
          );
          secondaryPointers.add(extraPointer);
        }
        await tester.pump();

        // Secondary pointers send move and up events
        for (int i = 0; i < secondaryPointers.length; i++) {
          final extraPointer = secondaryPointers[i];
          await extraPointer.moveBy(const Offset(10, 10));
          await extraPointer.up();
        }
        await tester.pump();

        // At this point, no evaluation must have occurred because pointer 1 is still down
        expect(recognizer.evaluateCallCount, equals(0),
            reason: 'Secondary pointer lifts must never trigger evaluation');

        // Primary pointer executes valid stroke trajectory
        await pointer1.moveBy(const Offset(30, 60));
        await pointer1.moveBy(const Offset(30, -60));
        await pointer1.up();
        await tester.pumpAndSettle();

        expect(recognizer.evaluateCallCount, equals(1),
            reason: 'Only primary pointer 1 must trigger evaluation');
        expect(matchedCount, equals(1),
            reason: 'Only primary pointer 1 must trigger gesture matched');
      });

      testWidgets(
          'Rapid pointer handoff supersedes in-flight isolate evaluation cleanly',
          (WidgetTester tester) async {
        final completer1 = Completer<VaultResult<RecognitionScore>>();
        int matchedCount = 0;
        int callCount = 0;

        final recognizer = AdversarialFakeGestureRecognizer(
          onEvaluate: (stroke, template, tier) {
            callCount++;
            if (callCount == 1) {
              return completer1.future;
            }
            return Future<VaultResult<RecognitionScore>>.value(
              VaultResult.success(
                RecognitionScore(
                  dollarOneScore: 0.96,
                  dtwScore: 0.94,
                  featureScore: 0.92,
                  ensembleScore: 0.945,
                  decision: GestureMatchDecisionEnum.matched,
                ),
              ),
            );
          },
        );

        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: recognizer,
              onGestureMatched: () {
                matchedCount++;
              },
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));

        // Stroke 1: Pointer 1 draws and lifts
        final pointer1 = await tester.startGesture(center, pointer: 1);
        await pointer1.moveBy(const Offset(40, 80));
        await pointer1.up();
        await tester.pump();

        expect(recognizer.evaluateCallCount, equals(1));
        expect(completer1.isCompleted, isFalse);

        // Immediate subsequent touch: Pointer 2 touches down before stroke 1 finishes
        final pointer2 =
            await tester.startGesture(center + const Offset(10, 10), pointer: 2);
        await tester.pump();

        // Stroke 1 completes with a matched score while pointer 2 is active
        completer1.complete(
          VaultResult.success(
            RecognitionScore(
              dollarOneScore: 0.95,
              dtwScore: 0.91,
              featureScore: 0.90,
              ensembleScore: 0.925,
              decision: GestureMatchDecisionEnum.matched,
            ),
          ),
        );
        await tester.pump();

        // Stroke 1 must have been superseded and discarded
        expect(matchedCount, equals(0),
            reason: 'Superseded stroke 1 must not trigger onGestureMatched');

        // Stroke 2 completes valid trajectory and lifts
        await pointer2.moveBy(const Offset(40, 80));
        await pointer2.moveBy(const Offset(40, -80));
        await pointer2.up();
        await tester.pumpAndSettle();

        expect(recognizer.evaluateCallCount, equals(2));
        expect(matchedCount, equals(1),
            reason: 'Active stroke 2 must trigger onGestureMatched');
      });

      testWidgets(
          'Rapid interleaved pointer storm preserves epoch sequencing and drops stale results',
          (WidgetTester tester) async {
        final completers = <Completer<VaultResult<RecognitionScore>>>[
          Completer<VaultResult<RecognitionScore>>(),
          Completer<VaultResult<RecognitionScore>>(),
          Completer<VaultResult<RecognitionScore>>(),
        ];
        int matchedCount = 0;
        int callCount = 0;

        final recognizer = AdversarialFakeGestureRecognizer(
          onEvaluate: (stroke, template, tier) {
            final int index = callCount;
            callCount++;
            if (index < completers.length) {
              return completers[index].future;
            }
            return Future<VaultResult<RecognitionScore>>.value(
              VaultResult.success(
                RecognitionScore(
                  dollarOneScore: 0.95,
                  dtwScore: 0.92,
                  featureScore: 0.90,
                  ensembleScore: 0.932,
                  decision: GestureMatchDecisionEnum.matched,
                ),
              ),
            );
          },
        );

        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: recognizer,
              onGestureMatched: () {
                matchedCount++;
              },
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));

        // Dispatch 3 rapid successive strokes
        for (int p = 1; p <= 3; p++) {
          final gesture =
              await tester.startGesture(center + Offset(p * 2.0, p * 2.0), pointer: p);
          await gesture.moveBy(const Offset(25, 25));
          await gesture.up();
          await tester.pump();
        }

        expect(recognizer.evaluateCallCount, equals(3));

        // Complete stroke 1 and stroke 2 (both superseded)
        for (int i = 0; i < 2; i++) {
          completers[i].complete(
            VaultResult.success(
              RecognitionScore(
                dollarOneScore: 0.95,
                dtwScore: 0.92,
                featureScore: 0.90,
                ensembleScore: 0.932,
                decision: GestureMatchDecisionEnum.matched,
              ),
            ),
          );
        }
        await tester.pump();

        expect(matchedCount, equals(0),
            reason: 'Superseded strokes 1 and 2 must not fire match callback');

        // Complete final stroke 3 (not superseded)
        completers[2].complete(
          VaultResult.success(
            RecognitionScore(
              dollarOneScore: 0.95,
              dtwScore: 0.92,
              featureScore: 0.90,
              ensembleScore: 0.932,
              decision: GestureMatchDecisionEnum.matched,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(matchedCount, equals(1),
            reason: 'Final active stroke 3 must fire match callback exactly once');
      });

      testWidgets(
          'Real GestureRecognizerService background isolate evaluation supersedes on new touch',
          (WidgetTester tester) async {
        final realService = GestureRecognizerService();
        int matchedCount = 0;

        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: realService,
              onGestureMatched: () {
                matchedCount++;
              },
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));

        // Stroke 1: Draw canonical V shape and release
        final gesture1 = await tester.startGesture(center, pointer: 1);
        await gesture1.moveBy(const Offset(50, 100));
        await gesture1.moveBy(const Offset(50, -100));
        await gesture1.up();
        await tester.pump();

        final initialEpoch = realService.currentEpoch;

        // Immediate new touch down within same event turn
        final gesture2 =
            await tester.startGesture(center + const Offset(10, 10), pointer: 2);
        await tester.pump();

        // Epoch must have incremented due to cancellation
        expect(realService.currentEpoch, greaterThan(initialEpoch),
            reason: 'New touch must advance service epoch to cancel isolate');

        await tester.pumpAndSettle();

        // Lift gesture 2 without drawing
        await gesture2.up();
        await tester.pumpAndSettle();

        expect(matchedCount, equals(0),
            reason: 'Superseded stroke 1 must not trigger match');
      });

      testWidgets(
          'Secondary pointer spurious moves and lifts do not corrupt active primary stroke',
          (WidgetTester tester) async {
        int matchedCount = 0;
        final recognizer = AdversarialFakeGestureRecognizer();

        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: recognizer,
              onGestureMatched: () {
                matchedCount++;
              },
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));

        // Primary pointer starts stroke
        final primaryPointer = await tester.startGesture(center, pointer: 1);
        await primaryPointer.moveBy(const Offset(10, 20));

        // Spurious secondary pointer attempts touch down, movement, and up
        final secondaryPointer =
            await tester.startGesture(center + const Offset(100, 100), pointer: 2);
        await secondaryPointer.moveBy(const Offset(20, 20));
        await secondaryPointer.up();
        await tester.pump();

        // Primary pointer continues stroke
        await primaryPointer.moveBy(const Offset(20, 40));
        await primaryPointer.up();
        await tester.pumpAndSettle();

        expect(recognizer.evaluateCallCount, equals(1));
        expect(matchedCount, equals(1));

        final evaluated = recognizer.evaluatedSamples.first;
        expect(evaluated.points.length, greaterThanOrEqualTo(3),
            reason: 'Primary pointer must retain all recorded points');
      });
    });

    group('2. Pointer Cancel Handling & Interruption Recovery', () {
      testWidgets(
          'Mid-stroke PointerCancelEvent clears points, stops ticker, and aborts evaluation',
          (WidgetTester tester) async {
        final mockService = AdversarialMockGestureRecognizerService();
        int matchedCount = 0;

        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: mockService,
              visibilityPolicy:
                  GestureVisibilityPolicyEnum.faintDissipatingHairline,
              onGestureMatched: () {
                matchedCount++;
              },
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));
        final gesture = await tester.startGesture(center, pointer: 1);

        // Move several times to accumulate points
        for (int i = 0; i < 10; i++) {
          await gesture.moveBy(const Offset(5, 5));
          await tester.pump(const Duration(milliseconds: 10));
        }

        // Ticker must be running
        expect(tester.hasRunningAnimations, isTrue,
            reason: 'Hairline ticker must be running during active drawing');

        // System dispatches pointer cancellation
        await gesture.cancel();
        await tester.pump();

        // Cancellation must stop ticker, call cancelActiveEvaluation, and reset points
        expect(tester.hasRunningAnimations, isFalse,
            reason: 'Cancellation must immediately halt hairline ticker');
        expect(mockService.cancelCallCount, equals(2),
            reason: 'cancelActiveEvaluation called on down and on cancel');
        expect(matchedCount, equals(0));

        await tester.pumpAndSettle();
      });

      testWidgets(
          'Secondary pointer cancellation leaves active primary stroke unaffected',
          (WidgetTester tester) async {
        int matchedCount = 0;
        final recognizer = AdversarialFakeGestureRecognizer();

        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: recognizer,
              onGestureMatched: () {
                matchedCount++;
              },
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));

        // Primary pointer starts stroke
        final primary = await tester.startGesture(center, pointer: 1);
        await primary.moveBy(const Offset(30, 30));

        // Secondary pointer touches down and is immediately cancelled by OS
        final secondary =
            await tester.startGesture(center + const Offset(50, 50), pointer: 2);
        await secondary.cancel();
        await tester.pump();

        // Primary pointer must continue drawing uninterrupted
        await primary.moveBy(const Offset(30, -30));
        await primary.up();
        await tester.pumpAndSettle();

        expect(recognizer.evaluateCallCount, equals(1),
            reason: 'Primary pointer must complete and evaluate normally');
        expect(matchedCount, equals(1));
      });

      testWidgets(
          'Rapid Cancel -> Down -> Up re-engagement cleanly evaluates new gesture',
          (WidgetTester tester) async {
        int matchedCount = 0;
        final recognizer = AdversarialFakeGestureRecognizer();

        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: recognizer,
              onGestureMatched: () {
                matchedCount++;
              },
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));

        // Stroke 1 starts and gets cancelled
        final gesture1 = await tester.startGesture(center, pointer: 1);
        await gesture1.moveBy(const Offset(20, 20));
        await gesture1.cancel();
        await tester.pump();

        expect(recognizer.evaluateCallCount, equals(0));

        // Immediately start stroke 2
        final gesture2 =
            await tester.startGesture(center + const Offset(5, 5), pointer: 2);
        await gesture2.moveBy(const Offset(40, 80));
        await gesture2.moveBy(const Offset(40, -80));
        await gesture2.up();
        await tester.pumpAndSettle();

        expect(recognizer.evaluateCallCount, equals(1),
            reason: 'Stroke 2 must evaluate cleanly after stroke 1 cancellation');
        expect(matchedCount, equals(1));
      });

      testWidgets('Orphaned PointerCancelEvent when idle does not throw or corrupt state',
          (WidgetTester tester) async {
        final recognizer = AdversarialFakeGestureRecognizer();

        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: recognizer,
              onGestureMatched: () {},
            ),
          ),
        );

        // Find the leaf Listener inside StealthGesturePad
        final listenerWidgets = tester.widgetList<Listener>(
          find.descendant(
            of: find.byType(StealthGesturePad),
            matching: find.byType(Listener),
          ),
        );
        expect(listenerWidgets.isNotEmpty, isTrue);

        final targetListener = listenerWidgets.last;
        final onCancel = targetListener.onPointerCancel;
        expect(onCancel, isNotNull);

        if (onCancel case final handler?) {
          // Trigger cancel with unmonitored pointer ID
          handler(const PointerCancelEvent(pointer: 99));
          await tester.pump();
        }

        expect(tester.takeException(), isNull);
        expect(recognizer.evaluateCallCount, equals(0));
      });
    });

    group('3. Micro-Taps, Stationary Touches & Sub-Deadband Stress', () {
      testWidgets('Stationary single-point tap (0px displacement) is dropped silently',
          (WidgetTester tester) async {
        int matchedCount = 0;
        final recognizer = AdversarialFakeGestureRecognizer();

        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: recognizer,
              onGestureMatched: () {
                matchedCount++;
              },
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));
        final tapGesture = await tester.startGesture(center);
        // Up at exact same position without move
        await tapGesture.up();
        await tester.pumpAndSettle();

        expect(recognizer.evaluateCallCount, equals(0),
            reason: 'Zero-displacement tap must not call evaluateStroke');
        expect(matchedCount, equals(0));
        expect(hasVibratedHaptic(), isFalse,
            reason: 'Zero haptic calls on dropped tap');
      });

      testWidgets('Stationary touch with sub-pixel micro-jitter is dropped silently',
          (WidgetTester tester) async {
        int matchedCount = 0;
        final recognizer = AdversarialFakeGestureRecognizer();

        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: recognizer,
              onGestureMatched: () {
                matchedCount++;
              },
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));
        final gesture = await tester.startGesture(center);

        // Send 5 move events with exact same coordinates (tremor without displacement)
        for (int i = 0; i < 5; i++) {
          await gesture.moveTo(center);
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await tester.pumpAndSettle();

        expect(recognizer.evaluateCallCount, equals(0),
            reason: 'Stationary tremor must not duplicate points or evaluate');
        expect(matchedCount, equals(0));
      });

      testWidgets('Deluge of 15 rapid micro-taps across canvas are all silently dropped',
          (WidgetTester tester) async {
        final recognizer = AdversarialFakeGestureRecognizer();
        int matchedCount = 0;

        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: recognizer,
              onGestureMatched: () {
                matchedCount++;
              },
            ),
          ),
        );

        final topLeft = tester.getTopLeft(find.byType(StealthGesturePad));

        // Tap 15 different spots rapidly
        for (int i = 0; i < 15; i++) {
          final pos = topLeft + Offset(20.0 + (i * 15.0), 30.0 + (i * 20.0));
          final tap = await tester.startGesture(pos, pointer: i + 1);
          await tap.up();
          await tester.pump(const Duration(milliseconds: 10));
        }
        await tester.pumpAndSettle();

        expect(recognizer.evaluateCallCount, equals(0),
            reason: 'All 15 micro-taps must be cleanly dropped without evaluation');
        expect(matchedCount, equals(0));
        expect(hasVibratedHaptic(), isFalse);
      });

      testWidgets(
          'Sub-deadband micro-stroke (< 2.5px displacement) is dropped before evaluateStroke',
          (WidgetTester tester) async {
        final recognizer = AdversarialFakeGestureRecognizer();
        int matchedCount = 0;

        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: recognizer,
              onGestureMatched: () {
                matchedCount++;
              },
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));

        // Stroke with only 1.0px displacement (sub-deadband)
        final microGesture = await tester.startGesture(center);
        await microGesture.moveBy(const Offset(1.0, 0.0));
        await microGesture.up();
        await tester.pumpAndSettle();

        expect(recognizer.evaluateCallCount, equals(0),
            reason: 'Sub-deadband touch under 2.5px must be dropped without evaluateStroke');
        expect(matchedCount, equals(0));
      });
    });

    group('4. Ink Dissipation Timing, Animation Controller & Memory Lifecycle', () {
      testWidgets(
          'Pure stealth mode (invisibleStealth) never activates animation controller ticker',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: AdversarialFakeGestureRecognizer(),
              visibilityPolicy: GestureVisibilityPolicyEnum.invisibleStealth,
              onGestureMatched: () {},
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));

        // Before gesture
        expect(tester.hasRunningAnimations, isFalse);

        // During gesture
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(20, 20));
        await tester.pump();

        expect(tester.hasRunningAnimations, isFalse,
            reason: 'invisibleStealth mode must NEVER start animation ticker');

        await gesture.up();
        await tester.pumpAndSettle();

        expect(tester.hasRunningAnimations, isFalse);
      });

      testWidgets(
          'Faint dissipating hairline mode activates ticker and halts within 280ms duration',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: AdversarialFakeGestureRecognizer(),
              visibilityPolicy:
                  GestureVisibilityPolicyEnum.faintDissipatingHairline,
              onGestureMatched: () {},
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));

        // Start drawing
        final gesture = await tester.startGesture(center);
        await tester.pump();

        expect(tester.hasRunningAnimations, isTrue,
            reason: 'Hairline mode must activate ticker on pointer down');

        await gesture.moveBy(const Offset(40, 40));
        await gesture.up();
        await tester.pump();

        // Advance 300ms in virtual time (exceeding 280ms dissipation duration)
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.hasRunningAnimations, isFalse,
            reason: 'Ticker must stop automatically once all points dissipate after 280ms');
      });

      testWidgets(
          'Sustained drawing keeps ticker active and purges aged points continuously',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: AdversarialFakeGestureRecognizer(),
              visibilityPolicy:
                  GestureVisibilityPolicyEnum.faintDissipatingHairline,
              onGestureMatched: () {},
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));
        final gesture = await tester.startGesture(center);

        // Draw continuously for 500ms (10 moves spaced 50ms apart)
        for (int i = 0; i < 10; i++) {
          await gesture.moveBy(const Offset(5, 5));
          await tester.pump(const Duration(milliseconds: 50));
          expect(tester.hasRunningAnimations, isTrue);
        }

        // Lift pointer
        await gesture.up();
        await tester.pump();

        // Advance 300ms to allow final tail to dissipate
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.hasRunningAnimations, isFalse,
            reason: 'Ticker must stop after finger lifts and all points dissipate');
      });

      testWidgets('Widget unmount during active hairline animation disposes cleanly',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: AdversarialFakeGestureRecognizer(),
              visibilityPolicy:
                  GestureVisibilityPolicyEnum.faintDissipatingHairline,
              onGestureMatched: () {},
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(30, 30));
        await tester.pump();

        expect(tester.hasRunningAnimations, isTrue);

        // Replace widget tree with empty container while ticker is active
        await tester.pumpWidget(
          createTestBed(child: const SizedBox()),
        );

        // Verify clean disposal with no unhandled ticker leaks
        expect(tester.takeException(), isNull);
        expect(tester.hasRunningAnimations, isFalse);
      });
    });

    group('5. Gesture Arena Multi-Competitor Stress', () {
      testWidgets(
          'Unconditionally defeats multi-gesture parent trap (HorizontalDrag, VerticalDrag, Tap)',
          (WidgetTester tester) async {
        bool parentHorizontalStarted = false;
        bool parentVerticalStarted = false;
        bool parentTapTriggered = false;
        bool padMatched = false;

        final recognizer = AdversarialFakeGestureRecognizer();

        await tester.pumpWidget(
          createTestBed(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => parentTapTriggered = true,
              onHorizontalDragStart: (_) => parentHorizontalStarted = true,
              onVerticalDragStart: (_) => parentVerticalStarted = true,
              child: StealthGesturePad(
                recognizer: recognizer,
                onGestureMatched: () {
                  padMatched = true;
                },
              ),
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));

        // Diagonal drag across pad
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(60, 60));
        await gesture.moveBy(const Offset(60, -60));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(parentHorizontalStarted, isFalse,
            reason: 'Parent horizontal drag must be defeated by EagerGestureRecognizer');
        expect(parentVerticalStarted, isFalse,
            reason: 'Parent vertical drag must be defeated by EagerGestureRecognizer');
        expect(parentTapTriggered, isFalse,
            reason: 'Parent tap must be defeated by EagerGestureRecognizer');
        expect(padMatched, isTrue,
            reason: 'StealthGesturePad must process the gesture and match');
      });

      testWidgets('Embedded in Scrollable claims pointer without scrolling parent',
          (WidgetTester tester) async {
        final scrollController = ScrollController();
        bool padMatched = false;

        await tester.pumpWidget(
          createTestBed(
            child: SingleChildScrollView(
              controller: scrollController,
              child: SizedBox(
                height: 1000,
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 100),
                    SizedBox(
                      height: 300,
                      width: 320,
                      child: StealthGesturePad(
                        recognizer: AdversarialFakeGestureRecognizer(),
                        onGestureMatched: () {
                          padMatched = true;
                        },
                      ),
                    ),
                    const SizedBox(height: 600),
                  ],
                ),
              ),
            ),
          ),
        );

        final padCenter = tester.getCenter(find.byType(StealthGesturePad));

        // Drag vertically over pad
        final gesture = await tester.startGesture(padCenter);
        await gesture.moveBy(const Offset(0, 100));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(scrollController.offset, equals(0.0),
            reason: 'Scrollable must not scroll because pad claimed pointer unconditionally');
        expect(padMatched, isTrue);

        scrollController.dispose();
      });
    });

    group('6. Pipeline & Boundary Exception Fault Tolerance', () {
      testWidgets(
          'Pipeline failure (VaultFailureResult) is rejected silently with zero UI leakage',
          (WidgetTester tester) async {
        bool padMatched = false;
        final recognizer = AdversarialFakeGestureRecognizer(
          onEvaluate: (stroke, template, tier) async {
            return const VaultResult.failure(
              VaultGestureFailure('Pipeline memory allocation limit exceeded'),
            );
          },
        );

        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: recognizer,
              onGestureMatched: () {
                padMatched = true;
              },
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(30, 30));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(padMatched, isFalse);
        expect(hasVibratedHaptic(), isFalse,
            reason: 'No haptics on pipeline failure');
        expect(find.byType(SnackBar), findsNothing);
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets(
          'Widget unmounted during in-flight evaluation gracefully discards result',
          (WidgetTester tester) async {
        final completer = Completer<VaultResult<RecognitionScore>>();
        bool padMatched = false;

        final recognizer = AdversarialFakeGestureRecognizer(
          onEvaluate: (stroke, template, tier) => completer.future,
        );

        await tester.pumpWidget(
          createTestBed(
            child: StealthGesturePad(
              recognizer: recognizer,
              onGestureMatched: () {
                padMatched = true;
              },
            ),
          ),
        );

        final center = tester.getCenter(find.byType(StealthGesturePad));
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(30, 30));
        await gesture.up();
        await tester.pump();

        expect(recognizer.evaluateCallCount, equals(1));

        // Unmount StealthGesturePad before evaluation completes
        await tester.pumpWidget(
          createTestBed(child: const SizedBox()),
        );

        // Complete evaluation with matched score
        completer.complete(
          VaultResult.success(
            RecognitionScore(
              dollarOneScore: 0.95,
              dtwScore: 0.92,
              featureScore: 0.90,
              ensembleScore: 0.932,
              decision: GestureMatchDecisionEnum.matched,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(padMatched, isFalse,
            reason: 'Unmounted pad must not trigger callback');
        expect(hasVibratedHaptic(), isFalse,
            reason: 'Unmounted pad must not trigger haptics');
        expect(tester.takeException(), isNull);
      });
    });

    group('7. Kinematic Gate & Service Pipeline Isolation Stress', () {
      test(
          'GestureRecognizerService silently rejects 2-point sub-deadband stroke via kinematic gate',
          () async {
        final service = GestureRecognizerService();
        final stroke = GestureSample(
          points: <GesturePoint>[
            GesturePoint(x: 160, y: 240, timestampMs: 0),
            GesturePoint(x: 163, y: 243, timestampMs: 16),
          ],
          sampledAtEpochMs: 1000,
          totalLength: 4.24,
        );

        final result = await service.evaluateStroke(
          liveStroke: stroke,
          template: DefaultGestureTemplate.canonicalVShape,
          sensitivityTier: GestureSensitivityTierEnum.balanced84Percent,
        );

        expect(result, isA<VaultSuccess<RecognitionScore>>());
        final score = (result as VaultSuccess<RecognitionScore>).data;
        expect(score.decision,
            equals(GestureMatchDecisionEnum.rejectedAntiScribble));
      });
    });
  });
}
