import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/active_reauth_interval.dart';
import 'package:musify_mu/features/vault/domain/policies/biometric_auth_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/policies/screen_security_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/enroll_gesture_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/mutate_vault_config_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/purge_vault_data_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/rotate_pin_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';

// =============================================================================
// Test Doubles for Use Cases
// =============================================================================

final class FakeVaultAuthService implements IVaultAuthService {
  LockoutCooldownInfo lockoutStatus = LockoutCooldownInfo.none();
  int failedAttemptsRecorded = 0;
  int resetFailedAttemptsCalled = 0;
  int clearSessionKeysCalled = 0;

  String? validPin = '123456';
  bool allowBiometrics = true;
  VaultResult<void>? rotatePinResult;

  final StreamController<VaultSessionState> _stateController =
      StreamController<VaultSessionState>.broadcast();

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({required String pin}) async {
    if (pin == validPin) {
      return VaultResult.success(
        AuthSession(
          sessionToken: 'test_token_pin',
          sessionStartedEpochMs: 1000,
          lastActiveEpochMs: 1000,
          authMethod: AuthMethodEnum.pin,
        ),
      );
    }
    return const VaultResult.failure(
      VaultAuthFailure('Invalid PIN', remainingAttempts: 0),
    );
  }

  @override
  Future<VaultResult<AuthSession>> authenticateWithBiometrics() async {
    if (allowBiometrics) {
      return VaultResult.success(
        AuthSession(
          sessionToken: 'test_token_biometric',
          sessionStartedEpochMs: 1000,
          lastActiveEpochMs: 1000,
          authMethod: AuthMethodEnum.biometric,
        ),
      );
    }
    return const VaultResult.failure(
      VaultAuthFailure('Biometric scan rejected', remainingAttempts: 0),
    );
  }

