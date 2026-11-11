import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:musify_mu/features/vault/data/datasources/i_native_vault_crypto_bridge.dart';
import 'package:musify_mu/features/vault/data/services/vault_pbkdf2_derivation.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/biometric_auth_policy.dart';
import 'package:musify_mu/features/vault/domain/states/crypto_engine_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:uuid/uuid.dart';

/// Implementation of [IVaultAuthService] governing the cryptographic security lifecycle,
/// PIN derivation, hardware KeyStore biometric challenges, brute-force lockout tracking,
/// and in-memory key buffer lifecycle management.
class VaultAuthService implements IVaultAuthService {
  static const String _kPinSaltStorageKey = 'musify_vault_pin_salt';
  static const String _kPinVerifierStorageKey = 'musify_vault_pin_verifier';
  static const String _kIsEnrolledStorageKey = 'musify_vault_is_enrolled';

  static const int _kTier1Threshold = 5;
  static const int _kTier2Threshold = 10;
  static const int _kTier1DurationMs = 30000;
  static const int _kTier2DurationMs = 300000;

  final INativeVaultCryptoBridge _cryptoBridge;
  final IVaultStorageRepository _storageRepository;
  final IMonotonicClock _monotonicClock;
  final FlutterSecureStorage _secureStorage;
  final VaultPbkdf2Derivation _pbkdf2Derivation;

  final StreamController<VaultSessionState> _sessionStateController;
  final StreamController<CryptoEngineState> _cryptoStateController;

  VaultSessionState _currentSessionState;
  CryptoEngineState _currentCryptoState;
  int _consecutiveFailedAttempts;
  final List<Uint8List> _transientKeyBuffers;

  /// Constructs a production-ready [VaultAuthService] instance.
  VaultAuthService({
    required INativeVaultCryptoBridge cryptoBridge,
    required IVaultStorageRepository storageRepository,
    required IMonotonicClock monotonicClock,
    FlutterSecureStorage? secureStorage,
    VaultPbkdf2Derivation? pbkdf2Derivation,
    VaultSessionState initialSessionState = const VaultUninitializedState(),
    CryptoEngineState initialCryptoState = const CryptoEngineUnprovisionedState(),
  })  : _cryptoBridge = cryptoBridge,
        _storageRepository = storageRepository,
        _monotonicClock = monotonicClock,
        _secureStorage = switch (secureStorage) {
          final s? => s,
          null => const FlutterSecureStorage(),
        },
        _pbkdf2Derivation = switch (pbkdf2Derivation) {
          final p? => p,
          null => const VaultPbkdf2Derivation(),
        },
        _sessionStateController = StreamController<VaultSessionState>.broadcast(),
        _cryptoStateController = StreamController<CryptoEngineState>.broadcast(),
        _currentSessionState = initialSessionState,
        _currentCryptoState = initialCryptoState,
        _consecutiveFailedAttempts = 0,
        _transientKeyBuffers = <Uint8List>[];

  @override
  Stream<VaultSessionState> get sessionStateStream => _sessionStateController.stream;

  /// Returns the current root security session state.
  VaultSessionState get currentSessionState => _currentSessionState;

  /// Stream of cryptographic engine lifecycle transitions.
  Stream<CryptoEngineState> get cryptoEngineStateStream => _cryptoStateController.stream;

  /// Returns the current cryptographic engine state.
  CryptoEngineState get currentCryptoState => _currentCryptoState;

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({
    required String pin,
  }) async {
    final lockoutStatus = await getLockoutStatus();
    if (lockoutStatus.tier != LockoutCooldownTierEnum.none) {
      return VaultResult.failure(
        VaultLockoutFailure(
          'Maximum PIN attempts exceeded. Cooldown active.',
          remainingCooldownSeconds: lockoutStatus.remainingCooldownSeconds,
          deadlineMonotonicMs: lockoutStatus.deadlineMonotonicMs,
        ),
      );
    }

    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      await recordFailedAttempt();
      final remaining = _kTier1Threshold - _consecutiveFailedAttempts;
      return VaultResult.failure(
        VaultAuthFailure(
          'PIN must be exactly 6 numeric digits.',
          remainingAttempts: remaining < 0 ? 0 : remaining,
        ),
      );
    }

    final saltBase64 = await _secureStorage.read(key: _kPinSaltStorageKey);
    final verifierBase64 = await _secureStorage.read(key: _kPinVerifierStorageKey);

    if (saltBase64 == null || verifierBase64 == null) {
      return const VaultResult.failure(
        VaultAuthFailure('Vault is not enrolled. Please set up initial credentials.'),
      );
    }

