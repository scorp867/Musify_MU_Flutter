import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/policies/keypad_layout_policy.dart';

/// Governs the presentation and lifecycle of the fixed 6-digit PIN pad.
enum PinPadStateEnum {
  /// Awaiting user digit taps (tracking entered length 0..6).
  idleInput,

  /// Exactly 6 digits entered; inline loading while isolate derives key via PBKDF2-HMAC-SHA256.
  evaluatingAndDeriving,

  /// Derived key verified; showing brief tactile success indicator before transition.
  authSuccess,

  /// Incorrect PIN; triggering subtle tactile error shake animation and decrementing remaining attempts.
  authFailureShake,

  /// 5 or 10 consecutive failures reached; displaying monotonic countdown timer.
  lockedOut;

  /// Returns whether the PIN pad is actively accepting user input.
  bool get isAcceptingInput => this == PinPadStateEnum.idleInput;

  /// Returns whether cryptographic key derivation or authentication is underway.
  bool get isEvaluating => this == PinPadStateEnum.evaluatingAndDeriving;

  /// Returns whether authentication has succeeded.
  bool get isSuccess => this == PinPadStateEnum.authSuccess;

  /// Returns whether the error shake animation is playing.
  bool get isShaking => this == PinPadStateEnum.authFailureShake;

  /// Returns whether the PIN pad is locked out due to excessive failed attempts.
  bool get isLockedOut => this == PinPadStateEnum.lockedOut;
}

/// Deeply immutable sealed state hierarchy for Sub-Service 6 (PIN Authentication Controller).
@immutable
sealed class PinPadState extends Equatable {
  const PinPadState();

  /// The active PIN pad state discriminator.
  PinPadStateEnum get stateEnum;

  @override
  List<Object?> get props => [];
}

/// Awaiting user digit entry; tracks entered digit count (0..6) and active keypad layout.
@immutable
final class PinPadIdleInputState extends PinPadState {
  const PinPadIdleInputState({
    required this.enteredDigitsCount,
    required this.keypadLayout,
    this.digits = KeypadLayoutPolicyEnum.standardDigits,
  }) : assert(
  enteredDigitsCount >= 0 && enteredDigitsCount <= 6,
  'enteredDigitsCount must be between 0 and 6, but was $enteredDigitsCount',
  );

  /// Number of digits currently entered by the user (0 to 6).
  final int enteredDigitsCount;

  /// Active keypad arrangement policy (standard ordered vs randomized per attempt).
  final KeypadLayoutPolicyEnum keypadLayout;

  /// Immutable sequence of digits defining the active keypad layout arrangement.
  final List<int> digits;

  @override
  PinPadStateEnum get stateEnum => PinPadStateEnum.idleInput;

  /// Returns a new instance with one additional digit entered (maximum 6).
  PinPadIdleInputState appendDigit() {
    if (enteredDigitsCount >= 6) {
      return this;
    }
    return PinPadIdleInputState(
      enteredDigitsCount: enteredDigitsCount + 1,
      keypadLayout: keypadLayout,
      digits: digits,
    );
  }

  /// Returns a new instance with one digit removed (minimum 0).
  PinPadIdleInputState removeDigit() {
    if (enteredDigitsCount <= 0) {
      return this;
    }
    return PinPadIdleInputState(
      enteredDigitsCount: enteredDigitsCount - 1,
      keypadLayout: keypadLayout,
      digits: digits,
    );
  }

  /// Returns a new instance with all entered digits cleared.
  PinPadIdleInputState clearDigits({List<int>? newDigits}) {
    return PinPadIdleInputState(
      enteredDigitsCount: 0,
      keypadLayout: keypadLayout,
      digits: newDigits ?? digits,
    );
  }

  @override
  List<Object?> get props => [enteredDigitsCount, keypadLayout, digits];
}

/// Exactly 6 digits entered; isolate is deriving key via PBKDF2-HMAC-SHA256.
@immutable
final class PinPadEvaluatingState extends PinPadState {
  const PinPadEvaluatingState();

  @override
  PinPadStateEnum get stateEnum => PinPadStateEnum.evaluatingAndDeriving;
}

/// Derived key successfully authenticated against stored verification slot.
@immutable
final class PinPadSuccessState extends PinPadState {
  final AuthSession? session;

  const PinPadSuccessState({this.session});

  @override
  PinPadStateEnum get stateEnum => PinPadStateEnum.authSuccess;

  @override
  List<Object?> get props => [session];
}

/// Incorrect PIN entered; triggers tactile error shake animation and decrements remaining attempts.
@immutable
final class PinPadFailureShakeState extends PinPadState {
  const PinPadFailureShakeState({
    required this.failedAttemptsCount,
    required this.remainingAttemptsBeforeCooldown,
  }) : assert(
  failedAttemptsCount >= 0,
  'failedAttemptsCount must be non-negative',
  );

  /// Total consecutive failed attempts accumulated in this session.
  final int failedAttemptsCount;

  /// Remaining failed attempts before monotonic lockout cooldown is triggered.
  final int remainingAttemptsBeforeCooldown;

  @override
  PinPadStateEnum get stateEnum => PinPadStateEnum.authFailureShake;

  @override
  List<Object?> get props => [
    failedAttemptsCount,
    remainingAttemptsBeforeCooldown,
  ];
}

/// Excessive failed PIN attempts; monotonic lockout cooldown timer is counting down.
@immutable
final class PinPadLockedOutState extends PinPadState {
  const PinPadLockedOutState({
    required this.cooldownRemainingSeconds,
    required this.deadlineMonotonicMs,
  }) : assert(
  cooldownRemainingSeconds >= 0,
  'cooldownRemainingSeconds must be non-negative',
  );

  /// Remaining seconds until lockout cooldown expires.
  final int cooldownRemainingSeconds;

  /// The absolute OS monotonic timestamp (CLOCK_MONOTONIC) when lockout expires.
  final int deadlineMonotonicMs;

  @override
  PinPadStateEnum get stateEnum => PinPadStateEnum.lockedOut;

  @override
  List<Object?> get props => [
    cooldownRemainingSeconds,
    deadlineMonotonicMs,
  ];
}