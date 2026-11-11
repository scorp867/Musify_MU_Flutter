import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';

/// Parameter carrying current and newly proposed PINs for PIN rotation.
@immutable
class RotatePinParams extends Equatable {
  /// The user's active 6-digit PIN.
  final String oldPin;

  /// The newly chosen 6-digit replacement PIN.
  final String newPin;

  const RotatePinParams({
    required this.oldPin,
    required this.newPin,
  });

  @override
  List<Object?> get props => [oldPin, newPin];
}

/// Use case interactor coordinating PIN credential rotation, format validation,
/// distinctness invariant enforcement, and PBKDF2 Master Vault Key re-wrapping.
@immutable
class RotatePinUseCase {
  final IVaultAuthService authService;

  const RotatePinUseCase({
    required this.authService,
  });

  /// Executes PIN rotation under the provided [params].
  ///
  /// Validates that both old and new PINs consist of exactly 6 numeric digits,
  /// enforces that the new PIN differs from the current PIN, and delegates
  /// key re-wrapping to [IVaultAuthService].
  Future<VaultResult<void>> execute(RotatePinParams params) async {
    if (!_isSixDigitNumeric(params.oldPin)) {
      return const VaultResult.failure(
        VaultValidationFailure('Current PIN must consist of exactly 6 numeric digits.'),
      );
    }
    if (!_isSixDigitNumeric(params.newPin)) {
      return const VaultResult.failure(
        VaultValidationFailure('New PIN must consist of exactly 6 numeric digits.'),
      );
    }
    if (params.oldPin == params.newPin) {
      return const VaultResult.failure(
        VaultValidationFailure('New PIN must differ from current PIN.'),
      );
    }

    return await authService.rotatePin(
      oldPin: params.oldPin,
      newPin: params.newPin,
    );
  }

  static bool _isSixDigitNumeric(String pin) {
    if (pin.length != 6) {
      return false;
    }
    for (var i = 0; i < pin.length; i++) {
      final codeUnit = pin.codeUnitAt(i);
      if (codeUnit < 48 || codeUnit > 57) {
        return false;
      }
    }
    return true;
  }
}
