import 'dart:typed_data';

import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';

/// Pure abstract interface defining the platform channel bridge to native Android
/// hardware-backed cryptographic security (Android KeyStore TEE / StrongBox).
///
/// Strictly enforces the Hardware Offload Invariant:
/// Master encryption keys, key wrapping keys, and raw AES keys NEVER enter Dart heap/RAM.
/// Dart communicates strictly via ciphertext or plaintext payload buffers.
/// All key derivation, key generation, biometric CryptoObject binding, and AES-256-GCM
/// cipher transformations execute natively inside Android TEE / StrongBox.
abstract interface class INativeVaultCryptoBridge {
  /// Queries whether a hardware-backed Master Vault Key (MVK) exists in the native Android KeyStore.
  ///
  /// Returns `true` if the key alias is provisioned in the Android KeyStore, `false` otherwise.
  /// Throws [VaultCryptoFailure] if the native KeyStore encounters an unrecoverable platform error.
  Future<bool> hasMasterKey();

  /// Generates a non-exportable 256-bit AES-GCM master key and non-exportable HMAC-SHA256
  /// pepper key inside Android KeyStore hardware (TEE/StrongBox).
  ///
  /// Throws [VaultCryptoFailure] if hardware key generation fails.
  Future<void> generateMasterKey();

  /// Derives a hardware-bound cryptographic key by passing an [intermediateKey] through
  /// Android KeyStore's non-exportable HMAC-SHA256 hardware pepper.
  ///
  /// Prevents offline GPU brute-force attacks against low-entropy PIN credentials by ensuring
  /// candidate derivations require interaction with the physical hardware security module.
  /// Throws [VaultValidationFailure] if [intermediateKey] is empty.
  /// Throws [VaultCryptoFailure] if hardware derivation fails.
  Future<Uint8List> deriveHardwarePepper(Uint8List intermediateKey);

  /// Encrypts [plaintext] bytes using native AES-256-GCM backed by the Android KeyStore hardware key.
  ///
  /// Enforces active session unlock authorization (`isSessionUnlocked == true`).
  /// Used exclusively for sensitive private media and playlist content.
  /// Returns a [Uint8List] containing the self-contained cryptographic envelope:
  /// `[12-byte IV + AES-GCM Ciphertext + 16-byte GCM Authentication Tag]`.
  /// Throws [VaultValidationFailure] if [plaintext] is empty.
  /// Throws [VaultCryptoFailure] if the master key is not provisioned, session is locked,
  /// or encryption fails.
  Future<Uint8List> encryptPayload(Uint8List plaintext);

  /// Decrypts [ciphertext] bytes using native AES-256-GCM backed by the Android KeyStore hardware key.
  ///
  /// Enforces active session unlock authorization (`isSessionUnlocked == true`).
  /// Used exclusively for sensitive private media and playlist content.
  /// Expects [ciphertext] formatted as `[12-byte IV + AES-GCM Ciphertext + 16-byte Tag]`.
  /// Returns the decrypted plaintext as a mutable [Uint8List].
  /// Throws [VaultValidationFailure] if [ciphertext] is smaller than the minimum envelope size (28 bytes).
  /// Throws [VaultCryptoFailure] if authentication tag verification fails, the payload is corrupted,
  /// the session is locked, or the native KeyStore has been invalidated.
  Future<Uint8List> decryptPayload(Uint8List ciphertext);

  /// Encrypts configuration [plaintext] bytes using native AES-256-GCM backed by the Android KeyStore hardware key.
  ///
  /// Does NOT require user session unlock authorization, permitting configuration persistence at any time
  /// while guaranteeing full hardware encryption at rest against offline device extraction.
  /// Returns a [Uint8List] containing the self-contained cryptographic envelope:
  /// `[12-byte IV + AES-GCM Ciphertext + 16-byte GCM Authentication Tag]`.
  /// Throws [VaultValidationFailure] if [plaintext] is empty.
  /// Throws [VaultCryptoFailure] if the master key is not provisioned or encryption fails.
  Future<Uint8List> encryptConfigPayload(Uint8List plaintext);

  /// Decrypts configuration [ciphertext] bytes using native AES-256-GCM backed by the Android KeyStore hardware key.
  ///
  /// Does NOT require user session unlock authorization, permitting deterministic cold-start rehydration
  /// before the user enters their PIN so pre-unlock security gates (drawer gesture sensor, auth pad, theme)
  /// are armed immediately on Frame 0.
  /// Expects [ciphertext] formatted as `[12-byte IV + AES-GCM Ciphertext + 16-byte Tag]`.
  /// Returns the decrypted plaintext as a mutable [Uint8List].
  /// Throws [VaultValidationFailure] if [ciphertext] is smaller than the minimum envelope size (28 bytes).
  /// Throws [VaultCryptoFailure] if authentication tag verification fails, payload is corrupted,
  /// or the native KeyStore encounters an error.
  Future<Uint8List> decryptConfigPayload(Uint8List ciphertext);

  /// Triggers native Android BiometricPrompt challenge backed by `BiometricPrompt.CryptoObject`.
  ///
  /// [title], [subtitle], and [cancelButton] configure the user-facing OS biometric prompt sheet.
  /// Returns `true` if biometric authentication succeeds and authorizes the KeyStore cipher.
  /// Returns `false` if the user cancels or dismisses the prompt without authenticating.
  /// Throws [VaultAuthFailure] if biometric verification fails (e.g. lockout or sensor error).
  /// Throws [VaultCryptoFailure] if the biometric key is permanently invalidated (`KeyPermanentlyInvalidatedException`).
  Future<bool> authenticateBiometrics({
    required String title,
    required String subtitle,
    required String cancelButton,
  });

  /// Unlocks the native cryptographic session after successful Slot 1 PIN derivation.
  ///
  /// Authorizes subsequent [encryptPayload] and [decryptPayload] operations.
  /// Throws [VaultCryptoFailure] if native session state mutation fails.
  Future<void> unlockSession();

  /// Closes active native session handles and clears any in-memory cipher state in native Kotlin.
  ///
  /// Throws [VaultCryptoFailure] if native session cleanup fails.
  Future<void> lockSession();

  /// Permanently deletes the Master Vault Key alias from the Android KeyStore and zeroes session state.
  ///
  /// Used during vault data purge or factory reset.
  /// Throws [VaultCryptoFailure] if key destruction fails.
  Future<void> destroyMasterKey();
}
