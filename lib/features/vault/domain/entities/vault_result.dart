import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Sealed hierarchy representing domain-level failures within the Secure Vault.
///
/// Strictly categorizes errors across cryptographic, authentication, storage,
/// gesture, and validation boundaries without swallowing exceptions or returning raw maps.
@immutable
sealed class VaultFailure extends Equatable {
  /// User-safe descriptive failure message.
  final String message;

  /// Optional underlying exception, error, or cause.
  final Object? cause;

  const VaultFailure(this.message, {this.cause});

  @override
  List<Object?> get props => [message, cause];
}

/// Authentication failure due to invalid PIN, canceled biometric challenge, or mismatched credentials.
final class VaultAuthFailure extends VaultFailure {
  /// Remaining attempts before escalating to lockout cooldown.
  final int remainingAttempts;

  const VaultAuthFailure(
    super.message, {
    this.remainingAttempts = 0,
    super.cause,
  });

  @override
  List<Object?> get props => [message, cause, remainingAttempts];
}

/// Brute-force protection lockout failure indicating active cooldown period.
final class VaultLockoutFailure extends VaultFailure {
  /// Remaining cooldown duration in seconds.
  final int remainingCooldownSeconds;

  /// Monotonic timestamp deadline when the cooldown elapses.
  final int deadlineMonotonicMs;

  const VaultLockoutFailure(
    super.message, {
    required this.remainingCooldownSeconds,
    required this.deadlineMonotonicMs,
    super.cause,
  });

  @override
  List<Object?> get props => [
        message,
        cause,
        remainingCooldownSeconds,
        deadlineMonotonicMs,
      ];
}

/// Cryptographic failure during key wrapping, unwrapping, PBKDF2 derivation, or KeyStore invalidation.
final class VaultCryptoFailure extends VaultFailure {
  const VaultCryptoFailure(super.message, {super.cause});
}

/// Storage failure during encrypted metadata persistence, retrieval, or media file relocation.
final class VaultStorageFailure extends VaultFailure {
  const VaultStorageFailure(super.message, {super.cause});
}

/// Gesture recognition pipeline failure, synthesis error, or stroke inconsistency.
final class VaultGestureFailure extends VaultFailure {
  const VaultGestureFailure(super.message, {super.cause});
}

/// Domain validation failure caused by corrupted schema, empty inputs, or negative bounds.
final class VaultValidationFailure extends VaultFailure {
  const VaultValidationFailure(super.message, {super.cause});
}

/// Dart 3 algebraic sealed result type representing either a successful domain value [T]
/// or a typed [VaultFailure].
///
/// Eliminates null fallbacks, dynamic maps, and swallowed exceptions.
@immutable
sealed class VaultResult<T> extends Equatable {
  const VaultResult();

  /// Constructs a successful result holding [data].
  const factory VaultResult.success(T data) = VaultSuccess<T>;

  /// Constructs a failed result holding [failure].
  const factory VaultResult.failure(VaultFailure failure) = VaultFailureResult<T>;

  /// Catamorphism folding over the two possible outcomes.
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(VaultFailure failure) onFailure,
  });
}

/// Successful variant of [VaultResult] carrying non-null payload of type [T].
final class VaultSuccess<T> extends VaultResult<T> {
  /// Successful domain payload.
  final T data;

  const VaultSuccess(this.data);

  @override
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(VaultFailure failure) onFailure,
  }) {
    return onSuccess(data);
  }

  @override
  List<Object?> get props => [data];
}

/// Failure variant of [VaultResult] carrying typed [VaultFailure].
final class VaultFailureResult<T> extends VaultResult<T> {
  /// Typed domain failure.
  final VaultFailure failure;

  const VaultFailureResult(this.failure);

  @override
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(VaultFailure failure) onFailure,
  }) {
    return onFailure(failure);
  }

  @override
  List<Object?> get props => [failure];
}
