import 'package:flutter/services.dart';
import 'package:musify_mu/features/vault/data/datasources/i_native_vault_crypto_bridge.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';

/// Production implementation of [INativeVaultCryptoBridge] communicating with native Kotlin
/// hardware security via Flutter MethodChannel.
///
/// Strictly enforces:
/// - Zero raw cryptographic keys in Dart memory.
/// - Zero untyped dynamic mappings.
/// - Zero `!` non-null assertions and zero fallback operators masking errors.
/// - Exhaustive error translation from native platform exceptions to typed [VaultFailure] classes.
final class NativeVaultCryptoBridge implements INativeVaultCryptoBridge {
  /// Canonical platform channel name matching Android native registration.
  static const String channelName = 'com.musify.mu/vault_hardware_keystore';

  /// Minimum byte length of an AES-GCM envelope: 12-byte IV + 16-byte GCM tag = 28 bytes.
  static const int minCiphertextEnvelopeBytes = 28;

  final MethodChannel _channel;

  /// Creates a [NativeVaultCryptoBridge] with optional injected [MethodChannel] for testing.
  const NativeVaultCryptoBridge({
    MethodChannel channel = const MethodChannel(channelName),
  }) : _channel = channel;

  @override
  Future<bool> hasMasterKey() async {
    try {
      final Object? result = await _channel.invokeMethod<Object?>('hasMasterKey');
      if (result is bool) {
        return result;
      }
      throw VaultCryptoFailure(
        'Native bridge hasMasterKey returned unexpected payload: ${result.runtimeType}',
      );
    } on PlatformException catch (e) {
      _handlePlatformException(e);
    }
  }

  @override
  Future<void> generateMasterKey() async {
    try {
      final Object? result = await _channel.invokeMethod<Object?>('generateMasterKey');
      if (result is bool && result) {
        return;
      }
      if (result == null) {
        return;
      }
      throw VaultCryptoFailure(
        'Native bridge generateMasterKey returned unexpected payload: ${result.runtimeType}',
      );
    } on PlatformException catch (e) {
      _handlePlatformException(e);
    }
  }

  @override
  Future<Uint8List> encryptPayload(Uint8List plaintext) async {
    if (plaintext.isEmpty) {
      throw const VaultValidationFailure(
        'Cannot encrypt an empty plaintext payload.',
      );
    }

    try {
      final Object? result = await _channel.invokeMethod<Object?>(
        'encryptPayload',
        <String, Object>{
          'payload': plaintext,
        },
      );

      if (result is Uint8List) {
        if (result.length < minCiphertextEnvelopeBytes) {
          throw VaultCryptoFailure(
            'Native bridge returned malformed ciphertext envelope (< $minCiphertextEnvelopeBytes bytes): ${result.length}',
          );
        }
        return Uint8List.fromList(result);
      } else if (result is List<int>) {
        if (result.length < minCiphertextEnvelopeBytes) {
          throw VaultCryptoFailure(
            'Native bridge returned malformed ciphertext envelope (< $minCiphertextEnvelopeBytes bytes): ${result.length}',
          );
        }
        return Uint8List.fromList(result);
      }

      throw VaultCryptoFailure(
        'Native bridge encryptPayload returned invalid type: ${result.runtimeType}',
      );
    } on PlatformException catch (e) {
      _handlePlatformException(e);
    }
  }

  @override
  Future<Uint8List> decryptPayload(Uint8List ciphertext) async {
    if (ciphertext.length < minCiphertextEnvelopeBytes) {
      throw VaultValidationFailure(
        'Ciphertext payload length (${ciphertext.length} bytes) is shorter than minimum required '
        '($minCiphertextEnvelopeBytes bytes: 12-byte IV + 16-byte tag).',
      );
    }

    try {
      final Object? result = await _channel.invokeMethod<Object?>(
        'decryptPayload',
        <String, Object>{
          'payload': ciphertext,
        },
      );

      if (result is Uint8List) {
        return Uint8List.fromList(result);
      } else if (result is List<int>) {
        return Uint8List.fromList(result);
      }

      throw VaultCryptoFailure(
        'Native bridge decryptPayload returned invalid type: ${result.runtimeType}',
      );
    } on PlatformException catch (e) {
      _handlePlatformException(e);
    }
  }

  @override
  Future<Uint8List> encryptConfigPayload(Uint8List plaintext) async {
    if (plaintext.isEmpty) {
      throw const VaultValidationFailure(
        'Cannot encrypt an empty plaintext payload.',
      );
    }

    try {
      final Object? result = await _channel.invokeMethod<Object?>(
        'encryptConfigPayload',
        <String, Object>{
          'payload': plaintext,
        },
      );

      if (result is Uint8List) {
        if (result.length < minCiphertextEnvelopeBytes) {
          throw VaultCryptoFailure(
            'Native bridge returned malformed ciphertext envelope (< $minCiphertextEnvelopeBytes bytes): ${result.length}',
          );
        }
        return Uint8List.fromList(result);
      } else if (result is List<int>) {
        if (result.length < minCiphertextEnvelopeBytes) {
          throw VaultCryptoFailure(
            'Native bridge returned malformed ciphertext envelope (< $minCiphertextEnvelopeBytes bytes): ${result.length}',
          );
        }
        return Uint8List.fromList(result);
      }

      throw VaultCryptoFailure(
        'Native bridge encryptConfigPayload returned invalid type: ${result.runtimeType}',
      );
    } on PlatformException catch (e) {
      _handlePlatformException(e);
    }
  }

