import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/active_reauth_interval.dart';
import 'package:musify_mu/features/vault/domain/policies/background_grace_timeout.dart';
import 'package:musify_mu/features/vault/domain/policies/biometric_auth_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/keypad_layout_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/screen_security_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/settings_mutation_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/mutate_vault_config_use_case.dart';

class StressMonotonicClock implements IMonotonicClock {
  int timeMs = 1000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class StressVaultStorageRepository implements IVaultStorageRepository {
  VaultConfig config = const VaultConfig.constant();
  bool shouldFailSave = false;
  String failureReason = 'Disk write failed';
  Duration writeDelay = Duration.zero;
  int saveCount = 0;
  final List<VaultConfig> savedHistory = <VaultConfig>[];

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(config);

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig newConfig) async {
    saveCount++;
    if (writeDelay > Duration.zero) {
      await Future<void>.delayed(writeDelay);
    }
    if (shouldFailSave) {
      return VaultResult.failure(VaultStorageFailure(failureReason));
    }
    config = newConfig;
    savedHistory.add(newConfig);
    return const VaultResult.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StressVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> _sessionController =
      StreamController<VaultSessionState>.broadcast();

  Stream<VaultSessionState> get sessionStateStream => _sessionController.stream;

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({required String pin}) async {
    if (pin == '123456') {
      return VaultResult.success(
        AuthSession(
          sessionToken: 'token_123',
          sessionStartedEpochMs: 1000,
          lastActiveEpochMs: 1000,
          authMethod: AuthMethodEnum.pin,
        ),
      );
    }
    return const VaultResult.failure(VaultAuthFailure('Invalid PIN'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late StressVaultStorageRepository storageRepo;
  late StressVaultAuthService authService;
  late StressMonotonicClock clock;
  late MutateVaultConfigUseCase mutateUseCase;
  late SettingsMutationCubit cubit;

  setUp(() {
    storageRepo = StressVaultStorageRepository();
    authService = StressVaultAuthService();
    clock = StressMonotonicClock();
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

  group('Stress 1: High-Concurrency Rapid Mutations', () {
    test('Sequential bursts of distinct general policy mutations succeed without deadlock', () async {
      final states = <SettingsMutationState>[];
      final sub = cubit.stream.listen(states.add);

      const iterations = 25;
      for (var i = 0; i < iterations; i++) {
        final palette = i.isEven
            ? VaultThemePalettePolicyEnum.forestNoir
            : VaultThemePalettePolicyEnum.warmEspresso;
        final behavior = i.isEven
            ? LockPlaybackBehaviorEnum.stopImmediately
            : LockPlaybackBehaviorEnum.continueMaskedInBackground;

        final newConfig = cubit.currentConfig.copyWith(
          themePalette: palette,
          lockPlaybackBehavior: behavior,
        );

        await cubit.updateGeneralPolicy(newConfig);
      }

      expect(storageRepo.saveCount, equals(iterations));
      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());
      expect(
        cubit.currentConfig.themePalette,
        equals(VaultThemePalettePolicyEnum.forestNoir),
      );

      await sub.cancel();
    });

    test('Parallel rapid mutations during delayed I/O are serialized via async FIFO queue', () async {
      // Introduce 20ms storage delay to simulate disk I/O
      storageRepo.writeDelay = const Duration(milliseconds: 20);

      final stateEmissions = <SettingsMutationState>[];
      final sub = cubit.stream.listen(stateEmissions.add);

      // Launch 3 parallel mutations almost simultaneously
      final future1 = cubit.updateGeneralPolicy(
        cubit.currentConfig.copyWith(themePalette: VaultThemePalettePolicyEnum.forestNoir),
      );
      final future2 = cubit.updateGeneralPolicy(
        cubit.currentConfig.copyWith(lockPlaybackBehavior: LockPlaybackBehaviorEnum.stopImmediately),
      );
      final future3 = cubit.updateGeneralPolicy(
        cubit.currentConfig.copyWith(keypadLayout: KeypadLayoutPolicyEnum.randomizedPerAttempt),
      );

      await Future.wait([future1, future2, future3]);

      // All 3 mutations are serialized without dropping
      expect(storageRepo.saveCount, equals(3),
          reason: 'Concurrent mutations are serialized via FIFO queue and all 3 save.');

      // Wait for cubit to settle back to syncedIdle
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());
      expect(cubit.currentConfig.keypadLayout, equals(KeypadLayoutPolicyEnum.randomizedPerAttempt));

      await sub.cancel();
    });

    test('100 asynchronous burst mutations do not crash or leave cubit in corrupted state', () async {
      storageRepo.writeDelay = const Duration(milliseconds: 1);

      final errors = <Object>[];
      final futures = <Future<void>>[];

      for (var i = 0; i < 100; i++) {
        futures.add(
          cubit.updateGeneralPolicy(
            cubit.currentConfig.copyWith(
              themePalette: i % 2 == 0
                  ? VaultThemePalettePolicyEnum.forestNoir
                  : VaultThemePalettePolicyEnum.warmEspresso,
            ),
          ).catchError((Object e) {
            errors.add(e);
          }),
        );
      }

      await Future.wait(futures);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // No unhandled exceptions thrown
      expect(errors, isEmpty);
      // Cubit safely returns to syncedIdle
      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());
      expect(cubit.isClosed, isFalse);
    });
  });

  group('Stress 2: Text Debounce Races (Keystrokes vs Focus-Loss Blur Saving)', () {
    test('Rapid consecutive keystrokes reset debounce timer cleanly to latest text', () async {
      const words = ['M', 'Mu', 'Mus', 'Musi', 'Musif', 'Musify'];

      for (final text in words) {
        cubit.updateDecoyPersonaDebounced(title: text);
        // Small delay between keystrokes (< 350ms)
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }

      // Storage should not have updated yet (timer keeps getting reset)
      expect(storageRepo.config.decoyTitle, isNot(equals('Musify')));

      // Wait 400ms for final debounce timer to complete
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(storageRepo.config.decoyTitle, equals('Musify'));
      expect(cubit.currentConfig.decoyTitle, equals('Musify'));
      expect(storageRepo.saveCount, equals(1));
    });

    test('Focus-loss blur immediately flushes and cancels pending debounce timer', () async {
      cubit.updateDecoyPersonaDebounced(
        title: 'Initial Typing',
        artist: 'Typing Artist',
        album: 'Typing Album',
      );

      // Blur happens 50ms after typing
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await cubit.flushDecoyPersonaImmediately();

      expect(storageRepo.config.decoyTitle, equals('Initial Typing'));
      expect(storageRepo.config.decoyArtist, equals('Typing Artist'));
      expect(storageRepo.config.decoyAlbum, equals('Typing Album'));
      expect(storageRepo.saveCount, equals(1));

      // Wait another 350ms to ensure the cancelled timer does NOT fire a second time
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(storageRepo.saveCount, equals(1));
    });

    test('Blur flush during in-flight persistence queues and preserves second field update', () async {
      // Simulate non-zero write latency
      storageRepo.writeDelay = const Duration(milliseconds: 40);

      // 1. User types in Title and blurs immediately
      cubit.updateDecoyPersonaDebounced(title: 'Saved Title');
      final blur1 = cubit.flushDecoyPersonaImmediately();

      // 2. While Title is persisting (in-flight), user types in Artist and blurs
      await Future<void>.delayed(const Duration(milliseconds: 10));
      cubit.updateDecoyPersonaDebounced(artist: 'Preserved Artist');
      final blur2 = cubit.flushDecoyPersonaImmediately();

      await Future.wait([blur1, blur2]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(storageRepo.config.decoyTitle, equals('Saved Title'));
      expect(storageRepo.config.decoyArtist, equals('Preserved Artist'),
          reason: 'Second flush was queued and preserved via FIFO mutation queue.');
    });

    test('Debounce rejects whitespace-only inputs without crashing or corrupting config', () async {
      final initialTitle = cubit.currentConfig.decoyTitle;

      cubit.updateDecoyPersonaDebounced(title: '     \t\n  ');
      await cubit.flushDecoyPersonaImmediately();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Config remains at initial title
      expect(cubit.currentConfig.decoyTitle, equals(initialTitle));
      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());
    });
  });

  group('Stress 3: Immediate Non-Blocking Error Recovery', () {
    test('Simulated disk failure emits mutationRejected and immediately resets to syncedIdle via microtask', () async {
      storageRepo.shouldFailSave = true;
      storageRepo.failureReason = 'I/O Block Device Full';

      final recordedStates = <SettingsMutationState>[];
      final sub = cubit.stream.listen(recordedStates.add);

      await cubit.updateGeneralPolicy(
        cubit.currentConfig.copyWith(themePalette: VaultThemePalettePolicyEnum.forestNoir),
      );

      // Wait for scheduled microtask to complete
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(recordedStates.length, equals(3));
      expect(recordedStates[0], isA<SettingsMutationPersistingConfigState>());
      expect(recordedStates[1], isA<SettingsMutationMutationRejectedState>());
      final rejected = recordedStates[1] as SettingsMutationMutationRejectedState;
      expect(rejected.rejectionReason, equals('I/O Block Device Full'));
      expect(rejected.mutationType, equals(SensitiveSettingMutationEnum.generalConfigUpdate));
      expect(recordedStates[2], isA<SettingsMutationSyncedIdleState>());

      // Last known good config is preserved
      expect(cubit.currentConfig.themePalette, equals(VaultThemePalettePolicyEnum.warmEspresso));

      await sub.cancel();
    });

    test('Microtask clobber race: Action initiated synchronously upon rejection is preserved', () async {
      storageRepo.shouldFailSave = true;

      SettingsMutationState? stateSeenInListener;
      final sub = cubit.stream.listen((state) {
        if (state is SettingsMutationMutationRejectedState) {
          stateSeenInListener = state;
          // Synchronously request a sensitive mutation before microtask runs
          cubit.requestSensitiveMutation(
            mutationType: SensitiveSettingMutationEnum.pinRotation,
          );
        }
      });

      await cubit.updateGeneralPolicy(
        cubit.currentConfig.copyWith(themePalette: VaultThemePalettePolicyEnum.forestNoir),
      );

      // Wait for microtask
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Guarded microtask checks state is still mutationRejected before resetting;
      // because state changed to AwaitingStepUpAuthState, it is not clobbered!
      expect(stateSeenInListener, isA<SettingsMutationMutationRejectedState>());
      expect(
        cubit.state,
        isA<SettingsMutationAwaitingStepUpAuthState>(),
        reason: 'Guarded microtask does not clobber newly requested state.',
      );

      await sub.cancel();
    });

    test('10 consecutive storage failures recover cleanly each time', () async {
      storageRepo.shouldFailSave = true;

      for (var i = 0; i < 10; i++) {
        await cubit.updateGeneralPolicy(
          cubit.currentConfig.copyWith(
            themePalette: i.isEven
                ? VaultThemePalettePolicyEnum.forestNoir
                : VaultThemePalettePolicyEnum.warmEspresso,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 5));
        expect(cubit.state, isA<SettingsMutationSyncedIdleState>());
      }

      expect(cubit.currentConfig.themePalette, equals(VaultThemePalettePolicyEnum.warmEspresso));
    });
  });

  group('Stress 4: Step-Up Guard Triggers', () {
    test('BiometricAuth mutation requires step-up while general policies persist directly', () async {
      // 1. BiometricAuth requires step-up, rejected via updateGeneralPolicy
      await cubit.updateGeneralPolicy(
        cubit.currentConfig.copyWith(biometricAuth: BiometricAuthPolicyEnum.pinAndBiometricStrong),
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());
      expect(cubit.currentConfig.biometricAuth, equals(BiometricAuthPolicyEnum.pinOnly));

      // 2. ScreenSecurity persists directly as a general preference
      await cubit.updateGeneralPolicy(
        cubit.currentConfig.copyWith(screenSecurity: ScreenSecurityPolicyEnum.allowCapture),
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());
      expect(cubit.currentConfig.screenSecurity, equals(ScreenSecurityPolicyEnum.allowCapture));

      // 3. ActiveReauthInterval persists directly as a general preference
      await cubit.updateGeneralPolicy(
        cubit.currentConfig.copyWith(activeReauthInterval: ActiveReauthIntervalEnum.every5Minutes),
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());
      expect(cubit.currentConfig.activeReauthInterval, equals(ActiveReauthIntervalEnum.every5Minutes));

      // 4. BackgroundGraceTimeout persists directly as a general preference
      await cubit.updateGeneralPolicy(
        cubit.currentConfig.copyWith(backgroundGraceTimeout: BackgroundGraceTimeoutEnum.immediate),
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());
      expect(cubit.currentConfig.backgroundGraceTimeout, equals(BackgroundGraceTimeoutEnum.immediate));
    });

    test('confirmSensitiveMutation with mismatched mutationType rejects and reverts to idle', () async {
      await cubit.requestSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.pinRotation,
      );
      expect(cubit.state, isA<SettingsMutationAwaitingStepUpAuthState>());

      final states = <SettingsMutationState>[];
      final sub = cubit.stream.listen(states.add);

      // Attempt to confirm with biometricPolicyChange instead of pinRotation
      await cubit.confirmSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.biometricPolicyChange,
        onExecute: () async {},
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(states.length, equals(2));
      expect(states[0], isA<SettingsMutationMutationRejectedState>());
      final rejected = states[0] as SettingsMutationMutationRejectedState;
      expect(rejected.rejectionReason, contains('Mutation type mismatch'));
      expect(states[1], isA<SettingsMutationSyncedIdleState>());

      await sub.cancel();
    });

    test('confirmSensitiveMutation when not awaiting rejects and reverts to idle', () async {
      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());

      final states = <SettingsMutationState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.confirmSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.vaultDataPurge,
        onExecute: () async {},
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(states[0], isA<SettingsMutationMutationRejectedState>());
      final rejected = states[0] as SettingsMutationMutationRejectedState;
      expect(rejected.rejectionReason, contains('not awaiting step-up authentication'));
      expect(states[1], isA<SettingsMutationSyncedIdleState>());

      await sub.cancel();
    });

    test('cancelSensitiveMutation cancels in-flight request with rejection message', () async {
      await cubit.requestSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.gestureReEnrollment,
      );

      final states = <SettingsMutationState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.cancelSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.gestureReEnrollment,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(states[0], isA<SettingsMutationMutationRejectedState>());
      final rejected = states[0] as SettingsMutationMutationRejectedState;
      expect(rejected.rejectionReason, contains('cancelled by user'));
      expect(states[1], isA<SettingsMutationSyncedIdleState>());

      await sub.cancel();
    });

    test('cancelSensitiveMutation when not awaiting step-up is a clean no-op', () async {
      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());

      final states = <SettingsMutationState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.cancelSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.pinRotation,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(states, isEmpty);
      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());

      await sub.cancel();
    });

    test('Calling updateGeneralPolicy while awaiting step-up clobbers awaiting state', () async {
      await cubit.requestSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.pinRotation,
      );
      expect(cubit.state, isA<SettingsMutationAwaitingStepUpAuthState>());

      // Inadvertently trigger general policy update while user is viewing step-up screen
      await cubit.updateGeneralPolicy(
        cubit.currentConfig.copyWith(themePalette: VaultThemePalettePolicyEnum.forestNoir),
      );

      // The step-up awaiting state was clobbered by the general policy persistence
      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());
      expect(cubit.currentConfig.themePalette, equals(VaultThemePalettePolicyEnum.forestNoir));
    });
  });
}
