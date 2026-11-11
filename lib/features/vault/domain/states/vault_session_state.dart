import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';

/// Enumeration of lockout cooldown tiers enforcing brute-force protection.
enum LockoutCooldownTierEnum {
  /// No lockout cooldown is active.
  none,

  /// Tier 1: 30-second cooldown enforced after 5 consecutive failed PIN attempts.
  tier1ThirtySeconds,

  /// Tier 2: 5-minute cooldown enforced after 10 consecutive failed PIN attempts.
  tier2FiveMinutes;

  /// Duration of this lockout tier in milliseconds.
  int get durationMs => switch (this) {
        LockoutCooldownTierEnum.none => 0,
        LockoutCooldownTierEnum.tier1ThirtySeconds => 30000,
        LockoutCooldownTierEnum.tier2FiveMinutes => 300000,
      };

  /// Consecutive failure threshold required to trigger this tier.
  int get thresholdAttempts => switch (this) {
        LockoutCooldownTierEnum.none => 0,
        LockoutCooldownTierEnum.tier1ThirtySeconds => 5,
        LockoutCooldownTierEnum.tier2FiveMinutes => 10,
      };
}

/// Root sealed state hierarchy governing the security lifecycle of the Private Vault
/// (Harel Region A: Root Security Authority).
///
/// Strictly adheres to David Harel's Statechart Automata and Dart 3 sealed class
/// patterns. Zero loose boolean flags. Every state carries only the exact strongly-typed
/// properties valid for that lifecycle phase.
@immutable
sealed class VaultSessionState extends Equatable {
  const VaultSessionState();

  @override
  List<Object?> get props => [];
}

/// Initial unprovisioned state.
///
/// Indicates that no Master Vault Key, custom PIN, or master gesture template has
/// been provisioned, or that a data purge has completed.
@immutable
final class VaultUninitializedState extends VaultSessionState {
  const VaultUninitializedState();

  @override
  List<Object?> get props => [];
}

/// Active first-time vault provisioning state.
///
/// Entered when the stealth gesture matches on an uninitialized vault and the user
/// is in the PIN creation setup flow. Cryptographic key provisioning and credential
/// enrollment are pending. If the application backgrounds during provisioning,
/// the state reverts to [VaultUninitializedState].
@immutable
final class VaultProvisioningState extends VaultSessionState {
  const VaultProvisioningState();

  @override
  List<Object?> get props => [];
}

/// Default secure locked state.
///
/// Cryptographic keys in RAM are zeroed and domain metadata is dereferenced.
/// Audio playback may proceed in the background only under the decoy masking strategy.
@immutable
final class VaultLockedState extends VaultSessionState {
  /// Monotonic timestamp in milliseconds when the vault locked.
  final int lockedAtMonotonicMs;

  const VaultLockedState({
    required this.lockedAtMonotonicMs,
  }) : assert(lockedAtMonotonicMs >= 0, 'lockedAtMonotonicMs must be non-negative');

  @override
  List<Object?> get props => [lockedAtMonotonicMs];
}

/// Active authentication sheet / PIN pad interaction state.
///
/// Entered when a stealth gesture match occurs or when the user invokes the PIN pad.
@immutable
final class VaultAuthenticatingState extends VaultSessionState {
  /// Unique identifier tracking this authentication flow attempt.
  final String authSessionId;

  /// Current 1-based attempt sequence number.
  final int attemptNumber;

  /// Number of remaining attempts allowed before escalating to lockout cooldown.
  final int remainingAttemptsBeforeCooldown;

  const VaultAuthenticatingState({
    required this.authSessionId,
    required this.attemptNumber,
    required this.remainingAttemptsBeforeCooldown,
  })  : assert(authSessionId.length > 0, 'authSessionId must not be empty'),
        assert(attemptNumber >= 1, 'attemptNumber must be at least 1'),
        assert(remainingAttemptsBeforeCooldown >= 0,
            'remainingAttemptsBeforeCooldown must be non-negative');

  /// Creates a copy of this state with updated fields.
  VaultAuthenticatingState copyWith({
    String? authSessionId,
    int? attemptNumber,
    int? remainingAttemptsBeforeCooldown,
  }) {
    return VaultAuthenticatingState(
      authSessionId: authSessionId ?? this.authSessionId,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      remainingAttemptsBeforeCooldown:
          remainingAttemptsBeforeCooldown ?? this.remainingAttemptsBeforeCooldown,
    );
  }

