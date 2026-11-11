import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Represents the cryptographic key wrapping slot used for envelope encryption.
enum CryptoWrappingSlotEnum {
  /// Slot 1: Key wrapped with a key derived from the user PIN via PBKDF2-HMAC-SHA256.
  slot1PinPbkdf2,

  /// Slot 2: Key wrapped with Android KeyStore hardware-backed master key via BiometricPrompt.
  slot2BiometricHardwareKeyStore,
}

/// Represents the root cause of a cryptographic fault or key invalidation.
enum CryptoFaultReasonEnum {
  /// Android KeyStore invalidated due to a new biometric enrollment at the OS level.
  keyStoreInvalidated,

  /// Encrypted ciphertext corrupted or authentication tag mismatch during AES-256-GCM decryption.
  decryptionCorrupted,

  /// Key unwrapping failed due to incorrect PIN or invalid cryptographic credentials.
  authenticationFailed,

  /// Hardware-backed secure element or KeyStore is currently unavailable.
  hardwareUnavailable,
}

/// Governs hardware key wrapping, envelope slots, and volatile RAM key lifecycle.
enum CryptoEngineStateEnum {
  /// No wrapped master key exists on disk; vault requires initial provisioning.
  unprovisioned,

  /// Master Vault Key (MVK) is encrypted on disk; zero plaintext key material in RAM.
  keyWrappedAtRest,

  /// Actively unwrapping MVK via Slot 1 (PBKDF2) or Slot 2 (Android BiometricPrompt).
  unwrappingMasterKey,

  /// Active AES-256-GCM session key is unwrapped and available in volatile RAM.
  masterKeyUnwrappedInRam,

  /// Re-wrapping the MVK with a new PIN or biometric cipher without modifying stored audio files.
  rotatingWrappingKey,

  /// Securely shredding encrypted metadata databases, isolated vault media files, and KeyStore aliases.
  purgingAllVaultData,

  /// KeyStore invalidation or decryption failure requiring Slot 1 PIN fallback recovery.
  cryptoFault;

  /// Returns whether decrypted key material is actively resident in volatile RAM.
  bool get isKeyMaterialInMemory => this == CryptoEngineStateEnum.masterKeyUnwrappedInRam;

  /// Returns whether a cryptographic mutation or unwrapping operation is actively in progress.
  bool get isTransitioning =>
      this == CryptoEngineStateEnum.unwrappingMasterKey ||
      this == CryptoEngineStateEnum.rotatingWrappingKey ||
      this == CryptoEngineStateEnum.purgingAllVaultData;

  /// Returns whether the engine is in a faulted state requiring recovery.
  bool get isFaulted => this == CryptoEngineStateEnum.cryptoFault;

  /// Returns whether the vault keys are dormant and wrapped at rest.
  bool get isAtRest => this == CryptoEngineStateEnum.keyWrappedAtRest;

  /// Returns whether the vault has never been provisioned with credentials.
  bool get isUnprovisioned => this == CryptoEngineStateEnum.unprovisioned;
}

/// Deeply immutable sealed state hierarchy for Sub-Service 2 (Cryptographic Engine).
@immutable
sealed class CryptoEngineState extends Equatable {
  const CryptoEngineState();

  /// The discriminator enum identifying the state.
  CryptoEngineStateEnum get stateEnum;

  @override
  List<Object?> get props => [];
}

/// Vault has no credentials configured; initial setup required.
@immutable
final class CryptoEngineUnprovisionedState extends CryptoEngineState {
  const CryptoEngineUnprovisionedState();

  @override
  CryptoEngineStateEnum get stateEnum => CryptoEngineStateEnum.unprovisioned;
}

/// MVK is safely wrapped on disk; zero key material in RAM.
@immutable
final class CryptoEngineKeyWrappedAtRestState extends CryptoEngineState {
  const CryptoEngineKeyWrappedAtRestState();

  @override
  CryptoEngineStateEnum get stateEnum => CryptoEngineStateEnum.keyWrappedAtRest;
}

/// Actively unwrapping the MVK using the specified credential slot.
@immutable
final class CryptoEngineUnwrappingMasterKeyState extends CryptoEngineState {
  const CryptoEngineUnwrappingMasterKeyState({
    required this.slot,
  });

  /// The cryptographic slot being unwrapped (Slot 1: PBKDF2, Slot 2: Biometrics).
  final CryptoWrappingSlotEnum slot;

  @override
  CryptoEngineStateEnum get stateEnum => CryptoEngineStateEnum.unwrappingMasterKey;

  @override
  List<Object?> get props => [slot];
}

/// Active AES-256-GCM session key is unwrapped in volatile RAM.
@immutable
final class CryptoEngineMasterKeyUnwrappedInRamState extends CryptoEngineState {
  const CryptoEngineMasterKeyUnwrappedInRamState({
    required this.unwrappedAtMonotonicMs,
  }) : assert(
          unwrappedAtMonotonicMs >= 0,
          'unwrappedAtMonotonicMs must be non-negative',
        );

  /// Timestamp in monotonic milliseconds when the master key was unwrapped.
  final int unwrappedAtMonotonicMs;

  @override
  CryptoEngineStateEnum get stateEnum => CryptoEngineStateEnum.masterKeyUnwrappedInRam;

  @override
  List<Object?> get props => [unwrappedAtMonotonicMs];
}

/// Actively re-wrapping the MVK with new credentials.
@immutable
final class CryptoEngineRotatingWrappingKeyState extends CryptoEngineState {
  const CryptoEngineRotatingWrappingKeyState({
    required this.targetSlot,
  });

  /// The slot being updated during key rotation.
  final CryptoWrappingSlotEnum targetSlot;

  @override
  CryptoEngineStateEnum get stateEnum => CryptoEngineStateEnum.rotatingWrappingKey;

  @override
  List<Object?> get props => [targetSlot];
}

/// Actively shredding and wiping all vault keys, databases, and media files.
@immutable
final class CryptoEnginePurgingAllVaultDataState extends CryptoEngineState {
  const CryptoEnginePurgingAllVaultDataState();

  @override
  CryptoEngineStateEnum get stateEnum => CryptoEngineStateEnum.purgingAllVaultData;
}

/// Cryptographic fault occurred requiring fallback or recovery.
@immutable
final class CryptoEngineCryptoFaultState extends CryptoEngineState {
  const CryptoEngineCryptoFaultState({
    required this.faultReason,
    required this.errorMessage,
  });

  /// The typed root cause of the fault.
  final CryptoFaultReasonEnum faultReason;

  /// Diagnostic error description.
  final String errorMessage;

  @override
  CryptoEngineStateEnum get stateEnum => CryptoEngineStateEnum.cryptoFault;

  @override
  List<Object?> get props => [faultReason, errorMessage];
}
