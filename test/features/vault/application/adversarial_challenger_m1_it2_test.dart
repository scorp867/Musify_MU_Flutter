import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/active_reauth_interval.dart';
import 'package:musify_mu/features/vault/domain/policies/background_grace_timeout.dart';
import 'package:musify_mu/features/vault/domain/policies/keypad_layout_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/screen_security_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/pin_pad_state.dart';
import 'package:musify_mu/features/vault/domain/states/settings_mutation_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/mutate_vault_config_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';

class AdversarialMonotonicClock implements IMonotonicClock {
  int timeMs = 10000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class AdversarialStorageRepository implements IVaultStorageRepository {
  VaultConfig config = const VaultConfig.constant();
  bool shouldFailSave = false;
  String failureReason = 'Disk write failed';
  Duration writeDelay = Duration.zero;
  int failOnSaveIndex = -1;
  int saveCount = 0;
  final List<VaultConfig> savedHistory = <VaultConfig>[];
  final List<Completer<void>> pendingWrites = <Completer<void>>[];

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(config);

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig newConfig) async {
    saveCount++;
    if (writeDelay > Duration.zero) {
      await Future<void>.delayed(writeDelay);
    }
    if (shouldFailSave || saveCount == failOnSaveIndex) {
      return VaultResult.failure(VaultStorageFailure(failureReason));
    }
    config = newConfig;
    savedHistory.add(newConfig);
    return const VaultResult.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdversarialAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> _sessionController =
      StreamController<VaultSessionState>.broadcast();

  int consecutiveFailedAttempts = 0;
  LockoutCooldownTierEnum activeTier = LockoutCooldownTierEnum.none;
  int lockoutDeadlineMs = 0;
  int resetAttemptsCallCount = 0;

  Stream<VaultSessionState> get sessionStateStream => _sessionController.stream;

  @override
  Future<LockoutCooldownInfo> getLockoutStatus() async {
    final remainingSec = activeTier == LockoutCooldownTierEnum.none
        ? 0
        : max(0, (lockoutDeadlineMs - 10000) ~/ 1000);
    return LockoutCooldownInfo(
      tier: activeTier,
      remainingCooldownSeconds: remainingSec,
      deadlineMonotonicMs: lockoutDeadlineMs,
      consecutiveFailedAttempts: consecutiveFailedAttempts,
    );
  }

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({required String pin}) async {
    if (activeTier != LockoutCooldownTierEnum.none) {
      return VaultResult.failure(
        VaultLockoutFailure(
          'Account locked out',
          remainingCooldownSeconds: 30,
          deadlineMonotonicMs: lockoutDeadlineMs,
        ),
      );
    }

    if (pin == '123456') {
      return VaultResult.success(
        AuthSession(
          sessionToken: 'valid_session_token',
          sessionStartedEpochMs: 1000,
          lastActiveEpochMs: 1000,
          authMethod: AuthMethodEnum.pin,
        ),
      );
    }

    return const VaultResult.failure(VaultAuthFailure('Invalid PIN'));
  }

  @override
  Future<void> recordFailedAttempt() async {
    consecutiveFailedAttempts++;
    if (consecutiveFailedAttempts >= 5) {
      activeTier = LockoutCooldownTierEnum.tier1ThirtySeconds;
      lockoutDeadlineMs = 40000;
    }
  }

  @override
  Future<void> resetFailedAttempts() async {
    resetAttemptsCallCount++;
    consecutiveFailedAttempts = 0;
    activeTier = LockoutCooldownTierEnum.none;
    lockoutDeadlineMs = 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Empirical Challenge 1: Concurrency Stress on SettingsMutationCubit', () {
    late AdversarialStorageRepository storageRepo;
    late AdversarialAuthService authService;
    late AdversarialMonotonicClock clock;
    late MutateVaultConfigUseCase mutateUseCase;
    late SettingsMutationCubit cubit;

    setUp(() {
      storageRepo = AdversarialStorageRepository();
      authService = AdversarialAuthService();
      clock = AdversarialMonotonicClock();
      mutateUseCase = MutateVaultConfigUseCase(
        authService: authService,
        storageRepository: storageRepo,
      );
      cubit = SettingsMutationCubit(
        storageRepository: storageRepo,
        mutateVaultConfigUseCase: mutateUseCase,
        authService: authService,
        monotonicClock: clock,
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('Rapid burst of 60 concurrent alternating mutations preserves strict FIFO execution and drops 0 writes', () async {
      // Set artificial write delay to simulate async I/O pressure
      storageRepo.writeDelay = const Duration(milliseconds: 5);

      final palettes = [
        VaultThemePalettePolicyEnum.warmEspresso,
        VaultThemePalettePolicyEnum.forestNoir,
      ];
      final securityPolicies = [
        ScreenSecurityPolicyEnum.blockScreenshotsAndRecents,
        ScreenSecurityPolicyEnum.allowCapture,
      ];
      final graceTimeouts = [
        BackgroundGraceTimeoutEnum.immediate,
        BackgroundGraceTimeoutEnum.thirtySeconds,
        BackgroundGraceTimeoutEnum.fiveMinutes,
      ];
      final playbackBehaviors = [
        LockPlaybackBehaviorEnum.continueMaskedInBackground,
        LockPlaybackBehaviorEnum.stopImmediately,
      ];
      final reauthIntervals = [
        ActiveReauthIntervalEnum.never,
        ActiveReauthIntervalEnum.every5Minutes,
        ActiveReauthIntervalEnum.every15Minutes,
      ];

      const burstSize = 60;
      final expectedConfigs = <VaultConfig>[];
      final futures = <Future<void>>[];

      var runningConfig = cubit.currentConfig;
      for (var i = 0; i < burstSize; i++) {
        runningConfig = runningConfig.copyWith(
          themePalette: palettes[i % palettes.length],
          screenSecurity: securityPolicies[i % securityPolicies.length],
          backgroundGraceTimeout: graceTimeouts[i % graceTimeouts.length],
          lockPlaybackBehavior: playbackBehaviors[i % playbackBehaviors.length],
          activeReauthInterval: reauthIntervals[i % reauthIntervals.length],
        );
        expectedConfigs.add(runningConfig);

        // Fire mutation into cubit concurrently without awaiting
        futures.add(cubit.updateGeneralPolicy(runningConfig));
      }

      // Await all concurrent bursts to finish
      await Future.wait(futures);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Verification 1: Exactly 60 writes executed (ZERO dropped mutations)
      expect(storageRepo.saveCount, equals(burstSize),
          reason: 'Every concurrent mutation must be queued and saved.');

      // Verification 2: Strict FIFO completion order
      expect(storageRepo.savedHistory.length, equals(burstSize));
      for (var i = 0; i < burstSize; i++) {
        expect(
          storageRepo.savedHistory[i].themePalette,
          equals(expectedConfigs[i].themePalette),
          reason: 'Mutation $i themePalette was out of FIFO order.',
        );
        expect(
          storageRepo.savedHistory[i].screenSecurity,
          equals(expectedConfigs[i].screenSecurity),
          reason: 'Mutation $i screenSecurity was out of FIFO order.',
        );
        expect(
          storageRepo.savedHistory[i].backgroundGraceTimeout,
          equals(expectedConfigs[i].backgroundGraceTimeout),
          reason: 'Mutation $i backgroundGraceTimeout was out of FIFO order.',
        );
        expect(
          storageRepo.savedHistory[i].lockPlaybackBehavior,
          equals(expectedConfigs[i].lockPlaybackBehavior),
          reason: 'Mutation $i lockPlaybackBehavior was out of FIFO order.',
        );
        expect(
          storageRepo.savedHistory[i].activeReauthInterval,
          equals(expectedConfigs[i].activeReauthInterval),
          reason: 'Mutation $i activeReauthInterval was out of FIFO order.',
        );
      }

      // Verification 3: Final state is cleanly SyncedIdle with latest config
      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());
      expect(cubit.currentConfig, equals(expectedConfigs.last));
      expect(storageRepo.config, equals(expectedConfigs.last));
    });

    test('Queue resilience: A failed mutation in the queue does not deadlock subsequent queued mutations', () async {
      storageRepo.writeDelay = const Duration(milliseconds: 5);
      storageRepo.failOnSaveIndex = 2;

      final successConfig1 = cubit.currentConfig.copyWith(
        themePalette: VaultThemePalettePolicyEnum.forestNoir,
      );
      final failingConfig = cubit.currentConfig.copyWith(
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.stopImmediately,
      );
      final successConfig2 = cubit.currentConfig.copyWith(
        themePalette: VaultThemePalettePolicyEnum.warmEspresso,
      );

      // Launch 3 mutations rapidly
      final f1 = cubit.updateGeneralPolicy(successConfig1);
      final f2 = cubit.updateGeneralPolicy(failingConfig);
      final f3 = cubit.updateGeneralPolicy(successConfig2);

      await Future.wait([f1, f2, f3]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(storageRepo.saveCount, equals(3));
      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());
      expect(cubit.currentConfig.themePalette, equals(VaultThemePalettePolicyEnum.warmEspresso));
    });
  });

  group('Empirical Challenge 2: Monotonic Lockout Bypass Resistance on PinPadCubit', () {
    late AdversarialAuthService authService;
    late AdversarialMonotonicClock clock;
    late UnlockVaultUseCase unlockUseCase;
    late PinPadCubit cubit;

    setUp(() {
      authService = AdversarialAuthService();
      clock = AdversarialMonotonicClock();
      unlockUseCase = UnlockVaultUseCase(authService: authService);
      cubit = PinPadCubit(
        unlockVaultUseCase: unlockUseCase,
        authService: authService,
        monotonicClock: clock,
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('Aggressive bypass attack: 100 rapid resetToIdle calls cannot terminate lockout state or timer', () async {
      const deadline = 40000; // 30s in future relative to clock 10000
      cubit.enterLockout(deadlineMonotonicMs: deadline, initialRemainingSeconds: 30);

      expect(cubit.state, isA<PinPadLockedOutState>());
      final initialLocked = cubit.state as PinPadLockedOutState;
      expect(initialLocked.cooldownRemainingSeconds, equals(30));
      expect(initialLocked.deadlineMonotonicMs, equals(deadline));

      final stateEmissions = <PinPadState>[];
      final sub = cubit.stream.listen(stateEmissions.add);

      // Attack: Spammer repeatedly hammers resetToIdle, clear, digits, and backspaces
      for (var i = 0; i < 100; i++) {
        cubit.resetToIdle();
        cubit.clear();
        cubit.onBackspace();
        cubit.onDigitEntered(i % 10);
      }

      // Assert state did NOT revert to PinPadIdleInputState
      expect(cubit.state, isA<PinPadLockedOutState>());
      expect((cubit.state as PinPadLockedOutState).cooldownRemainingSeconds, equals(30));

      // Advance clock by 5 seconds: timer must still be ticking and emit tick
      clock.timeMs += 5000;
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      // State is still locked out, and timer successfully ticked down to 25s
      expect(cubit.state, isA<PinPadLockedOutState>());
      expect((cubit.state as PinPadLockedOutState).cooldownRemainingSeconds, equals(25));

      // Hammer again while countdown is running
      for (var i = 0; i < 50; i++) {
        cubit.resetToIdle();
      }
      expect(cubit.state, isA<PinPadLockedOutState>());
      expect((cubit.state as PinPadLockedOutState).cooldownRemainingSeconds, equals(25));

      // Advance past deadline to complete
      clock.timeMs = 41000;
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      // Only now does it safely recover to idle
      expect(cubit.state, isA<PinPadIdleInputState>());
      expect(authService.resetAttemptsCallCount, equals(1));

      await sub.cancel();
    });

    test('Keypad layout updates during lockout do not break lockout state or leak digits', () {
      cubit.enterLockout(deadlineMonotonicMs: 30000, initialRemainingSeconds: 20);
      expect(cubit.state, isA<PinPadLockedOutState>());

      // Attempt to change layout during lockout
      cubit.updateKeypadLayout(KeypadLayoutPolicyEnum.randomizedPerAttempt);

      // State must strictly remain PinPadLockedOutState
      expect(cubit.state, isA<PinPadLockedOutState>());
      expect((cubit.state as PinPadLockedOutState).cooldownRemainingSeconds, equals(20));

      cubit.updateKeypadLayout(KeypadLayoutPolicyEnum.standardOrdered);
      expect(cubit.state, isA<PinPadLockedOutState>());
    });
  });

  group('Empirical Challenge 3: Decoy Persona Blur Flush & Focus-Loss Persistence', () {
    late AdversarialStorageRepository storageRepo;
    late AdversarialAuthService authService;
    late AdversarialMonotonicClock clock;
    late MutateVaultConfigUseCase mutateUseCase;
    late SettingsMutationCubit cubit;

    setUp(() {
      storageRepo = AdversarialStorageRepository();
      authService = AdversarialAuthService();
      clock = AdversarialMonotonicClock();
      mutateUseCase = MutateVaultConfigUseCase(
        authService: authService,
        storageRepository: storageRepo,
      );
      cubit = SettingsMutationCubit(
        storageRepository: storageRepo,
        mutateVaultConfigUseCase: mutateUseCase,
        authService: authService,
        monotonicClock: clock,
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('Sub-millisecond multi-field blur transitions: All 3 fields persist with zero dropped text', () async {
      // Simulate disk write latency of 30ms per write
      storageRepo.writeDelay = const Duration(milliseconds: 30);

      // Field 1: User types Title and blurs immediately
      cubit.updateDecoyPersonaDebounced(title: 'Adversarial Masterpiece');
      final blurTitle = cubit.flushDecoyPersonaImmediately();

      // Field 2: Almost simultaneously (while Title write is in-flight), User types Artist and blurs
      await Future<void>.delayed(const Duration(milliseconds: 5));
      cubit.updateDecoyPersonaDebounced(artist: 'Adversarial Artist');
      final blurArtist = cubit.flushDecoyPersonaImmediately();

      // Field 3: Almost simultaneously, User types Album and blurs
      await Future<void>.delayed(const Duration(milliseconds: 5));
      cubit.updateDecoyPersonaDebounced(album: 'Adversarial Album');
      final blurAlbum = cubit.flushDecoyPersonaImmediately();

      // Wait for all three blur flushes to complete
      await Future.wait([blurTitle, blurArtist, blurAlbum]);
      await Future<void>.delayed(const Duration(milliseconds: 40));

      // All 3 fields MUST be persisted into storage without dropping any field
      expect(storageRepo.config.decoyTitle, equals('Adversarial Masterpiece'));
      expect(storageRepo.config.decoyArtist, equals('Adversarial Artist'));
      expect(storageRepo.config.decoyAlbum, equals('Adversarial Album'));

      expect(cubit.currentConfig.decoyTitle, equals('Adversarial Masterpiece'));
      expect(cubit.currentConfig.decoyArtist, equals('Adversarial Artist'));
      expect(cubit.currentConfig.decoyAlbum, equals('Adversarial Album'));

      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());
    });

    test('In-flight typing race: User modifies field while previous blur is writing to disk', () async {
      storageRepo.writeDelay = const Duration(milliseconds: 30);

      // 1. Initial blur of title 'Draft 1'
      cubit.updateDecoyPersonaDebounced(title: 'Draft 1');
      final blur1 = cubit.flushDecoyPersonaImmediately();

      // 2. User quickly types 'Draft 2' while 'Draft 1' is still in-flight
      await Future<void>.delayed(const Duration(milliseconds: 5));
      cubit.updateDecoyPersonaDebounced(title: 'Draft 2');

      // 3. User blurs 'Draft 2'
      final blur2 = cubit.flushDecoyPersonaImmediately();

      await Future.wait([blur1, blur2]);
      await Future<void>.delayed(const Duration(milliseconds: 40));

      // The final persisted title MUST be 'Draft 2' (not overwritten or dropped)
      expect(storageRepo.config.decoyTitle, equals('Draft 2'));
      expect(cubit.currentConfig.decoyTitle, equals('Draft 2'));
    });

    test('Interleaved blur and general preference updates maintain consistency', () async {
      storageRepo.writeDelay = const Duration(milliseconds: 10);

      // 1. Update theme
      await cubit.updateGeneralPolicy(
        cubit.currentConfig.copyWith(themePalette: VaultThemePalettePolicyEnum.forestNoir),
      );

      // 2. Blur decoy title
      cubit.updateDecoyPersonaDebounced(title: 'Interleaved Title');
      await cubit.flushDecoyPersonaImmediately();

      // 3. Update screen security
      await cubit.updateGeneralPolicy(
        cubit.currentConfig.copyWith(screenSecurity: ScreenSecurityPolicyEnum.allowCapture),
      );

      expect(storageRepo.config.themePalette, equals(VaultThemePalettePolicyEnum.forestNoir));
      expect(storageRepo.config.decoyTitle, equals('Interleaved Title'));
      expect(storageRepo.config.screenSecurity, equals(ScreenSecurityPolicyEnum.allowCapture));
      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());
    });
  });
}
