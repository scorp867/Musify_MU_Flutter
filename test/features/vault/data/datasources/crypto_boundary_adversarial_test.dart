import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/datasources/native_vault_crypto_bridge.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_memory_wiper.dart';
import 'package:musify_mu/features/vault/data/services/vault_auth_service.dart';
import 'package:musify_mu/features/vault/data/services/vault_pbkdf2_derivation.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/biometric_auth_policy.dart';
import 'package:musify_mu/features/vault/domain/states/crypto_engine_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

class AdversarialFakeClock implements IMonotonicClock {
  int timeMs;
  AdversarialFakeClock({this.timeMs = 100000});

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class AdversarialFakeStorageRepository implements IVaultStorageRepository {
  VaultConfig config = VaultConfig();
  int? persistedDeadlineMs;

  @override
  Future<bool> hasEnrolledVault() async => true;

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async => VaultResult.success(config);

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig cfg) async {
    config = cfg;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<GestureTemplate>> loadGestureTemplate() async =>
      const VaultResult.failure(VaultStorageFailure('Not implemented'));

  @override
  Future<VaultResult<void>> saveGestureTemplate(GestureTemplate tmpl) async =>
      const VaultResult.success(null);

  @override
  Future<int?> getPersistedLockoutDeadlineMs() async => persistedDeadlineMs;

  @override
  Future<void> persistLockoutDeadlineMs(int deadlineMonotonicMs) async {
    persistedDeadlineMs = deadlineMonotonicMs;
  }

  @override
  Future<void> clearPersistedLockoutDeadline() async {
    persistedDeadlineMs = null;
  }

  @override
  Future<VaultResult<void>> purgeAllVaultData() async {
    persistedDeadlineMs = null;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<List<PrivatePlaylist>>> getPlaylists() async =>
      const VaultResult.success(<PrivatePlaylist>[]);

  @override
  Future<VaultResult<PrivatePlaylist>> getPlaylistById(String id) async =>
      const VaultResult.failure(VaultStorageFailure('Not found'));

  @override
  Future<VaultResult<PrivatePlaylist>> createPlaylist({
    required String name,
    required String description,
    String? coverUri,
  }) async =>
      const VaultResult.failure(VaultStorageFailure('Not implemented'));

  @override
  Future<VaultResult<void>> updatePlaylist(PrivatePlaylist playlist) async =>
      const VaultResult.success(null);

  @override
  Future<VaultResult<void>> deletePlaylist(String playlistId) async =>
      const VaultResult.success(null);

  @override
  Future<VaultResult<void>> addTrackToPlaylist({
    required String playlistId,
    required PrivateTrackRef trackRef,
  }) async =>
      const VaultResult.success(null);

  @override
  Future<VaultResult<void>> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async =>
      const VaultResult.success(null);

  @override
  Future<VaultResult<void>> reorderTracksInPlaylist({
    required String playlistId,
    required List<String> trackIdsInOrder,
  }) async =>
      const VaultResult.success(null);
}

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

  group('Adversarial Boundary: Truncated & Short Ciphertext Attacks (<28 Bytes)', () {
    final shortByteLengths = [0, 1, 2, 5, 11, 12, 13, 20, 26, 27];

    for (final length in shortByteLengths) {
      test('decryptPayload rejects $length bytes (<28 bytes) with VaultValidationFailure before channel call', () async {
        var channelCalled = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall call) async {
          channelCalled = true;
          return Uint8List(16);
        });

        final truncatedBytes = Uint8List(length);
        expect(
          () => bridge.decryptPayload(truncatedBytes),
          throwsA(
            isA<VaultValidationFailure>().having(
              (e) => e.message,
              'message contains length warning',
              contains('shorter than minimum required'),
            ),
          ),
        );
        expect(channelCalled, isFalse, reason: 'Must fail fast in Dart without IPC invocation');
      });
    }

    test('decryptPayload accepts exactly 28 bytes boundary (12-byte IV + 16-byte GCM Tag)', () async {
      final boundary28Bytes = Uint8List(28);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.method, 'decryptPayload');
        return Uint8List(0); // empty plaintext for 0-byte ciphertext
      });

