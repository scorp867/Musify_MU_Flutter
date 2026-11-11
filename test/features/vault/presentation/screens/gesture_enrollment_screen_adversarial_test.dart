import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/application/gesture/gesture_engine_cubit.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/data/services/gesture_recognizer_service.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_screen_privacy_controller.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/policies/screen_security_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';
import 'package:musify_mu/features/vault/presentation/screens/gesture_enrollment_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_auth_screen.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';

class MockMonotonicClock implements IMonotonicClock {
  int timeMs = 1000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class MockScreenPrivacyController implements IScreenPrivacyController {
  ScreenPrivacyStateEnum _state = ScreenPrivacyStateEnum.publicUnrestricted;
  final StreamController<ScreenPrivacyStateEnum> _streamController =
      StreamController<ScreenPrivacyStateEnum>.broadcast();

  int enableCount = 0;
  int disableCount = 0;

  @override
  ScreenPrivacyStateEnum get currentState => _state;

  @override
  Stream<ScreenPrivacyStateEnum> get stateStream => _streamController.stream;

  @override
  Future<void> enableSecureFlag() async {
    enableCount++;
    _state = ScreenPrivacyStateEnum.secureFlagEngaged;
    _streamController.add(_state);
  }

  @override
  Future<void> disableSecureFlag() async {
    disableCount++;
    _state = ScreenPrivacyStateEnum.publicUnrestricted;
    _streamController.add(_state);
  }
}

class ControllableGestureRecognizer implements IGestureRecognizer {
  Future<VaultResult<void>> Function(List<GestureSample> samples)?
      onValidateConsistency;
  Future<VaultResult<GestureTemplate>> Function(List<GestureSample> samples)?
      onSynthesize;
  Future<VaultResult<RecognitionScore>> Function(
    GestureSample liveStroke,
    GestureTemplate template,
    GestureSensitivityTierEnum sensitivityTier,
  )? onEvaluate;

  int consistencyCount = 0;
  int synthesisCount = 0;
  int evaluateCount = 0;

