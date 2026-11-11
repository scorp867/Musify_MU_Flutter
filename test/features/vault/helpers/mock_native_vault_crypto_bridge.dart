import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:musify_mu/features/vault/data/datasources/i_native_vault_crypto_bridge.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';

/// In-memory mock implementation of [INativeVaultCryptoBridge] for unit and integration testing.
///
/// Accurately simulates:
/// 1. Self-contained 28-byte cryptographic envelope: `[12-byte IV + AES-GCM Ciphertext + 16-byte Tag]`.
/// 2. Session locking behavior: throws [VaultCryptoFailure] on encryption/decryption when locked.
/// 3. AEAD authentication tag verification: throws [VaultCryptoFailure] when ciphertext or tag is modified.
/// 4. KeyStore lifecycle: simulates key generation, unlocking, locking, and destruction.
class MockNativeVaultCryptoBridge implements INativeVaultCryptoBridge {
  bool _hasMasterKey;
  bool _isSessionUnlocked;
  bool _isBiometricEnrolled;
  int _ivCounter = 1;

  /// Creates a [MockNativeVaultCryptoBridge] with configurable initial state.
  MockNativeVaultCryptoBridge({
    bool hasMasterKey = true,
    bool isSessionUnlocked = true,
    bool isBiometricEnrolled = true,
  })  : _hasMasterKey = hasMasterKey,
        _isSessionUnlocked = isSessionUnlocked,
        _isBiometricEnrolled = isBiometricEnrolled;

  /// Explicitly mutates the mock session unlock state.
  void setSessionUnlocked(bool unlocked) {
    _isSessionUnlocked = unlocked;
  }

  /// Explicitly mutates the mock master key presence.
  void setHasMasterKey(bool hasKey) {
    _hasMasterKey = hasKey;
  }

  /// Explicitly mutates the mock biometric enrollment state.
  void setBiometricEnrolled(bool enrolled) {
    _isBiometricEnrolled = enrolled;
  }

  @override
  Future<bool> hasMasterKey() async => _hasMasterKey;

  @override
  Future<void> generateMasterKey() async {
    _hasMasterKey = true;
  }

  @override
  Future<Uint8List> encryptPayload(Uint8List plaintext) async {
    if (plaintext.isEmpty) {
      throw const VaultValidationFailure('Plaintext payload must not be empty.');
    }
    if (!_hasMasterKey) {
      throw const VaultCryptoFailure('Master key has not been generated or provisioned.');
    }
    if (!_isSessionUnlocked) {
      throw const VaultCryptoFailure('Vault session is locked. Authenticate first.');
    }

    // Generate 12-byte deterministic IV
    final iv = Uint8List(12);
    for (int i = 0; i < 12; i++) {
      iv[i] = ((_ivCounter + i * 17) & 0xFF);
    }
    _ivCounter++;

    // Reversible byte transformation (simulating AES-GCM encryption)
    final cipherBody = Uint8List(plaintext.length);
    for (int i = 0; i < plaintext.length; i++) {
      cipherBody[i] = plaintext[i] ^ 0xA5;
    }

    // Compute 16-byte authentication tag over IV + cipherBody using SHA-256
    final tagInput = Uint8List(iv.length + cipherBody.length);
    tagInput.setRange(0, iv.length, iv);
    tagInput.setRange(iv.length, tagInput.length, cipherBody);

    final digest = sha256.convert(tagInput);
    final tag = Uint8List.fromList(digest.bytes.sublist(0, 16));

    // Construct envelope: 12-byte IV + cipherBody + 16-byte Tag
    final envelope = Uint8List(12 + cipherBody.length + 16);
    envelope.setRange(0, 12, iv);
    envelope.setRange(12, 12 + cipherBody.length, cipherBody);
    envelope.setRange(12 + cipherBody.length, envelope.length, tag);

    return envelope;
  }

  @override
  Future<Uint8List> decryptPayload(Uint8List ciphertext) async {
    if (ciphertext.length < 28) {
      throw VaultValidationFailure(
        'Ciphertext envelope is shorter than minimum 28 bytes: ${ciphertext.length}',
      );
    }
    if (!_hasMasterKey) {
      throw const VaultCryptoFailure('Master key has not been generated or provisioned.');
    }
    if (!_isSessionUnlocked) {
      throw const VaultCryptoFailure('Vault session is locked. Authenticate first.');
    }

    final iv = ciphertext.sublist(0, 12);
    final tag = ciphertext.sublist(ciphertext.length - 16);
    final cipherBody = ciphertext.sublist(12, ciphertext.length - 16);

    // Verify authentication tag
    final tagInput = Uint8List(iv.length + cipherBody.length);
    tagInput.setRange(0, iv.length, iv);
    tagInput.setRange(iv.length, tagInput.length, cipherBody);

    final digest = sha256.convert(tagInput);
    final expectedTag = digest.bytes.sublist(0, 16);

    for (int i = 0; i < 16; i++) {
      if (tag[i] != expectedTag[i]) {
        throw const VaultCryptoFailure(
          'Cryptographic authentication tag verification failed. Ciphertext has been tampered with or corrupted.',
        );
      }
    }

    // Decrypt payload
    final plaintext = Uint8List(cipherBody.length);
    for (int i = 0; i < cipherBody.length; i++) {
      plaintext[i] = cipherBody[i] ^ 0xA5;
    }

    return plaintext;
  }

  @override
  Future<bool> authenticateBiometrics({
    required String title,
    required String subtitle,
    required String cancelButton,
  }) async {
    if (!_hasMasterKey) {
      throw const VaultCryptoFailure('Master key not provisioned.');
    }
    if (!_isBiometricEnrolled) {
      throw const VaultCryptoFailure('Biometric key invalidated.');
    }
    _isSessionUnlocked = true;
    return true;
  }

  @override
  Future<void> unlockSession() async {
    if (!_hasMasterKey) {
      throw const VaultCryptoFailure('Master key not provisioned.');
    }
    _isSessionUnlocked = true;
  }

  @override
  Future<void> lockSession() async {
    _isSessionUnlocked = false;
  }

  @override
  Future<void> destroyMasterKey() async {
    _hasMasterKey = false;
    _isSessionUnlocked = false;
  }
}