      final result = await bridge.decryptPayload(boundary28Bytes);
      expect(result, isA<Uint8List>());
      expect(result.isEmpty, isTrue);
    });

    for (final length in shortByteLengths) {
      test('encryptPayload throws VaultCryptoFailure if native returns malformed short envelope ($length bytes)', () async {
        final validPlaintext = Uint8List.fromList([42, 43, 44]);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall call) async {
          return Uint8List(length);
        });

        expect(
          () => bridge.encryptPayload(validPlaintext),
          throwsA(
            isA<VaultCryptoFailure>().having(
              (e) => e.message,
              'message',
              contains('malformed ciphertext envelope'),
            ),
          ),
        );
      });
    }
  });

  group('Adversarial Boundary: Corrupt Native Payloads & Type Confusion', () {
    final corruptPayloads = <String, Object?>{
      'null': null,
      'string': 'corrupted_string_payload',
      'int': 123456789,
      'double': 3.14159,
      'empty map': <String, Object?>{},
      'map with data': <String, Object?>{'key': 'value'},
      'boolean': true,
      'list of strings': <Object?>['a', 'b', 'c'],
    };

    corruptPayloads.forEach((description, payload) {
      test('encryptPayload throws VaultCryptoFailure when native returns $description', () async {
        final plaintext = Uint8List.fromList([1, 2, 3, 4]);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall call) async {
          return payload;
        });

        expect(
          () => bridge.encryptPayload(plaintext),
          throwsA(isA<VaultCryptoFailure>()),
        );
      });

      test('decryptPayload throws VaultCryptoFailure when native returns $description', () async {
        final ciphertext = Uint8List(32);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall call) async {
          return payload;
        });

        expect(
          () => bridge.decryptPayload(ciphertext),
          throwsA(isA<VaultCryptoFailure>()),
        );
      });
    });

    test('encryptPayload throws VaultCryptoFailure when generic List<Object?> is returned instead of Uint8List', () async {
      final plaintext = Uint8List.fromList([10, 20]);
      final validListInt = List<int>.generate(32, (i) => i % 256);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        return validListInt;
      });

      expect(
        () => bridge.encryptPayload(plaintext),
        throwsA(isA<VaultCryptoFailure>()),
      );
    });

    test('decryptPayload throws VaultCryptoFailure when generic List<Object?> is returned instead of Uint8List', () async {
      final ciphertext = Uint8List(32);
      final validListInt = List<int>.generate(8, (i) => i * 10);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        return validListInt;
      });

      expect(
        () => bridge.decryptPayload(ciphertext),
        throwsA(isA<VaultCryptoFailure>()),
      );
    });

    test('encryptPayload succeeds when native byte array (Uint8List) is returned', () async {
      final plaintext = Uint8List.fromList([10, 20]);
      final validBytes = Uint8List.fromList(List<int>.generate(32, (i) => i % 256));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        return validBytes;
      });

      final result = await bridge.encryptPayload(plaintext);
      expect(result, isA<Uint8List>());
      expect(result.length, 32);
    });

    test('decryptPayload succeeds when native byte array (Uint8List) is returned', () async {
      final ciphertext = Uint8List(32);
      final validBytes = Uint8List.fromList(List<int>.generate(8, (i) => i * 10));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        return validBytes;
      });

      final result = await bridge.decryptPayload(ciphertext);
      expect(result, isA<Uint8List>());
      expect(result.length, 8);
    });

    test('hasMasterKey throws VaultCryptoFailure on non-boolean return value', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        return 'yes';
      });

      expect(() => bridge.hasMasterKey(), throwsA(isA<VaultCryptoFailure>()));
    });

    test('generateMasterKey throws VaultCryptoFailure on unexpected return value', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        return 'error_status';
      });

      expect(() => bridge.generateMasterKey(), throwsA(isA<VaultCryptoFailure>()));
    });

    test('unlockSession throws VaultCryptoFailure on unexpected return value', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        return 999;
      });

      expect(() => bridge.unlockSession(), throwsA(isA<VaultCryptoFailure>()));
    });

    test('lockSession throws VaultCryptoFailure on unexpected return value', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        return <String, Object>{'locked': false};
      });

      expect(() => bridge.lockSession(), throwsA(isA<VaultCryptoFailure>()));
    });

    test('destroyMasterKey throws VaultCryptoFailure on unexpected return value', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        return -1;
      });

      expect(() => bridge.destroyMasterKey(), throwsA(isA<VaultCryptoFailure>()));
    });
  });

  group('Adversarial Boundary: Biometric Prompt Input Validation & Error Mapping', () {
    test('authenticateBiometrics rejects empty title with VaultValidationFailure', () async {
      expect(
        () => bridge.authenticateBiometrics(
          title: '',
          subtitle: 'Valid Subtitle',
          cancelButton: 'Cancel',
        ),
        throwsA(isA<VaultValidationFailure>()),
      );
    });

    test('authenticateBiometrics rejects whitespace-only title with VaultValidationFailure', () async {
      expect(
        () => bridge.authenticateBiometrics(
          title: '   \t\n  ',
          subtitle: 'Valid Subtitle',
          cancelButton: 'Cancel',
        ),
        throwsA(isA<VaultValidationFailure>()),
      );
    });

    test('authenticateBiometrics rejects empty cancelButton with VaultValidationFailure', () async {
      expect(
        () => bridge.authenticateBiometrics(
          title: 'Valid Title',
          subtitle: 'Valid Subtitle',
          cancelButton: '',
        ),
        throwsA(isA<VaultValidationFailure>()),
      );
    });

    test('authenticateBiometrics rejects whitespace-only cancelButton with VaultValidationFailure', () async {
      expect(
        () => bridge.authenticateBiometrics(
          title: 'Valid Title',
          subtitle: 'Valid Subtitle',
          cancelButton: '   ',
        ),
        throwsA(isA<VaultValidationFailure>()),
      );
    });

    test('authenticateBiometrics returns false on BIOMETRIC_CANCELLED PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(code: 'BIOMETRIC_CANCELLED', message: 'User dismissed');
      });

      final result = await bridge.authenticateBiometrics(
        title: 'Unlock',
        subtitle: 'Sub',
        cancelButton: 'Cancel',
      );
      expect(result, isFalse);
    });

    final platformErrorCases = <String, Type>{
      'CRYPTO_FAULT_KEY_INVALIDATED': VaultCryptoFailure,
      'CRYPTO_FAULT_SESSION_LOCKED': VaultCryptoFailure,
      'CRYPTO_FAULT_KEY_NOT_FOUND': VaultCryptoFailure,
      'KEY_NOT_FOUND': VaultCryptoFailure,
      'CRYPTO_FAULT_DECRYPTION_CORRUPTED': VaultCryptoFailure,
      'CRYPTO_FAULT_HARDWARE_UNAVAILABLE': VaultCryptoFailure,
      'BIOMETRIC_NOT_ENROLLED': VaultAuthFailure,
      'BIOMETRIC_UNAVAILABLE': VaultAuthFailure,
      'BIOMETRIC_LOCKED_OUT': VaultAuthFailure,
      'BIOMETRIC_ERROR': VaultAuthFailure,
      'BIOMETRIC_FAILED': VaultAuthFailure,
      'INVALID_ARGUMENT': VaultValidationFailure,
      'KEYSTORE_ERROR': VaultStorageFailure,
      'UNKNOWN_RANDOM_CODE': VaultCryptoFailure,
    };

    platformErrorCases.forEach((code, expectedType) {
      test('PlatformException($code) maps exhaustively to $expectedType without crashing', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall call) async {
          throw PlatformException(code: code, message: 'Simulated fault for $code');
        });

        expect(
          () => bridge.hasMasterKey(),
          throwsA(isA<VaultFailure>().having((e) => e.runtimeType, 'type', expectedType)),
        );
      });
    });

    test('PlatformException with null message and details handled safely', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(code: 'CRYPTO_FAULT_INTERNAL', message: null, details: null);
      });

      expect(
        () => bridge.hasMasterKey(),
        throwsA(
          isA<VaultCryptoFailure>().having(
            (e) => e.message,
            'fallback message',
            contains('Native cryptographic platform exception occurred'),
          ),
        ),
      );
    });
  });

  group('Adversarial Stress Suite: Memory Wiper Security Invariants', () {
    test('zeroBuffer on empty buffer is safe no-op', () {
      final empty = Uint8List(0);
      expect(() => VaultMemoryWiper.zeroBuffer(empty), returnsNormally);
    });

    test('zeroBuffer actively overwrites multi-megabyte buffer completely with 0x00', () {
      const bufferSize = 1024 * 1024 * 2; // 2 MB
      final largeBuffer = Uint8List(bufferSize);
      for (var i = 0; i < bufferSize; i += 4096) {
        largeBuffer[i] = 0xAA;
      }

      VaultMemoryWiper.zeroBuffer(largeBuffer);

      for (var i = 0; i < bufferSize; i += 4096) {
        expect(largeBuffer[i], 0);
      }
    });

    test('zeroBuffer on unmodifiable view throws VaultCryptoFailure (surfaces security violation)', () {
      final modifiable = Uint8List.fromList([1, 2, 3, 4]);
      final unmodifiable = modifiable.asUnmodifiableView();

      expect(
        () => VaultMemoryWiper.zeroBuffer(unmodifiable),
        throwsA(
          isA<VaultCryptoFailure>().having(
            (e) => e.message,
            'message',
            contains('Critical Memory Security Violation'),
          ),
        ),
      );
    });

    test('allocateMutable rejects negative lengths with VaultValidationFailure', () {
      expect(
        () => VaultMemoryWiper.allocateMutable(-1),
        throwsA(isA<VaultValidationFailure>()),
      );
      expect(
        () => VaultMemoryWiper.allocateMutable(-1000),
        throwsA(isA<VaultValidationFailure>()),
      );
    });

    test('VaultPlaintextBuffer RAII semantics: prevents access after zeroize', () {
      final buffer = VaultPlaintextBuffer([0xFF, 0xEE, 0xDD]);
      expect(buffer.isZeroed, isFalse);
      expect(buffer.length, 3);
      expect(buffer.bytes[0], 0xFF);

      buffer.zeroize();
      expect(buffer.isZeroed, isTrue);
      expect(() => buffer.bytes, throwsA(isA<VaultCryptoFailure>()));

      // Idempotent: second zeroize does not throw
      expect(() => buffer.zeroize(), returnsNormally);
    });

    test('withPlaintextScope wipes mutable buffer even when action throws', () async {
      late Uint8List capturedBuffer;
      final original = Uint8List.fromList([1, 2, 3, 4, 5]);

      try {
        await VaultMemoryWiper.withPlaintextScope<void>(
          plaintext: original,
          action: (mutable) async {
            capturedBuffer = mutable;
            expect(mutable, [1, 2, 3, 4, 5]);
            throw StateError('Simulated unexpected worker failure');
          },
        );
      } catch (e) {
        expect(e, isA<StateError>());
      }

      expect(capturedBuffer, [0, 0, 0, 0, 0]);
    });

    test('withPlaintextScopeSync wipes mutable buffer even when action throws', () {
      late Uint8List capturedBuffer;
      final original = Uint8List.fromList([9, 8, 7]);

      try {
        VaultMemoryWiper.withPlaintextScopeSync<void>(
          plaintext: original,
          action: (mutable) {
            capturedBuffer = mutable;
            expect(mutable, [9, 8, 7]);
            throw StateError('Simulated sync error');
          },
        );
      } catch (e) {
        expect(e, isA<StateError>());
      }

      expect(capturedBuffer, [0, 0, 0]);
    });
  });

  group('Adversarial Stress Suite: PBKDF2 Background Derivation Contract', () {
    const derivation = VaultPbkdf2Derivation();
    final validSalt = Uint8List.fromList(List<int>.generate(16, (i) => i));

    test('rejects non-numeric PIN with FormatException', () async {
      expect(
        () => derivation.derive(pin: 'abcdef', salt: validSalt),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects PIN with incorrect length with FormatException', () async {
      expect(
        () => derivation.derive(pin: '12345', salt: validSalt),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => derivation.derive(pin: '1234567', salt: validSalt),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => derivation.derive(pin: '', salt: validSalt),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects empty salt with FormatException', () async {
      final emptySalt = Uint8List(0);
      expect(
        () => derivation.derive(pin: '123456', salt: emptySalt),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects iterations <= 0 with FormatException', () async {
      expect(
        () => derivation.derive(pin: '123456', salt: validSalt, iterations: 0),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => derivation.derive(pin: '123456', salt: validSalt, iterations: -5),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects keyLength <= 0 with FormatException', () async {
      expect(
        () => derivation.derive(pin: '123456', salt: validSalt, keyLength: 0),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => derivation.derive(pin: '123456', salt: validSalt, keyLength: -1),
        throwsA(isA<FormatException>()),
      );
    });

    test('constantTimeEquals rejects length mismatch safely without RangeError', () {
      final a = Uint8List.fromList([1, 2, 3]);
      final b = Uint8List.fromList([1, 2, 3, 4]);

      expect(VaultPbkdf2Derivation.constantTimeEquals(a, b), isFalse);
    });

    test('constantTimeEquals detects single-bit divergence', () {
      final a = Uint8List.fromList([0xAA, 0xBB, 0xCC, 0xDD]);
      final b = Uint8List.fromList([0xAA, 0xBB, 0xCD, 0xDD]); // 1 bit flip

      expect(VaultPbkdf2Derivation.constantTimeEquals(a, b), isFalse);
      expect(VaultPbkdf2Derivation.constantTimeEquals(a, a), isTrue);
    });
  });

  group('Adversarial Integration: KeyPermanentlyInvalidated -> CryptoEngineFault -> Slot 1 Recovery', () {
    test('Simulated OS biometric enrollment invalidation triggers fault and Slot 1 recovery', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'musify_vault_is_enrolled': 'true',
        'musify_vault_pin_salt': base64Encode(List<int>.generate(16, (i) => i + 1)),
      });

      final secureStorage = const FlutterSecureStorage();
      final clock = AdversarialFakeClock();
      final storageRepo = AdversarialFakeStorageRepository();
      storageRepo.config = storageRepo.config.copyWith(
        biometricAuth: BiometricAuthPolicyEnum.pinAndBiometricStrong,
      );

      final saltBytes = base64Decode((await secureStorage.read(key: 'musify_vault_pin_salt'))!);
      const pbkdf2 = VaultPbkdf2Derivation();
      final derivedToken = await pbkdf2.derive(pin: '654321', salt: Uint8List.fromList(saltBytes));
      final verifierBytes = sha256.convert(derivedToken).bytes;
      await secureStorage.write(
        key: 'musify_vault_pin_verifier',
        value: base64Encode(verifierBytes),
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'hasMasterKey':
            return true;
          case 'authenticateBiometrics':
            // Simulate KeyPermanentlyInvalidatedException from Android KeyStore
            throw PlatformException(
              code: 'CRYPTO_FAULT_KEY_INVALIDATED',
              message: 'Biometric key permanently invalidated by new OS biometric enrollment.',
            );
          case 'unlockSession':
            return true;
          case 'lockSession':
            return true;
          default:
            return true;
        }
      });

      final authService = VaultAuthService(
        cryptoBridge: bridge,
        storageRepository: storageRepo,
        monotonicClock: clock,
        secureStorage: secureStorage,
        pbkdf2Derivation: pbkdf2,
      );

      final cryptoStates = <CryptoEngineState>[];
      final sessionStates = <VaultSessionState>[];
      final cryptoSub = authService.cryptoEngineStateStream.listen(cryptoStates.add);
      final sessionSub = authService.sessionStateStream.listen(sessionStates.add);

      // Attempt biometric auth -> triggers KeyPermanentlyInvalidated
      final bioResult = await authService.authenticateWithBiometrics();
      switch (bioResult) {
        case VaultFailureResult(failure: final f):
          expect(f, isA<VaultCryptoFailure>());
          expect(f.message, contains('Slot 1 PIN recovery'));
        case VaultSuccess():
          fail('Expected biometric authentication to fail due to KeyPermanentlyInvalidated');
      }

      // Check emitted state
      expect(
        authService.currentCryptoState,
        isA<CryptoEngineCryptoFaultState>().having(
          (s) => s.faultReason,
          'faultReason',
          CryptoFaultReasonEnum.keyStoreInvalidated,
        ),
      );

      expect(
        authService.currentSessionState,
        isA<VaultAuthenticatingState>().having(
          (s) => s.authSessionId,
          'authSessionId',
          'slot1-fallback-recovery',
        ),
      );

      // Verify Slot 1 PIN recovery can now unlock successfully!
      final pinResult = await authService.authenticateWithPin(pin: '654321');
      switch (pinResult) {
        case VaultSuccess(data: final session):
          expect(session, isA<AuthSession>());
          expect(authService.currentSessionState, isA<VaultUnlockedState>());
          expect(authService.currentCryptoState, isA<CryptoEngineMasterKeyUnwrappedInRamState>());
        case VaultFailureResult(failure: final f):
          fail('Expected PIN recovery to succeed, but failed with: $f');
      }

      await cryptoSub.cancel();
      await sessionSub.cancel();
    });
  });
}