  @override
  Future<Uint8List> decryptConfigPayload(Uint8List ciphertext) async {
    if (ciphertext.length < minCiphertextEnvelopeBytes) {
      throw VaultValidationFailure(
        'Ciphertext payload length (${ciphertext.length} bytes) is shorter than minimum required '
        '($minCiphertextEnvelopeBytes bytes: 12-byte IV + 16-byte tag).',
      );
    }

    try {
      final Object? result = await _channel.invokeMethod<Object?>(
        'decryptConfigPayload',
        <String, Object>{
          'payload': ciphertext,
        },
      );

      if (result is Uint8List) {
        return Uint8List.fromList(result);
      } else if (result is List<int>) {
        return Uint8List.fromList(result);
      }

      throw VaultCryptoFailure(
        'Native bridge decryptConfigPayload returned invalid type: ${result.runtimeType}',
      );
    } on PlatformException catch (e) {
      _handlePlatformException(e);
    }
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

    try {
      final Object? result = await _channel.invokeMethod<Object?>(
        'authenticateBiometrics',
        <String, Object>{
          'title': title,
          'subtitle': subtitle,
          'cancelButton': cancelButton,
        },
      );

      if (result is bool) {
        return result;
      }

      throw VaultCryptoFailure(
        'Native bridge authenticateBiometrics returned invalid type: ${result.runtimeType}',
      );
    } on PlatformException catch (e) {
      if (e.code == 'BIOMETRIC_CANCELLED') {
        return false;
      }
      _handlePlatformException(e);
    }
  }

  @override
  Future<void> unlockSession() async {
    try {
      final Object? result = await _channel.invokeMethod<Object?>('unlockSession');
      if (result is bool && result) {
        return;
      }
      if (result == null) {
        return;
      }
      throw VaultCryptoFailure(
        'Native bridge unlockSession returned unexpected payload: ${result.runtimeType}',
      );
    } on PlatformException catch (e) {
      _handlePlatformException(e);
    }
  }

  @override
  Future<void> lockSession() async {
    try {
      final Object? result = await _channel.invokeMethod<Object?>('lockSession');
      if (result is bool && result) {
        return;
      }
      if (result == null) {
        return;
      }
      throw VaultCryptoFailure(
        'Native bridge lockSession returned unexpected payload: ${result.runtimeType}',
      );
    } on PlatformException catch (e) {
      _handlePlatformException(e);
    }
  }

  @override
  Future<void> destroyMasterKey() async {
    try {
      final Object? result = await _channel.invokeMethod<Object?>('destroyMasterKey');
      if (result is bool && result) {
        return;
      }
      if (result == null) {
        return;
      }
      throw VaultCryptoFailure(
        'Native bridge destroyMasterKey returned unexpected payload: ${result.runtimeType}',
      );
    } on PlatformException catch (e) {
      _handlePlatformException(e);
    }
  }

  /// Maps native Android KeyStore platform exceptions to typed [VaultFailure] domain exceptions.
  Never _handlePlatformException(PlatformException exception) {
    final rawMessage = exception.message;
    final message = (rawMessage != null && rawMessage.trim().isNotEmpty)
        ? rawMessage
        : 'Native cryptographic platform exception occurred';

    switch (exception.code) {
      case 'CRYPTO_FAULT_KEY_INVALIDATED':
        throw VaultCryptoFailure(
          'Android KeyStore key permanently invalidated by new OS biometric enrollment.',
          cause: exception,
        );

      case 'CRYPTO_FAULT_SESSION_LOCKED':
        throw VaultCryptoFailure(
          'Vault session is locked. Complete PIN or biometric authentication first.',
          cause: exception,
        );

      case 'CRYPTO_FAULT_KEY_NOT_FOUND':
      case 'KEY_NOT_FOUND':
        throw VaultCryptoFailure(
          'Master key is not provisioned in Android KeyStore.',
          cause: exception,
        );

      case 'CRYPTO_FAULT_DECRYPTION_CORRUPTED':
        throw VaultCryptoFailure(
          'Decryption authentication failed: corrupted ciphertext or tampered authentication tag.',
          cause: exception,
        );

      case 'CRYPTO_FAULT_HARDWARE_UNAVAILABLE':
        throw VaultCryptoFailure(
          'Hardware KeyStore security validation failed or StrongBox is unavailable.',
          cause: exception,
        );

      case 'BIOMETRIC_NOT_ENROLLED':
        throw VaultAuthFailure(
          'No biometric credentials are enrolled in Android OS.',
          cause: exception,
        );

      case 'BIOMETRIC_UNAVAILABLE':
        throw VaultAuthFailure(
          'Biometric hardware is unavailable on this device.',
          cause: exception,
        );

      case 'BIOMETRIC_LOCKED_OUT':
        throw VaultAuthFailure(
          'Biometric sensor temporarily locked due to consecutive failed attempts.',
          cause: exception,
        );

      case 'BIOMETRIC_ERROR':
      case 'BIOMETRIC_FAILED':
        throw VaultAuthFailure(
          message,
          cause: exception,
        );

      case 'INVALID_ARGUMENT':
        throw VaultValidationFailure(
          message,
          cause: exception,
        );

      case 'KEYSTORE_ERROR':
        throw VaultStorageFailure(
          message,
          cause: exception,
        );

      default:
        throw VaultCryptoFailure(
          'Native crypto bridge error [${exception.code}]: $message',
          cause: exception,
        );
    }
  }
}