  @override
  List<Object?> get props => [
        authSessionId,
        attemptNumber,
        remainingAttemptsBeforeCooldown,
      ];
}

/// Abstract compound state representing an authenticated, active vault session.
///
/// Guarantees that an authenticated [AuthSession] is non-null for all active sub-states.
@immutable
sealed class VaultActiveSessionState extends VaultSessionState {
  /// The active authenticated session context.
  final AuthSession session;

  const VaultActiveSessionState({
    required this.session,
  });

  @override
  List<Object?> get props => [session];
}

/// Actively unlocked vault state.
///
/// The user is actively browsing or interacting with the vault. The Master Vault Key
/// is unwrapped in RAM, decrypted metadata is present, and the active cool-off
/// timer is progressing toward [reauthDeadlineMonotonicMs].
@immutable
final class VaultUnlockedState extends VaultActiveSessionState {
  /// Monotonic timestamp in milliseconds when the session unlocked.
  final int unlockedAtMonotonicMs;

  /// Monotonic timestamp deadline after which active re-auth is triggered.
  /// A value of 0 indicates active re-auth is disabled (ActiveReauthIntervalEnum.never).
  final int reauthDeadlineMonotonicMs;

  const VaultUnlockedState({
    required super.session,
    required this.unlockedAtMonotonicMs,
    required this.reauthDeadlineMonotonicMs,
  })  : assert(unlockedAtMonotonicMs >= 0, 'unlockedAtMonotonicMs must be non-negative'),
        assert(reauthDeadlineMonotonicMs >= 0,
            'reauthDeadlineMonotonicMs must be non-negative');

  /// Creates a copy of this state with updated parameters.
  VaultUnlockedState copyWith({
    AuthSession? session,
    int? unlockedAtMonotonicMs,
    int? reauthDeadlineMonotonicMs,
  }) {
    return VaultUnlockedState(
      session: session ?? this.session,
      unlockedAtMonotonicMs: unlockedAtMonotonicMs ?? this.unlockedAtMonotonicMs,
      reauthDeadlineMonotonicMs:
          reauthDeadlineMonotonicMs ?? this.reauthDeadlineMonotonicMs,
    );
  }

  @override
  List<Object?> get props => [
        session,
        unlockedAtMonotonicMs,
        reauthDeadlineMonotonicMs,
      ];
}

/// Background grace period state.
///
/// Entered when the application transitions to the background (paused/inactive) while
/// the vault is unlocked, and background grace policy is not immediate.
/// If the application resumes before [graceDeadlineMonotonicMs], state restores to
/// [VaultUnlockedState]; otherwise, state transitions to [VaultLockedState].
@immutable
final class VaultBackgroundGraceState extends VaultActiveSessionState {
  /// Monotonic timestamp in milliseconds when the application entered the background.
  final int enteredBackgroundMonotonicMs;

  /// Configured grace timeout duration in milliseconds.
  final int graceTimeoutMs;

  /// Monotonic timestamp deadline when the grace window elapses.
  final int graceDeadlineMonotonicMs;

  const VaultBackgroundGraceState({
    required super.session,
    required this.enteredBackgroundMonotonicMs,
    required this.graceTimeoutMs,
    required this.graceDeadlineMonotonicMs,
  })  : assert(enteredBackgroundMonotonicMs >= 0,
            'enteredBackgroundMonotonicMs must be non-negative'),
        assert(graceTimeoutMs >= 0, 'graceTimeoutMs must be non-negative'),
        assert(graceDeadlineMonotonicMs >= enteredBackgroundMonotonicMs,
            'graceDeadlineMonotonicMs must be >= enteredBackgroundMonotonicMs');

  /// Creates a copy of this state with updated parameters.
  VaultBackgroundGraceState copyWith({
    AuthSession? session,
    int? enteredBackgroundMonotonicMs,
    int? graceTimeoutMs,
    int? graceDeadlineMonotonicMs,
  }) {
    return VaultBackgroundGraceState(
      session: session ?? this.session,
      enteredBackgroundMonotonicMs:
          enteredBackgroundMonotonicMs ?? this.enteredBackgroundMonotonicMs,
      graceTimeoutMs: graceTimeoutMs ?? this.graceTimeoutMs,
      graceDeadlineMonotonicMs:
          graceDeadlineMonotonicMs ?? this.graceDeadlineMonotonicMs,
    );
  }

