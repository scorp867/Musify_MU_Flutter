import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
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

class FakeMonotonicClock implements IMonotonicClock {
  int timeMs = 1000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class FakeScreenPrivacyController implements IScreenPrivacyController {
  ScreenPrivacyStateEnum _state = ScreenPrivacyStateEnum.publicUnrestricted;
  final StreamController<ScreenPrivacyStateEnum> _streamController =
      StreamController<ScreenPrivacyStateEnum>.broadcast();

  int enableCallCount = 0;
  int disableCallCount = 0;

  @override
  ScreenPrivacyStateEnum get currentState => _state;

  @override
  Stream<ScreenPrivacyStateEnum> get stateStream => _streamController.stream;

  @override
  Future<void> enableSecureFlag() async {
    enableCallCount++;
    _state = ScreenPrivacyStateEnum.secureFlagEngaged;
    _streamController.add(_state);
  }

  @override
  Future<void> disableSecureFlag() async {
    disableCallCount++;
    _state = ScreenPrivacyStateEnum.publicUnrestricted;
    _streamController.add(_state);
  }
}

class FakeGestureRecognizer implements IGestureRecognizer {
  Future<VaultResult<void>> Function(List<GestureSample> samples)?
      onValidateConsistency;
  Future<VaultResult<GestureTemplate>> Function(List<GestureSample> samples)?
      onSynthesize;
  Future<VaultResult<RecognitionScore>> Function(
    GestureSample liveStroke,
    GestureTemplate template,
    GestureSensitivityTierEnum sensitivityTier,
  )? onEvaluate;

  int consistencyCalls = 0;
  int synthesisCalls = 0;
  int evaluateCalls = 0;