    final saltBytes = base64Decode(saltBase64);
    final storedVerifierBytes = base64Decode(verifierBase64);

    _emitCryptoState(
      const CryptoEngineUnwrappingMasterKeyState(
        slot: CryptoWrappingSlotEnum.slot1PinPbkdf2,
      ),
    );

    final derivedToken = await _pbkdf2Derivation.derive(
      pin: pin,
      salt: saltBytes,
    );
    _registerTransientBuffer(derivedToken);

    final computedVerifier = Uint8List.fromList(sha256.convert(derivedToken).bytes);
    _registerTransientBuffer(computedVerifier);

    final isCorrectPin = VaultPbkdf2Derivation.constantTimeEquals(
      computedVerifier,
      Uint8List.fromList(storedVerifierBytes),
    );

    _wipeTransientBuffers();

    if (!isCorrectPin) {
      await recordFailedAttempt();
      final currentLockout = await getLockoutStatus();
      if (currentLockout.tier != LockoutCooldownTierEnum.none) {
        return VaultResult.failure(
          VaultLockoutFailure(
            'Incorrect PIN. Lockout cooldown activated.',
            remainingCooldownSeconds: currentLockout.remainingCooldownSeconds,
            deadlineMonotonicMs: currentLockout.deadlineMonotonicMs,
          ),
        );
      }
      final remaining = _kTier1Threshold - _consecutiveFailedAttempts;
      return VaultResult.failure(
        VaultAuthFailure(
          'Incorrect PIN.',
          remainingAttempts: remaining < 0 ? 0 : remaining,
        ),
      );
    }

    await _cryptoBridge.unlockSession();
    await resetFailedAttempts();

    final nowEpochMs = DateTime.now().millisecondsSinceEpoch;
    final nowMonotonicMs = _monotonicClock.currentMonotonicMs;
    final sessionToken = const Uuid().v4();

    final session = AuthSession(
      sessionToken: sessionToken,
      sessionStartedEpochMs: nowEpochMs,
      lastActiveEpochMs: nowEpochMs,
      authMethod: AuthMethodEnum.pin,
    );

    var reauthDeadlineMonotonicMs = 0;
    final configResult = await _storageRepository.loadVaultConfig();
    switch (configResult) {
      case VaultSuccess<VaultConfig>(data: final config):
        if (config.activeReauthInterval.milliseconds case final intervalMs?) {
          reauthDeadlineMonotonicMs = nowMonotonicMs + intervalMs;
        }
      case VaultFailureResult<VaultConfig>():
        reauthDeadlineMonotonicMs = 0;
    }

    _emitCryptoState(
      CryptoEngineMasterKeyUnwrappedInRamState(
        unwrappedAtMonotonicMs: nowMonotonicMs,
      ),
    );

    _emitSessionState(
      VaultUnlockedState(
        session: session,
        unlockedAtMonotonicMs: nowMonotonicMs,
        reauthDeadlineMonotonicMs: reauthDeadlineMonotonicMs,
      ),
    );