  @override
  List<Object?> get props => [
        session,
        enteredBackgroundMonotonicMs,
        graceTimeoutMs,
        graceDeadlineMonotonicMs,
      ];
}

/// Non-destructive mid-session re-authentication state.
///
/// Triggered when the active session cool-off timer elapses while the user is inside
/// the vault. The UI displays a non-destructive blurred overlay while audio playback
/// continues uninterrupted. Successful step-up re-auth restores [VaultUnlockedState]
/// without destroying scroll or view state.
@immutable
final class VaultPendingReauthState extends VaultActiveSessionState {
  /// Monotonic timestamp in milliseconds when re-auth was triggered.
  final int reauthTriggeredAtMonotonicMs;

  /// Remaining step-up attempts before session invalidation and lock.
  final int remainingAttempts;

  const VaultPendingReauthState({
    required super.session,
    required this.reauthTriggeredAtMonotonicMs,
    required this.remainingAttempts,
  })  : assert(reauthTriggeredAtMonotonicMs >= 0,
            'reauthTriggeredAtMonotonicMs must be non-negative'),
        assert(remainingAttempts >= 0, 'remainingAttempts must be non-negative');

  /// Creates a copy of this state with updated parameters.
  VaultPendingReauthState copyWith({
    AuthSession? session,
    int? reauthTriggeredAtMonotonicMs,
    int? remainingAttempts,
  }) {
    return VaultPendingReauthState(
      session: session ?? this.session,
      reauthTriggeredAtMonotonicMs:
          reauthTriggeredAtMonotonicMs ?? this.reauthTriggeredAtMonotonicMs,
      remainingAttempts: remainingAttempts ?? this.remainingAttempts,
    );
  }

  @override
  List<Object?> get props => [
        session,
        reauthTriggeredAtMonotonicMs,
        remainingAttempts,
      ];
}

/// Brute-force protection lockout cooldown state.
///
/// Active after consecutive failed PIN attempts (5 failures = 30 seconds; 10 failures = 5 minutes).
/// The monotonic deadline is securely persisted so that app termination does not bypass lockout.
/// When [deadlineMonotonicMs] is reached, the state deterministically transitions back to
/// [VaultLockedState] with failed attempt counters reset to 0.
@immutable
final class VaultLockoutCooldownState extends VaultSessionState {
  /// Cooldown tier (tier1ThirtySeconds or tier2FiveMinutes).
  final LockoutCooldownTierEnum tier;

  /// Monotonic timestamp in milliseconds when the cooldown started.
  final int cooldownStartedMonotonicMs;

  /// Total duration of the cooldown in milliseconds.
  final int durationMs;

  /// Monotonic timestamp deadline when the lockout expires.
  final int deadlineMonotonicMs;

  /// Total count of consecutive failed attempts that caused this lockout.
  final int failedAttemptsCount;

  const VaultLockoutCooldownState({
    required this.tier,
    required this.cooldownStartedMonotonicMs,
    required this.durationMs,
    required this.deadlineMonotonicMs,
    required this.failedAttemptsCount,
  })  : assert(cooldownStartedMonotonicMs >= 0,
            'cooldownStartedMonotonicMs must be non-negative'),
        assert(durationMs > 0, 'durationMs must be positive'),
        assert(deadlineMonotonicMs >= cooldownStartedMonotonicMs,
            'deadlineMonotonicMs must be >= cooldownStartedMonotonicMs'),
        assert(failedAttemptsCount >= 5,
            'failedAttemptsCount must be >= 5 for lockout cooldown');

  /// Creates a copy of this state with updated parameters.
  VaultLockoutCooldownState copyWith({
    LockoutCooldownTierEnum? tier,
    int? cooldownStartedMonotonicMs,
    int? durationMs,
    int? deadlineMonotonicMs,
    int? failedAttemptsCount,
  }) {
    return VaultLockoutCooldownState(
      tier: tier ?? this.tier,
      cooldownStartedMonotonicMs:
          cooldownStartedMonotonicMs ?? this.cooldownStartedMonotonicMs,
      durationMs: durationMs ?? this.durationMs,
      deadlineMonotonicMs: deadlineMonotonicMs ?? this.deadlineMonotonicMs,
      failedAttemptsCount: failedAttemptsCount ?? this.failedAttemptsCount,
    );
  }

  @override
  List<Object?> get props => [
        tier,
        cooldownStartedMonotonicMs,
        durationMs,
        deadlineMonotonicMs,
        failedAttemptsCount,
      ];
}
