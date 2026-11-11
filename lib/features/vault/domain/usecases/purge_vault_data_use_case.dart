import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';

/// Parameter carrying confirmation PIN for irrevocable vault data purging.
@immutable
class PurgeVaultDataParams extends Equatable {
  /// The 6-digit confirmation PIN authorizing total vault destruction.
  final String confirmationPin;

  const PurgeVaultDataParams({
    required this.confirmationPin,
  });

  @override
  List<Object?> get props => [confirmationPin];
}

/// Use case interactor coordinating complete cryptographic destruction, metadata purging,
/// isolated media deletion, and in-RAM key zeroization.
@immutable
class PurgeVaultDataUseCase {
  final IVaultAuthService authService;
  final IVaultStorageRepository storageRepository;

  const PurgeVaultDataUseCase({
    required this.authService,
    required this.storageRepository,
  });

  /// Executes vault data purge under the provided [params].
  ///
  /// Enforces:
  /// 1. 6-digit PIN authentication via [IVaultAuthService].
  /// 2. Atomic purge of all vault databases, files, and keys via [IVaultStorageRepository].
  /// 3. Invalidation of persistent lockout deadlines.
  /// 4. Cryptographic zeroization of all session keys from RAM.
  Future<VaultResult<void>> execute(PurgeVaultDataParams params) async {
    final authResult = await authService.authenticateWithPin(
      pin: params.confirmationPin,
    );
    switch (authResult) {
      case final VaultFailureResult<AuthSession> failure:
        return VaultResult.failure(
          VaultAuthFailure(
            'PIN authorization failed for vault purge: ${failure.failure.message}',
            cause: failure.failure.cause,
          ),
        );
      case VaultSuccess<AuthSession>():
        break;
    }

    final purgeResult = await storageRepository.purgeAllVaultData();
    switch (purgeResult) {
      case final VaultFailureResult<void> failure:
        return VaultResult.failure(failure.failure);
      case VaultSuccess<void>():
        break;
    }

    await storageRepository.clearPersistedLockoutDeadline();
    authService.clearSessionKeysFromRam();

    return const VaultResult.success(null);
  }
}
