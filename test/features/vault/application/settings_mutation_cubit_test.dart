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

class FakeMonotonicClock implements IMonotonicClock {
  int timeMs = 1000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class FakeVaultStorageRepository implements IVaultStorageRepository {
  VaultConfig config = const VaultConfig.constant();
  bool shouldFailSave = false;

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(config);

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig newConfig) async {
    if (shouldFailSave) {
      return const VaultResult.failure(VaultStorageFailure('Disk write failed'));
    }
    config = newConfig;
    return const VaultResult.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVaultAuthService implements IVaultAuthService {
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
  late FakeVaultStorageRepository fakeStorage;
  late FakeVaultAuthService fakeAuthService;
  late FakeMonotonicClock fakeClock;
  late MutateVaultConfigUseCase mutateUseCase;
  late SettingsMutationCubit cubit;

  setUp(() {
    fakeStorage = FakeVaultStorageRepository();
    fakeAuthService = FakeVaultAuthService();
    fakeClock = FakeMonotonicClock();
    mutateUseCase = MutateVaultConfigUseCase(
      authService: fakeAuthService,
      storageRepository: fakeStorage,
    );
    cubit = SettingsMutationCubit(
      storageRepository: fakeStorage,
      mutateVaultConfigUseCase: mutateUseCase,
      authService: fakeAuthService,
      monotonicClock: fakeClock,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  group('SettingsMutationCubit Lifecycle & Initialization', () {
    test('starts with SyncedIdleState and default config', () {
      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());
      expect(cubit.currentConfig.themePalette, equals(VaultThemePalettePolicyEnum.warmEspresso));
    });

    test('initialize loads configuration and emits to configStream', () async {
      fakeStorage.config = fakeStorage.config.copyWith(
        themePalette: VaultThemePalettePolicyEnum.forestNoir,
      );

      final streamEvents = <VaultConfig>[];
      final sub = cubit.configStream.listen(streamEvents.add);

      await cubit.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(cubit.currentConfig.themePalette, equals(VaultThemePalettePolicyEnum.forestNoir));
      expect(streamEvents.length, equals(1));
      expect(streamEvents.first.themePalette, equals(VaultThemePalettePolicyEnum.forestNoir));
      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());

      await sub.cancel();
    });
  });

  group('General Policy Mutations (Non-Sensitive)', () {
    test('updateGeneralPolicy persists non-sensitive changes immediately', () async {
      final updated = cubit.currentConfig.copyWith(
        themePalette: VaultThemePalettePolicyEnum.forestNoir,
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.stopImmediately,
        keypadLayout: KeypadLayoutPolicyEnum.randomizedPerAttempt,
      );

      final states = <SettingsMutationState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.updateGeneralPolicy(updated);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(states.length, equals(2));
      expect(states[0], isA<SettingsMutationPersistingConfigState>());
      expect(states[1], isA<SettingsMutationSyncedIdleState>());
      expect(cubit.currentConfig.themePalette, equals(VaultThemePalettePolicyEnum.forestNoir));
      expect(cubit.currentConfig.lockPlaybackBehavior, equals(LockPlaybackBehaviorEnum.stopImmediately));
      expect(fakeStorage.config.themePalette, equals(VaultThemePalettePolicyEnum.forestNoir));

      await sub.cancel();
    });

    test('updateGeneralPolicy persists general security preferences without step-up auth', () async {
      final updated = cubit.currentConfig.copyWith(
        screenSecurity: ScreenSecurityPolicyEnum.allowCapture,
        activeReauthInterval: ActiveReauthIntervalEnum.every5Minutes,
        backgroundGraceTimeout: BackgroundGraceTimeoutEnum.fiveMinutes,
      );

      final states = <SettingsMutationState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.updateGeneralPolicy(updated);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(states.length, equals(2));
      expect(states[0], isA<SettingsMutationPersistingConfigState>());
      expect(states[1], isA<SettingsMutationSyncedIdleState>());
      expect(cubit.currentConfig.screenSecurity, equals(ScreenSecurityPolicyEnum.allowCapture));
      expect(cubit.currentConfig.activeReauthInterval, equals(ActiveReauthIntervalEnum.every5Minutes));
      expect(cubit.currentConfig.backgroundGraceTimeout, equals(BackgroundGraceTimeoutEnum.fiveMinutes));
      expect(fakeStorage.config.screenSecurity, equals(ScreenSecurityPolicyEnum.allowCapture));

      await sub.cancel();
    });

    test('updateGeneralPolicy intercepts sensitive mutation and non-blockingly recovers', () async {
      final updated = cubit.currentConfig.copyWith(
        biometricAuth: BiometricAuthPolicyEnum.pinAndBiometricStrong,
      );

      final states = <SettingsMutationState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.updateGeneralPolicy(updated);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(states.length, equals(2));
      expect(states[0], isA<SettingsMutationMutationRejectedState>());
      final rejected = states[0] as SettingsMutationMutationRejectedState;
      expect(rejected.rejectionReason, contains('Sensitive policy mutation attempted'));
      expect(states[1], isA<SettingsMutationSyncedIdleState>());

      // Config remains unchanged
      expect(cubit.currentConfig.biometricAuth, equals(BiometricAuthPolicyEnum.pinOnly));

      await sub.cancel();
    });

    test('reverts and recovers when persistence encounters disk failure', () async {
      fakeStorage.shouldFailSave = true;

      final updated = cubit.currentConfig.copyWith(
        themePalette: VaultThemePalettePolicyEnum.forestNoir,
      );

      final states = <SettingsMutationState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.updateGeneralPolicy(updated);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(states.length, equals(3));
      expect(states[0], isA<SettingsMutationPersistingConfigState>());
      expect(states[1], isA<SettingsMutationMutationRejectedState>());
      expect(states[2], isA<SettingsMutationSyncedIdleState>());

      // Config remains at last known good
      expect(cubit.currentConfig.themePalette, equals(VaultThemePalettePolicyEnum.warmEspresso));

      await sub.cancel();
    });
  });

  group('Decoy Persona Debouncing & Focus-Loss Blur Saving', () {
    test('updateDecoyPersonaDebounced delays persistence until 350ms elapses', () async {
      cubit.updateDecoyPersonaDebounced(
        title: 'Draft Title',
        artist: 'Draft Artist',
        album: 'Draft Album',
      );

      // Immediately after typing: storage not updated
      expect(fakeStorage.config.decoyTitle, isNot(equals('Draft Title')));

      // Wait 400ms for debounce timer to fire
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(fakeStorage.config.decoyTitle, equals('Draft Title'));
      expect(fakeStorage.config.decoyArtist, equals('Draft Artist'));
      expect(fakeStorage.config.decoyAlbum, equals('Draft Album'));
      expect(cubit.currentConfig.decoyTitle, equals('Draft Title'));
    });

    test('flushDecoyPersonaImmediately saves pending edits instantly on blur', () async {
      cubit.updateDecoyPersonaDebounced(
        title: 'Instant Blurred Title',
      );

      // Flush immediately on blur
      await cubit.flushDecoyPersonaImmediately();

      expect(fakeStorage.config.decoyTitle, equals('Instant Blurred Title'));
      expect(cubit.currentConfig.decoyTitle, equals('Instant Blurred Title'));
    });

    test('rejects empty or whitespace decoy persona fields', () async {
      cubit.updateDecoyPersonaDebounced(
        title: '   ',
      );

      final states = <SettingsMutationState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.flushDecoyPersonaImmediately();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(states.length, equals(2));
      expect(states[0], isA<SettingsMutationMutationRejectedState>());
      expect(states[1], isA<SettingsMutationSyncedIdleState>());
      expect(cubit.currentConfig.decoyTitle, isNot(equals('   ')));

      await sub.cancel();
    });
  });

  group('Sensitive Mutation Step-Up Guard Flow', () {
    test('requestSensitiveMutation enters AwaitingStepUpAuthState with monotonic timestamp', () async {
      await cubit.requestSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.biometricPolicyChange,
      );

      expect(cubit.state, isA<SettingsMutationAwaitingStepUpAuthState>());
      final stepUpState = cubit.state as SettingsMutationAwaitingStepUpAuthState;
      expect(stepUpState.mutationType, equals(SensitiveSettingMutationEnum.biometricPolicyChange));
      expect(stepUpState.requestedAtMonotonicMs, equals(1000));
    });

    test('confirmSensitiveMutation executes authorized mutation and syncs config', () async {
      await cubit.requestSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.biometricPolicyChange,
      );

      bool closureExecuted = false;
      await cubit.confirmSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.biometricPolicyChange,
        onExecute: () async {
          closureExecuted = true;
          fakeStorage.config = fakeStorage.config.copyWith(
            biometricAuth: BiometricAuthPolicyEnum.pinAndBiometricStrong,
          );
        },
      );

      expect(closureExecuted, isTrue);
      expect(cubit.state, isA<SettingsMutationSyncedIdleState>());
      expect(cubit.currentConfig.biometricAuth, equals(BiometricAuthPolicyEnum.pinAndBiometricStrong));
    });

    test('confirmSensitiveMutation rejects if called in invalid state or type mismatch', () async {
      final states = <SettingsMutationState>[];
      final sub = cubit.stream.listen(states.add);

      // Attempt to confirm without requesting
      await cubit.confirmSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.pinRotation,
        onExecute: () async {},
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(states[0], isA<SettingsMutationMutationRejectedState>());
      expect(states[1], isA<SettingsMutationSyncedIdleState>());

      await sub.cancel();
    });

    test('cancelSensitiveMutation aborts pending mutation cleanly', () async {
      await cubit.requestSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.vaultDataPurge,
      );

      final states = <SettingsMutationState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.cancelSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.vaultDataPurge,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(states.length, equals(2));
      expect(states[0], isA<SettingsMutationMutationRejectedState>());
      final rejected = states[0] as SettingsMutationMutationRejectedState;
      expect(rejected.rejectionReason, contains('cancelled by user'));
      expect(states[1], isA<SettingsMutationSyncedIdleState>());

      await sub.cancel();
    });
  });
}
