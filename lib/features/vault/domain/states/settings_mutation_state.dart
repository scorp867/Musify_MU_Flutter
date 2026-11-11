import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Governs reading, updating, step-up authentication, and persistence of VaultConfig.
enum SettingsMutationStateEnum {
  /// Configuration safely loaded and idle.
  syncedIdle,

  /// Sensitive mutation requested; awaiting step-up re-authentication.
  awaitingStepUpAuth,

  /// Validating, mutating, and encrypting updated VaultConfig to disk.
  persistingConfig,

  /// Validation or step-up authentication failed; reverted to last known good configuration.
  mutationRejected;

  /// Returns whether the settings engine is idle and synced.
  bool get isIdle => this == SettingsMutationStateEnum.syncedIdle;

  /// Returns whether a mutation is waiting for step-up PIN/Biometric verification.
  bool get isAwaitingStepUp => this == SettingsMutationStateEnum.awaitingStepUpAuth;

  /// Returns whether configuration changes are actively being persisted to disk.
  bool get isPersisting => this == SettingsMutationStateEnum.persistingConfig;

  /// Returns whether the last mutation request was rejected.
  bool get isRejected => this == SettingsMutationStateEnum.mutationRejected;
}

/// Categorizes the sensitive configuration setting being mutated.
enum SensitiveSettingMutationEnum {
  /// 6-digit PIN rotation requiring step-up authentication.
  pinRotation,

  /// Enabling or disabling biometric authentication policy.
  biometricPolicyChange,

  /// Re-enrolling or modifying master single-stroke stealth gesture.
  gestureReEnrollment,

  /// Altering active re-auth interval or background grace timeout policies.
  securityTimeoutChange,

  /// Irreversible deletion of all vault keys, metadata, and media files.
  vaultDataPurge,

  /// General non-sensitive policy update (e.g. theme palette, decoy persona text).
  generalConfigUpdate,
}

/// Deeply immutable sealed state hierarchy for Sub-Service 5 (Vault Settings & Mutation Controller).
@immutable
sealed class SettingsMutationState extends Equatable {
  const SettingsMutationState();

  /// The active mutation state discriminator.
  SettingsMutationStateEnum get stateEnum;

  @override
  List<Object?> get props => [];
}

/// Configuration is synchronized and idle.
@immutable
final class SettingsMutationSyncedIdleState extends SettingsMutationState {
  const SettingsMutationSyncedIdleState();

  @override
  SettingsMutationStateEnum get stateEnum => SettingsMutationStateEnum.syncedIdle;
}

/// Sensitive setting mutation requires step-up authentication before proceeding.
@immutable
final class SettingsMutationAwaitingStepUpAuthState extends SettingsMutationState {
  const SettingsMutationAwaitingStepUpAuthState({
    required this.mutationType,
    required this.requestedAtMonotonicMs,
  }) : assert(
          requestedAtMonotonicMs >= 0,
          'requestedAtMonotonicMs must be non-negative',
        );

  /// The specific setting type requiring step-up verification.
  final SensitiveSettingMutationEnum mutationType;

  /// Monotonic timestamp when step-up verification was requested.
  final int requestedAtMonotonicMs;

  @override
  SettingsMutationStateEnum get stateEnum => SettingsMutationStateEnum.awaitingStepUpAuth;

  @override
  List<Object?> get props => [mutationType, requestedAtMonotonicMs];
}

/// Validating, encrypting, and writing updated VaultConfig to secure storage.
@immutable
final class SettingsMutationPersistingConfigState extends SettingsMutationState {
  const SettingsMutationPersistingConfigState({
    required this.mutationType,
  });

  /// The type of configuration change currently being persisted.
  final SensitiveSettingMutationEnum mutationType;

  @override
  SettingsMutationStateEnum get stateEnum => SettingsMutationStateEnum.persistingConfig;

  @override
  List<Object?> get props => [mutationType];
}

/// Mutation was rejected due to failed validation, authentication, or disk error.
@immutable
final class SettingsMutationMutationRejectedState extends SettingsMutationState {
  const SettingsMutationMutationRejectedState({
    required this.mutationType,
    required this.rejectionReason,
  });

  /// The type of configuration change that was rejected.
  final SensitiveSettingMutationEnum mutationType;

  /// Explanatory message indicating why the mutation was rejected.
  final String rejectionReason;

  @override
  SettingsMutationStateEnum get stateEnum => SettingsMutationStateEnum.mutationRejected;

  @override
  List<Object?> get props => [mutationType, rejectionReason];
}
