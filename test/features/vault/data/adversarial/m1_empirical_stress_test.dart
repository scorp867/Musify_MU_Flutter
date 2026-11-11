import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_memory_wiper.dart';
import 'package:musify_mu/features/vault/data/services/vault_auth_service.dart';
import 'package:musify_mu/features/vault/data/services/vault_pbkdf2_derivation.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

import '../datasources/fake_native_vault_crypto_bridge.dart';

class EmpiricalFakeStorageRepository implements IVaultStorageRepository {
  VaultConfig config = VaultConfig();
  GestureTemplate? template;
  int? persistedDeadlineMs;

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async => VaultResult.success(config);

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig cfg) async {
    config = cfg;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<GestureTemplate>> loadGestureTemplate() async {
    if (template case final t?) {
      return VaultResult.success(t);
    }
    return const VaultResult.failure(VaultStorageFailure('No template.'));
  }

  @override
  Future<VaultResult<void>> saveGestureTemplate(GestureTemplate tmpl) async {
    template = tmpl;
    return const VaultResult.success(null);
  }

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
    template = null;
    persistedDeadlineMs = null;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<List<PrivatePlaylist>>> getPlaylists() async =>
      const VaultResult.success(<PrivatePlaylist>[]);

  @override
  Future<VaultResult<PrivatePlaylist>> getPlaylistById(String id) async =>
      const VaultResult.failure(VaultStorageFailure('Not found.'));

  @override
  Future<VaultResult<PrivatePlaylist>> createPlaylist({
    required String name,
    required String description,
    String? coverUri,
  }) async =>
      const VaultResult.failure(VaultStorageFailure('Not implemented.'));

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

class EmpiricalFakeMonotonicClock implements IMonotonicClock {
  int timeMs = 10000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class EmpiricalFakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> storage = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      storage[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      storage[key] = value;
    } else {
      storage.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    storage.remove(key);
  }
}

void main() {
  group('Empirical Challenge 1: PBKDF2 Isolate Derivation Stress & Side Channels', () {
    const derivation = VaultPbkdf2Derivation();

    test('Concurrent isolate stress: 20 simultaneous derivations without race conditions', () async {
      final salts = List.generate(20, (i) => VaultPbkdf2Derivation.generateSalt());
      final pins = List.generate(20, (i) => '${(100000 + i)}');

      // Launch 20 concurrent derivations across isolates with lower iterations (1000) for harness speed
      final futures = List.generate(
        20,
        (i) => derivation.derive(
          pin: pins[i],
          salt: salts[i],
          iterations: 1000,
        ),
      );

      final results = await Future.wait(futures);

      expect(results.length, equals(20));
      for (final result in results) {
        expect(result.length, equals(32));
        expect(result.any((byte) => byte != 0), isTrue);
      }

      // Verify pairwise uniqueness across different PINs/salts
      final distinctKeys = results.map((r) => base64Encode(r)).toSet();
      expect(distinctKeys.length, equals(20));
    });

    test('Parallel deterministic output: 10 identical inputs yield identical keys', () async {
      final salt = VaultPbkdf2Derivation.generateSalt();
      const pin = '654321';

      final futures = List.generate(
        10,
        (_) => derivation.derive(
          pin: pin,
          salt: salt,
          iterations: 1000,
        ),
      );

      final results = await Future.wait(futures);
      final reference = results.first;

      for (var i = 1; i < results.length; i++) {
        expect(
          VaultPbkdf2Derivation.constantTimeEquals(reference, results[i]),
          isTrue,
        );
      }
    });

    test('Multi-block key derivation: keyLength > 32 bytes (64 bytes)', () async {
      final salt = VaultPbkdf2Derivation.generateSalt();
      final key = await derivation.derive(
        pin: '123456',
        salt: salt,
        iterations: 100,
        keyLength: 64,
      );

      expect(key.length, equals(64));
      // First 32 bytes and second 32 bytes should both be non-trivial
      final block1 = key.sublist(0, 32);
      final block2 = key.sublist(32, 64);
      expect(VaultPbkdf2Derivation.constantTimeEquals(block1, block2), isFalse);
    });

    test('Input validation boundary fuzzing on PIN, salt, iterations, keyLength', () async {
      final validSalt = VaultPbkdf2Derivation.generateSalt();

      // Invalid PIN formats
      for (final invalidPin in ['', '12345', '1234567', 'abcdef', '12 345', '12345\n', '+12345', '-12345']) {
        expect(
          () => derivation.derive(pin: invalidPin, salt: validSalt, iterations: 1),
          throwsA(isA<FormatException>()),
          reason: 'Should reject invalid PIN: "$invalidPin"',
        );
      }

      // Empty salt
      expect(
        () => derivation.derive(pin: '123456', salt: Uint8List(0), iterations: 1),
        throwsA(isA<FormatException>()),
      );

      // Non-positive iterations
      expect(
        () => derivation.derive(pin: '123456', salt: validSalt, iterations: 0),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => derivation.derive(pin: '123456', salt: validSalt, iterations: -5),
        throwsA(isA<FormatException>()),
      );

      // Non-positive keyLength
      expect(
        () => derivation.derive(pin: '123456', salt: validSalt, iterations: 1, keyLength: 0),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => derivation.derive(pin: '123456', salt: validSalt, iterations: 1, keyLength: -32),
        throwsA(isA<FormatException>()),
      );
    });

    test('Constant-time comparison evaluation with byte offsets and slices', () {
      final a = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final b = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final c = Uint8List.fromList([9, 2, 3, 4, 5, 6, 7, 8]); // differs at first byte
      final d = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 9]); // differs at last byte
      final e = Uint8List.fromList([1, 2, 3]); // different length

      expect(VaultPbkdf2Derivation.constantTimeEquals(a, b), isTrue);
      expect(VaultPbkdf2Derivation.constantTimeEquals(a, c), isFalse);
      expect(VaultPbkdf2Derivation.constantTimeEquals(a, d), isFalse);
      expect(VaultPbkdf2Derivation.constantTimeEquals(a, e), isFalse);
      expect(VaultPbkdf2Derivation.constantTimeEquals(Uint8List(0), Uint8List(0)), isTrue);
      expect(VaultPbkdf2Derivation.constantTimeEquals(Uint8List(0), a), isFalse);

      // Subview slices with non-zero byte offsets
      final bigBuffer1 = Uint8List.fromList([99, 99, 1, 2, 3, 4, 88]);
      final bigBuffer2 = Uint8List.fromList([77, 1, 2, 3, 4, 66]);
      final slice1 = bigBuffer1.buffer.asUint8List(2, 4); // [1, 2, 3, 4]
      final slice2 = bigBuffer2.buffer.asUint8List(1, 4); // [1, 2, 3, 4]

      expect(VaultPbkdf2Derivation.constantTimeEquals(slice1, slice2), isTrue);
    });
  });

  group('Empirical Challenge 2: Lockout State Machine Stress & Restart Persistence', () {
    late FakeNativeVaultCryptoBridge cryptoBridge;
    late EmpiricalFakeStorageRepository storageRepository;
    late EmpiricalFakeMonotonicClock clock;
    late EmpiricalFakeSecureStorage secureStorage;

    final samplePoints = List.generate(
      64,
      (i) => GesturePoint(x: i.toDouble(), y: (i * 2).toDouble(), timestampMs: i * 10),
    );
    final validTemplate = GestureTemplate(
      id: 'stress-template-1',
      normalizedPoints: samplePoints,
      rubineFeatureVector: const [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5],
      createdAtEpochMs: 1000000,
    );

    setUp(() {
      cryptoBridge = FakeNativeVaultCryptoBridge();
      storageRepository = EmpiricalFakeStorageRepository();
      clock = EmpiricalFakeMonotonicClock();
      secureStorage = EmpiricalFakeSecureStorage();
    });

    test('Consecutive failed attempt progression and Tier 1 lockout rejection', () async {
      final authService = VaultAuthService(
        cryptoBridge: cryptoBridge,
        storageRepository: storageRepository,
        monotonicClock: clock,
        secureStorage: secureStorage,
      );

      await authService.enrollInitialCredentials(pin: '123456', template: validTemplate);

      // Attempts 1 to 4: increments and returns VaultAuthFailure with remaining count
      for (var attempt = 1; attempt <= 4; attempt++) {
        final result = await authService.authenticateWithPin(pin: '000000');
        expect(result, isA<VaultFailureResult<AuthSession>>());
        final failure = (result as VaultFailureResult<AuthSession>).failure as VaultAuthFailure;
        expect(failure.remainingAttempts, equals(5 - attempt));
        expect(storageRepository.persistedDeadlineMs, isNull);
      }

      // 5th attempt: triggers Tier 1 (30s) lockout
      final lockoutResult = await authService.authenticateWithPin(pin: '000000');
      expect(lockoutResult, isA<VaultFailureResult<AuthSession>>());
      final lockoutFailure = (lockoutResult as VaultFailureResult<AuthSession>).failure;
      expect(lockoutFailure, isA<VaultLockoutFailure>());
      expect(authService.currentSessionState, isA<VaultLockoutCooldownState>());
      expect(storageRepository.persistedDeadlineMs, equals(clock.currentMonotonicMs + 30000));

      // Attempt while locked out MUST be rejected immediately without modifying persisted deadline
      final activeDeadline = storageRepository.persistedDeadlineMs;
      final rejected = await authService.authenticateWithPin(pin: '123456'); // even correct PIN is rejected
      expect(rejected, isA<VaultFailureResult<AuthSession>>());
      expect((rejected as VaultFailureResult<AuthSession>).failure, isA<VaultLockoutFailure>());
      expect(storageRepository.persistedDeadlineMs, equals(activeDeadline));

      await authService.close();
    });

    test('Simulated app restart: active lockout deadline survives process restart', () async {
      // Instance 1 triggers lockout
      final service1 = VaultAuthService(
        cryptoBridge: cryptoBridge,
        storageRepository: storageRepository,
        monotonicClock: clock,
        secureStorage: secureStorage,
      );

      await service1.enrollInitialCredentials(pin: '123456', template: validTemplate);
      for (var i = 0; i < 5; i++) {
        await service1.authenticateWithPin(pin: '999999');
      }
      expect(storageRepository.persistedDeadlineMs, isNotNull);
      final expectedDeadline = storageRepository.persistedDeadlineMs!;

      // Simulate process kill (closing service 1)
      await service1.close();

      // Process restarted: Instance 2 created with same backing storage and clock
      final service2 = VaultAuthService(
        cryptoBridge: cryptoBridge,
        storageRepository: storageRepository,
        monotonicClock: clock,
        secureStorage: secureStorage,
      );

      // Service 2 queries lockout status before any auth
      final statusOnBoot = await service2.getLockoutStatus();
      expect(statusOnBoot.tier, equals(LockoutCooldownTierEnum.tier1ThirtySeconds));
      expect(statusOnBoot.deadlineMonotonicMs, equals(expectedDeadline));
      expect(statusOnBoot.remainingCooldownSeconds, greaterThan(0));

      // Attempting PIN auth on service 2 is rejected
      final bootAuthResult = await service2.authenticateWithPin(pin: '123456');
      expect(bootAuthResult, isA<VaultFailureResult<AuthSession>>());
      expect((bootAuthResult as VaultFailureResult<AuthSession>).failure, isA<VaultLockoutFailure>());

      // Advance monotonic clock past deadline
      clock.timeMs = expectedDeadline + 1;

      // Status query now clears persisted deadline
      final statusAfterExpiry = await service2.getLockoutStatus();
      expect(statusAfterExpiry.tier, equals(LockoutCooldownTierEnum.none));
      expect(storageRepository.persistedDeadlineMs, isNull);

      // Now authentication with correct PIN succeeds cleanly on service 2
      final successfulAuth = await service2.authenticateWithPin(pin: '123456');
      expect(successfulAuth, isA<VaultSuccess<AuthSession>>());

      await service2.close();
    });

    test('Empirical analysis of lockout reset behavior after Tier 1 expiration', () async {
      final authService = VaultAuthService(
        cryptoBridge: cryptoBridge,
        storageRepository: storageRepository,
        monotonicClock: clock,
        secureStorage: secureStorage,
      );

      await authService.enrollInitialCredentials(pin: '123456', template: validTemplate);

      // Fail 5 times to trigger Tier 1
      for (var i = 0; i < 5; i++) {
        await authService.authenticateWithPin(pin: '000000');
      }
      expect(authService.currentSessionState, isA<VaultLockoutCooldownState>());

      // Cooldown expires
      clock.timeMs += 31000;
      final status = await authService.getLockoutStatus();
      expect(status.tier, equals(LockoutCooldownTierEnum.none));

      // After Tier 1 expires, test what attempt number is assigned on the next failure:
      final nextFailure = await authService.authenticateWithPin(pin: '000000');
      expect(nextFailure, isA<VaultFailureResult<AuthSession>>());
      final failure = (nextFailure as VaultFailureResult<AuthSession>).failure as VaultAuthFailure;

      // Notice: In the current implementation, getLockoutStatus() resets consecutive failures to 0
      // when deadline passes, so the remaining attempts before cooldown is 4 (attempt 1 of 5).
      expect(failure.remainingAttempts, equals(4));

      await authService.close();
    });
  });

  group('Empirical Challenge 3: Memory Wiping Stress & Edge Cases', () {
    test('zeroBuffer on empty buffer executes without exception', () {
      final empty = Uint8List(0);
      expect(() => VaultMemoryWiper.zeroBuffer(empty), returnsNormally);
      expect(empty.length, equals(0));
    });

    test('zeroBuffer on large 5MB buffer completely zeroes every byte', () {
      const size = 5 * 1024 * 1024;
      final largeBuffer = Uint8List(size);
      for (var i = 0; i < 1000; i++) {
        largeBuffer[i * 5000] = 0xAA;
      }
      expect(largeBuffer.any((b) => b != 0), isTrue);

      VaultMemoryWiper.zeroBuffer(largeBuffer);

      // Verify every byte is 0
      var nonZeroCount = 0;
      for (var i = 0; i < largeBuffer.length; i++) {
        if (largeBuffer[i] != 0) nonZeroCount++;
      }
      expect(nonZeroCount, equals(0));
    });

    test('zeroBuffer on sliced buffer subviews zeroes exact backing segment', () {
      final backingBuffer = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      // Create subview slice [3, 4, 5, 6] at byte offset 2 with length 4
      final slice = backingBuffer.buffer.asUint8List(2, 4);

      VaultMemoryWiper.zeroBuffer(slice);

      // Sliced view is zeroed
      expect(slice, equals(Uint8List.fromList([0, 0, 0, 0])));
      // Backing buffer bytes 0..1 and 6..9 remain intact, bytes 2..5 are zeroed
      expect(backingBuffer, equals(Uint8List.fromList([1, 2, 0, 0, 0, 0, 7, 8, 9, 10])));
    });

    test('zeroBuffer on unmodifiable view throws VaultCryptoFailure (does not crash with unhandled exception)', () {
      final unmodifiable = Uint8List.fromList([1, 2, 3]).asUnmodifiableView();
      expect(
        () => VaultMemoryWiper.zeroBuffer(unmodifiable),
        throwsA(isA<VaultCryptoFailure>()),
      );
    });

    test('withPlaintextScope safely zeroes temporary mutable copy even if action throws', () async {
      Uint8List? capturedBuffer;
      final input = Uint8List.fromList([10, 20, 30, 40]);

      try {
        await VaultMemoryWiper.withPlaintextScope<void>(
          plaintext: input,
          action: (mutableBuffer) async {
            capturedBuffer = mutableBuffer;
            throw StateError('Simulated unexpected worker failure');
          },
        );
      } catch (e) {
        expect(e, isA<StateError>());
      }

      expect(capturedBuffer, isNotNull);
      expect(capturedBuffer!, equals(Uint8List.fromList([0, 0, 0, 0])));
    });

    test('withPlaintextScope handles unmodifiable input gracefully when wipeInputIfMutable is true', () async {
      final unmodifiable = Uint8List.fromList([1, 2, 3]).asUnmodifiableView();

      final result = await VaultMemoryWiper.withPlaintextScope<int>(
        plaintext: unmodifiable,
        wipeInputIfMutable: true,
        action: (mutableBuffer) async {
          expect(mutableBuffer, equals(Uint8List.fromList([1, 2, 3])));
          return 42;
        },
      );

      expect(result, equals(42));
    });

    test('VaultPlaintextBuffer RAII zeroize and use-after-free prevention', () {
      final buffer = VaultPlaintextBuffer([0xDE, 0xAD, 0xBE, 0xEF]);
      expect(buffer.length, equals(4));
      expect(buffer.isZeroed, isFalse);
      expect(buffer.bytes, equals(Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF])));

      buffer.zeroize();
      expect(buffer.isZeroed, isTrue);

      // Subsequent access must throw VaultCryptoFailure
      expect(() => buffer.bytes, throwsA(isA<VaultCryptoFailure>()));

      // Multiple zeroize calls are idempotent
      expect(() => buffer.zeroize(), returnsNormally);
    });

    test('allocateMutable defensive negative length check', () {
      expect(
        () => VaultMemoryWiper.allocateMutable(-1),
        throwsA(isA<VaultValidationFailure>()),
      );
      final allocated = VaultMemoryWiper.allocateMutable(16);
      expect(allocated.length, equals(16));
      expect(allocated.every((b) => b == 0), isTrue);
    });
  });
}