  @override
  Future<VaultResult<void>> rotatePin({
    required String oldPin,
    required String newPin,
  }) async {
    final result = rotatePinResult;
    if (result != null) {
      return result;
    }
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> enrollInitialCredentials({
    required String pin,
    required GestureTemplate template,
  }) async {
    return const VaultResult.success(null);
  }

  @override
  Future<LockoutCooldownInfo> getLockoutStatus() async => lockoutStatus;

  @override
  Future<void> recordFailedAttempt() async {
    failedAttemptsRecorded++;
    if (failedAttemptsRecorded >= 5) {
      lockoutStatus = LockoutCooldownInfo(
        tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
        consecutiveFailedAttempts: failedAttemptsRecorded,
        deadlineMonotonicMs: 30000,
        remainingCooldownSeconds: 30,
      );
    } else {
      lockoutStatus = LockoutCooldownInfo(
        tier: LockoutCooldownTierEnum.none,
        consecutiveFailedAttempts: failedAttemptsRecorded,
        deadlineMonotonicMs: 0,
        remainingCooldownSeconds: 0,
      );
    }
  }

  @override
  Future<void> resetFailedAttempts() async {
    resetFailedAttemptsCalled++;
    failedAttemptsRecorded = 0;
    lockoutStatus = LockoutCooldownInfo.none();
  }

  @override
  void clearSessionKeysFromRam() {
    clearSessionKeysCalled++;
  }

  @override
  Stream<VaultSessionState> get sessionStateStream => _stateController.stream;
}

final class FakeVaultStorageRepository implements IVaultStorageRepository {
  VaultConfig persistedConfig = VaultConfig();
  GestureTemplate? persistedTemplate;
  int purgeCount = 0;
  int clearLockoutCount = 0;
  VaultResult<void>? saveConfigResult;
  VaultResult<void>? saveTemplateResult;
  VaultResult<void>? purgeResult;

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async {
    return VaultResult.success(persistedConfig);
  }

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig config) async {
    final res = saveConfigResult;
    if (res != null) {
      return res;
    }
    persistedConfig = config;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<List<PrivatePlaylist>>> getPlaylists() async {
    return const VaultResult.success([]);
  }

  @override
  Future<VaultResult<PrivatePlaylist>> getPlaylistById(String id) async {
    return const VaultResult.failure(VaultStorageFailure('Not found'));
  }

  @override
  Future<VaultResult<PrivatePlaylist>> createPlaylist({
    required String name,
    required String description,
    String? coverUri,
  }) async {
    return const VaultResult.failure(VaultStorageFailure('Unimplemented'));
  }

  @override
  Future<VaultResult<void>> updatePlaylist(PrivatePlaylist playlist) async {
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> deletePlaylist(String playlistId) async {
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> addTrackToPlaylist({
    required String playlistId,
    required PrivateTrackRef trackRef,
  }) async {
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> reorderTracksInPlaylist({
    required String playlistId,
    required List<String> trackIdsInOrder,
  }) async {
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<GestureTemplate>> loadGestureTemplate() async {
    final t = persistedTemplate;
    if (t != null) {
      return VaultResult.success(t);
    }
    return const VaultResult.failure(VaultStorageFailure('No template'));
  }

  @override
  Future<VaultResult<void>> saveGestureTemplate(GestureTemplate template) async {
    final res = saveTemplateResult;
    if (res != null) {
      return res;
    }
    persistedTemplate = template;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> purgeAllVaultData() async {
    final res = purgeResult;
    if (res != null) {
      return res;
    }
    purgeCount++;
    return const VaultResult.success(null);
  }

  @override
  Future<int?> getPersistedLockoutDeadlineMs() async => null;

  @override
  Future<void> persistLockoutDeadlineMs(int deadlineMonotonicMs) async {}

  @override
  Future<void> clearPersistedLockoutDeadline() async {
    clearLockoutCount++;
  }
}

final class FakeGestureRecognizer implements IGestureRecognizer {
  VaultResult<RecognitionScore>? evaluateResult;
  VaultResult<void>? consistencyResult;
  VaultResult<GestureTemplate>? synthesisResult;

  @override
  Future<VaultResult<RecognitionScore>> evaluateStroke({
    required GestureSample liveStroke,
    required GestureTemplate template,
    required GestureSensitivityTierEnum sensitivityTier,
  }) async {
    return evaluateResult ??
        VaultResult.success(
          RecognitionScore(
            dollarOneScore: 0.95,
            dtwScore: 0.95,
            featureScore: 0.95,
            ensembleScore: 0.95,
            decision: GestureMatchDecisionEnum.matched,
          ),
        );
  }

  @override
  Future<VaultResult<GestureTemplate>> synthesizeMasterTemplate({
    required List<GestureSample> samples,
  }) async {
    return synthesisResult ??
        VaultResult.success(
          GestureTemplate(
            id: 'golden_1',
            normalizedPoints: List.generate(
              64,
              (i) => GesturePoint(x: i.toDouble(), y: i.toDouble(), timestampMs: (i + 1) * 10),
            ),
            rubineFeatureVector: const [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0],
            createdAtEpochMs: 1000,
          ),
        );
  }

  @override
  Future<VaultResult<void>> validateSampleConsistency({
    required List<GestureSample> samples,
  }) async {
    return consistencyResult ?? const VaultResult.success(null);
  }
}

final class FakeMonotonicClock implements IMonotonicClock {
  int currentMs = 1000;

  @override
  int get currentMonotonicMs => currentMs;

  @override
  int get elapsedMilliseconds => currentMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

// =============================================================================
// Helper Factory
// =============================================================================

List<GestureSample> createTestSamples(int count) {
  return List.generate(
    count,
    (index) => GestureSample(
      points: [
        GesturePoint(x: 10.0, y: 10.0, timestampMs: 10),
        GesturePoint(x: 20.0, y: 20.0, timestampMs: 50),
        GesturePoint(x: 30.0, y: 30.0, timestampMs: 100),
      ],
      totalLength: 28.28,
      sampledAtEpochMs: 1000 + index,
    ),
  );
}

// =============================================================================
// Test Suite
// =============================================================================

void main() {
  group('UnlockVaultUseCase', () {
    late FakeVaultAuthService authService;
    late UnlockVaultUseCase useCase;

    setUp(() {
      authService = FakeVaultAuthService();
      useCase = UnlockVaultUseCase(authService: authService);
    });

    test('returns VaultLockoutFailure immediately when lockout cooldown is active', () async {
      authService.lockoutStatus = LockoutCooldownInfo(
        tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
        consecutiveFailedAttempts: 5,
        deadlineMonotonicMs: 60000,
        remainingCooldownSeconds: 30,
      );

      final result = await useCase.execute(const PinUnlockParams('123456'));

      expect(result, isA<VaultFailureResult<AuthSession>>());
      final failure = (result as VaultFailureResult<AuthSession>).failure;
      expect(failure, isA<VaultLockoutFailure>());
      final lockoutFailure = failure as VaultLockoutFailure;
      expect(lockoutFailure.remainingCooldownSeconds, 30);
      expect(lockoutFailure.deadlineMonotonicMs, 60000);
      expect(authService.failedAttemptsRecorded, 0);
    });

    test('returns VaultValidationFailure when PIN is not 6 digits', () async {
      final shortResult = await useCase.execute(const PinUnlockParams('123'));
      expect(shortResult, isA<VaultFailureResult<AuthSession>>());
      expect((shortResult as VaultFailureResult<AuthSession>).failure, isA<VaultValidationFailure>());

      final nonNumericResult = await useCase.execute(const PinUnlockParams('abcdef'));
      expect(nonNumericResult, isA<VaultFailureResult<AuthSession>>());
      expect((nonNumericResult as VaultFailureResult<AuthSession>).failure, isA<VaultValidationFailure>());
      expect(authService.failedAttemptsRecorded, 0);
    });

    test('successful PIN unlock resets failed attempts and returns AuthSession', () async {
      final result = await useCase.execute(const PinUnlockParams('123456'));

      expect(result, isA<VaultSuccess<AuthSession>>());
      final session = (result as VaultSuccess<AuthSession>).data;
      expect(session.sessionToken, 'test_token_pin');
      expect(session.authMethod, AuthMethodEnum.pin);
      expect(authService.resetFailedAttemptsCalled, 1);
    });

    test('failed PIN unlock records attempt and returns VaultAuthFailure with remaining attempts', () async {
      final result = await useCase.execute(const PinUnlockParams('999999'));

      expect(result, isA<VaultFailureResult<AuthSession>>());
      final failure = (result as VaultFailureResult<AuthSession>).failure;
      expect(failure, isA<VaultAuthFailure>());
      final authFailure = failure as VaultAuthFailure;
      expect(authFailure.remainingAttempts, 4); // 5 - 1
      expect(authService.failedAttemptsRecorded, 1);
    });

    test('5 consecutive failed PIN unlocks trigger VaultLockoutFailure', () async {
      for (var i = 0; i < 4; i++) {
        await useCase.execute(const PinUnlockParams('999999'));
      }
      final fifthResult = await useCase.execute(const PinUnlockParams('999999'));

      expect(fifthResult, isA<VaultFailureResult<AuthSession>>());
      final failure = (fifthResult as VaultFailureResult<AuthSession>).failure;
      expect(failure, isA<VaultLockoutFailure>());
      final lockoutFailure = failure as VaultLockoutFailure;
      expect(lockoutFailure.remainingCooldownSeconds, 30);
    });

    test('successful Biometric unlock resets failed attempts and returns AuthSession', () async {
      final result = await useCase.execute(const BiometricUnlockParams());

      expect(result, isA<VaultSuccess<AuthSession>>());
      final session = (result as VaultSuccess<AuthSession>).data;
      expect(session.sessionToken, 'test_token_biometric');
      expect(session.authMethod, AuthMethodEnum.biometric);
      expect(authService.resetFailedAttemptsCalled, 1);
    });

    test('failed Biometric unlock records attempt and returns VaultAuthFailure', () async {
      authService.allowBiometrics = false;

      final result = await useCase.execute(const BiometricUnlockParams());

      expect(result, isA<VaultFailureResult<AuthSession>>());
      expect((result as VaultFailureResult<AuthSession>).failure, isA<VaultAuthFailure>());
      expect(authService.failedAttemptsRecorded, 1);
    });
  });

  group('VerifySessionCoolOffUseCase', () {
    late FakeMonotonicClock clock;
    late VerifySessionCoolOffUseCase useCase;
    late VaultConfig config;
    late AuthSession session;

    setUp(() {
      clock = FakeMonotonicClock();
      useCase = VerifySessionCoolOffUseCase(clock: clock);
      config = VaultConfig(activeReauthInterval: ActiveReauthIntervalEnum.every15Minutes);
      session = AuthSession(
        sessionToken: 'sess_1',
        sessionStartedEpochMs: 1000,
        lastActiveEpochMs: 1000,
        authMethod: AuthMethodEnum.pin,
      );
    });

    test('VaultUnlockedState: returns sessionValid when reauth deadline not reached', () {
      clock.currentMs = 5000;
      final state = VaultUnlockedState(
        session: session,
        unlockedAtMonotonicMs: 1000,
        reauthDeadlineMonotonicMs: 10000,
      );

      final result = useCase.execute(
        VerifyCoolOffParams(currentState: state, config: config),
      );

      expect(result, isA<VaultSuccess<CoolOffDecisionEnum>>());
      expect((result as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.sessionValid);
    });

    test('VaultUnlockedState: returns reauthRequired when deadline reached', () {
      clock.currentMs = 10000;
      final state = VaultUnlockedState(
        session: session,
        unlockedAtMonotonicMs: 1000,
        reauthDeadlineMonotonicMs: 10000,
      );

      final result = useCase.execute(
        VerifyCoolOffParams(currentState: state, config: config),
      );

      expect(result, isA<VaultSuccess<CoolOffDecisionEnum>>());
      expect((result as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.reauthRequired);
    });

    test('VaultUnlockedState: returns sessionValid when interval is never regardless of timestamp', () {
      clock.currentMs = 999999;
      final neverConfig = VaultConfig(activeReauthInterval: ActiveReauthIntervalEnum.never);
      final state = VaultUnlockedState(
        session: session,
        unlockedAtMonotonicMs: 1000,
        reauthDeadlineMonotonicMs: 1000,
      );

      final result = useCase.execute(
        VerifyCoolOffParams(currentState: state, config: neverConfig),
      );

      expect(result, isA<VaultSuccess<CoolOffDecisionEnum>>());
      expect((result as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.sessionValid);
    });

    test('VaultBackgroundGraceState: returns sessionValid before grace deadline', () {
      clock.currentMs = 25000;
      final state = VaultBackgroundGraceState(
        session: session,
        enteredBackgroundMonotonicMs: 10000,
        graceTimeoutMs: 30000,
        graceDeadlineMonotonicMs: 40000,
      );

      final result = useCase.execute(
        VerifyCoolOffParams(currentState: state, config: config),
      );

      expect(result, isA<VaultSuccess<CoolOffDecisionEnum>>());
      expect((result as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.sessionValid);
    });

    test('VaultBackgroundGraceState: returns graceExpiredLock when grace deadline reached', () {
      clock.currentMs = 40000;
      final state = VaultBackgroundGraceState(
        session: session,
        enteredBackgroundMonotonicMs: 10000,
        graceTimeoutMs: 30000,
        graceDeadlineMonotonicMs: 40000,
      );

      final result = useCase.execute(
        VerifyCoolOffParams(currentState: state, config: config),
      );

      expect(result, isA<VaultSuccess<CoolOffDecisionEnum>>());
      expect((result as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.graceExpiredLock);
    });

    test('VaultLockoutCooldownState: returns lockoutActive before deadline and lockoutElapsedReset after', () {
      clock.currentMs = 20000;
      final lockoutState = VaultLockoutCooldownState(
        tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
        cooldownStartedMonotonicMs: 0,
        durationMs: 30000,
        deadlineMonotonicMs: 30000,
        failedAttemptsCount: 5,
      );

      final activeResult = useCase.execute(
        VerifyCoolOffParams(currentState: lockoutState, config: config),
      );
      expect((activeResult as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.lockoutActive);

      clock.currentMs = 30000;
      final resetResult = useCase.execute(
        VerifyCoolOffParams(currentState: lockoutState, config: config),
      );
      expect((resetResult as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.lockoutElapsedReset);
    });

    test('Other states (uninitialized, locked, authenticating, pendingReauth) return sessionValid', () {
      expect(
        (useCase.execute(VerifyCoolOffParams(currentState: const VaultUninitializedState(), config: config))
                as VaultSuccess<CoolOffDecisionEnum>)
            .data,
        CoolOffDecisionEnum.sessionValid,
      );
      expect(
        (useCase.execute(VerifyCoolOffParams(currentState: const VaultLockedState(lockedAtMonotonicMs: 100), config: config))
                as VaultSuccess<CoolOffDecisionEnum>)
            .data,
        CoolOffDecisionEnum.sessionValid,
      );
      expect(
        (useCase.execute(VerifyCoolOffParams(
          currentState: const VaultAuthenticatingState(
            authSessionId: 'auth_1',
            attemptNumber: 1,
            remainingAttemptsBeforeCooldown: 4,
          ),
          config: config,
        )) as VaultSuccess<CoolOffDecisionEnum>)
            .data,
        CoolOffDecisionEnum.sessionValid,
      );
      expect(
        (useCase.execute(VerifyCoolOffParams(
          currentState: VaultPendingReauthState(
            session: session,
            reauthTriggeredAtMonotonicMs: 1000,
            remainingAttempts: 3,
          ),
          config: config,
        )) as VaultSuccess<CoolOffDecisionEnum>)
            .data,
        CoolOffDecisionEnum.sessionValid,
      );
    });
  });

  group('EnrollGestureUseCase', () {
    late FakeVaultAuthService authService;
    late FakeGestureRecognizer recognizer;
    late FakeVaultStorageRepository storageRepository;
    late EnrollGestureUseCase useCase;

    setUp(() {
      authService = FakeVaultAuthService();
      recognizer = FakeGestureRecognizer();
      storageRepository = FakeVaultStorageRepository();
      useCase = EnrollGestureUseCase(
        authService: authService,
        recognizer: recognizer,
        storageRepository: storageRepository,
      );
    });

    test('fails with VaultValidationFailure if samples length != 3', () async {
      final resultTwo = await useCase.execute(
        EnrollGestureParams(
          samples: createTestSamples(2),
          authorizationPin: '123456',
        ),
      );
      expect(resultTwo, isA<VaultFailureResult<GestureTemplate>>());
      expect((resultTwo as VaultFailureResult<GestureTemplate>).failure, isA<VaultValidationFailure>());

      final resultFour = await useCase.execute(
        EnrollGestureParams(
          samples: createTestSamples(4),
          authorizationPin: '123456',
        ),
      );
      expect(resultFour, isA<VaultFailureResult<GestureTemplate>>());
      expect((resultFour as VaultFailureResult<GestureTemplate>).failure, isA<VaultValidationFailure>());
    });

    test('fails with VaultAuthFailure if authorization PIN is invalid', () async {
      final result = await useCase.execute(
        EnrollGestureParams(
          samples: createTestSamples(3),
          authorizationPin: '999999',
        ),
      );

      expect(result, isA<VaultFailureResult<GestureTemplate>>());
      expect((result as VaultFailureResult<GestureTemplate>).failure, isA<VaultAuthFailure>());
    });

    test('fails if sample consistency validation fails', () async {
      recognizer.consistencyResult = const VaultResult.failure(
        VaultGestureFailure('Sample variance exceeded consistency envelope'),
      );

      final result = await useCase.execute(
        EnrollGestureParams(
          samples: createTestSamples(3),
          authorizationPin: '123456',
        ),
      );

      expect(result, isA<VaultFailureResult<GestureTemplate>>());
      expect((result as VaultFailureResult<GestureTemplate>).failure, isA<VaultGestureFailure>());
    });

    test('fails if master template synthesis fails', () async {
      recognizer.synthesisResult = const VaultResult.failure(
        VaultGestureFailure('DBA convergence failed'),
      );

      final result = await useCase.execute(
        EnrollGestureParams(
          samples: createTestSamples(3),
          authorizationPin: '123456',
        ),
      );

      expect(result, isA<VaultFailureResult<GestureTemplate>>());
      expect((result as VaultFailureResult<GestureTemplate>).failure, isA<VaultGestureFailure>());
    });

    test('fails if template storage fails', () async {
      storageRepository.saveTemplateResult = const VaultResult.failure(
        VaultStorageFailure('Disk write failed'),
      );

      final result = await useCase.execute(
        EnrollGestureParams(
          samples: createTestSamples(3),
          authorizationPin: '123456',
        ),
      );

      expect(result, isA<VaultFailureResult<GestureTemplate>>());
      expect((result as VaultFailureResult<GestureTemplate>).failure, isA<VaultStorageFailure>());
    });

    test('succeeds, saves golden template, and returns GestureTemplate', () async {
      final result = await useCase.execute(
        EnrollGestureParams(
          samples: createTestSamples(3),
          authorizationPin: '123456',
        ),
      );

      expect(result, isA<VaultSuccess<GestureTemplate>>());
      final template = (result as VaultSuccess<GestureTemplate>).data;
      expect(template.id, 'golden_1');
      expect(storageRepository.persistedTemplate, template);
    });
  });

  group('RotatePinUseCase', () {
    late FakeVaultAuthService authService;
    late RotatePinUseCase useCase;

    setUp(() {
      authService = FakeVaultAuthService();
      useCase = RotatePinUseCase(authService: authService);
    });

    test('rejects non-6-digit oldPin or newPin', () async {
      final badOld = await useCase.execute(
        const RotatePinParams(oldPin: '12345', newPin: '654321'),
      );
      expect((badOld as VaultFailureResult<void>).failure, isA<VaultValidationFailure>());

      final badNew = await useCase.execute(
        const RotatePinParams(oldPin: '123456', newPin: '65432'),
      );
      expect((badNew as VaultFailureResult<void>).failure, isA<VaultValidationFailure>());

      final nonNumeric = await useCase.execute(
        const RotatePinParams(oldPin: '123456', newPin: 'abcdef'),
      );
      expect((nonNumeric as VaultFailureResult<void>).failure, isA<VaultValidationFailure>());
    });

    test('rejects identical oldPin and newPin with VaultValidationFailure', () async {
      final identical = await useCase.execute(
        const RotatePinParams(oldPin: '123456', newPin: '123456'),
      );
      expect(identical, isA<VaultFailureResult<void>>());
      final failure = (identical as VaultFailureResult<void>).failure;
      expect(failure, isA<VaultValidationFailure>());
      expect(
        failure.message,
        'New PIN must differ from current PIN.',
      );
    });

    test('delegates valid rotation to IVaultAuthService and succeeds', () async {
      final result = await useCase.execute(
        const RotatePinParams(oldPin: '123456', newPin: '654321'),
      );

      expect(result, isA<VaultSuccess<void>>());
    });
  });

  group('MutateVaultConfigUseCase', () {
    late FakeVaultAuthService authService;
    late FakeVaultStorageRepository storageRepository;
    late MutateVaultConfigUseCase useCase;
    late VaultConfig currentConfig;

    setUp(() {
      authService = FakeVaultAuthService();
      storageRepository = FakeVaultStorageRepository();
      useCase = MutateVaultConfigUseCase(
        authService: authService,
        storageRepository: storageRepository,
      );
      currentConfig = VaultConfig();
    });

    test('non-sensitive mutation does not require stepUpPin and succeeds', () async {
      final newConfig = currentConfig.copyWith(
        themePalette: VaultThemePalettePolicyEnum.forestNoir,
      );

      final result = await useCase.execute(
        MutateVaultConfigParams(
          currentConfig: currentConfig,
          newConfig: newConfig,
        ),
      );

      expect(result, isA<VaultSuccess<VaultConfig>>());
      final success = result as VaultSuccess<VaultConfig>;
      expect(success.data.themePalette, VaultThemePalettePolicyEnum.forestNoir);
      expect(storageRepository.persistedConfig.themePalette, VaultThemePalettePolicyEnum.forestNoir);
    });

    test('sensitive mutation requires stepUpPin and fails if null', () async {
      final newConfig = currentConfig.copyWith(
        biometricAuth: BiometricAuthPolicyEnum.pinAndBiometricStrong,
      );

      final result = await useCase.execute(
        MutateVaultConfigParams(
          currentConfig: currentConfig,
          newConfig: newConfig,
          stepUpPin: null,
        ),
      );

      expect(result, isA<VaultFailureResult<VaultConfig>>());
      expect((result as VaultFailureResult<VaultConfig>).failure, isA<VaultAuthFailure>());
    });

    test('sensitive mutation with invalid stepUpPin fails with VaultAuthFailure', () async {
      final newConfig = currentConfig.copyWith(
        biometricAuth: BiometricAuthPolicyEnum.pinAndBiometricStrong,
      );

      final result = await useCase.execute(
        MutateVaultConfigParams(
          currentConfig: currentConfig,
          newConfig: newConfig,
          stepUpPin: '999999',
        ),
      );

      expect(result, isA<VaultFailureResult<VaultConfig>>());
      expect((result as VaultFailureResult<VaultConfig>).failure, isA<VaultAuthFailure>());
    });

    test('sensitive mutation with valid stepUpPin succeeds and saves', () async {
      final newConfig = currentConfig.copyWith(
        biometricAuth: BiometricAuthPolicyEnum.pinAndBiometricStrong,
      );

      final result = await useCase.execute(
        MutateVaultConfigParams(
          currentConfig: currentConfig,
          newConfig: newConfig,
          stepUpPin: '123456',
        ),
      );

      expect(result, isA<VaultSuccess<VaultConfig>>());
      final success = result as VaultSuccess<VaultConfig>;
      expect(success.data.biometricAuth, BiometricAuthPolicyEnum.pinAndBiometricStrong);
    });

    test('general security preferences (screenSecurity, activeReauthInterval, backgroundGraceTimeout) succeed without stepUpPin', () async {
      final newConfig = currentConfig.copyWith(
        screenSecurity: ScreenSecurityPolicyEnum.allowCapture,
        activeReauthInterval: ActiveReauthIntervalEnum.every5Minutes,
      );

      final result = await useCase.execute(
        MutateVaultConfigParams(
          currentConfig: currentConfig,
          newConfig: newConfig,
          stepUpPin: null,
        ),
      );

      expect(result, isA<VaultSuccess<VaultConfig>>());
      final success = result as VaultSuccess<VaultConfig>;
      expect(success.data.screenSecurity, ScreenSecurityPolicyEnum.allowCapture);
      expect(success.data.activeReauthInterval, ActiveReauthIntervalEnum.every5Minutes);
    });

    test('fails with VaultValidationFailure if decoy fields are whitespace', () async {
      const emptyDecoyConfig = VaultConfig.constant(decoyTitle: '   ');

      final result = await useCase.execute(
        MutateVaultConfigParams(
          currentConfig: currentConfig,
          newConfig: emptyDecoyConfig,
        ),
      );

      expect(result, isA<VaultFailureResult<VaultConfig>>());
      expect((result as VaultFailureResult<VaultConfig>).failure, isA<VaultValidationFailure>());
    });

    test('fails if storage persistence fails', () async {
      storageRepository.saveConfigResult = const VaultResult.failure(
        VaultStorageFailure('Disk write failed'),
      );

      final newConfig = currentConfig.copyWith(
        themePalette: VaultThemePalettePolicyEnum.forestNoir,
      );

      final result = await useCase.execute(
        MutateVaultConfigParams(
          currentConfig: currentConfig,
          newConfig: newConfig,
        ),
      );

      expect(result, isA<VaultFailureResult<VaultConfig>>());
      expect((result as VaultFailureResult<VaultConfig>).failure, isA<VaultStorageFailure>());
    });
  });

  group('PurgeVaultDataUseCase', () {
    late FakeVaultAuthService authService;
    late FakeVaultStorageRepository storageRepository;
    late PurgeVaultDataUseCase useCase;

    setUp(() {
      authService = FakeVaultAuthService();
      storageRepository = FakeVaultStorageRepository();
      useCase = PurgeVaultDataUseCase(
        authService: authService,
        storageRepository: storageRepository,
      );
    });

    test('fails with VaultAuthFailure if confirmation PIN is invalid', () async {
      final result = await useCase.execute(
        const PurgeVaultDataParams(confirmationPin: '999999'),
      );

      expect(result, isA<VaultFailureResult<void>>());
      expect((result as VaultFailureResult<void>).failure, isA<VaultAuthFailure>());
      expect(storageRepository.purgeCount, 0);
      expect(authService.clearSessionKeysCalled, 0);
    });

    test('fails if storageRepository.purgeAllVaultData fails', () async {
      storageRepository.purgeResult = const VaultResult.failure(
        VaultStorageFailure('Failed to shred SQLite database'),
      );

      final result = await useCase.execute(
        const PurgeVaultDataParams(confirmationPin: '123456'),
      );

      expect(result, isA<VaultFailureResult<void>>());
      expect((result as VaultFailureResult<void>).failure, isA<VaultStorageFailure>());
    });

    test('succeeds: executes storage purge, clears persisted lockout, and zeros session keys in RAM', () async {
      final result = await useCase.execute(
        const PurgeVaultDataParams(confirmationPin: '123456'),
      );

      expect(result, isA<VaultSuccess<void>>());
      expect(storageRepository.purgeCount, 1);
      expect(storageRepository.clearLockoutCount, 1);
      expect(authService.clearSessionKeysCalled, 1);
    });
  });
}
