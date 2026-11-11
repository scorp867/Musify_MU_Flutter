import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/states/vault_setup_state.dart';

/// First-time vault provisioning state machine (cubit).
///
/// Manages the two-phase PIN creation flow:
///   [SetupAwaitingNewPinState] -> [SetupAwaitingConfirmationState]
///     -> [SetupEnrollingCredentialsState] -> [SetupCompleteState]
///     or -> [SetupPinMismatchState] -> [SetupAwaitingNewPinState]
///
/// The chosen PIN is stored internally and never exposed in emitted states.
/// Upon confirmation match, enrolls initial credentials (MVK provisioning,
/// PBKDF2 Slot 1 wrapping, canonical V-shape gesture storage) via
/// [IVaultAuthService.enrollInitialCredentials].
///
/// Zero loose boolean flags. Concurrency is naturally serialized by cubit
/// single-emission semantics.
class VaultSetupCubit extends Cubit<VaultSetupState> {
  final IVaultAuthService _authService;

  /// Internally held chosen PIN from phase 1. Never exposed in state.
  String? _chosenPin;

  /// Retained copy of the PIN after successful enrollment, used for auto-authentication.
  /// Cleared on [close].
  String? _lastEnrolledPin;

  VaultSetupCubit({
    required IVaultAuthService authService,
  })  : _authService = authService,
        super(const SetupAwaitingNewPinState());

  /// Returns the PIN that was used for the last successful enrollment.
  /// Available only between [SetupCompleteState] emission and [close].
  String? get lastEnrolledPin => _lastEnrolledPin;

  /// Called by the [PinPadCubit]'s [customPinSubmitter] when 6 digits are entered.
  ///
  /// Returns [VaultResult] to drive [PinPadCubit] state transitions:
  /// - [VaultSuccess] triggers [PinPadSuccessState] (phase 1 capture or enrollment success).
  /// - [VaultFailureResult] triggers [PinPadFailureShakeState] (mismatch or enrollment error).
  Future<VaultResult<dynamic>> handlePinSubmission(String pin) async {
    switch (state) {
      case SetupAwaitingNewPinState():
        _chosenPin = pin;
        emit(const SetupAwaitingConfirmationState());
        return const VaultResult.success(null);

      case SetupAwaitingConfirmationState():
        if (pin != _chosenPin) {
          _chosenPin = null;
          emit(const SetupPinMismatchState());
          return const VaultResult.failure(
            VaultAuthFailure(
              'PINs do not match. Please start over.',
              remainingAttempts: 99,
            ),
          );
        }

        emit(const SetupEnrollingCredentialsState());

        final enrollResult = await _authService.enrollInitialCredentials(
          pin: pin,
          template: DefaultGestureTemplate.canonicalVShape,
        );

        if (isClosed) {
          return const VaultResult.failure(
            VaultStorageFailure('Setup cubit closed during enrollment.'),
          );
        }

        switch (enrollResult) {
          case VaultSuccess<void>():
            _lastEnrolledPin = pin;
            emit(const SetupCompleteState());
            return const VaultResult.success(null);
          case VaultFailureResult<void>(:final failure):
            _chosenPin = null;
            emit(SetupEnrollmentFailedState(errorMessage: failure.message));
            return VaultResult.failure(failure);
        }

      case SetupEnrollingCredentialsState():
        return const VaultResult.failure(
          VaultValidationFailure('Enrollment already in progress.'),
        );

      case SetupPinMismatchState():
      case SetupCompleteState():
      case SetupEnrollmentFailedState():
        return const VaultResult.failure(
          VaultValidationFailure('Invalid setup phase for PIN submission.'),
        );
    }
  }

  /// Resets the setup flow back to phase 1 (choose new PIN).
  ///
  /// Called after a mismatch error or enrollment failure so the user can retry.
  void resetToNewPin() {
    _chosenPin = null;
    emit(const SetupAwaitingNewPinState());
  }

  @override
  Future<void> close() {
    _chosenPin = null;
    _lastEnrolledPin = null;
    return super.close();
  }
}
