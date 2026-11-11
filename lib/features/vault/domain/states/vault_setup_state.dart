import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Enumerates the discrete phases of the first-time vault provisioning flow.
enum VaultSetupPhaseEnum {
  /// Awaiting the user to choose a new 6-digit master PIN.
  awaitingNewPin,

  /// First PIN captured; awaiting confirmation re-entry.
  awaitingConfirmation,

  /// PINs matched; enrollment and key provisioning in progress.
  enrollingCredentials,

  /// Confirmation PIN did not match the chosen PIN; will reset to phase 1.
  pinMismatch,

  /// Enrollment completed successfully; vault is provisioned.
  complete,

  /// Enrollment failed due to a cryptographic or storage error.
  enrollmentFailed;

  /// Whether the keypad should accept user digit input in this phase.
  bool get isAcceptingInput =>
      this == VaultSetupPhaseEnum.awaitingNewPin ||
      this == VaultSetupPhaseEnum.awaitingConfirmation;
}

/// Deeply immutable sealed state hierarchy for the first-time vault setup flow.
///
/// Governs the two-phase PIN creation (choose then confirm), credential enrollment
/// via [IVaultAuthService.enrollInitialCredentials], and error recovery.
/// Zero loose boolean flags. Each state subclass carries only the exact fields
/// valid for that lifecycle phase.
@immutable
sealed class VaultSetupState extends Equatable {
  const VaultSetupState();

  /// The active setup phase discriminator.
  VaultSetupPhaseEnum get phase;

  @override
  List<Object?> get props => [];
}

/// Phase 1: Awaiting the user to choose a new 6-digit master PIN.
@immutable
final class SetupAwaitingNewPinState extends VaultSetupState {
  const SetupAwaitingNewPinState();

  @override
  VaultSetupPhaseEnum get phase => VaultSetupPhaseEnum.awaitingNewPin;
}

/// Phase 2: First PIN captured; awaiting confirmation re-entry.
@immutable
final class SetupAwaitingConfirmationState extends VaultSetupState {
  const SetupAwaitingConfirmationState();

  @override
  VaultSetupPhaseEnum get phase => VaultSetupPhaseEnum.awaitingConfirmation;
}

/// PINs matched; enrollment and key provisioning in progress.
@immutable
final class SetupEnrollingCredentialsState extends VaultSetupState {
  const SetupEnrollingCredentialsState();

  @override
  VaultSetupPhaseEnum get phase => VaultSetupPhaseEnum.enrollingCredentials;
}

/// Confirmation PIN did not match the chosen PIN.
@immutable
final class SetupPinMismatchState extends VaultSetupState {
  const SetupPinMismatchState();

  @override
  VaultSetupPhaseEnum get phase => VaultSetupPhaseEnum.pinMismatch;
}

/// Enrollment completed successfully; vault is provisioned and authenticated.
@immutable
final class SetupCompleteState extends VaultSetupState {
  const SetupCompleteState();

  @override
  VaultSetupPhaseEnum get phase => VaultSetupPhaseEnum.complete;
}

/// Enrollment failed due to a cryptographic or storage error.
@immutable
final class SetupEnrollmentFailedState extends VaultSetupState {
  /// Structured error message from the enrollment subsystem.
  final String errorMessage;

  const SetupEnrollmentFailedState({
    required this.errorMessage,
  });

  @override
  VaultSetupPhaseEnum get phase => VaultSetupPhaseEnum.enrollmentFailed;

  @override
  List<Object?> get props => [errorMessage];
}
