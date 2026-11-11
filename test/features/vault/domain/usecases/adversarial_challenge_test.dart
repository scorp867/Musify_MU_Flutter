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
import 'package:musify_mu/features/vault/domain/policies/background_grace_timeout.dart';
import 'package:musify_mu/features/vault/domain/policies/biometric_auth_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/keypad_layout_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';
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
// Adversarial Test Doubles
// =============================================================================

final class AdversarialAuthService implements IVaultAuthService {
  LockoutCooldownInfo currentLockout = LockoutCooldownInfo.none();
  int failedAttempts = 0;
  int resetAttemptsCount = 0;
  int clearKeysCount = 0;
  int authenticateWithPinCalls = 0;
  int authenticateWithBiometricsCalls = 0;
  int rotatePinCalls = 0;

  String activePin = '123456';
  bool biometricsAvailable = true;
  VaultResult<void>? rotateOverride;

  final StreamController<VaultSessionState> _stateController =
      StreamController<VaultSessionState>.broadcast();

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({required String pin}) async {
    authenticateWithPinCalls++;
    if (pin == activePin) {
      return VaultResult.success(
        AuthSession(
          sessionToken: 'adversarial_pin_token',
          sessionStartedEpochMs: 5000,
          lastActiveEpochMs: 5000,
          authMethod: AuthMethodEnum.pin,
        ),
      );
    }
    return const VaultResult.failure(
      VaultAuthFailure('Incorrect PIN credentials', remainingAttempts: 0),
    );
  }

  @override
  Future<VaultResult<AuthSession>> authenticateWithBiometrics() async {
    authenticateWithBiometricsCalls++;
    if (biometricsAvailable) {
      return VaultResult.success(
        AuthSession(
          sessionToken: 'adversarial_bio_token',
          sessionStartedEpochMs: 5000,
          lastActiveEpochMs: 5000,
          authMethod: AuthMethodEnum.biometric,
        ),
      );
    }
    return const VaultResult.failure(
      VaultAuthFailure('Biometric sensor rejected verification', remainingAttempts: 0),
    );
  }

  @override
  Future<VaultResult<void>> rotatePin({
    required String oldPin,
    required String newPin,
  }) async {
    rotatePinCalls++;
    if (rotateOverride != null) {
      return rotateOverride!;
    }
    if (oldPin != activePin) {
      return const VaultResult.failure(
        VaultAuthFailure('Current PIN verification failed during rotation'),
      );
    }
    activePin = newPin;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> enrollInitialCredentials({
    required String pin,
    required GestureTemplate template,
  }) async {
    activePin = pin;
    return const VaultResult.success(null);
  }

  @override
  Future<LockoutCooldownInfo> getLockoutStatus() async => currentLockout;

  @override
  Future<void> recordFailedAttempt() async {
    failedAttempts++;
    if (failedAttempts >= 10) {
      currentLockout = LockoutCooldownInfo(
        tier: LockoutCooldownTierEnum.tier2FiveMinutes,
        consecutiveFailedAttempts: failedAttempts,
        deadlineMonotonicMs: 300000,
        remainingCooldownSeconds: 300,
      );
    } else if (failedAttempts == 5) {
      currentLockout = LockoutCooldownInfo(
        tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
        consecutiveFailedAttempts: failedAttempts,
        deadlineMonotonicMs: 30000,
        remainingCooldownSeconds: 30,
      );
    } else {
      currentLockout = LockoutCooldownInfo(
        tier: LockoutCooldownTierEnum.none,
        consecutiveFailedAttempts: failedAttempts,
        deadlineMonotonicMs: 0,
        remainingCooldownSeconds: 0,
      );
    }
  }

  @override
  Future<void> resetFailedAttempts() async {
    resetAttemptsCount++;
    failedAttempts = 0;
    currentLockout = LockoutCooldownInfo.none();
  }

  @override
  void clearSessionKeysFromRam() {
    clearKeysCount++;
  }

  @override
  Stream<VaultSessionState> get sessionStateStream => _stateController.stream;
}

final class AdversarialStorageRepository implements IVaultStorageRepository {
  VaultConfig config = VaultConfig();
  GestureTemplate? template;
  int purgeCalls = 0;
  int clearLockoutCalls = 0;
  int saveConfigCalls = 0;
  int saveTemplateCalls = 0;

