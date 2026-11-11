import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/policies/active_reauth_interval.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

/// Exhaustive operational decisions resulting from monotonic session evaluation.
enum CoolOffDecisionEnum {
  /// Session remains valid and unexpired; normal active operation may continue.
  sessionValid,

  /// Active session timer elapsed; step-up re-authentication overlay required.
  reauthRequired,

  /// Background grace period deadline exceeded; session expired and vault locked.
  graceExpiredLock,

  /// Lockout cooldown elapsed; failure counters reset and vault ready for unlock.
  lockoutElapsedReset,

  /// Lockout cooldown remains actively enforced.
  lockoutActive,
}

/// Parameter carrying current session state and vault configuration for cool-off evaluation.
@immutable
class VerifyCoolOffParams extends Equatable {
  /// The active [VaultSessionState] being evaluated.
  final VaultSessionState currentState;

  /// The active [VaultConfig] containing timeout and re-authentication policies.
  final VaultConfig config;

  const VerifyCoolOffParams({
    required this.currentState,
    required this.config,
  });

  @override
  List<Object?> get props => [currentState, config];
}

/// Use case interactor evaluating active session and lockout deadlines against
/// the tamper-resistant monotonic clock.
@immutable
class VerifySessionCoolOffUseCase {
  final IMonotonicClock clock;

  const VerifySessionCoolOffUseCase({
    required this.clock,
  });

  /// Evaluates the session state against monotonic time and returns [CoolOffDecisionEnum].
  ///
  /// Guarantees exhaustive handling of all [VaultSessionState] subtypes with zero wildcards.
  VaultResult<CoolOffDecisionEnum> execute(VerifyCoolOffParams params) {
    final currentMs = clock.currentMonotonicMs;
    final CoolOffDecisionEnum decision = switch (params.currentState) {
      final VaultUnlockedState unlockedState =>
        (params.config.activeReauthInterval != ActiveReauthIntervalEnum.never &&
                currentMs >= unlockedState.reauthDeadlineMonotonicMs)
            ? CoolOffDecisionEnum.reauthRequired
            : CoolOffDecisionEnum.sessionValid,
      final VaultBackgroundGraceState graceState =>
        (currentMs >= graceState.graceDeadlineMonotonicMs)
            ? CoolOffDecisionEnum.graceExpiredLock
            : CoolOffDecisionEnum.sessionValid,
      final VaultLockoutCooldownState lockoutState =>
        (currentMs >= lockoutState.deadlineMonotonicMs)
            ? CoolOffDecisionEnum.lockoutElapsedReset
            : CoolOffDecisionEnum.lockoutActive,
      VaultUninitializedState() => CoolOffDecisionEnum.sessionValid,
      VaultProvisioningState() => CoolOffDecisionEnum.sessionValid,
      VaultLockedState() => CoolOffDecisionEnum.sessionValid,
      VaultAuthenticatingState() => CoolOffDecisionEnum.sessionValid,
      VaultPendingReauthState() => CoolOffDecisionEnum.sessionValid,
    };

    return VaultResult.success(decision);
  }
}
