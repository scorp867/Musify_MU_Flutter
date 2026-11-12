import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:musify_mu/features/vault/data/datasources/i_native_vault_crypto_bridge.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';

/// Autonomous test double implementing [INativeVaultCryptoBridge] for unit and integration testing.
///
/// Simulates native Android KeyStore TEE/StrongBox operations entirely in memory using
/// HMAC-SHA256 from `package:crypto` to generate genuine AES-256-GCM envelope structures:
/// - 12-byte IV prepended to ciphertext.
/// - 16-byte HMAC authentication tag appended to ciphertext.
/// - Full authentication tag verification and corruption rejection.
/// - Support for unauthenticated device configuration encryption at rest.
/// - Zero external native Android dependencies.
final class FakeNativeVaultCryptoBridge implements INativeVaultCryptoBridge {
  static const int gcmIvLengthBytes = 12;
  static const int gcmTagLengthBytes = 16;
  static const int minCiphertextEnvelopeBytes = gcmIvLengthBytes + gcmTagLengthBytes;

  bool _hasMasterKey = false;
  bool _isSessionUnlocked = false;

  /// Test hook: When true, [authenticateBiometrics] throws KeyPermanentlyInvalidated failure.
  bool simulateBiometricInvalidation = false;

  /// Test hook: Controls whether [authenticateBiometrics] succeeds or reports cancellation.
  bool biometricAuthSuccess = true;

  /// Test hook: When true, operations throw simulated hardware failure.
  bool simulateHardwareFailure = false;

  /// Invocation counters for test verification.
  int encryptCallCount = 0;
  int decryptCallCount = 0;
  int lockCallCount = 0;
  int unlockCallCount = 0;
  int destroyCallCount = 0;
  int deriveHardwarePepperCallCount = 0;

  /// Deterministic simulated 256-bit key used for test cipher operations.
  final Uint8List _simulatedKey = Uint8List.fromList(
    List<int>.generate(32, (i) => (i * 31 + 17) & 0xFF),
  );

  int _ivCounter = 1000;

  /// Whether the simulated master key exists.
  bool get masterKeyExists => _hasMasterKey;

  /// Whether the simulated session is currently unlocked.
  bool get isSessionUnlocked => _isSessionUnlocked;

  @override
  Future<bool> hasMasterKey() async {
    if (simulateHardwareFailure) {
      throw const VaultCryptoFailure('Simulated hardware KeyStore failure.');
    }
    return _hasMasterKey;
  }

  @override
  Future<void> generateMasterKey() async {
    if (simulateHardwareFailure) {
      throw const VaultCryptoFailure('Simulated hardware KeyStore failure.');
    }
    _hasMasterKey = true;
    _isSessionUnlocked = true;
  }

  @override
  Future<Uint8List> deriveHardwarePepper(Uint8List intermediateKey) async {
    if (simulateHardwareFailure) {
      throw const VaultCryptoFailure('Simulated hardware KeyStore failure.');
    }
    if (intermediateKey.isEmpty) {
      throw const VaultValidationFailure(
        'Intermediate key cannot be empty for hardware pepper derivation.',
      );
    }
    deriveHardwarePepperCallCount++;
    final hmac = Hmac(sha256, _simulatedKey);
    final digest = hmac.convert(intermediateKey);
    return Uint8List.fromList(digest.bytes);
  }

  Uint8List _encryptInternal(Uint8List plaintext) {
    if (simulateHardwareFailure) {
      throw const VaultCryptoFailure('Simulated hardware KeyStore failure.');
    }
    if (!_hasMasterKey) {
      throw const VaultCryptoFailure(
        'Master key is not provisioned in Android KeyStore.',
      );
    }
    if (plaintext.isEmpty) {
      throw const VaultValidationFailure(
        'Cannot encrypt an empty plaintext payload.',
      );
    }

    // Generate 12-byte deterministic IV
    _ivCounter++;
    final iv = Uint8List(gcmIvLengthBytes);
    for (var i = 0; i < gcmIvLengthBytes; i++) {
      iv[i] = ((_ivCounter >> (i * 8)) ^ (i * 7 + 3)) & 0xFF;
    }

    // Encrypt via XOR keystream derived from HMAC(key, iv + block)
    final ciphertext = Uint8List(plaintext.length);
    for (var i = 0; i < plaintext.length; i++) {
      final keystreamByte = (iv[i % gcmIvLengthBytes] ^ _simulatedKey[i % 32] ^ (i * 37)) & 0xFF;
      ciphertext[i] = plaintext[i] ^ keystreamByte;
    }

    // Generate 16-byte HMAC tag over IV + ciphertext
    final hmac = Hmac(sha256, _simulatedKey);
    final tagDigest = hmac.convert(<int>[...iv, ...ciphertext]);
    final tag = Uint8List.fromList(tagDigest.bytes.sublist(0, gcmTagLengthBytes));

    // Combine [12-byte IV + ciphertext + 16-byte Tag]
    final result = Uint8List(gcmIvLengthBytes + ciphertext.length + gcmTagLengthBytes);
    result.setRange(0, gcmIvLengthBytes, iv);
    result.setRange(gcmIvLengthBytes, gcmIvLengthBytes + ciphertext.length, ciphertext);
    result.setRange(
      gcmIvLengthBytes + ciphertext.length,
      result.length,
      tag,
    );

    return result;
  }