    return VaultResult.success(session);
  }

  @override
  Future<VaultResult<AuthSession>> authenticateWithBiometrics() async {
    final lockoutStatus = await getLockoutStatus();
    if (lockoutStatus.tier != LockoutCooldownTierEnum.none) {
      return VaultResult.failure(
        VaultLockoutFailure(
          'Vault is currently locked out. Please wait for cooldown to expire.',
          remainingCooldownSeconds: lockoutStatus.remainingCooldownSeconds,
          deadlineMonotonicMs: lockoutStatus.deadlineMonotonicMs,
        ),
      );
    }

    final isEnrolled = await _secureStorage.read(key: _kIsEnrolledStorageKey);
    if (isEnrolled != 'true') {
      return const VaultResult.failure(
        VaultAuthFailure('Vault is not enrolled. Please complete initial setup.'),
      );
    }

    final configResult = await _storageRepository.loadVaultConfig();
    switch (configResult) {
      case VaultSuccess<VaultConfig>(data: final config):
        if (config.biometricAuth == BiometricAuthPolicyEnum.pinOnly) {
          return const VaultResult.failure(
            VaultAuthFailure('Biometric authentication is disabled by vault policy.'),
          );
        }
      case VaultFailureResult<VaultConfig>():
        break;
    }

    _emitCryptoState(
      const CryptoEngineUnwrappingMasterKeyState(
        slot: CryptoWrappingSlotEnum.slot2BiometricHardwareKeyStore,
      ),
    );

    try {
      final success = await _cryptoBridge.authenticateBiometrics(
        title: 'Unlock Private Vault',
        subtitle: 'Verify biometric identity to access private playlists',
        cancelButton: 'Use PIN',
      );

      if (!success) {
        _emitCryptoState(const CryptoEngineKeyWrappedAtRestState());
        return const VaultResult.failure(
          VaultAuthFailure('Biometric authentication was canceled or unconfirmed.'),
        );
      }

      await resetFailedAttempts();

      final nowEpochMs = DateTime.now().millisecondsSinceEpoch;
      final nowMonotonicMs = _monotonicClock.currentMonotonicMs;
      final sessionToken = const Uuid().v4();

      final session = AuthSession(
        sessionToken: sessionToken,
        sessionStartedEpochMs: nowEpochMs,
        lastActiveEpochMs: nowEpochMs,
        authMethod: AuthMethodEnum.biometric,
      );

      var reauthDeadlineMonotonicMs = 0;
      switch (configResult) {
        case VaultSuccess<VaultConfig>(data: final config):
          if (config.activeReauthInterval.milliseconds case final intervalMs?) {
            reauthDeadlineMonotonicMs = nowMonotonicMs + intervalMs;
          }
        case VaultFailureResult<VaultConfig>():
          reauthDeadlineMonotonicMs = 0;
      }

      _emitCryptoState(
        CryptoEngineMasterKeyUnwrappedInRamState(
          unwrappedAtMonotonicMs: nowMonotonicMs,
        ),
      );

      _emitSessionState(
        VaultUnlockedState(
          session: session,
          unlockedAtMonotonicMs: nowMonotonicMs,
          reauthDeadlineMonotonicMs: reauthDeadlineMonotonicMs,
        ),
      );

      return VaultResult.success(session);
    } catch (e) {
      final message = e.toString();
      final isPermanentlyInvalidated = message.contains('KeyPermanentlyInvalidated') ||
          message.contains('CRYPTO_FAULT_KEY_INVALIDATED') ||
          message.toLowerCase().contains('invalidated');

      if (isPermanentlyInvalidated) {
        _emitCryptoState(
          const CryptoEngineCryptoFaultState(
            faultReason: CryptoFaultReasonEnum.keyStoreInvalidated,
            errorMessage: 'Biometric hardware key invalidated by OS credential change.',
          ),
        );

        _emitSessionState(
          const VaultAuthenticatingState(
            authSessionId: 'slot1-fallback-recovery',
            attemptNumber: 1,
            remainingAttemptsBeforeCooldown: _kTier1Threshold,
          ),
        );

        return VaultResult.failure(
          VaultCryptoFailure(
            'Biometric key permanently invalidated by OS. Please authenticate with Slot 1 PIN recovery.',
            cause: e,
          ),
        );
      }

      _emitCryptoState(const CryptoEngineKeyWrappedAtRestState());
      return VaultResult.failure(
        VaultAuthFailure('Biometric authentication challenge failed: $e', cause: e),
      );
    }
  }

  @override
  Future<VaultResult<void>> rotatePin({
    required String oldPin,
    required String newPin,
  }) async {
    final lockoutStatus = await getLockoutStatus();
    if (lockoutStatus.tier != LockoutCooldownTierEnum.none) {
      return VaultResult.failure(
        VaultLockoutFailure(
          'Cannot rotate PIN during active lockout cooldown.',
          remainingCooldownSeconds: lockoutStatus.remainingCooldownSeconds,
          deadlineMonotonicMs: lockoutStatus.deadlineMonotonicMs,
        ),
      );
    }

    if (!RegExp(r'^\d{6}$').hasMatch(oldPin)) {
      return const VaultResult.failure(
        VaultValidationFailure('Old PIN must be exactly 6 numeric digits.'),
      );
    }
    if (!RegExp(r'^\d{6}$').hasMatch(newPin)) {
      return const VaultResult.failure(
        VaultValidationFailure('New PIN must be exactly 6 numeric digits.'),
      );
    }
    if (oldPin == newPin) {
      return const VaultResult.failure(
        VaultValidationFailure('New PIN must be different from the current PIN.'),
      );
    }

    final saltBase64 = await _secureStorage.read(key: _kPinSaltStorageKey);
    final verifierBase64 = await _secureStorage.read(key: _kPinVerifierStorageKey);

    if (saltBase64 == null || verifierBase64 == null) {
      return const VaultResult.failure(
        VaultAuthFailure('Vault is not enrolled. Cannot rotate PIN.'),
      );
    }

    final saltBytes = base64Decode(saltBase64);
    final storedVerifierBytes = base64Decode(verifierBase64);

    final oldDerivedToken = await _pbkdf2Derivation.derive(
      pin: oldPin,
      salt: saltBytes,
    );
    _registerTransientBuffer(oldDerivedToken);

    final oldComputedVerifier = Uint8List.fromList(sha256.convert(oldDerivedToken).bytes);
    _registerTransientBuffer(oldComputedVerifier);

    final isOldPinValid = VaultPbkdf2Derivation.constantTimeEquals(
      oldComputedVerifier,
      Uint8List.fromList(storedVerifierBytes),
    );

    _wipeTransientBuffers();

    if (!isOldPinValid) {
      await recordFailedAttempt();
      final remaining = _kTier1Threshold - _consecutiveFailedAttempts;
      return VaultResult.failure(
        VaultAuthFailure(
          'Current PIN verification failed.',
          remainingAttempts: remaining < 0 ? 0 : remaining,
        ),
      );
    }

    _emitCryptoState(
      const CryptoEngineRotatingWrappingKeyState(
        targetSlot: CryptoWrappingSlotEnum.slot1PinPbkdf2,
      ),
    );

    final newSaltBytes = VaultPbkdf2Derivation.generateSalt();
    final newDerivedToken = await _pbkdf2Derivation.derive(
      pin: newPin,
      salt: newSaltBytes,
    );
    _registerTransientBuffer(newDerivedToken);

    final newComputedVerifier = Uint8List.fromList(sha256.convert(newDerivedToken).bytes);
    _registerTransientBuffer(newComputedVerifier);

    await _secureStorage.write(
      key: _kPinSaltStorageKey,
      value: base64Encode(newSaltBytes),
    );
    await _secureStorage.write(
      key: _kPinVerifierStorageKey,
      value: base64Encode(newComputedVerifier),
    );

    _wipeTransientBuffers();

    _emitCryptoState(const CryptoEngineKeyWrappedAtRestState());

    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> enrollInitialCredentials({
    required String pin,
    required GestureTemplate template,
  }) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      return const VaultResult.failure(
        VaultValidationFailure('PIN must be exactly 6 numeric digits.'),
      );
    }

    if (template.normalizedPoints.isEmpty) {
      return const VaultResult.failure(
        VaultValidationFailure('Gesture template must contain resampled stroke points.'),
      );
    }

    _emitCryptoState(
      const CryptoEngineRotatingWrappingKeyState(
        targetSlot: CryptoWrappingSlotEnum.slot1PinPbkdf2,
      ),
    );

    final saltBytes = VaultPbkdf2Derivation.generateSalt();
    final derivedToken = await _pbkdf2Derivation.derive(
      pin: pin,
      salt: saltBytes,
    );
    _registerTransientBuffer(derivedToken);

    final computedVerifier = Uint8List.fromList(sha256.convert(derivedToken).bytes);
    _registerTransientBuffer(computedVerifier);

    try {
      await _cryptoBridge.generateMasterKey();

      await _secureStorage.write(
        key: _kPinSaltStorageKey,
        value: base64Encode(saltBytes),
      );
      await _secureStorage.write(
        key: _kPinVerifierStorageKey,
        value: base64Encode(computedVerifier),
      );
      await _secureStorage.write(
        key: _kIsEnrolledStorageKey,
        value: 'true',
      );

      final templateResult = await _storageRepository.saveGestureTemplate(template);
      if (templateResult is VaultFailureResult) {
        return templateResult;
      }

      final configResult = await _storageRepository.saveVaultConfig(VaultConfig());
      if (configResult is VaultFailureResult) {
        return configResult;
      }

      await resetFailedAttempts();

      final nowMonotonicMs = _monotonicClock.currentMonotonicMs;
      _emitCryptoState(const CryptoEngineKeyWrappedAtRestState());
      _emitSessionState(
        VaultLockedState(lockedAtMonotonicMs: nowMonotonicMs),
      );

      return const VaultResult.success(null);
    } catch (e) {
      _emitCryptoState(const CryptoEngineUnprovisionedState());
      return VaultResult.failure(
        VaultCryptoFailure('Initial credential enrollment failed: $e', cause: e),
      );
    } finally {
      _wipeTransientBuffers();
    }
  }

  @override
  Future<LockoutCooldownInfo> getLockoutStatus() async {
    final nowMonotonicMs = _monotonicClock.currentMonotonicMs;
    final persistedDeadline = await _storageRepository.getPersistedLockoutDeadlineMs();

    if (persistedDeadline case final deadline?) {
      if (deadline > nowMonotonicMs) {
        final remainingMs = deadline - nowMonotonicMs;
        final remainingSeconds = (remainingMs + 999) ~/ 1000;
        final tier = remainingMs > _kTier1DurationMs
            ? LockoutCooldownTierEnum.tier2FiveMinutes
            : LockoutCooldownTierEnum.tier1ThirtySeconds;

        return LockoutCooldownInfo(
          tier: tier,
          consecutiveFailedAttempts: _consecutiveFailedAttempts,
          deadlineMonotonicMs: deadline,
          remainingCooldownSeconds: remainingSeconds,
        );
      } else {
        await _storageRepository.clearPersistedLockoutDeadline();
        _consecutiveFailedAttempts = 0;
        if (_currentSessionState is VaultLockoutCooldownState) {
          _emitSessionState(
            VaultLockedState(lockedAtMonotonicMs: nowMonotonicMs),
          );
        }
        return LockoutCooldownInfo.none();
      }
    }

    return LockoutCooldownInfo(
      tier: LockoutCooldownTierEnum.none,
      consecutiveFailedAttempts: _consecutiveFailedAttempts,
      deadlineMonotonicMs: 0,
      remainingCooldownSeconds: 0,
    );
  }

  @override
  Future<void> recordFailedAttempt() async {
    _consecutiveFailedAttempts++;
    final nowMonotonicMs = _monotonicClock.currentMonotonicMs;

    if (_consecutiveFailedAttempts >= _kTier2Threshold) {
      final deadline = nowMonotonicMs + _kTier2DurationMs;
      await _storageRepository.persistLockoutDeadlineMs(deadline);
      _emitSessionState(
        VaultLockoutCooldownState(
          tier: LockoutCooldownTierEnum.tier2FiveMinutes,
          cooldownStartedMonotonicMs: nowMonotonicMs,
          durationMs: _kTier2DurationMs,
          deadlineMonotonicMs: deadline,
          failedAttemptsCount: _consecutiveFailedAttempts,
        ),
      );
    } else if (_consecutiveFailedAttempts >= _kTier1Threshold) {
      final deadline = nowMonotonicMs + _kTier1DurationMs;
      await _storageRepository.persistLockoutDeadlineMs(deadline);
      _emitSessionState(
        VaultLockoutCooldownState(
          tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
          cooldownStartedMonotonicMs: nowMonotonicMs,
          durationMs: _kTier1DurationMs,
          deadlineMonotonicMs: deadline,
          failedAttemptsCount: _consecutiveFailedAttempts,
        ),
      );
    } else {
      final remaining = _kTier1Threshold - _consecutiveFailedAttempts;
      _emitSessionState(
        VaultAuthenticatingState(
          authSessionId: 'auth-attempt-$_consecutiveFailedAttempts',
          attemptNumber: _consecutiveFailedAttempts,
          remainingAttemptsBeforeCooldown: remaining,
        ),
      );
    }
  }

  @override
  Future<void> resetFailedAttempts() async {
    _consecutiveFailedAttempts = 0;
    await _storageRepository.clearPersistedLockoutDeadline();
    if (_currentSessionState is VaultLockoutCooldownState) {
      _emitSessionState(
        VaultLockedState(
          lockedAtMonotonicMs: _monotonicClock.currentMonotonicMs,
        ),
      );
    }
  }

  @override
  void clearSessionKeysFromRam() {
    _wipeTransientBuffers();
    unawaited(_cryptoBridge.lockSession());
    if (_currentSessionState is VaultActiveSessionState) {
      _emitSessionState(
        VaultLockedState(
          lockedAtMonotonicMs: _monotonicClock.currentMonotonicMs,
        ),
      );
    }
    _emitCryptoState(const CryptoEngineKeyWrappedAtRestState());
  }

  /// Closes internal broadcast streams.
  Future<void> close() async {
    _wipeTransientBuffers();
    await _sessionStateController.close();
    await _cryptoStateController.close();
  }

  void _emitSessionState(VaultSessionState state) {
    _currentSessionState = state;
    if (!_sessionStateController.isClosed) {
      _sessionStateController.add(state);
    }
  }

  void _emitCryptoState(CryptoEngineState state) {
    _currentCryptoState = state;
    if (!_cryptoStateController.isClosed) {
      _cryptoStateController.add(state);
    }
  }

  void _registerTransientBuffer(Uint8List buffer) {
    _transientKeyBuffers.add(buffer);
  }

  void _wipeTransientBuffers() {
    for (final buffer in _transientKeyBuffers) {
      buffer.fillRange(0, buffer.length, 0);
    }
    _transientKeyBuffers.clear();
  }
}
