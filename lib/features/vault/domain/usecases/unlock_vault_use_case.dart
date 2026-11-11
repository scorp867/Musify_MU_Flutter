import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

/// Sealed parameter hierarchy for [UnlockVaultUseCase] authentication requests.
@immutable
sealed class UnlockVaultParams extends Equatable {
  const UnlockVaultParams();
}

/// Parameter carrying a 6-digit numeric PIN for vault unlock.
@immutable
final class PinUnlockParams extends UnlockVaultParams {
  /// The 6-digit numeric PIN entered by the user.
  final String pin;

  const PinUnlockParams(this.pin);

  @override
  List<Object?> get props => [pin];
}

/// Parameter requesting hardware-backed biometric authentication for vault unlock.
@immutable
final class BiometricUnlockParams extends UnlockVaultParams {
  const BiometricUnlockParams();

  @override
  List<Object?> get props => [];
}

/// Use case interactor coordinating authentication, brute-force lockout enforcement,
/// and session credential unwrapping.
@immutable
class UnlockVaultUseCase {
  final IVaultAuthService authService;

  const UnlockVaultUseCase({
    required this.authService,
  });

  /// Executes vault unlock under the provided [params].
  ///
  /// Verifies brute-force lockout status before attempting authentication.
  /// If lockout cooldown is active, immediately returns [VaultLockoutFailure].
  /// On success, resets consecutive failure counters and returns [VaultSuccess] with [AuthSession].
  /// On failure, records the failed attempt and escalates to [VaultLockoutFailure] if cooldown
  /// thresholds are reached, otherwise returns [VaultAuthFailure] with remaining attempt count.
  Future<VaultResult<AuthSession>> execute(UnlockVaultParams params) async {
    final lockoutStatus = await authService.getLockoutStatus();
    if (lockoutStatus.tier != LockoutCooldownTierEnum.none) {
      return VaultResult.failure(
        VaultLockoutFailure(
          'Vault is locked out. Please wait for cooldown to expire.',
          remainingCooldownSeconds: lockoutStatus.remainingCooldownSeconds,
          deadlineMonotonicMs: lockoutStatus.deadlineMonotonicMs,
        ),
      );
    }

    final VaultResult<AuthSession> authResult;
    switch (params) {
      case final PinUnlockParams pinParams:
        if (!_isSixDigitNumeric(pinParams.pin)) {
          return const VaultResult.failure(
            VaultValidationFailure('PIN must consist of exactly 6 numeric digits.'),
          );
        }
        authResult = await authService.authenticateWithPin(pin: pinParams.pin);
      case BiometricUnlockParams():
        authResult = await authService.authenticateWithBiometrics();
    }

    switch (authResult) {
      case final VaultSuccess<AuthSession> success:
        await authService.resetFailedAttempts();
        return VaultResult.success(success.data);
      case final VaultFailureResult<AuthSession> failureResult:
        await authService.recordFailedAttempt();
        final updatedLockout = await authService.getLockoutStatus();
        if (updatedLockout.tier != LockoutCooldownTierEnum.none) {
          return VaultResult.failure(
            VaultLockoutFailure(
              'Too many failed attempts. Cooldown engaged.',
              remainingCooldownSeconds: updatedLockout.remainingCooldownSeconds,
              deadlineMonotonicMs: updatedLockout.deadlineMonotonicMs,
              cause: failureResult.failure.cause,
            ),
          );
        }

        final remainingAttempts = _calculateRemainingAttempts(
          consecutiveFailedAttempts: updatedLockout.consecutiveFailedAttempts,
        );
        return VaultResult.failure(
          VaultAuthFailure(
            failureResult.failure.message,
            remainingAttempts: remainingAttempts,
            cause: failureResult.failure.cause,
          ),
        );
    }
  }

  static bool _isSixDigitNumeric(String pin) {
    if (pin.length != 6) {
      return false;
    }
    for (var i = 0; i < pin.length; i++) {
      final codeUnit = pin.codeUnitAt(i);
      if (codeUnit < 48 || codeUnit > 57) {
        return false;
      }
    }
    return true;
  }

  static int _calculateRemainingAttempts({
    required int consecutiveFailedAttempts,
  }) {
    if (consecutiveFailedAttempts < 5) {
      return 5 - consecutiveFailedAttempts;
    }
    if (consecutiveFailedAttempts < 10) {
      return 10 - consecutiveFailedAttempts;
    }
    return 0;
  }
}
