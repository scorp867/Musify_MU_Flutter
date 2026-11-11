import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/policies/keypad_layout_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/states/crypto_engine_state.dart';
import 'package:musify_mu/features/vault/domain/states/gesture_engine_state.dart';
import 'package:musify_mu/features/vault/domain/states/pin_pad_state.dart';
import 'package:musify_mu/features/vault/domain/states/playback_privacy_mode.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/settings_mutation_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

void main() {
  final testSession = AuthSession(
    sessionToken: 'test_token_xyz',
    sessionStartedEpochMs: 1000,
    lastActiveEpochMs: 1500,
    authMethod: AuthMethodEnum.pin,
  );

  group('VaultSessionState & LockoutCooldownTierEnum', () {
    test('LockoutCooldownTierEnum properties', () {
      expect(LockoutCooldownTierEnum.none.durationMs, 0);
      expect(LockoutCooldownTierEnum.none.thresholdAttempts, 0);

      expect(LockoutCooldownTierEnum.tier1ThirtySeconds.durationMs, 30000);
      expect(LockoutCooldownTierEnum.tier1ThirtySeconds.thresholdAttempts, 5);

      expect(LockoutCooldownTierEnum.tier2FiveMinutes.durationMs, 300000);
      expect(LockoutCooldownTierEnum.tier2FiveMinutes.thresholdAttempts, 10);
    });

    test('VaultUninitializedState equality and props', () {
      const state1 = VaultUninitializedState();
      const state2 = VaultUninitializedState();
      expect(state1, state2);
      expect(state1.props, isEmpty);
    });

    test('VaultLockedState properties and assertion', () {
      const locked = VaultLockedState(lockedAtMonotonicMs: 5000);
      expect(locked.lockedAtMonotonicMs, 5000);
      expect(locked.props, [5000]);

      expect(
        () => VaultLockedState(lockedAtMonotonicMs: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('VaultAuthenticatingState copyWith and assertions', () {
      const auth = VaultAuthenticatingState(
        authSessionId: 'sess_1',
        attemptNumber: 1,
        remainingAttemptsBeforeCooldown: 4,
      );

      final updated = auth.copyWith(attemptNumber: 2, remainingAttemptsBeforeCooldown: 3);
      expect(updated.attemptNumber, 2);
      expect(updated.remainingAttemptsBeforeCooldown, 3);
      expect(updated.authSessionId, 'sess_1');

      expect(
        () => VaultAuthenticatingState(
          authSessionId: '',
          attemptNumber: 1,
          remainingAttemptsBeforeCooldown: 4,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('VaultUnlockedState copyWith and properties', () {
      final unlocked = VaultUnlockedState(
        session: testSession,
        unlockedAtMonotonicMs: 1000,
        reauthDeadlineMonotonicMs: 60000,
      );

      expect(unlocked.session, testSession);
      expect(unlocked.unlockedAtMonotonicMs, 1000);
      expect(unlocked.reauthDeadlineMonotonicMs, 60000);

      final updated = unlocked.copyWith(reauthDeadlineMonotonicMs: 120000);
      expect(updated.reauthDeadlineMonotonicMs, 120000);
      expect(updated.unlockedAtMonotonicMs, 1000);
    });

    test('VaultBackgroundGraceState copyWith and assertions', () {
      final grace = VaultBackgroundGraceState(
        session: testSession,
        enteredBackgroundMonotonicMs: 2000,
        graceTimeoutMs: 30000,
        graceDeadlineMonotonicMs: 32000,
      );

      expect(grace.enteredBackgroundMonotonicMs, 2000);
      expect(grace.graceDeadlineMonotonicMs, 32000);

      expect(
        () => VaultBackgroundGraceState(
          session: testSession,
          enteredBackgroundMonotonicMs: 5000,
          graceTimeoutMs: 1000,
          graceDeadlineMonotonicMs: 4000,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('VaultPendingReauthState copyWith and properties', () {
      final pending = VaultPendingReauthState(
        session: testSession,
        reauthTriggeredAtMonotonicMs: 60000,
        remainingAttempts: 3,
      );

      expect(pending.reauthTriggeredAtMonotonicMs, 60000);
      expect(pending.remainingAttempts, 3);

      final updated = pending.copyWith(remainingAttempts: 2);
      expect(updated.remainingAttempts, 2);
    });

    test('VaultLockoutCooldownState copyWith and assertions', () {
      const cooldown = VaultLockoutCooldownState(
        tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
        cooldownStartedMonotonicMs: 10000,
        durationMs: 30000,
        deadlineMonotonicMs: 40000,
        failedAttemptsCount: 5,
      );

      expect(cooldown.tier, LockoutCooldownTierEnum.tier1ThirtySeconds);
      expect(cooldown.failedAttemptsCount, 5);

      expect(
        () => VaultLockoutCooldownState(
          tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
          cooldownStartedMonotonicMs: 10000,
          durationMs: 30000,
          deadlineMonotonicMs: 40000,
          failedAttemptsCount: 4,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('exhaustive pattern match on VaultSessionState', () {
      final List<VaultSessionState> states = [
        const VaultUninitializedState(),
        const VaultLockedState(lockedAtMonotonicMs: 100),
        const VaultAuthenticatingState(
          authSessionId: 's',
          attemptNumber: 1,
          remainingAttemptsBeforeCooldown: 4,
        ),
        VaultUnlockedState(
          session: testSession,
          unlockedAtMonotonicMs: 100,
          reauthDeadlineMonotonicMs: 200,
        ),
        VaultBackgroundGraceState(
          session: testSession,
          enteredBackgroundMonotonicMs: 100,
          graceTimeoutMs: 100,
          graceDeadlineMonotonicMs: 200,
        ),
        VaultPendingReauthState(
          session: testSession,
          reauthTriggeredAtMonotonicMs: 100,
          remainingAttempts: 3,
        ),
        const VaultLockoutCooldownState(
          tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
          cooldownStartedMonotonicMs: 100,
          durationMs: 30000,
          deadlineMonotonicMs: 30100,
          failedAttemptsCount: 5,
        ),
      ];

      for (final state in states) {
        final label = switch (state) {
          VaultUninitializedState() => 'uninitialized',
          VaultProvisioningState() => 'provisioning',
          VaultLockedState() => 'locked',
          VaultAuthenticatingState() => 'authenticating',
          VaultUnlockedState() => 'unlocked',
          VaultBackgroundGraceState() => 'grace',
          VaultPendingReauthState() => 'pendingReauth',
          VaultLockoutCooldownState() => 'lockout',
        };
        expect(label, isNotEmpty);
      }
    });
  });

  group('GestureEngineStateEnum & GestureEnrollmentState', () {
    test('GestureEngineStateEnum values and isBusy', () {
      expect(GestureEngineStateEnum.idle.isBusy, isFalse);
      expect(GestureEngineStateEnum.capturingStroke.isBusy, isTrue);
      expect(GestureEngineStateEnum.evaluatingPipeline.isBusy, isTrue);
      expect(GestureEngineStateEnum.matchConfirmed.isBusy, isFalse);
      expect(GestureEngineStateEnum.rejectedSilent.isBusy, isFalse);
    });

    test('GestureRecordingSampleState invariants and copyWith', () {
      final sample1 = GestureSample(
        points: [GesturePoint(x: 0, y: 0, timestampMs: 10)],
        sampledAtEpochMs: 100,
        totalLength: 10.0,
      );

      final state1 = GestureRecordingSampleState(sampleIndex: 1);
      expect(state1.sampleIndex, 1);
      expect(state1.previousSamples, isEmpty);

      final state2 = GestureRecordingSampleState(
        sampleIndex: 2,
        previousSamples: [sample1],
      );
      expect(state2.previousSamples.length, 1);

      expect(
        () => GestureRecordingSampleState(
          sampleIndex: 2,
          previousSamples: const [],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('GestureSynthesizingTemplateState assertions', () {
      final sample = GestureSample(
        points: [GesturePoint(x: 1, y: 1, timestampMs: 10)],
        sampledAtEpochMs: 50,
        totalLength: 5.0,
      );

      final synth = GestureSynthesizingTemplateState(samples: [sample]);
      expect(synth.samples.length, 1);

      expect(
        () => GestureSynthesizingTemplateState(samples: const []),
        throwsA(isA<AssertionError>()),
      );
    });

    test('GestureSandboxTestingState copyWith', () {
      final template = GestureTemplate(
        id: 'tmpl_1',
        normalizedPoints: List.generate(64, (i) => GesturePoint(x: i.toDouble(), y: 0, timestampMs: i)),
        rubineFeatureVector: List.filled(7, 0.5),
        createdAtEpochMs: 100,
      );

      final sandbox = GestureSandboxTestingState(synthesizedTemplate: template);
      expect(sandbox.testAttemptsCount, 0);
      expect(sandbox.lastScore, isNull);

      final updated = sandbox.copyWith(testAttemptsCount: 1);
      expect(updated.testAttemptsCount, 1);
    });

    test('GestureCommittedState and GestureEnrollmentFailedState', () {
      final template = GestureTemplate(
        id: 'tmpl_2',
        normalizedPoints: List.generate(64, (i) => GesturePoint(x: 0, y: i.toDouble(), timestampMs: i)),
        rubineFeatureVector: List.filled(7, 0.1),
        createdAtEpochMs: 200,
      );

      final committed = GestureCommittedState(finalTemplate: template);
      expect(committed.finalTemplate, template);

      const failed = GestureEnrollmentFailedState(failureReason: 'Divergent strokes');
      expect(failed.failureReason, 'Divergent strokes');

      expect(
        () => GestureEnrollmentFailedState(failureReason: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('exhaustive switch on GestureEnrollmentState', () {
      final template = GestureTemplate(
        id: 'tmpl_3',
        normalizedPoints: List.generate(64, (i) => GesturePoint(x: 0, y: 0, timestampMs: 0)),
        rubineFeatureVector: List.filled(7, 0.0),
        createdAtEpochMs: 1,
      );

      final List<GestureEnrollmentState> states = [
        GestureRecordingSampleState(sampleIndex: 1),
        GestureSynthesizingTemplateState(samples: [
          GestureSample(
            points: [GesturePoint(x: 0, y: 0, timestampMs: 1)],
            sampledAtEpochMs: 1,
            totalLength: 1,
          )
        ]),
        GestureSandboxTestingState(synthesizedTemplate: template),
        GestureCommittedState(finalTemplate: template),
        const GestureEnrollmentFailedState(failureReason: 'err'),
      ];

      for (final s in states) {
        final label = switch (s) {
          GestureRecordingSampleState() => 'recording',
          GestureSynthesizingTemplateState() => 'synthesizing',
          GestureSandboxTestingState() => 'sandbox',
          GestureCommittedState() => 'committed',
          GestureEnrollmentFailedState() => 'failed',
        };
        expect(label, isNotEmpty);
      }
    });
  });

  group('CryptoEngineState & CryptoEngineStateEnum', () {
    test('enum getters', () {
      expect(CryptoEngineStateEnum.masterKeyUnwrappedInRam.isKeyMaterialInMemory, isTrue);
      expect(CryptoEngineStateEnum.unprovisioned.isKeyMaterialInMemory, isFalse);

      expect(CryptoEngineStateEnum.unwrappingMasterKey.isTransitioning, isTrue);
      expect(CryptoEngineStateEnum.rotatingWrappingKey.isTransitioning, isTrue);
      expect(CryptoEngineStateEnum.purgingAllVaultData.isTransitioning, isTrue);
      expect(CryptoEngineStateEnum.keyWrappedAtRest.isTransitioning, isFalse);

      expect(CryptoEngineStateEnum.cryptoFault.isFaulted, isTrue);
      expect(CryptoEngineStateEnum.keyWrappedAtRest.isAtRest, isTrue);
      expect(CryptoEngineStateEnum.unprovisioned.isUnprovisioned, isTrue);
    });

    test('sealed state hierarchy covers all 7 states', () {
      const List<CryptoEngineState> states = [
        CryptoEngineUnprovisionedState(),
        CryptoEngineKeyWrappedAtRestState(),
        CryptoEngineUnwrappingMasterKeyState(slot: CryptoWrappingSlotEnum.slot1PinPbkdf2),
        CryptoEngineMasterKeyUnwrappedInRamState(unwrappedAtMonotonicMs: 100),
        CryptoEngineRotatingWrappingKeyState(targetSlot: CryptoWrappingSlotEnum.slot2BiometricHardwareKeyStore),
        CryptoEnginePurgingAllVaultDataState(),
        CryptoEngineCryptoFaultState(
          faultReason: CryptoFaultReasonEnum.keyStoreInvalidated,
          errorMessage: 'KeyStore invalidated',
        ),
      ];

      for (final s in states) {
        final label = switch (s) {
          CryptoEngineUnprovisionedState() => 'unprovisioned',
          CryptoEngineKeyWrappedAtRestState() => 'atRest',
          CryptoEngineUnwrappingMasterKeyState(:final slot) => 'unwrapping_${slot.name}',
          CryptoEngineMasterKeyUnwrappedInRamState(:final unwrappedAtMonotonicMs) => 'inRam_$unwrappedAtMonotonicMs',
          CryptoEngineRotatingWrappingKeyState(:final targetSlot) => 'rotating_${targetSlot.name}',
          CryptoEnginePurgingAllVaultDataState() => 'purging',
          CryptoEngineCryptoFaultState(:final faultReason) => 'fault_${faultReason.name}',
        };
        expect(label, isNotEmpty);
        expect(s.stateEnum, isNotNull);
      }
    });
  });

  group('PlaybackPrivacyState & PlaybackPrivacyModeEnum', () {
    test('enum getters', () {
      expect(PlaybackPrivacyModeEnum.vaultTrackActive.isVaultTrack, isTrue);
      expect(PlaybackPrivacyModeEnum.vaultTrackActive.isPublicPassthrough, isFalse);
      expect(PlaybackPrivacyModeEnum.publicPassthrough.isPublicPassthrough, isTrue);
    });

    test('sealed state classes', () {
      const state1 = PlaybackPrivacyPublicPassthroughState();
      expect(state1.modeEnum, PlaybackPrivacyModeEnum.publicPassthrough);

      const state2 = PlaybackPrivacyVaultTrackActiveState(
        vaultTrackId: 'trk_1',
        maskingStatus: PlaybackMaskingStatusEnum.decoyPersonaProjected,
        visibilityPolicy: MetadataVisibilityPolicyEnum.maskWithPlaceholder,
      );
      expect(state2.vaultTrackId, 'trk_1');
      expect(state2.modeEnum, PlaybackPrivacyModeEnum.vaultTrackActive);

      const state3 = PlaybackPrivacyExecutingLockStrategyState(
        activeVaultTrackId: 'trk_1',
        executingBehavior: LockPlaybackBehaviorEnum.continueMaskedInBackground,
      );
      expect(state3.activeVaultTrackId, 'trk_1');
      expect(state3.executingBehavior, LockPlaybackBehaviorEnum.continueMaskedInBackground);
    });
  });

  group('ScreenPrivacyState & ScreenPrivacyStateEnum', () {
    test('enum getters', () {
      expect(ScreenPrivacyStateEnum.secureFlagEngaged.isFlagEngaged, isTrue);
      expect(ScreenPrivacyStateEnum.platformSyncPending.isSyncPending, isTrue);
      expect(ScreenPrivacyStateEnum.publicUnrestricted.allowsScreenCapture, isTrue);
    });

    test('sealed state hierarchy', () {
      const state1 = ScreenPrivacyPublicUnrestrictedState();
      expect(state1.stateEnum, ScreenPrivacyStateEnum.publicUnrestricted);

      const state2 = ScreenPrivacySecureFlagEngagedState(
        reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
      );
      expect(state2.reason, ScreenPrivacyEngageReasonEnum.vaultRouteActive);

      const state3 = ScreenPrivacyPlatformSyncPendingState(
        targetState: ScreenPrivacyStateEnum.secureFlagEngaged,
        requestedAtMonotonicMs: 1234,
      );
      expect(state3.targetState, ScreenPrivacyStateEnum.secureFlagEngaged);
      expect(state3.requestedAtMonotonicMs, 1234);
    });
  });

  group('SettingsMutationState & SettingsMutationStateEnum', () {
    test('enum getters', () {
      expect(SettingsMutationStateEnum.syncedIdle.isIdle, isTrue);
      expect(SettingsMutationStateEnum.awaitingStepUpAuth.isAwaitingStepUp, isTrue);
      expect(SettingsMutationStateEnum.persistingConfig.isPersisting, isTrue);
      expect(SettingsMutationStateEnum.mutationRejected.isRejected, isTrue);
    });

    test('sealed state hierarchy', () {
      const state1 = SettingsMutationSyncedIdleState();
      expect(state1.stateEnum, SettingsMutationStateEnum.syncedIdle);

      const state2 = SettingsMutationAwaitingStepUpAuthState(
        mutationType: SensitiveSettingMutationEnum.pinRotation,
        requestedAtMonotonicMs: 500,
      );
      expect(state2.mutationType, SensitiveSettingMutationEnum.pinRotation);

      const state3 = SettingsMutationPersistingConfigState(
        mutationType: SensitiveSettingMutationEnum.securityTimeoutChange,
      );
      expect(state3.mutationType, SensitiveSettingMutationEnum.securityTimeoutChange);

      const state4 = SettingsMutationMutationRejectedState(
        mutationType: SensitiveSettingMutationEnum.vaultDataPurge,
        rejectionReason: 'Authentication cancelled',
      );
      expect(state4.rejectionReason, 'Authentication cancelled');
    });
  });

  group('PinPadState & PinPadStateEnum', () {
    test('enum getters', () {
      expect(PinPadStateEnum.idleInput.isAcceptingInput, isTrue);
      expect(PinPadStateEnum.evaluatingAndDeriving.isEvaluating, isTrue);
      expect(PinPadStateEnum.authSuccess.isSuccess, isTrue);
      expect(PinPadStateEnum.authFailureShake.isShaking, isTrue);
      expect(PinPadStateEnum.lockedOut.isLockedOut, isTrue);
    });

    test('PinPadIdleInputState append, remove, clear and bounds', () {
      const initial = PinPadIdleInputState(
        enteredDigitsCount: 0,
        keypadLayout: KeypadLayoutPolicyEnum.standardOrdered,
      );

      final d1 = initial.appendDigit();
      expect(d1.enteredDigitsCount, 1);

      final d2 = d1.appendDigit().appendDigit().appendDigit().appendDigit().appendDigit();
      expect(d2.enteredDigitsCount, 6);

      // Clamped at 6
      final d3 = d2.appendDigit();
      expect(d3.enteredDigitsCount, 6);

      // Decrement
      final d4 = d3.removeDigit();
      expect(d4.enteredDigitsCount, 5);

      // Clear
      final cleared = d4.clearDigits();
      expect(cleared.enteredDigitsCount, 0);

      // Decrement from 0
      final atZero = cleared.removeDigit();
      expect(atZero.enteredDigitsCount, 0);

      expect(
        () => PinPadIdleInputState(
          enteredDigitsCount: 7,
          keypadLayout: KeypadLayoutPolicyEnum.standardOrdered,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('other PinPad states', () {
      const evaluating = PinPadEvaluatingState();
      expect(evaluating.stateEnum, PinPadStateEnum.evaluatingAndDeriving);

      const success = PinPadSuccessState();
      expect(success.stateEnum, PinPadStateEnum.authSuccess);

      const failure = PinPadFailureShakeState(
        failedAttemptsCount: 3,
        remainingAttemptsBeforeCooldown: 2,
      );
      expect(failure.failedAttemptsCount, 3);
      expect(failure.remainingAttemptsBeforeCooldown, 2);

      const lockedOut = PinPadLockedOutState(
        cooldownRemainingSeconds: 30,
        deadlineMonotonicMs: 50000,
      );
      expect(lockedOut.cooldownRemainingSeconds, 30);
      expect(lockedOut.deadlineMonotonicMs, 50000);
    });
  });
}
