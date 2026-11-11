import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/services/vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/biometric_auth_policy.dart';
import 'package:musify_mu/features/vault/domain/states/crypto_engine_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

import '../datasources/fake_native_vault_crypto_bridge.dart';

class FakeVaultStorageRepository implements IVaultStorageRepository {
  VaultConfig config = VaultConfig();
  GestureTemplate? template;
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
  Future<VaultResult<GestureTemplate>> loadGestureTemplate() async {
    if (template case final t?) {
      return VaultResult.success(t);
    }
    return const VaultResult.failure(VaultStorageFailure('No template stored.'));
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

class FakeMonotonicClock implements IMonotonicClock {
  int timeMs = 1000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _storage = <String, String>{};

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
      _storage[key];

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
      _storage[key] = value;
    } else {
      _storage.remove(key);
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
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.clear();
  }
}

void main() {
  late FakeNativeVaultCryptoBridge cryptoBridge;
  late FakeVaultStorageRepository storageRepository;
  late FakeMonotonicClock clock;
  late FakeFlutterSecureStorage secureStorage;
  late VaultAuthService authService;

  final samplePoints = List.generate(
    64,
        (i) => GesturePoint(x: i.toDouble(), y: (i * 2).toDouble(), timestampMs: i * 10),
  );
  final validTemplate = GestureTemplate(
    id: 'test-template-1',
    normalizedPoints: samplePoints,
    rubineFeatureVector: const [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5],
    createdAtEpochMs: 1234567,
  );

  setUp(() {
    cryptoBridge = FakeNativeVaultCryptoBridge();
    storageRepository = FakeVaultStorageRepository();
    clock = FakeMonotonicClock();
    secureStorage = FakeFlutterSecureStorage();

    authService = VaultAuthService(
      cryptoBridge: cryptoBridge,
      storageRepository: storageRepository,
      monotonicClock: clock,
      secureStorage: secureStorage,
    );
  });

  tearDown(() async {
    await authService.close();
  });

  group('VaultAuthService Credential Enrollment', () {
    test('Successfully enrolls initial credentials and provisions master key', () async {
      final result = await authService.enrollInitialCredentials(
        pin: '123456',
        template: validTemplate,
      );

      expect(result, isA<VaultSuccess<void>>());
      expect(cryptoBridge.masterKeyExists, isTrue);
      expect(storageRepository.template, isNotNull);
      expect(await secureStorage.read(key: 'musify_vault_is_enrolled'), equals('true'));
      expect(authService.currentCryptoState, isA<CryptoEngineKeyWrappedAtRestState>());
    });

    test('Rejects invalid PIN format on enrollment', () async {
      final result = await authService.enrollInitialCredentials(
        pin: '123',
        template: validTemplate,
      );

      expect(result, isA<VaultFailureResult<void>>());
      final failure = (result as VaultFailureResult<void>).failure;
      expect(failure, isA<VaultValidationFailure>());
    });
  });

  group('VaultAuthService PIN Authentication & Lockout Escalation', () {
    setUp(() async {
      await authService.enrollInitialCredentials(
        pin: '123456',
        template: validTemplate,
      );
    });

    test('Authenticates successfully with correct PIN', () async {
      final result = await authService.authenticateWithPin(pin: '123456');

      expect(result, isA<VaultSuccess<AuthSession>>());
      final session = (result as VaultSuccess<AuthSession>).data;
      expect(session.authMethod, equals(AuthMethodEnum.pin));
      expect(cryptoBridge.isSessionUnlocked, isTrue);
    });

    test('Fails on incorrect PIN and triggers failure shake tracking (1-4 attempts)', () async {
      final result = await authService.authenticateWithPin(pin: '654321');

      expect(result, isA<VaultFailureResult<AuthSession>>());
      final failure = (result as VaultFailureResult<AuthSession>).failure;
      expect(failure, isA<VaultAuthFailure>());
      expect((failure as VaultAuthFailure).remainingAttempts, equals(4));
    });

    test('5 consecutive failures activates 30-second cooldown (Tier 1)', () async {
      for (var i = 0; i < 4; i++) {
        await authService.authenticateWithPin(pin: '000000');
      }

      final result = await authService.authenticateWithPin(pin: '000000');
      expect(result, isA<VaultFailureResult<AuthSession>>());
      final failure = (result as VaultFailureResult<AuthSession>).failure;
      expect(failure, isA<VaultLockoutFailure>());
      expect((failure as VaultLockoutFailure).remainingCooldownSeconds, equals(30));
      expect(storageRepository.persistedDeadlineMs, equals(clock.currentMonotonicMs + 30000));

      // Immediate attempt while locked out is rejected without PBKDF2
      final blockedResult = await authService.authenticateWithPin(pin: '123456');
      expect(blockedResult, isA<VaultFailureResult<AuthSession>>());
      expect((blockedResult as VaultFailureResult<AuthSession>).failure, isA<VaultLockoutFailure>());
    });

    test('10 consecutive failures activates 5-minute cooldown (Tier 2)', () async {
      for (var i = 0; i < 5; i++) {
        await authService.authenticateWithPin(pin: '000000');
      }
      // Simulate tier 1 expired but consecutive failures continue
      clock.timeMs += 35000;
      // Reset lockout status from clock advance
      await authService.getLockoutStatus();

      // Trigger 5 more failures (total 10)
      for (var i = 0; i < 9; i++) {
        await authService.recordFailedAttempt();
      }
      await authService.recordFailedAttempt(); // 10th attempt

      final status = await authService.getLockoutStatus();
      expect(status.tier, equals(LockoutCooldownTierEnum.tier2FiveMinutes));
      expect(status.remainingCooldownSeconds, inInclusiveRange(290, 300));
    });

    test('Cooldown expiration restores unthrottled locked state', () async {
      for (var i = 0; i < 5; i++) {
        await authService.authenticateWithPin(pin: '000000');
      }

      // Advance monotonic clock past 30s
      clock.timeMs += 35000;

      final status = await authService.getLockoutStatus();
      expect(status.tier, equals(LockoutCooldownTierEnum.none));
      expect(storageRepository.persistedDeadlineMs, isNull);

      // Now authentication with correct PIN succeeds
      final result = await authService.authenticateWithPin(pin: '123456');
      expect(result, isA<VaultSuccess<AuthSession>>());
    });
  });

  group('VaultAuthService Biometric Authentication & Invalidation', () {
    setUp(() async {
      await authService.enrollInitialCredentials(
        pin: '123456',
        template: validTemplate,
      );
      storageRepository.config = storageRepository.config.copyWith(
        biometricAuth: BiometricAuthPolicyEnum.pinAndBiometricStrong,
      );
    });

    test('Unlocks session upon successful biometric verification', () async {
      final result = await authService.authenticateWithBiometrics();

      expect(result, isA<VaultSuccess<AuthSession>>());
      final session = (result as VaultSuccess<AuthSession>).data;
      expect(session.authMethod, equals(AuthMethodEnum.biometric));
    });

    test('Rejects biometric authentication when policy is pinOnly', () async {
      storageRepository.config = storageRepository.config.copyWith(
        biometricAuth: BiometricAuthPolicyEnum.pinOnly,
      );

      final result = await authService.authenticateWithBiometrics();
      expect(result, isA<VaultFailureResult<AuthSession>>());
      final failure = (result as VaultFailureResult<AuthSession>).failure;
      expect(failure, isA<VaultAuthFailure>());
    });

    test('Handles KeyPermanentlyInvalidated exception, emitting fault and Slot 1 fallback', () async {
      cryptoBridge.simulateBiometricInvalidation = true;
      final cryptoStates = <CryptoEngineState>[];
      final subscription = authService.cryptoEngineStateStream.listen(cryptoStates.add);

      final result = await authService.authenticateWithBiometrics();

      expect(result, isA<VaultFailureResult<AuthSession>>());
      final failure = (result as VaultFailureResult<AuthSession>).failure;
      expect(failure, isA<VaultCryptoFailure>());
      expect(authService.currentCryptoState, isA<CryptoEngineCryptoFaultState>());
      expect(
        (authService.currentCryptoState as CryptoEngineCryptoFaultState).faultReason,
        equals(CryptoFaultReasonEnum.keyStoreInvalidated),
      );

      await subscription.cancel();
    });
  });

  group('VaultAuthService PIN Rotation & Memory Wiping', () {
    setUp(() async {
      await authService.enrollInitialCredentials(
        pin: '123456',
        template: validTemplate,
      );
    });

    test('Rotates PIN successfully with correct old PIN', () async {
      final result = await authService.rotatePin(
        oldPin: '123456',
        newPin: '987654',
      );

      expect(result, isA<VaultSuccess<void>>());

      // Old PIN no longer works
      final oldAuth = await authService.authenticateWithPin(pin: '123456');
      expect(oldAuth, isA<VaultFailureResult<AuthSession>>());

      // New PIN authenticates successfully
      final newAuth = await authService.authenticateWithPin(pin: '987654');
      expect(newAuth, isA<VaultSuccess<AuthSession>>());
    });

    test('Rejects rotating to the same PIN', () async {
      final result = await authService.rotatePin(
        oldPin: '123456',
        newPin: '123456',
      );

      expect(result, isA<VaultFailureResult<void>>());
      final failure = (result as VaultFailureResult<void>).failure;
      expect(failure, isA<VaultValidationFailure>());
    });

    test('clearSessionKeysFromRam locks session and restores locked state', () async {
      await authService.authenticateWithPin(pin: '123456');
      authService.clearSessionKeysFromRam();
      expect(cryptoBridge.isSessionUnlocked, isFalse);
      expect(authService.currentCryptoState, isA<CryptoEngineKeyWrappedAtRestState>());
    });
  });
}