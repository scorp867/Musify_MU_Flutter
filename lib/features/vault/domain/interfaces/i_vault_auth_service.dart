import 'dart:async';

import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';

/// Pure abstract interface defining the cryptographic and authentication service
/// for the Secure Vault (Harel Region A: Root Security Authority).
///
/// Encapsulates PIN derivation via PBKDF2-HMAC-SHA256, Android KeyStore biometric
/// challenges, PIN rotation, credential enrollment, brute-force lockout tracking,
/// and in-memory key buffer lifecycle management.
abstract interface class IVaultAuthService {
  /// Authenticates the user using a 6-digit PIN.
  ///
  /// On success, unwraps the Master Vault Key (MVK) via Slot 1 and returns an [AuthSession].
  /// On failure, increments the failed attempt counter, triggers lockout if a threshold is exceeded,
  /// and returns a typed [VaultAuthFailure] or [VaultLockoutFailure].
  Future<VaultResult<AuthSession>> authenticateWithPin({
    required String pin,
  });

  /// Authenticates the user via Android KeyStore hardware-backed biometrics (Slot 2).
  ///
  /// Resolves the cryptographic cipher via BiometricPrompt.CryptoObject and unwraps the MVK.
  /// Returns [AuthSession] on success or typed [VaultFailure] on failure or cancellation.
  Future<VaultResult<AuthSession>> authenticateWithBiometrics();

  /// Rotates the user's PIN from [oldPin] to [newPin], re-wrapping the MVK in Slot 1.
  ///
  /// Validates [oldPin] via step-up authentication and persists the re-wrapped key.
  Future<VaultResult<void>> rotatePin({
    required String oldPin,
    required String newPin,
  });

  /// Enrolls initial credentials for first-time vault setup.
  ///
  /// Provisions the Master Vault Key, derives Slot 1 KEK from [pin], and securely stores
  /// the synthesized golden gesture [template].
  Future<VaultResult<void>> enrollInitialCredentials({
    required String pin,
    required GestureTemplate template,
  });

  /// Retrieves the current brute-force protection status, active cooldown tier,
  /// and remaining cooldown duration.
  Future<LockoutCooldownInfo> getLockoutStatus();

  /// Records a failed PIN entry attempt, advancing the failure counter and triggering
  /// monotonic lockout cooldown escalation if 5 or 10 consecutive failures are reached.
  Future<void> recordFailedAttempt();

  /// Resets consecutive failed attempt counters upon successful authentication
  /// or when an active lockout cooldown deadline has elapsed.
  Future<void> resetFailedAttempts();

  /// Immediately zeros and dereferences all unwrapped cryptographic session keys,
  /// Master Vault Keys, and intermediate buffers in RAM.
  void clearSessionKeysFromRam();
}