  @override
  Future<VaultResult<void>> validateSampleConsistency({
    required List<GestureSample> samples,
    double consistencyThreshold = 0.70,
  }) async {
    consistencyCount++;
    final handler = onValidateConsistency;
    if (handler != null) {
      return handler(samples);
    }
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<GestureTemplate>> synthesizeMasterTemplate({
    required List<GestureSample> samples,
    String? templateId,
    double consistencyThreshold = 0.70,
    int maxIterations = 5,
  }) async {
    synthesisCount++;
    final handler = onSynthesize;
    if (handler != null) {
      return handler(samples);
    }
    return VaultResult.success(DefaultGestureTemplate.canonicalVShape);
  }

  @override
  Future<VaultResult<RecognitionScore>> evaluateStroke({
    required GestureSample liveStroke,
    required GestureTemplate template,
    required GestureSensitivityTierEnum sensitivityTier,
  }) async {
    evaluateCount++;
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
}

class MockVaultAuthService implements IVaultAuthService {
  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({
    required String pin,
  }) async {
    return VaultResult.success(
      AuthSession(
        sessionToken: 'adv_test_token',
        sessionStartedEpochMs: 2000,
        lastActiveEpochMs: 2000,
        authMethod: AuthMethodEnum.pin,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ControllableVaultStorageRepository implements IVaultStorageRepository {
  GestureTemplate? savedTemplate;
  bool shouldFailSave = false;

  @override
  Future<VaultResult<void>> saveGestureTemplate(GestureTemplate template) async {
    if (shouldFailSave) {
      return const VaultResult.failure(
        VaultStorageFailure('Encrypted disk write rejected by test harness.'),
      );
    }
    savedTemplate = template;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<GestureTemplate>> loadGestureTemplate() async {
    final t = savedTemplate ?? DefaultGestureTemplate.canonicalVShape;
    return VaultResult.success(t);
  }

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      const VaultResult.success(VaultConfig.constant());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adversarial Empirical Challenge — GestureEnrollmentScreen', () {
    late ControllableGestureRecognizer recognizer;
    late ControllableVaultStorageRepository storage;
    late MockScreenPrivacyController privacyController;
    late MockMonotonicClock monotonicClock;
    late MockVaultAuthService fakeAuth;
    late UnlockVaultUseCase unlockUseCase;
    late PinPadCubit pinPadCubit;
    late ScreenPrivacyCubit screenPrivacyCubit;
    late GestureEngineCubit gestureEngineCubit;

    setUp(() {
      recognizer = ControllableGestureRecognizer();
      storage = ControllableVaultStorageRepository();
      privacyController = MockScreenPrivacyController();
      monotonicClock = MockMonotonicClock();
      fakeAuth = MockVaultAuthService();
      unlockUseCase = UnlockVaultUseCase(authService: fakeAuth);
      pinPadCubit = PinPadCubit(
        unlockVaultUseCase: unlockUseCase,
        authService: fakeAuth,
        monotonicClock: monotonicClock,
      );
      screenPrivacyCubit = ScreenPrivacyCubit(
        privacyController: privacyController,
        monotonicClock: monotonicClock,
        initialPolicy: ScreenSecurityPolicyEnum.blockScreenshotsAndRecents,
      );
      gestureEngineCubit = GestureEngineCubit(
        recognizer: recognizer,
        storageRepository: storage,
        vaultAuthService: fakeAuth,
      );
    });

    tearDown(() {
      pinPadCubit.close();
      screenPrivacyCubit.close();
      gestureEngineCubit.close();
    });

    Widget createTestBed({
      VoidCallback? onComplete,
      String? initialAuthorizationPin,
      VaultThemePalettePolicyEnum palette =
          VaultThemePalettePolicyEnum.warmEspresso,
      IGestureRecognizer? customRecognizer,
    }) {
      return VaultTheme(
        data: VaultThemeData.fromPalette(palette),
        child: MaterialApp(
          home: GestureEnrollmentScreen(
            recognizer: customRecognizer ?? recognizer,
            storageRepository: storage,
            authService: fakeAuth,
            screenPrivacyCubit: screenPrivacyCubit,
            pinPadCubit: pinPadCubit,
            gestureEngineCubit: gestureEngineCubit,
            onEnrollmentComplete: onComplete,
            initialAuthorizationPin: initialAuthorizationPin,
          ),
        ),
      );
    }

    Future<void> drawStroke(
      WidgetTester tester, {
      Offset startDelta = const Offset(-50, -50),
      Offset midDelta = const Offset(0, 50),
      Offset endDelta = const Offset(50, -50),
    }) async {
      final padFinder = find.byKey(const ValueKey('gesture_enrollment_pad'));
      expect(padFinder, findsOneWidget);
      final center = tester.getCenter(padFinder);

      final gesture = await tester.startGesture(center + startDelta);
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveTo(center + midDelta);
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveTo(center + endDelta);
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.up();
      await tester.pumpAndSettle();
    }

    Future<void> drawRealisticVStroke(
      WidgetTester tester, {
      Offset startDelta = const Offset(-40, -40),
      Offset midDelta = const Offset(0, 40),
      Offset endDelta = const Offset(40, -40),
    }) async {
      final padFinder = find.byKey(const ValueKey('gesture_enrollment_pad'));
      expect(padFinder, findsOneWidget);
      final center = tester.getCenter(padFinder);

      final gesture = await tester.startGesture(center + startDelta);
      for (int i = 1; i <= 8; i++) {
        final t = i / 8.0;
        final x = (center.dx + startDelta.dx) * (1.0 - t) +
            (center.dx + midDelta.dx) * t;
        final y = (center.dy + startDelta.dy) * (1.0 - t) +
            (center.dy + midDelta.dy) * t;
        await gesture.moveTo(Offset(x, y));
        await tester.pump(const Duration(milliseconds: 16));
      }
      for (int i = 1; i <= 8; i++) {
        final t = i / 8.0;
        final x = (center.dx + midDelta.dx) * (1.0 - t) +
            (center.dx + endDelta.dx) * t;
        final y = (center.dy + midDelta.dy) * (1.0 - t) +
            (center.dy + endDelta.dy) * t;
        await gesture.moveTo(Offset(x, y));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets(
        'ADVERSARIAL: Deadband boundary stress rejects sub-2.5px micro-movements',
        (tester) async {
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      final padFinder = find.byKey(const ValueKey('gesture_enrollment_pad'));
      final center = tester.getCenter(padFinder);

      // Scenario A: Exact zero-displacement tap
      await tester.tap(padFinder);
      await tester.pumpAndSettle();
      expect(find.text('Sample 1 of 3'), findsOneWidget);
      expect(
        find.text('Stroke too brief. Draw a continuous gesture.'),
        findsOneWidget,
      );

      // Scenario B: 1.0px micro-drag (less than 2.5px threshold)
      final gesture1 = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 16));
      await gesture1.moveTo(center + const Offset(1.0, 0.0));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture1.up();
      await tester.pumpAndSettle();

      expect(find.text('Sample 1 of 3'), findsOneWidget);
      expect(
        find.text('Stroke too brief. Draw a continuous gesture.'),
        findsOneWidget,
      );

      // Scenario C: 2.45px micro-drag (below 2.50px)
      final gesture2 = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 16));
      await gesture2.moveTo(center + const Offset(0.0, 2.45));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture2.up();
      await tester.pumpAndSettle();

      expect(find.text('Sample 1 of 3'), findsOneWidget);
      expect(
        find.text('Stroke too brief. Draw a continuous gesture.'),
        findsOneWidget,
      );

      // Scenario D: Valid stroke exceeding deadband threshold progresses to Sample 2
      await drawStroke(tester);
      expect(find.text('Sample 2 of 3'), findsOneWidget);
    });

    testWidgets(
        'ADVERSARIAL: Clear Stroke button resets temporary warnings without wiping step',
        (tester) async {
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      // Trigger deadband warning
      final padFinder = find.byKey(const ValueKey('gesture_enrollment_pad'));
      await tester.tap(padFinder);
      await tester.pumpAndSettle();
      expect(
        find.text('Stroke too brief. Draw a continuous gesture.'),
        findsOneWidget,
      );

      // Tap Clear Stroke
      await tester.tap(find.byKey(const ValueKey('gesture_clear_stroke_button')));
      await tester.pumpAndSettle();

      // Warning cleared, still on Sample 1
      expect(find.text('Sample 1 of 3'), findsOneWidget);
      expect(
        find.text('Stroke too brief. Draw a continuous gesture.'),
        findsNothing,
      );
    });

    testWidgets(
        'ADVERSARIAL: Start Over button at Sample 2 resets collected samples and returns to Sample 1',
        (tester) async {
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      // Draw sample 1 to reach Sample 2
      await drawStroke(tester);
      expect(find.text('Sample 2 of 3'), findsOneWidget);

      // Tap Start Over
      await tester.tap(find.byKey(const ValueKey('gesture_start_over_button')));
      await tester.pumpAndSettle();

      expect(find.text('Sample 1 of 3'), findsOneWidget);
      expect(
        find.text('Draw your secret single-stroke gesture on the canvas.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'ADVERSARIAL: FastDTW inconsistency on Sample 2 preserves Sample 1 and allows successful retry',
        (tester) async {
      int checkCount = 0;
      recognizer.onValidateConsistency = (samples) async {
        checkCount++;
        if (checkCount == 1) {
          // First attempt at Sample 2 diverges
          return const VaultResult.failure(
            VaultValidationFailure('Pairwise FastDTW alignment distance exceeded 0.70 threshold.'),
          );
        }
        // Second attempt at Sample 2 passes
        return const VaultResult.success(null);
      };

      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      // Sample 1 succeeds
      await drawStroke(tester);
      expect(find.text('Sample 2 of 3'), findsOneWidget);

      // Divergent Sample 2 attempt
      await drawStroke(tester);
      expect(find.text('Sample 2 of 3'), findsOneWidget);
      expect(
        find.textContaining('Stroke differed from previous sample: Pairwise FastDTW alignment distance exceeded 0.70 threshold.'),
        findsOneWidget,
      );

      // Retry Sample 2 with matching gesture
      await drawStroke(tester);

      // Should advance to Sample 3 of 3!
      expect(find.text('Sample 3 of 3'), findsOneWidget);
      expect(
        find.text('Draw the same gesture again to verify consistency.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'ADVERSARIAL: FastDTW inconsistency on Sample 3 preserves Sample 1 and 2 for retry',
        (tester) async {
      int checkCount = 0;
      recognizer.onValidateConsistency = (samples) async {
        checkCount++;
        if (checkCount == 2) {
          // Sample 3 first attempt diverges
          return const VaultResult.failure(
            VaultValidationFailure('Sample 3 diverged from previous master average.'),
          );
        }
        return const VaultResult.success(null);
      };

      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      // Sample 1
      await drawStroke(tester);
      expect(find.text('Sample 2 of 3'), findsOneWidget);

      // Sample 2
      await drawStroke(tester);
      expect(find.text('Sample 3 of 3'), findsOneWidget);

      // Sample 3 diverges
      await drawStroke(tester);
      expect(find.text('Sample 3 of 3'), findsOneWidget);
      expect(
        find.textContaining('Sample 3 diverged from previous master average.'),
        findsOneWidget,
      );

      // Sample 3 retried successfully
      await drawStroke(tester);
      expect(find.text('Practice & Verify'), findsOneWidget);
      expect(find.byKey(const ValueKey('gesture_telemetry_card')), findsOneWidget);
    });

    testWidgets(
        'ADVERSARIAL: Synthesis failure transitions to GestureEnrollmentFailedState and resets cleanly',
        (tester) async {
      recognizer.onSynthesize = (samples) async {
        return const VaultResult.failure(
          VaultGestureFailure('DBA Isolate failed to converge within 5 iterations.'),
        );
      };

      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      // Complete 3 samples
      await drawStroke(tester);
      await drawStroke(tester);
      await drawStroke(tester);

      // Expect failure screen
      expect(find.text('Sample Inconsistency'), findsOneWidget);
      expect(
        find.textContaining('Synthesis error: DBA Isolate failed to converge within 5 iterations.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('gesture_retry_failed_button')), findsOneWidget);

      // Tap Try Again From Sample 1
      await tester.tap(find.byKey(const ValueKey('gesture_retry_failed_button')));
      await tester.pumpAndSettle();

      // Back to Sample 1
      expect(find.text('Sample 1 of 3'), findsOneWidget);
    });

    testWidgets(
        'ADVERSARIAL: Sandbox practice telemetry reflects both match and non-match scores correctly',
        (tester) async {
      int evalCount = 0;
      recognizer.onEvaluate = (stroke, template, tier) async {
        evalCount++;
        if (evalCount == 1) {
          return VaultResult.success(
            RecognitionScore(
              dollarOneScore: 0.96,
              dtwScore: 0.94,
              featureScore: 0.91,
              ensembleScore: 0.946,
              decision: GestureMatchDecisionEnum.matched,
            ),
          );
        } else {
          return VaultResult.success(
            RecognitionScore(
              dollarOneScore: 0.42,
              dtwScore: 0.38,
              featureScore: 0.30,
              ensembleScore: 0.388,
              decision: GestureMatchDecisionEnum.rejectedBelowSensitivityTier,
            ),
          );
        }
      };

      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      // Complete 3 samples
      await drawStroke(tester);
      await drawStroke(tester);
      await drawStroke(tester);

      expect(find.text('Practice & Verify'), findsOneWidget);
      expect(
        find.text('Draw on the pad to test match recognition'),
        findsOneWidget,
      );

      // Stroke 1: Match
      await drawStroke(tester);
      expect(find.textContaining('Match Confirmed (94.6%)'), findsOneWidget);
      expect(find.textContaining('Tests: 1 (1 matched)'), findsOneWidget);
      expect(
        find.textContaining('\$1: 0.96 | DTW: 0.94 | Rubine: 0.91'),
        findsOneWidget,
      );

      // Stroke 2: No Match
      await drawStroke(tester);
      expect(find.textContaining('No Match (38.8%)'), findsOneWidget);
      expect(find.textContaining('Tests: 2 (1 matched)'), findsOneWidget);
      expect(
        find.textContaining('\$1: 0.42 | DTW: 0.38 | Rubine: 0.30'),
        findsOneWidget,
      );
    });

    testWidgets(
        'ADVERSARIAL: Step-up authentication rejection aborts persistence and stays in sandbox',
        (tester) async {
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      // Complete 3 samples to enter sandbox
      await drawStroke(tester);
      await drawStroke(tester);
      await drawStroke(tester);
      expect(find.text('Practice & Verify'), findsOneWidget);

      // Tap Save Gesture -> Pushes VaultAuthScreen
      await tester.tap(find.byKey(const ValueKey('gesture_save_button')));
      await tester.pumpAndSettle();

      expect(find.byType(VaultAuthScreen), findsOneWidget);
      expect(find.text('Authorize Gesture Enrollment'), findsOneWidget);

      // User presses back button to abort auth
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
      } else {
        final iconButton = find.widgetWithIcon(IconButton, Icons.arrow_back);
        await tester.tap(iconButton.first);
      }
      await tester.pumpAndSettle();

      // Returned to Sandbox; template NOT saved
      expect(find.text('Practice & Verify'), findsOneWidget);
      expect(storage.savedTemplate, isNull);
    });

    testWidgets(
        'ADVERSARIAL: Storage failure on Save displays error banner and halts progression',
        (tester) async {
      storage.shouldFailSave = true;

      await tester.pumpWidget(
        createTestBed(initialAuthorizationPin: '123456'),
      );
      await tester.pumpAndSettle();

      // Complete 3 samples
      await drawStroke(tester);
      await drawStroke(tester);
      await drawStroke(tester);
      expect(find.text('Practice & Verify'), findsOneWidget);

      // Tap Save Gesture
      await tester.tap(find.byKey(const ValueKey('gesture_save_button')));
      await tester.pumpAndSettle();

      // Error banner displayed
      expect(
        find.textContaining('Failed to persist template: Encrypted disk write rejected by test harness.'),
        findsOneWidget,
      );
      expect(find.text('Practice & Verify'), findsOneWidget);
    });

    testWidgets(
        'ADVERSARIAL: Successful save updates GestureEngineCubit activeTemplate',
        (tester) async {
      await tester.pumpWidget(
        createTestBed(initialAuthorizationPin: '654321'),
      );
      await tester.pumpAndSettle();

      // Complete 3 samples
      await drawStroke(tester);
      await drawStroke(tester);
      await drawStroke(tester);
      expect(find.text('Practice & Verify'), findsOneWidget);

      // Tap Save Gesture
      await tester.tap(find.byKey(const ValueKey('gesture_save_button')));
      await tester.pumpAndSettle();

      // Verified GestureEngineCubit received updated template
      expect(storage.savedTemplate, isNotNull);
      expect(
        gestureEngineCubit.activeTemplate,
        equals(storage.savedTemplate),
      );
    });

    testWidgets(
        'ADVERSARIAL: Anti-slop & styling invariants hold across warmEspresso and forestNoir palettes',
        (tester) async {
      for (final palette in [
        VaultThemePalettePolicyEnum.warmEspresso,
        VaultThemePalettePolicyEnum.forestNoir,
      ]) {
        await tester.pumpWidget(createTestBed(palette: palette));
        await tester.pumpAndSettle();

        // 1. Check all text widgets for emojis or em dashes
        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        for (final text in textWidgets) {
          final content = text.data ?? text.textSpan?.toPlainText() ?? '';
          expect(content.contains('\u2014'), isFalse,
              reason: 'Em dash found in text: "$content"');
          expect(content.contains('—'), isFalse,
              reason: 'Em dash character found in text: "$content"');

          // Emoji regex check
          final hasEmoji = RegExp(
            r'[\u{1F300}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
            unicode: true,
          ).hasMatch(content);
          expect(hasEmoji, isFalse,
              reason: 'Emoji detected in text: "$content"');
        }

        // 2. Check all buttons do NOT use StadiumBorder (no pill-shaped buttons)
        final outlinedButtons =
            tester.widgetList<OutlinedButton>(find.byType(OutlinedButton));
        for (final btn in outlinedButtons) {
          final shape = btn.style?.shape?.resolve({});
          expect(shape is StadiumBorder, isFalse,
              reason: 'OutlinedButton has forbidden StadiumBorder (pill shape)');
        }

        final filledButtons =
            tester.widgetList<FilledButton>(find.byType(FilledButton));
        for (final btn in filledButtons) {
          final shape = btn.style?.shape?.resolve({});
          expect(shape is StadiumBorder, isFalse,
              reason: 'FilledButton has forbidden StadiumBorder (pill shape)');
        }
      }
    });

    testWidgets(
        'ADVERSARIAL: Real GestureRecognizerService isolate synthesis integration',
        (tester) async {
      final realRecognizer = GestureRecognizerService();

      await tester.pumpWidget(
        createTestBed(
          customRecognizer: realRecognizer,
          initialAuthorizationPin: '123456',
        ),
      );
      await tester.pumpAndSettle();

      // Draw 3 consistent V-shaped strokes
      await drawRealisticVStroke(
        tester,
        startDelta: const Offset(-40, -40),
        midDelta: const Offset(0, 40),
        endDelta: const Offset(40, -40),
      );
      expect(find.text('Sample 2 of 3'), findsOneWidget);

      await drawRealisticVStroke(
        tester,
        startDelta: const Offset(-42, -38),
        midDelta: const Offset(0, 42),
        endDelta: const Offset(38, -42),
      );
      expect(find.text('Sample 3 of 3'), findsOneWidget);

      await drawRealisticVStroke(
        tester,
        startDelta: const Offset(-39, -41),
        midDelta: const Offset(0, 39),
        endDelta: const Offset(41, -39),
      );

      // Allow background isolate DBA synthesis to complete
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 1200));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Real background isolate DBA synthesis executes and enters sandbox
      expect(find.text('Practice & Verify'), findsOneWidget);
      expect(find.byKey(const ValueKey('gesture_telemetry_card')), findsOneWidget);

      // Draw a practice V-shape stroke in sandbox using real recognizer isolate
      await drawRealisticVStroke(
        tester,
        startDelta: const Offset(-40, -40),
        midDelta: const Offset(0, 40),
        endDelta: const Offset(40, -40),
      );

      // Telemetry card updated with real isolate matching scores
      expect(find.textContaining('Match Confirmed'), findsOneWidget);
      expect(find.textContaining('Tests: 1 (1 matched)'), findsOneWidget);
    });
  });
}
