import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/application/gesture/gesture_engine_cubit.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';

class FakeGestureRecognizer implements IGestureRecognizer {
  RecognitionScore matchScore = RecognitionScore(
    dollarOneScore: 0.95,
    dtwScore: 0.90,
    featureScore: 0.88,
    ensembleScore: 0.92,
    decision: GestureMatchDecisionEnum.matched,
  );

  RecognitionScore rejectScore = RecognitionScore(
    dollarOneScore: 0.45,
    dtwScore: 0.50,
    featureScore: 0.40,
    ensembleScore: 0.46,
    decision: GestureMatchDecisionEnum.rejectedBelowSensitivityTier,
  );

  bool returnMatch = true;
  bool shouldFailConsistency = false;
  bool shouldFailSynthesis = false;

  @override
  Future<VaultResult<RecognitionScore>> evaluateStroke({
    required GestureSample liveStroke,
    required GestureTemplate template,
    required GestureSensitivityTierEnum sensitivityTier,
  }) async {
    if (returnMatch) {
      return VaultResult.success(matchScore);
    }
    return VaultResult.success(rejectScore);
  }

  @override
  Future<VaultResult<GestureTemplate>> synthesizeMasterTemplate({
    required List<GestureSample> samples,
  }) async {
    if (shouldFailSynthesis) {
      return const VaultResult.failure(VaultGestureFailure('Synthesis failed'));
    }
    return VaultResult.success(DefaultGestureTemplate.canonicalVShape);
  }

  @override
  Future<VaultResult<void>> validateSampleConsistency({
    required List<GestureSample> samples,
  }) async {
    if (shouldFailConsistency) {
      return const VaultResult.failure(VaultGestureFailure('Inconsistent stroke'));
    }
    return const VaultResult.success(null);
  }
}

class FakeStorageRepository implements IVaultStorageRepository {
  GestureTemplate? savedTemplate;
  VaultConfig config = const VaultConfig.constant();

  @override
  Future<VaultResult<GestureTemplate>> loadGestureTemplate() async {
    if (savedTemplate != null) {
      return VaultResult.success(savedTemplate!);
    }
    return const VaultResult.failure(VaultStorageFailure('No template'));
  }

