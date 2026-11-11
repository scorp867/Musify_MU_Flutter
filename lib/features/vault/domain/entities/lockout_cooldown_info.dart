import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

/// Deeply immutable value object representing the brute-force protection lockout status.
///
/// Encapsulates the active cooldown tier, consecutive failure count, monotonic deadline,
/// and remaining cooldown time in seconds.
///
/// Strictly enforces the Zero Loose Booleans mandate: contains zero `bool isLockedOut` flags.
/// Throttling status is evaluated deterministically via [tier].
@immutable
class LockoutCooldownInfo extends Equatable {
  /// Active cooldown tier enforcing PIN throttling.
  final LockoutCooldownTierEnum tier;

  /// Current count of consecutive failed PIN authentication attempts.
  final int consecutiveFailedAttempts;

  /// Monotonic timestamp deadline in milliseconds after which the lockout expires.
  /// A value of 0 indicates no active lockout.
  final int deadlineMonotonicMs;

  /// Calculated remaining cooldown duration in seconds.
  /// Evaluates to 0 when no cooldown is active.
  final int remainingCooldownSeconds;

  /// Constructs a validated [LockoutCooldownInfo] instance.
  ///
  /// Throws [FormatException] if [consecutiveFailedAttempts], [deadlineMonotonicMs],
  /// or [remainingCooldownSeconds] is negative.
  LockoutCooldownInfo({
    required this.tier,
    required this.consecutiveFailedAttempts,
    required this.deadlineMonotonicMs,
    required this.remainingCooldownSeconds,
  }) {
    if (consecutiveFailedAttempts < 0) {
      throw FormatException(
        'LockoutCooldownInfo consecutiveFailedAttempts must be non-negative: $consecutiveFailedAttempts',
      );
    }
    if (deadlineMonotonicMs < 0) {
      throw FormatException(
        'LockoutCooldownInfo deadlineMonotonicMs must be non-negative: $deadlineMonotonicMs',
      );
    }
    if (remainingCooldownSeconds < 0) {
      throw FormatException(
        'LockoutCooldownInfo remainingCooldownSeconds must be non-negative: $remainingCooldownSeconds',
      );
    }
  }

  /// Factory constructor representing an unthrottled, clear security state.
  factory LockoutCooldownInfo.none() {
    return LockoutCooldownInfo(
      tier: LockoutCooldownTierEnum.none,
      consecutiveFailedAttempts: 0,
      deadlineMonotonicMs: 0,
      remainingCooldownSeconds: 0,
    );
  }

  /// Creates a copy of this info object with updated properties.
  LockoutCooldownInfo copyWith({
    LockoutCooldownTierEnum? tier,
    int? consecutiveFailedAttempts,
    int? deadlineMonotonicMs,
    int? remainingCooldownSeconds,
  }) {
    return LockoutCooldownInfo(
      tier: tier ?? this.tier,
      consecutiveFailedAttempts:
          consecutiveFailedAttempts ?? this.consecutiveFailedAttempts,
      deadlineMonotonicMs: deadlineMonotonicMs ?? this.deadlineMonotonicMs,
      remainingCooldownSeconds:
          remainingCooldownSeconds ?? this.remainingCooldownSeconds,
    );
  }

  @override
  List<Object?> get props => [
        tier,
        consecutiveFailedAttempts,
        deadlineMonotonicMs,
        remainingCooldownSeconds,
      ];
}
