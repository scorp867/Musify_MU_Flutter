import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/datasources/native_vault_crypto_bridge.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(NativeVaultCryptoBridge.channelName);
  late NativeVaultCryptoBridge bridge;

  setUp(() {
    bridge = const NativeVaultCryptoBridge(channel: channel);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('NativeVaultCryptoBridge: hasMasterKey', () {
    test('returns true when native KeyStore has key', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.method, 'hasMasterKey');
        return true;
      });

      final result = await bridge.hasMasterKey();
      expect(result, isTrue);
    });

    test('returns false when native KeyStore lacks key', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        return false;
      });

      final result = await bridge.hasMasterKey();
      expect(result, isFalse);
    });

    test('throws VaultCryptoFailure on unexpected return type', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        return 'invalid_type';
      });

      expect(
        () => bridge.hasMasterKey(),
        throwsA(isA<VaultCryptoFailure>()),
      );
    });

    test('throws VaultStorageFailure on KEYSTORE_ERROR PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(
          code: 'KEYSTORE_ERROR',
          message: 'KeyStore provider damaged',
        );
      });

      expect(
        () => bridge.hasMasterKey(),
        throwsA(isA<VaultStorageFailure>()),
      );
    });
  });

  group('NativeVaultCryptoBridge: generateMasterKey', () {
    test('calls native generateMasterKey and completes successfully', () async {
      var invoked = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.method, 'generateMasterKey');
        invoked = true;
        return true;
      });

      await bridge.generateMasterKey();
      expect(invoked, isTrue);
    });

    test('throws VaultCryptoFailure on PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(
          code: 'CRYPTO_FAULT_HARDWARE_UNAVAILABLE',
          message: 'Hardware enclave rejected key generation',
        );
      });

      expect(
        () => bridge.generateMasterKey(),
        throwsA(isA<VaultCryptoFailure>()),
      );
    });
  });

  group('NativeVaultCryptoBridge: encryptPayload', () {
    test('passes payload and returns valid ciphertext envelope', () async {
      final plaintext = Uint8List.fromList(utf8.encode('Top Secret Metadata'));
      final mockCiphertext = Uint8List.fromList(List<int>.generate(40, (i) => i));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.method, 'encryptPayload');
        final args = call.arguments as Map<Object?, Object?>;
        expect(args['payload'], plaintext);
        return mockCiphertext;
      });

      final result = await bridge.encryptPayload(plaintext);
      expect(result, mockCiphertext);
      expect(result.length, 40);
    });

    test('rejects empty plaintext with VaultValidationFailure before calling channel', () async {
      final empty = Uint8List(0);
      expect(
        () => bridge.encryptPayload(empty),
        throwsA(isA<VaultValidationFailure>()),
      );
    });

    test('throws VaultCryptoFailure if native returns ciphertext shorter than 28 bytes', () async {
      final plaintext = Uint8List.fromList([1, 2, 3]);
      final shortCiphertext = Uint8List.fromList(List<int>.generate(20, (i) => i));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        return shortCiphertext;
      });

      expect(
        () => bridge.encryptPayload(plaintext),
        throwsA(isA<VaultCryptoFailure>()),
      );
    });

    test('translates CRYPTO_FAULT_SESSION_LOCKED to VaultCryptoFailure', () async {
      final plaintext = Uint8List.fromList([1, 2, 3]);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(
          code: 'CRYPTO_FAULT_SESSION_LOCKED',
          message: 'Session is locked',
        );
      });

      expect(
        () => bridge.encryptPayload(plaintext),
        throwsA(isA<VaultCryptoFailure>()),
      );
    });
  });

  group('NativeVaultCryptoBridge: decryptPayload', () {
    test('passes ciphertext and returns decrypted plaintext', () async {
      final ciphertext = Uint8List.fromList(List<int>.generate(40, (i) => i));
      final mockPlaintext = Uint8List.fromList(utf8.encode('Decrypted Plaintext'));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.method, 'decryptPayload');
        final args = call.arguments as Map<Object?, Object?>;
        expect(args['payload'], ciphertext);
        return mockPlaintext;
      });

      final result = await bridge.decryptPayload(ciphertext);
      expect(result, mockPlaintext);
    });

    test('rejects ciphertext shorter than 28 bytes with VaultValidationFailure', () async {
      final short = Uint8List(27);
      expect(
        () => bridge.decryptPayload(short),
        throwsA(isA<VaultValidationFailure>()),
      );
    });

    test('translates CRYPTO_FAULT_DECRYPTION_CORRUPTED to VaultCryptoFailure', () async {
      final ciphertext = Uint8List(30);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(
          code: 'CRYPTO_FAULT_DECRYPTION_CORRUPTED',
          message: 'GCM tag mismatch',
        );
      });

      expect(
        () => bridge.decryptPayload(ciphertext),
        throwsA(isA<VaultCryptoFailure>()),
      );
    });
  });

  group('NativeVaultCryptoBridge: authenticateBiometrics', () {
    test('passes prompt metadata and returns true on authentication success', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.method, 'authenticateBiometrics');
        final args = call.arguments as Map<Object?, Object?>;
        expect(args['title'], 'Unlock Vault');
        expect(args['subtitle'], 'Touch sensor');
        expect(args['cancelButton'], 'Cancel');
        return true;
      });

      final result = await bridge.authenticateBiometrics(
        title: 'Unlock Vault',
        subtitle: 'Touch sensor',
        cancelButton: 'Cancel',
      );
      expect(result, isTrue);
    });

    test('returns false when user cancels prompt (BIOMETRIC_CANCELLED)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(
          code: 'BIOMETRIC_CANCELLED',
          message: 'User pressed cancel',
        );
      });

      final result = await bridge.authenticateBiometrics(
        title: 'Unlock Vault',
        subtitle: 'Touch sensor',
        cancelButton: 'Cancel',
      );
      expect(result, isFalse);
    });

    test('throws VaultCryptoFailure on CRYPTO_FAULT_KEY_INVALIDATED', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(
          code: 'CRYPTO_FAULT_KEY_INVALIDATED',
          message: 'New biometric enrolled in OS',
        );
      });

      expect(
        () => bridge.authenticateBiometrics(
          title: 'Unlock Vault',
          subtitle: 'Touch sensor',
          cancelButton: 'Cancel',
        ),
        throwsA(isA<VaultCryptoFailure>()),
      );
    });

    test('throws VaultAuthFailure on BIOMETRIC_LOCKED_OUT', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(
          code: 'BIOMETRIC_LOCKED_OUT',
          message: 'Too many attempts',
        );
      });

      expect(
        () => bridge.authenticateBiometrics(
          title: 'Unlock Vault',
          subtitle: 'Touch sensor',
          cancelButton: 'Cancel',
        ),
        throwsA(isA<VaultAuthFailure>()),
      );
    });

    test('validates non-empty prompt strings', () async {
      expect(
        () => bridge.authenticateBiometrics(
          title: '',
          subtitle: 'Touch',
          cancelButton: 'Cancel',
        ),
        throwsA(isA<VaultValidationFailure>()),
      );
    });
  });

  group('NativeVaultCryptoBridge: Session Control', () {
    test('unlockSession calls channel unlockSession', () async {
      var invoked = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.method, 'unlockSession');
        invoked = true;
        return true;
      });

      await bridge.unlockSession();
      expect(invoked, isTrue);
    });

    test('lockSession calls channel lockSession', () async {
      var invoked = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.method, 'lockSession');
        invoked = true;
        return true;
      });

      await bridge.lockSession();
      expect(invoked, isTrue);
    });

    test('destroyMasterKey calls channel destroyMasterKey', () async {
      var invoked = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.method, 'destroyMasterKey');
        invoked = true;
        return true;
      });

      await bridge.destroyMasterKey();
      expect(invoked, isTrue);
    });
  });
}