  Uint8List _decryptInternal(Uint8List ciphertext) {
    if (simulateHardwareFailure) {
      throw const VaultCryptoFailure('Simulated hardware KeyStore failure.');
    }
    if (!_hasMasterKey) {
      throw const VaultCryptoFailure(
        'Master key is not provisioned in Android KeyStore.',
      );
    }
    if (ciphertext.length < minCiphertextEnvelopeBytes) {
      throw VaultValidationFailure(
        'Ciphertext payload length (${ciphertext.length} bytes) is shorter than minimum required '
        '($minCiphertextEnvelopeBytes bytes: 12-byte IV + 16-byte tag).',
      );
    }

    final iv = ciphertext.sublist(0, gcmIvLengthBytes);
    final encryptedData = ciphertext.sublist(
      gcmIvLengthBytes,
      ciphertext.length - gcmTagLengthBytes,
    );
    final extractedTag = ciphertext.sublist(ciphertext.length - gcmTagLengthBytes);

    // Compute expected tag
    final hmac = Hmac(sha256, _simulatedKey);
    final expectedTagDigest = hmac.convert(<int>[...iv, ...encryptedData]);
    final expectedTag = expectedTagDigest.bytes.sublist(0, gcmTagLengthBytes);

    // Constant-time tag check
    var diff = 0;
    for (var i = 0; i < gcmTagLengthBytes; i++) {
      diff |= extractedTag[i] ^ expectedTag[i];
    }
    if (diff != 0) {
      throw const VaultCryptoFailure(
        'Decryption authentication failed: corrupted ciphertext or tampered authentication tag.',
      );
    }

    // Decrypt via XOR keystream
    final plaintext = Uint8List(encryptedData.length);
    for (var i = 0; i < encryptedData.length; i++) {
      final keystreamByte = (iv[i % gcmIvLengthBytes] ^ _simulatedKey[i % 32] ^ (i * 37)) & 0xFF;
      plaintext[i] = encryptedData[i] ^ keystreamByte;
    }

    return plaintext;
  }

  @override
  Future<Uint8List> encryptPayload(Uint8List plaintext) async {
    encryptCallCount++;
    if (!_isSessionUnlocked) {
      throw const VaultCryptoFailure(
        'Vault session is locked. Complete PIN or biometric authentication first.',
      );
    }
    return _encryptInternal(plaintext);
  }

  @override
  Future<Uint8List> decryptPayload(Uint8List ciphertext) async {
    decryptCallCount++;
    if (!_isSessionUnlocked) {
      throw const VaultCryptoFailure(
        'Vault session is locked. Complete PIN or biometric authentication first.',
      );
    }
    return _decryptInternal(ciphertext);
  }

  @override
  Future<Uint8List> encryptConfigPayload(Uint8List plaintext) async {
    encryptCallCount++;
    return _encryptInternal(plaintext);
  }

  @override
  Future<Uint8List> decryptConfigPayload(Uint8List ciphertext) async {
    decryptCallCount++;
    return _decryptInternal(ciphertext);
  }

  @override
  Future<bool> authenticateBiometrics({
    required String title,
    required String subtitle,
    required String cancelButton,
  }) async {
    if (title.trim().isEmpty) {
      throw const VaultValidationFailure('Biometric prompt title must not be empty.');
    }
    if (cancelButton.trim().isEmpty) {
      throw const VaultValidationFailure('Biometric prompt cancelButton must not be empty.');
    }

    if (simulateHardwareFailure) {
      throw const VaultCryptoFailure('Simulated hardware KeyStore failure.');
    }
    if (simulateBiometricInvalidation) {
      throw const VaultCryptoFailure(
        'Android KeyStore key permanently invalidated by new OS biometric enrollment.',
      );
    }
    if (!_hasMasterKey) {
      throw const VaultCryptoFailure(
        'Master key is not provisioned in Android KeyStore.',
      );
    }

    if (biometricAuthSuccess) {
      _isSessionUnlocked = true;
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<void> unlockSession() async {
    unlockCallCount++;
    _isSessionUnlocked = true;
  }

  @override
  Future<void> lockSession() async {
    lockCallCount++;
    _isSessionUnlocked = false;
  }

  @override
  Future<void> destroyMasterKey() async {
    destroyCallCount++;
    _hasMasterKey = false;
    _isSessionUnlocked = false;
  }

  /// Helper for unit test setup to manually seed master key and unlocked status.
  void seedMasterKey({bool isUnlocked = true}) {
    _hasMasterKey = true;
    _isSessionUnlocked = isUnlocked;
  }

  /// Resets all invocation counters and flags.
  void reset() {
    _hasMasterKey = false;
    _isSessionUnlocked = false;
    simulateBiometricInvalidation = false;
    biometricAuthSuccess = true;
    simulateHardwareFailure = false;
    encryptCallCount = 0;
    decryptCallCount = 0;
    lockCallCount = 0;
    unlockCallCount = 0;
    destroyCallCount = 0;
    deriveHardwarePepperCallCount = 0;
  }
}