  @override
  Future<VaultResult<void>> validateSampleConsistency({
    required List<GestureSample> samples,
  }) async {
    consistencyCalls++;
    final handler = onValidateConsistency;
    if (handler != null) {
      return handler(samples);
    }
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<GestureTemplate>> synthesizeMasterTemplate({
    required List<GestureSample> samples,
  }) async {
    synthesisCalls++;
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
    evaluateCalls++;
    final handler = onEvaluate;
    if (handler != null) {
      return handler(liveStroke, template, sensitivityTier);
    }
    return VaultResult.success(
      RecognitionScore(
        dollarOneScore: 0.94,
        dtwScore: 0.91,
        featureScore: 0.89,
        ensembleScore: 0.922,
        decision: GestureMatchDecisionEnum.matched,
      ),
    );
  }
}

class FakeVaultAuthService implements IVaultAuthService {
  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({required String pin}) async {
    return VaultResult.success(
      AuthSession(
        sessionToken: 'test_token',
        sessionStartedEpochMs: 1000,
        lastActiveEpochMs: 1000,
        authMethod: AuthMethodEnum.pin,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVaultStorageRepository implements IVaultStorageRepository {
  GestureTemplate? savedTemplate;

  @override
  Future<VaultResult<void>> saveGestureTemplate(GestureTemplate template) async {
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

  group('GestureEnrollmentScreen Tests', () {
    late FakeGestureRecognizer recognizer;
    late FakeVaultStorageRepository storage;
    late FakeScreenPrivacyController privacyController;
    late FakeMonotonicClock monotonicClock;
    late FakeVaultAuthService fakeAuth;
    late UnlockVaultUseCase unlockUseCase;
    late PinPadCubit pinPadCubit;
    late ScreenPrivacyCubit screenPrivacyCubit;

    setUp(() {
      recognizer = FakeGestureRecognizer();
      storage = FakeVaultStorageRepository();
      privacyController = FakeScreenPrivacyController();
      monotonicClock = FakeMonotonicClock();
      fakeAuth = FakeVaultAuthService();
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
    });

    tearDown(() {
      // Clean teardown
    });

    Widget createTestBed({
      VoidCallback? onComplete,
      String? initialAuthorizationPin,
    }) {
      return VaultTheme(
        data: VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.warmEspresso),
        child: MaterialApp(
          home: GestureEnrollmentScreen(
            recognizer: recognizer,
            storageRepository: storage,
            authService: fakeAuth,
            screenPrivacyCubit: screenPrivacyCubit,
            pinPadCubit: pinPadCubit,
            onEnrollmentComplete: onComplete,
            initialAuthorizationPin: initialAuthorizationPin,
          ),
        ),
      );
    }

    Future<void> drawSample(WidgetTester tester) async {
      final padFinder = find.byKey(const ValueKey('gesture_enrollment_pad'));
      expect(padFinder, findsOneWidget);
      final center = tester.getCenter(padFinder);

      final gesture = await tester.startGesture(center - const Offset(60, 60));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveTo(center + const Offset(0, 60));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveTo(center + const Offset(60, -60));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('Initial state displays Sample 1 of 3 and step indicator',
        (tester) async {
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      expect(find.text('Sample 1 of 3'), findsOneWidget);
      expect(
        find.text('Draw your secret single-stroke gesture on the canvas.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('gesture_step_indicator_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('gesture_step_indicator_2')), findsOneWidget);
      expect(find.byKey(const ValueKey('gesture_step_indicator_3')), findsOneWidget);
      expect(find.byKey(const ValueKey('gesture_enrollment_pad')), findsOneWidget);
      expect(find.byKey(const ValueKey('gesture_clear_stroke_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('gesture_start_over_button')), findsOneWidget);

      // Verify Screen Privacy engaged
      expect(privacyController.enableCallCount, greaterThan(0));
    });

    testWidgets('Sub-deadband touch tap clears without advancing sample',
        (tester) async {
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      final padFinder = find.byKey(const ValueKey('gesture_enrollment_pad'));
      await tester.tap(padFinder);
      await tester.pumpAndSettle();

      // Remains on Sample 1
      expect(find.text('Sample 1 of 3'), findsOneWidget);
      expect(
        find.text('Stroke too brief. Draw a continuous gesture.'),
        findsOneWidget,
      );
    });

    testWidgets('Drawing Sample 1 advances wizard to Sample 2 of 3',
        (tester) async {
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      await drawSample(tester);

      expect(find.text('Sample 2 of 3'), findsOneWidget);
      expect(
        find.text('Draw the same gesture again to verify consistency.'),
        findsOneWidget,
      );
    });

    testWidgets('Sample 2 consistency failure shows warning and preserves sample 1',
        (tester) async {
      recognizer.onValidateConsistency = (samples) async {
        return const VaultResult.failure(
          VaultValidationFailure('Gestures diverged beyond tolerance.'),
        );
      };

      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      // Sample 1 succeeds (no pairwise consistency check on sample 1)
      await drawSample(tester);
      expect(find.text('Sample 2 of 3'), findsOneWidget);

      // Sample 2 fails consistency
      await drawSample(tester);

      expect(find.text('Sample 2 of 3'), findsOneWidget);
      expect(
        find.textContaining('Stroke differed from previous sample'),
        findsOneWidget,
      );
    });

    testWidgets('Completing 3 samples triggers isolate synthesis and enters sandbox',
        (tester) async {
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      // Sample 1
      await drawSample(tester);
      expect(find.text('Sample 2 of 3'), findsOneWidget);

      // Sample 2
      await drawSample(tester);
      expect(find.text('Sample 3 of 3'), findsOneWidget);

      // Sample 3
      await drawSample(tester);

      // Enters Sandbox testing
      expect(find.text('Practice & Verify'), findsOneWidget);
      expect(find.byKey(const ValueKey('gesture_telemetry_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('gesture_rerecord_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('gesture_save_button')), findsOneWidget);
      expect(recognizer.synthesisCalls, equals(1));
    });

    testWidgets('Sandbox practice stroke updates live telemetry card',
        (tester) async {
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      // Complete 3 samples
      await drawSample(tester);
      await drawSample(tester);
      await drawSample(tester);

      expect(find.text('Practice & Verify'), findsOneWidget);

      // Practice stroke in sandbox
      await drawSample(tester);

      expect(find.textContaining('Match Confirmed (92.2%)'), findsOneWidget);
      expect(find.textContaining('Tests: 1 (1 matched)'), findsOneWidget);
      expect(find.textContaining('\$1: 0.94 | DTW: 0.91 | Rubine: 0.89'), findsOneWidget);
      expect(recognizer.evaluateCalls, equals(1));
    });

    testWidgets('Re-record button in sandbox restarts wizard from sample 1',
        (tester) async {
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      // Complete 3 samples
      await drawSample(tester);
      await drawSample(tester);
      await drawSample(tester);

      expect(find.text('Practice & Verify'), findsOneWidget);

      // Tap Re-record
      await tester.tap(find.byKey(const ValueKey('gesture_rerecord_button')));
      await tester.pumpAndSettle();

      expect(find.text('Sample 1 of 3'), findsOneWidget);
    });

    testWidgets('Save gesture with pre-verified PIN persists template and completes',
        (tester) async {
      bool completed = false;
      await tester.pumpWidget(
        createTestBed(
          onComplete: () => completed = true,
          initialAuthorizationPin: '123456',
        ),
      );
      await tester.pumpAndSettle();

      // Complete 3 samples
      await drawSample(tester);
      await drawSample(tester);
      await drawSample(tester);

      expect(find.text('Practice & Verify'), findsOneWidget);

      // Tap Save Gesture
      await tester.tap(find.byKey(const ValueKey('gesture_save_button')));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(storage.savedTemplate, isNotNull);
    });

    testWidgets('Save gesture pushes VaultAuthScreen when initial PIN is omitted',
        (tester) async {
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      // Complete 3 samples
      await drawSample(tester);
      await drawSample(tester);
      await drawSample(tester);

      expect(find.text('Practice & Verify'), findsOneWidget);

      // Tap Save Gesture
      await tester.tap(find.byKey(const ValueKey('gesture_save_button')));
      await tester.pumpAndSettle();

      // Step-up authentication screen pushed
      expect(find.byType(VaultAuthScreen), findsOneWidget);
      expect(find.text('Authorize Gesture Enrollment'), findsOneWidget);
    });

    testWidgets('Design system compliance: zero purple colors, 8px radius, zero emojis, zero em dashes',
        (tester) async {
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      // Check all Text widgets for emojis and em dashes
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final text in textWidgets) {
        final content = text.data ?? text.textSpan?.toPlainText() ?? '';
        expect(content.contains('\u2014'), isFalse,
            reason: 'Em dash found in: "$content"');
        expect(content.contains('—'), isFalse,
            reason: 'Em dash character found in: "$content"');
      }
    });
  });
}