  VaultResult<void>? saveConfigFailure;
  VaultResult<void>? saveTemplateFailure;
  VaultResult<void>? purgeFailure;

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async => VaultResult.success(config);

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig newConfig) async {
    saveConfigCalls++;
    if (saveConfigFailure != null) {
      return saveConfigFailure!;
    }
    config = newConfig;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<List<PrivatePlaylist>>> getPlaylists() async => const VaultResult.success([]);

  @override
  Future<VaultResult<PrivatePlaylist>> getPlaylistById(String id) async =>
      const VaultResult.failure(VaultStorageFailure('Not found'));

  @override
  Future<VaultResult<PrivatePlaylist>> createPlaylist({
    required String name,
    required String description,
    String? coverUri,
  }) async =>
      const VaultResult.failure(VaultStorageFailure('Not implemented'));

  @override
  Future<VaultResult<void>> updatePlaylist(PrivatePlaylist playlist) async =>
      const VaultResult.success(null);

  @override
  Future<VaultResult<void>> deletePlaylist(String playlistId) async =>
      const VaultResult.success(null);

  @override
  Future<VaultResult<void>> addTrackToPlaylist({
    required String playlistId,
    required PrivateTrackRef trackRef,
  }) async =>
      const VaultResult.success(null);

  @override
  Future<VaultResult<void>> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async =>
      const VaultResult.success(null);

  @override
  Future<VaultResult<void>> reorderTracksInPlaylist({
    required String playlistId,
    required List<String> trackIdsInOrder,
  }) async =>
      const VaultResult.success(null);

  @override
  Future<VaultResult<GestureTemplate>> loadGestureTemplate() async {
    final t = template;
    if (t != null) {
      return VaultResult.success(t);
    }
    return const VaultResult.failure(VaultStorageFailure('Template not found'));
  }

  @override
  Future<VaultResult<void>> saveGestureTemplate(GestureTemplate newTemplate) async {
    saveTemplateCalls++;
    if (saveTemplateFailure != null) {
      return saveTemplateFailure!;
    }
    template = newTemplate;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> purgeAllVaultData() async {
    purgeCalls++;
    if (purgeFailure != null) {
      return purgeFailure!;
    }
    return const VaultResult.success(null);
  }

  @override
  Future<int?> getPersistedLockoutDeadlineMs() async => null;

  @override
  Future<void> persistLockoutDeadlineMs(int deadlineMonotonicMs) async {}

  @override
  Future<void> clearPersistedLockoutDeadline() async {
    clearLockoutCalls++;
  }
}

final class AdversarialGestureRecognizer implements IGestureRecognizer {
  VaultResult<RecognitionScore>? evaluateResult;
  VaultResult<void>? consistencyResult;
  VaultResult<GestureTemplate>? synthesisResult;

  int evaluateCalls = 0;
  int consistencyCalls = 0;
  int synthesisCalls = 0;

  @override
  Future<VaultResult<RecognitionScore>> evaluateStroke({
    required GestureSample liveStroke,
    required GestureTemplate template,
    required GestureSensitivityTierEnum sensitivityTier,
  }) async {
    evaluateCalls++;
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
    synthesisCalls++;
    return synthesisResult ??
        VaultResult.success(
          GestureTemplate(
            id: 'adversarial_golden',
            normalizedPoints: List.generate(
              64,
              (i) => GesturePoint(x: i.toDouble(), y: i.toDouble(), timestampMs: (i + 1) * 10),
            ),
            rubineFeatureVector: const [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0],
            createdAtEpochMs: 5000,
          ),
        );
  }

  @override
  Future<VaultResult<void>> validateSampleConsistency({
    required List<GestureSample> samples,
  }) async {
    consistencyCalls++;
    return consistencyResult ?? const VaultResult.success(null);
  }
}

final class AdversarialMonotonicClock implements IMonotonicClock {
  int currentMs = 0;

  @override
  int get currentMonotonicMs => currentMs;

  @override
  int get elapsedMilliseconds => currentMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

List<GestureSample> buildGestureSamples(int count) {
  return List.generate(
    count,
    (index) => GestureSample(
      points: [
        GesturePoint(x: 10.0 + index, y: 10.0 + index, timestampMs: 10),
        GesturePoint(x: 20.0 + index, y: 20.0 + index, timestampMs: 50),
        GesturePoint(x: 30.0 + index, y: 30.0 + index, timestampMs: 100),
      ],
      totalLength: 28.28,
      sampledAtEpochMs: 2000 + index,
    ),
  );
}

// =============================================================================
// Adversarial Test Suites
// =============================================================================

void main() {
  group('Adversarial Stress: UnlockVaultUseCase', () {
    late AdversarialAuthService authService;
    late UnlockVaultUseCase useCase;

    setUp(() {
      authService = AdversarialAuthService();
      useCase = UnlockVaultUseCase(authService: authService);
    });

    test('Locked out state blocks all authentication without hitting auth service or recording attempts', () async {
      authService.currentLockout = LockoutCooldownInfo(
        tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
        consecutiveFailedAttempts: 5,
        deadlineMonotonicMs: 70000,
        remainingCooldownSeconds: 30,
      );

      // Attempt with correct PIN
      final pinResult = await useCase.execute(const PinUnlockParams('123456'));
      expect(pinResult, isA<VaultFailureResult<AuthSession>>());
      final pinFailure = (pinResult as VaultFailureResult<AuthSession>).failure;
      expect(pinFailure, isA<VaultLockoutFailure>());
      expect((pinFailure as VaultLockoutFailure).remainingCooldownSeconds, 30);
      expect(pinFailure.deadlineMonotonicMs, 70000);
      expect(authService.authenticateWithPinCalls, 0);
      expect(authService.failedAttempts, 0);

      // Attempt with Biometrics while locked out
      final bioResult = await useCase.execute(const BiometricUnlockParams());
      expect(bioResult, isA<VaultFailureResult<AuthSession>>());
      final bioFailure = (bioResult as VaultFailureResult<AuthSession>).failure;
      expect(bioFailure, isA<VaultLockoutFailure>());
      expect(authService.authenticateWithBiometricsCalls, 0);
      expect(authService.failedAttempts, 0);
    });

    test('PIN format violations: exhaustive symbol, whitespace, length, and non-ASCII attack vectors', () async {
      final invalidPins = <String>[
        '',
        '1',
        '12',
        '123',
        '1234',
        '12345',
        '1234567',
        '12345678',
        'abcdef',
        'ABCDEF',
        '12345a',
        'A12345',
        '12-345',
        '12.345',
        '12+345',
        '12 345',
        ' 12345',
        '12345 ',
        '      ',
        '123\n45',
        '123\t45',
        '123\x0045',
        '12345#',
        '12345*',
        '۱۲৩৪৫۶', // Arabic-Indic digits (not ASCII 48..57)
        '１２３４５６', // Full-width digits (not ASCII 48..57)
      ];

      for (final badPin in invalidPins) {
        final result = await useCase.execute(PinUnlockParams(badPin));
        expect(
          result,
          isA<VaultFailureResult<AuthSession>>(),
          reason: 'PIN "$badPin" should be rejected as invalid format',
        );
        final failure = (result as VaultFailureResult<AuthSession>).failure;
        expect(
          failure,
          isA<VaultValidationFailure>(),
          reason: 'PIN "$badPin" must produce VaultValidationFailure',
        );
      }
      // Zero calls to authService and zero failed attempts recorded for validation failures
      expect(authService.authenticateWithPinCalls, 0);
      expect(authService.failedAttempts, 0);
    });

    test('Lockout cooldown tier escalation: 5 failures triggers 30s, 10 failures triggers 5m', () async {
      // Failures 1 through 4: remaining attempts count down from 4 to 1
      for (var attempt = 1; attempt <= 4; attempt++) {
        final res = await useCase.execute(const PinUnlockParams('000000'));
        expect(res, isA<VaultFailureResult<AuthSession>>());
        final f = (res as VaultFailureResult<AuthSession>).failure;
        expect(f, isA<VaultAuthFailure>());
        expect((f as VaultAuthFailure).remainingAttempts, 5 - attempt);
      }
      expect(authService.failedAttempts, 4);

      // 5th failure: triggers Tier 1 (30s) lockout
      final res5 = await useCase.execute(const PinUnlockParams('000000'));
      expect(res5, isA<VaultFailureResult<AuthSession>>());
      final f5 = (res5 as VaultFailureResult<AuthSession>).failure;
      expect(f5, isA<VaultLockoutFailure>());
      final lockout5 = f5 as VaultLockoutFailure;
      expect(lockout5.remainingCooldownSeconds, 30);
      expect(lockout5.deadlineMonotonicMs, 30000);
      expect(authService.failedAttempts, 5);

      // Now simulate cooldown has elapsed by changing lockout status in service to none
      authService.currentLockout = LockoutCooldownInfo(
        tier: LockoutCooldownTierEnum.none,
        consecutiveFailedAttempts: 5,
        deadlineMonotonicMs: 0,
        remainingCooldownSeconds: 0,
      );

      // Failures 6 through 9: remaining attempts count down from 4 to 1 (towards 10)
      for (var attempt = 6; attempt <= 9; attempt++) {
        final res = await useCase.execute(const PinUnlockParams('000000'));
        expect(res, isA<VaultFailureResult<AuthSession>>());
        final f = (res as VaultFailureResult<AuthSession>).failure;
        expect(f, isA<VaultAuthFailure>());
        expect((f as VaultAuthFailure).remainingAttempts, 10 - attempt);
      }
      expect(authService.failedAttempts, 9);

      // 10th failure: triggers Tier 2 (5m = 300s) lockout
      final res10 = await useCase.execute(const PinUnlockParams('000000'));
      expect(res10, isA<VaultFailureResult<AuthSession>>());
      final f10 = (res10 as VaultFailureResult<AuthSession>).failure;
      expect(f10, isA<VaultLockoutFailure>());
      final lockout10 = f10 as VaultLockoutFailure;
      expect(lockout10.remainingCooldownSeconds, 300);
      expect(lockout10.deadlineMonotonicMs, 300000);
      expect(authService.failedAttempts, 10);
    });

    test('Interleaved failures and success: successful auth resets failed counter completely', () async {
      // 3 failed attempts
      for (var i = 0; i < 3; i++) {
        await useCase.execute(const PinUnlockParams('000000'));
      }
      expect(authService.failedAttempts, 3);

      // 4th attempt: correct PIN
      final successResult = await useCase.execute(const PinUnlockParams('123456'));
      expect(successResult, isA<VaultSuccess<AuthSession>>());
      expect(authService.resetAttemptsCount, 1);
      expect(authService.failedAttempts, 0);

      // Next failure should report 4 remaining attempts again (5 - 1)
      final failResult = await useCase.execute(const PinUnlockParams('000000'));
      expect(failResult, isA<VaultFailureResult<AuthSession>>());
      final f = (failResult as VaultFailureResult<AuthSession>).failure;
      expect(f, isA<VaultAuthFailure>());
      expect((f as VaultAuthFailure).remainingAttempts, 4);
    });

    test('Biometric failure increments failed attempt counter and triggers lockout on threshold', () async {
      authService.biometricsAvailable = false;

      // 4 biometric failures
      for (var i = 0; i < 4; i++) {
        final res = await useCase.execute(const BiometricUnlockParams());
        expect(res, isA<VaultFailureResult<AuthSession>>());
        final f = (res as VaultFailureResult<AuthSession>).failure;
        expect(f, isA<VaultAuthFailure>());
        expect((f as VaultAuthFailure).remainingAttempts, 4 - i);
      }

      // 5th biometric failure: triggers lockout
      final res5 = await useCase.execute(const BiometricUnlockParams());
      expect(res5, isA<VaultFailureResult<AuthSession>>());
      final f5 = (res5 as VaultFailureResult<AuthSession>).failure;
      expect(f5, isA<VaultLockoutFailure>());
      expect((f5 as VaultLockoutFailure).remainingCooldownSeconds, 30);
    });
  });

  group('Adversarial Stress: VerifySessionCoolOffUseCase', () {
    late AdversarialMonotonicClock clock;
    late VerifySessionCoolOffUseCase useCase;
    late VaultConfig config15m;
    late VaultConfig configNever;
    late AuthSession session;

    setUp(() {
      clock = AdversarialMonotonicClock();
      useCase = VerifySessionCoolOffUseCase(clock: clock);
      config15m = VaultConfig(activeReauthInterval: ActiveReauthIntervalEnum.every15Minutes);
      configNever = VaultConfig(activeReauthInterval: ActiveReauthIntervalEnum.never);
      session = AuthSession(
        sessionToken: 'adv_sess_1',
        sessionStartedEpochMs: 1000,
        lastActiveEpochMs: 1000,
        authMethod: AuthMethodEnum.pin,
      );
    });

    test('Monotonic clock edge cases: exact deadline equality vs +1ms expiry vs -1ms valid', () {
      const deadline = 50000;
      final unlockedState = VaultUnlockedState(
        session: session,
        unlockedAtMonotonicMs: 10000,
        reauthDeadlineMonotonicMs: deadline,
      );

      // 1 ms before deadline: sessionValid
      clock.currentMs = deadline - 1;
      final rBefore = useCase.execute(
        VerifyCoolOffParams(currentState: unlockedState, config: config15m),
      );
      expect((rBefore as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.sessionValid);

      // Exact deadline equality: reauthRequired
      clock.currentMs = deadline;
      final rExact = useCase.execute(
        VerifyCoolOffParams(currentState: unlockedState, config: config15m),
      );
      expect((rExact as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.reauthRequired);

      // 1 ms post-deadline: reauthRequired
      clock.currentMs = deadline + 1;
      final rAfter = useCase.execute(
        VerifyCoolOffParams(currentState: unlockedState, config: config15m),
      );
      expect((rAfter as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.reauthRequired);
    });

    test('Background grace edge cases: exact deadline equality vs post-deadline expiry', () {
      const graceDeadline = 80000;
      final graceState = VaultBackgroundGraceState(
        session: session,
        enteredBackgroundMonotonicMs: 50000,
        graceTimeoutMs: 30000,
        graceDeadlineMonotonicMs: graceDeadline,
      );

      // 1 ms before: sessionValid
      clock.currentMs = graceDeadline - 1;
      final rBefore = useCase.execute(
        VerifyCoolOffParams(currentState: graceState, config: config15m),
      );
      expect((rBefore as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.sessionValid);

      // Exact deadline: graceExpiredLock
      clock.currentMs = graceDeadline;
      final rExact = useCase.execute(
        VerifyCoolOffParams(currentState: graceState, config: config15m),
      );
      expect((rExact as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.graceExpiredLock);

      // Post-deadline: graceExpiredLock
      clock.currentMs = graceDeadline + 5000;
      final rAfter = useCase.execute(
        VerifyCoolOffParams(currentState: graceState, config: config15m),
      );
      expect((rAfter as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.graceExpiredLock);
    });

    test('Lockout cooldown edge cases: active before deadline, reset on exact and post deadline', () {
      const lockoutDeadline = 60000;
      final lockoutState = VaultLockoutCooldownState(
        tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
        cooldownStartedMonotonicMs: 30000,
        durationMs: 30000,
        deadlineMonotonicMs: lockoutDeadline,
        failedAttemptsCount: 5,
      );

      // 1 ms before: lockoutActive
      clock.currentMs = lockoutDeadline - 1;
      final rBefore = useCase.execute(
        VerifyCoolOffParams(currentState: lockoutState, config: config15m),
      );
      expect((rBefore as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.lockoutActive);

      // Exact deadline: lockoutElapsedReset
      clock.currentMs = lockoutDeadline;
      final rExact = useCase.execute(
        VerifyCoolOffParams(currentState: lockoutState, config: config15m),
      );
      expect((rExact as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.lockoutElapsedReset);

      // Post deadline: lockoutElapsedReset
      clock.currentMs = lockoutDeadline + 10000;
      final rAfter = useCase.execute(
        VerifyCoolOffParams(currentState: lockoutState, config: config15m),
      );
      expect((rAfter as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.lockoutElapsedReset);
    });

    test('Large monotonic timestamp handling (near 64-bit int boundaries)', () {
      // 1 trillion milliseconds (~31 years monotonic uptime)
      const hugeDeadline = 1000000000000;
      final unlockedState = VaultUnlockedState(
        session: session,
        unlockedAtMonotonicMs: 999999000000,
        reauthDeadlineMonotonicMs: hugeDeadline,
      );

      clock.currentMs = hugeDeadline - 100;
      final rBefore = useCase.execute(
        VerifyCoolOffParams(currentState: unlockedState, config: config15m),
      );
      expect((rBefore as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.sessionValid);

      clock.currentMs = hugeDeadline + 100;
      final rAfter = useCase.execute(
        VerifyCoolOffParams(currentState: unlockedState, config: config15m),
      );
      expect((rAfter as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.reauthRequired);
    });

    test('ActiveReauthIntervalEnum.never unconditionally permits session to remain valid', () {
      final unlockedState = VaultUnlockedState(
        session: session,
        unlockedAtMonotonicMs: 1000,
        reauthDeadlineMonotonicMs: 2000,
      );

      // Monotonic time is decades ahead
      clock.currentMs = 999999999999;
      final result = useCase.execute(
        VerifyCoolOffParams(currentState: unlockedState, config: configNever),
      );
      expect((result as VaultSuccess<CoolOffDecisionEnum>).data, CoolOffDecisionEnum.sessionValid);
    });
  });

  group('Adversarial Stress: EnrollGestureUseCase', () {
    late AdversarialAuthService authService;
    late AdversarialGestureRecognizer recognizer;
    late AdversarialStorageRepository storageRepository;
    late EnrollGestureUseCase useCase;

    setUp(() {
      authService = AdversarialAuthService();
      recognizer = AdversarialGestureRecognizer();
      storageRepository = AdversarialStorageRepository();
      useCase = EnrollGestureUseCase(
        authService: authService,
        recognizer: recognizer,
        storageRepository: storageRepository,
      );
    });

    test('Sample count boundary violations: strictly rejects sample count != 3', () async {
      final badSampleCounts = [0, 1, 2, 4, 5, 10, 50];

      for (final count in badSampleCounts) {
        final result = await useCase.execute(
          EnrollGestureParams(
            samples: buildGestureSamples(count),
            authorizationPin: '123456',
          ),
        );
        expect(
          result,
          isA<VaultFailureResult<GestureTemplate>>(),
          reason: 'Sample count $count must be rejected',
        );
        final failure = (result as VaultFailureResult<GestureTemplate>).failure;
        expect(failure, isA<VaultValidationFailure>());
        expect(failure.message, 'Exactly 3 gesture samples are required for enrollment.');
      }

      // Ensure no downstream interactions occurred
      expect(authService.authenticateWithPinCalls, 0);
      expect(recognizer.consistencyCalls, 0);
      expect(recognizer.synthesisCalls, 0);
      expect(storageRepository.saveTemplateCalls, 0);
    });

    test('Authorization PIN failure blocks recognition and storage completely', () async {
      final result = await useCase.execute(
        EnrollGestureParams(
          samples: buildGestureSamples(3),
          authorizationPin: '000000', // Invalid PIN
        ),
      );

      expect(result, isA<VaultFailureResult<GestureTemplate>>());
      final failure = (result as VaultFailureResult<GestureTemplate>).failure;
      expect(failure, isA<VaultAuthFailure>());
      expect(authService.authenticateWithPinCalls, 1);
      expect(recognizer.consistencyCalls, 0);
      expect(recognizer.synthesisCalls, 0);
      expect(storageRepository.saveTemplateCalls, 0);
    });

    test('Divergent sample consistency rejection halts pipeline prior to DBA synthesis', () async {
      recognizer.consistencyResult = const VaultResult.failure(
        VaultGestureFailure('Pairwise DTW distance exceeded threshold (divergent strokes)'),
      );

      final result = await useCase.execute(
        EnrollGestureParams(
          samples: buildGestureSamples(3),
          authorizationPin: '123456',
        ),
      );

      expect(result, isA<VaultFailureResult<GestureTemplate>>());
      final failure = (result as VaultFailureResult<GestureTemplate>).failure;
      expect(failure, isA<VaultGestureFailure>());
      expect(authService.authenticateWithPinCalls, 1);
      expect(recognizer.consistencyCalls, 1);
      expect(recognizer.synthesisCalls, 0);
      expect(storageRepository.saveTemplateCalls, 0);
    });

    test('Synthesis failure blocks storage persistence', () async {
      recognizer.synthesisResult = const VaultResult.failure(
        VaultGestureFailure('DBA Barycenter averaging failed to converge in isolate'),
      );

      final result = await useCase.execute(
        EnrollGestureParams(
          samples: buildGestureSamples(3),
          authorizationPin: '123456',
        ),
      );

      expect(result, isA<VaultFailureResult<GestureTemplate>>());
      final failure = (result as VaultFailureResult<GestureTemplate>).failure;
      expect(failure, isA<VaultGestureFailure>());
      expect(recognizer.synthesisCalls, 1);
      expect(storageRepository.saveTemplateCalls, 0);
    });

    test('Storage failure propagates cleanly when disk write fails', () async {
      storageRepository.saveTemplateFailure = const VaultResult.failure(
        VaultStorageFailure('Encrypted storage disk full or write protected'),
      );

      final result = await useCase.execute(
        EnrollGestureParams(
          samples: buildGestureSamples(3),
          authorizationPin: '123456',
        ),
      );

      expect(result, isA<VaultFailureResult<GestureTemplate>>());
      final failure = (result as VaultFailureResult<GestureTemplate>).failure;
      expect(failure, isA<VaultStorageFailure>());
      expect(storageRepository.saveTemplateCalls, 1);
    });
  });

  group('Adversarial Stress: RotatePinUseCase', () {
    late AdversarialAuthService authService;
    late RotatePinUseCase useCase;

    setUp(() {
      authService = AdversarialAuthService();
      useCase = RotatePinUseCase(authService: authService);
    });

    test('Identical PIN rejection: oldPin == newPin fails with VaultValidationFailure', () async {
      final identicalPins = ['123456', '000000', '999999', '654321'];

      for (final pin in identicalPins) {
        final result = await useCase.execute(
          RotatePinParams(oldPin: pin, newPin: pin),
        );

        expect(result, isA<VaultFailureResult<void>>());
        final failure = (result as VaultFailureResult<void>).failure;
        expect(failure, isA<VaultValidationFailure>());
        expect(failure.message, 'New PIN must differ from current PIN.');
      }

      expect(authService.rotatePinCalls, 0);
    });

    test('Old PIN format violations: rejected before auth service invocation', () async {
      final invalidOldPins = ['', '1', '12345', '1234567', 'abcdef', '123 45', '12-345'];

      for (final badOld in invalidOldPins) {
        final result = await useCase.execute(
          RotatePinParams(oldPin: badOld, newPin: '654321'),
        );

        expect(result, isA<VaultFailureResult<void>>());
        final failure = (result as VaultFailureResult<void>).failure;
        expect(failure, isA<VaultValidationFailure>());
        expect(failure.message, 'Current PIN must consist of exactly 6 numeric digits.');
      }

      expect(authService.rotatePinCalls, 0);
    });

    test('New PIN format violations: rejected before auth service invocation', () async {
      final invalidNewPins = ['', '1', '12345', '1234567', 'abcdef', '123 45', '12-345'];

      for (final badNew in invalidNewPins) {
        final result = await useCase.execute(
          RotatePinParams(oldPin: '123456', newPin: badNew),
        );

        expect(result, isA<VaultFailureResult<void>>());
        final failure = (result as VaultFailureResult<void>).failure;
        expect(failure, isA<VaultValidationFailure>());
        expect(failure.message, 'New PIN must consist of exactly 6 numeric digits.');
      }

      expect(authService.rotatePinCalls, 0);
    });

    test('Rotation fails if current PIN step-up verification in auth service fails', () async {
      final result = await useCase.execute(
        const RotatePinParams(oldPin: '000000', newPin: '654321'),
      );

      expect(result, isA<VaultFailureResult<void>>());
      final failure = (result as VaultFailureResult<void>).failure;
      expect(failure, isA<VaultAuthFailure>());
      expect(authService.rotatePinCalls, 1);
    });

    test('Successful rotation re-wraps key and updates active PIN', () async {
      final result = await useCase.execute(
        const RotatePinParams(oldPin: '123456', newPin: '654321'),
      );

      expect(result, isA<VaultSuccess<void>>());
      expect(authService.rotatePinCalls, 1);
      expect(authService.activePin, '654321');
    });
  });

  group('Adversarial Stress: MutateVaultConfigUseCase', () {
    late AdversarialAuthService authService;
    late AdversarialStorageRepository storageRepository;
    late MutateVaultConfigUseCase useCase;
    late VaultConfig baseConfig;

    setUp(() {
      authService = AdversarialAuthService();
      storageRepository = AdversarialStorageRepository();
      useCase = MutateVaultConfigUseCase(
        authService: authService,
        storageRepository: storageRepository,
      );
      baseConfig = VaultConfig();
    });

    test('Sensitive policy mutation without stepUpPin is strictly rejected', () async {
      final sensitiveMutations = [
        baseConfig.copyWith(biometricAuth: BiometricAuthPolicyEnum.pinAndBiometricStrong),
      ];

      for (final mutated in sensitiveMutations) {
        final result = await useCase.execute(
          MutateVaultConfigParams(
            currentConfig: baseConfig,
            newConfig: mutated,
            stepUpPin: null, // Omitted PIN
          ),
        );

        expect(result, isA<VaultFailureResult<VaultConfig>>());
        final failure = (result as VaultFailureResult<VaultConfig>).failure;
        expect(failure, isA<VaultAuthFailure>());
        expect(failure.message, 'Step-up PIN is required to mutate sensitive security policies.');
      }

      expect(authService.authenticateWithPinCalls, 0);
      expect(storageRepository.saveConfigCalls, 0);
    });

    test('Sensitive policy mutation with invalid stepUpPin fails with VaultAuthFailure', () async {
      final mutated = baseConfig.copyWith(
        biometricAuth: BiometricAuthPolicyEnum.pinAndBiometricStrong,
      );

      final result = await useCase.execute(
        MutateVaultConfigParams(
          currentConfig: baseConfig,
          newConfig: mutated,
          stepUpPin: '000000', // Invalid PIN
        ),
      );

      expect(result, isA<VaultFailureResult<VaultConfig>>());
      final failure = (result as VaultFailureResult<VaultConfig>).failure;
      expect(failure, isA<VaultAuthFailure>());
      expect(authService.authenticateWithPinCalls, 1);
      expect(storageRepository.saveConfigCalls, 0);
    });

    test('Non-sensitive policy mutations succeed without stepUpPin', () async {
      final nonSensitiveMutations = [
        baseConfig.copyWith(themePalette: VaultThemePalettePolicyEnum.forestNoir),
        baseConfig.copyWith(screenSecurity: ScreenSecurityPolicyEnum.allowCapture),
        baseConfig.copyWith(activeReauthInterval: ActiveReauthIntervalEnum.every5Minutes),
        baseConfig.copyWith(backgroundGraceTimeout: BackgroundGraceTimeoutEnum.fiveMinutes),
        baseConfig.copyWith(metadataVisibility: MetadataVisibilityPolicyEnum.maskWithPlaceholder),
        baseConfig.copyWith(lockPlaybackBehavior: LockPlaybackBehaviorEnum.stopImmediately),
        baseConfig.copyWith(gestureSensitivity: GestureSensitivityTierEnum.strict92Percent),
        baseConfig.copyWith(gestureVisibility: GestureVisibilityPolicyEnum.faintDissipatingHairline),
        baseConfig.copyWith(keypadLayout: KeypadLayoutPolicyEnum.randomizedPerAttempt),
      ];

      for (final mutated in nonSensitiveMutations) {
        final result = await useCase.execute(
          MutateVaultConfigParams(
            currentConfig: baseConfig,
            newConfig: mutated,
            stepUpPin: null,
          ),
        );

        expect(result, isA<VaultSuccess<VaultConfig>>());
      }

      // Step-up authentication never called for non-sensitive changes
      expect(authService.authenticateWithPinCalls, 0);
      expect(storageRepository.saveConfigCalls, nonSensitiveMutations.length);
    });

    test('Decoy persona whitespace rejection: title, artist, album must not be blank', () async {
      final blankDecoyVariants = [
        const VaultConfig.constant(decoyTitle: '   '),
        const VaultConfig.constant(decoyTitle: '\t\n'),
        const VaultConfig.constant(decoyArtist: '   '),
        const VaultConfig.constant(decoyArtist: '\t\n'),
        const VaultConfig.constant(decoyAlbum: '   '),
        const VaultConfig.constant(decoyAlbum: '\t\n'),
      ];

      for (final badDecoyConfig in blankDecoyVariants) {
        final result = await useCase.execute(
          MutateVaultConfigParams(
            currentConfig: baseConfig,
            newConfig: badDecoyConfig,
          ),
        );

        expect(result, isA<VaultFailureResult<VaultConfig>>());
        final failure = (result as VaultFailureResult<VaultConfig>).failure;
        expect(failure, isA<VaultValidationFailure>());
      }

      expect(storageRepository.saveConfigCalls, 0);
    });

    test('Storage failure propagation during config mutation', () async {
      storageRepository.saveConfigFailure = const VaultResult.failure(
        VaultStorageFailure('Disk write I/O error'),
      );

      final mutated = baseConfig.copyWith(
        themePalette: VaultThemePalettePolicyEnum.forestNoir,
      );

      final result = await useCase.execute(
        MutateVaultConfigParams(
          currentConfig: baseConfig,
          newConfig: mutated,
        ),
      );

      expect(result, isA<VaultFailureResult<VaultConfig>>());
      final failure = (result as VaultFailureResult<VaultConfig>).failure;
      expect(failure, isA<VaultStorageFailure>());
    });
  });

  group('Adversarial Stress: PurgeVaultDataUseCase', () {
    late AdversarialAuthService authService;
    late AdversarialStorageRepository storageRepository;
    late PurgeVaultDataUseCase useCase;

    setUp(() {
      authService = AdversarialAuthService();
      storageRepository = AdversarialStorageRepository();
      useCase = PurgeVaultDataUseCase(
        authService: authService,
        storageRepository: storageRepository,
      );
    });

    test('Purge without valid confirmation PIN is rejected and leaves data intact', () async {
      final result = await useCase.execute(
        const PurgeVaultDataParams(confirmationPin: '999999'),
      );

      expect(result, isA<VaultFailureResult<void>>());
      final failure = (result as VaultFailureResult<void>).failure;
      expect(failure, isA<VaultAuthFailure>());
      expect(storageRepository.purgeCalls, 0);
      expect(storageRepository.clearLockoutCalls, 0);
      expect(authService.clearKeysCount, 0);
    });

    test('Storage purge failure does NOT clear lockout deadline or zero session keys prematurely', () async {
      storageRepository.purgeFailure = const VaultResult.failure(
        VaultStorageFailure('Failed to unlink encrypted database files'),
      );

      final result = await useCase.execute(
        const PurgeVaultDataParams(confirmationPin: '123456'),
      );

      expect(result, isA<VaultFailureResult<void>>());
      final failure = (result as VaultFailureResult<void>).failure;
      expect(failure, isA<VaultStorageFailure>());
      expect(storageRepository.purgeCalls, 1);
      expect(storageRepository.clearLockoutCalls, 0);
      expect(authService.clearKeysCount, 0);
    });

    test('Successful purge executes atomic storage wipe, clears lockout, and flushes RAM keys', () async {
      final result = await useCase.execute(
        const PurgeVaultDataParams(confirmationPin: '123456'),
      );

      expect(result, isA<VaultSuccess<void>>());
      expect(storageRepository.purgeCalls, 1);
      expect(storageRepository.clearLockoutCalls, 1);
      expect(authService.clearKeysCount, 1);
    });
  });
}