  @override
  Future<VaultResult<void>> saveGestureTemplate(GestureTemplate template) async {
    savedTemplate = template;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(config);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService implements IVaultAuthService {
  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({required String pin}) async {
    if (pin == '123456') {
      return VaultResult.success(
        AuthSession(
          sessionToken: 'token',
          sessionStartedEpochMs: 1,
          lastActiveEpochMs: 1,
          authMethod: AuthMethodEnum.pin,
        ),
      );
    }
    return const VaultResult.failure(VaultAuthFailure('Wrong PIN'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeGestureRecognizer fakeRecognizer;
  late FakeStorageRepository fakeStorage;
  late FakeAuthService fakeAuthService;
  late GestureEngineCubit cubit;

  final sampleStroke = GestureSample(
    points: [
      GesturePoint(x: 0, y: 0, timestampMs: 0),
      GesturePoint(x: 125, y: 250, timestampMs: 200),
      GesturePoint(x: 250, y: 0, timestampMs: 400),
    ],
    sampledAtEpochMs: 1000,
    totalLength: 350.0,
  );

  setUp(() {
    fakeRecognizer = FakeGestureRecognizer();
    fakeStorage = FakeStorageRepository();
    fakeAuthService = FakeAuthService();
    cubit = GestureEngineCubit(
      recognizer: fakeRecognizer,
      storageRepository: fakeStorage,
      vaultAuthService: fakeAuthService,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  group('GestureEngineCubit Initialization & Default Template', () {
    test('initial state is GestureEngineIdleState with canonical "V" shape template', () {
      expect(cubit.state, isA<GestureEngineIdleState>());
      expect(cubit.activeTemplate.id, equals(DefaultGestureTemplate.canonicalId));
      expect(cubit.sensitivityTier, equals(GestureSensitivityTierEnum.balanced84Percent));
    });

    test('initialize loads saved template and configured sensitivity from storage', () async {
      fakeStorage.config = fakeStorage.config.copyWith(
        gestureSensitivity: GestureSensitivityTierEnum.strict92Percent,
      );

      await cubit.initialize();

      expect(cubit.sensitivityTier, equals(GestureSensitivityTierEnum.strict92Percent));
    });
  });

  group('Live Stroke Evaluation & Epoch Superseding', () {
    test('matching stroke emits MatchConfirmedState and emits to matchConfirmedStream', () async {
      fakeRecognizer.returnMatch = true;

      final scores = <RecognitionScore>[];
      final sub = cubit.matchConfirmedStream.listen(scores.add);

      await cubit.evaluateStroke(sampleStroke);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(scores.length, equals(1));
      expect(scores.first.decision, equals(GestureMatchDecisionEnum.matched));
      expect(cubit.state, isA<GestureEngineIdleState>());

      await sub.cancel();
    });

    test('non-matching stroke emits RejectedSilentState and returns to idle silently', () async {
      fakeRecognizer.returnMatch = false;

      final states = <GestureEngineState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.evaluateStroke(sampleStroke);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(states.any((s) => s is GestureEngineRejectedSilentState), isTrue);
      expect(cubit.state, isA<GestureEngineIdleState>());

      await sub.cancel();
    });

    test('onPointerDown cancels in-flight evaluation and resets to idle', () {
      cubit.emit(GestureEngineEvaluatingStrokeState(
        liveStroke: sampleStroke,
        activeTemplate: cubit.activeTemplate,
        sensitivityTier: cubit.sensitivityTier,
      ));

      cubit.onPointerDown();

      expect(cubit.state, isA<GestureEngineIdleState>());
    });
  });

  group('Multi-Sample 3-Sample Enrollment Wizard Flow', () {
    test('guided enrollment sequence: 3 samples -> DBA synthesis -> sandbox testing', () async {
      cubit.startEnrollment(totalRequiredSamples: 3);
      expect(cubit.state, isA<GestureEngineRecordingSampleState>());
      expect((cubit.state as GestureEngineRecordingSampleState).sampleIndex, equals(1));

      // Sample 1
      await cubit.recordSample(sampleStroke);
      expect((cubit.state as GestureEngineRecordingSampleState).sampleIndex, equals(2));

      // Sample 2
      await cubit.recordSample(sampleStroke);
      expect((cubit.state as GestureEngineRecordingSampleState).sampleIndex, equals(3));

      // Sample 3: triggers DBA synthesis
      await cubit.recordSample(sampleStroke);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(cubit.state, isA<GestureEngineSandboxTestingState>());
      final sandbox = cubit.state as GestureEngineSandboxTestingState;
      expect(sandbox.testAttemptsCount, equals(0));
    });

    test('sample inconsistency triggers GestureEngineEnrollmentFailedState', () async {
      cubit.startEnrollment(totalRequiredSamples: 3);
      await cubit.recordSample(sampleStroke);

      fakeRecognizer.shouldFailConsistency = true;
      await cubit.recordSample(sampleStroke);

      expect(cubit.state, isA<GestureEngineEnrollmentFailedState>());
      final failed = cubit.state as GestureEngineEnrollmentFailedState;
      expect(failed.failureReason, contains('Sample diverged'));
    });

    test('sandbox testing evaluates test strokes and updates attempt counter', () async {
      cubit.startEnrollment(totalRequiredSamples: 3);
      await cubit.recordSample(sampleStroke);
      await cubit.recordSample(sampleStroke);
      await cubit.recordSample(sampleStroke);

      expect(cubit.state, isA<GestureEngineSandboxTestingState>());

      await cubit.testSandboxStroke(sampleStroke);
      final sandbox = cubit.state as GestureEngineSandboxTestingState;
      expect(sandbox.testAttemptsCount, equals(1));
      expect(sandbox.lastScore, isNotNull);
    });

    test('commitEnrollment verifies step-up PIN and saves template', () async {
      cubit.startEnrollment(totalRequiredSamples: 3);
      await cubit.recordSample(sampleStroke);
      await cubit.recordSample(sampleStroke);
      await cubit.recordSample(sampleStroke);

      // Commit with valid PIN
      final result = await cubit.commitEnrollment(authorizationPin: '123456');

      expect(result, isA<VaultSuccess<GestureTemplate>>());
      expect(fakeStorage.savedTemplate, isNotNull);
      expect(cubit.state, isA<GestureEngineIdleState>());
    });

    test('commitEnrollment rejects when PIN is incorrect', () async {
      cubit.startEnrollment(totalRequiredSamples: 3);
      await cubit.recordSample(sampleStroke);
      await cubit.recordSample(sampleStroke);
      await cubit.recordSample(sampleStroke);

      // Commit with wrong PIN
      final result = await cubit.commitEnrollment(authorizationPin: '000000');

      expect(result, isA<VaultFailureResult<GestureTemplate>>());
      expect(cubit.state, isA<GestureEngineSandboxTestingState>());
    });

    test('cancelEnrollment restores idle live recognition state', () {
      cubit.startEnrollment(totalRequiredSamples: 3);
      cubit.cancelEnrollment();

      expect(cubit.state, isA<GestureEngineIdleState>());
    });
  });
}
