import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';

/// Parameter carrying current and proposed vault configuration alongside optional step-up PIN.
@immutable
class MutateVaultConfigParams extends Equatable {
  /// Active configuration before mutation.
  final VaultConfig currentConfig;

  /// Proposed updated configuration.
  final VaultConfig newConfig;

  /// 6-digit authorization PIN required if sensitive security policies are modified.
  final String? stepUpPin;

  const MutateVaultConfigParams({
    required this.currentConfig,
    required this.newConfig,
    this.stepUpPin,
  });

  @override
  List<Object?> get props => [currentConfig, newConfig, stepUpPin];
}

/// Use case interactor coordinating vault configuration mutation, step-up authorization
/// for sensitive policy modifications, persona invariant checks, and persistence.
@immutable
class MutateVaultConfigUseCase {
  final IVaultAuthService authService;
  final IVaultStorageRepository storageRepository;

  const MutateVaultConfigUseCase({
    required this.authService,
    required this.storageRepository,
  });

  /// Executes vault configuration mutation under the provided [params].
  ///
  /// Checks whether sensitive policies (`biometricAuth`) are being mutated.
  /// If so, enforces step-up PIN authentication.
  /// General preferences (`screenSecurity`, `activeReauthInterval`, `backgroundGraceTimeout`,
  /// `themePalette`, `decoyPersona`, `metadataMasking`, `lockPlaybackBehavior`, `keypadLayout`,
  /// `gestureSensitivityTier`, `gestureVisibilityPolicy`) persist directly without step-up PIN.
  /// Validates non-empty decoy persona metadata and persists the configuration.
  Future<VaultResult<VaultConfig>> execute(MutateVaultConfigParams params) async {
    final hasSensitiveMutation =
        params.newConfig.biometricAuth != params.currentConfig.biometricAuth;

    if (hasSensitiveMutation) {
      final pin = params.stepUpPin;
      if (pin == null) {
        return const VaultResult.failure(
          VaultAuthFailure('Step-up PIN is required to mutate sensitive security policies.'),
        );
      }

      final authResult = await authService.authenticateWithPin(pin: pin);
      switch (authResult) {
        case final VaultFailureResult<AuthSession> failure:
          return VaultResult.failure(
            VaultAuthFailure(
              'Step-up authentication failed: ${failure.failure.message}',
              cause: failure.failure.cause,
            ),
          );
        case VaultSuccess<AuthSession>():
          break;
      }
    }

    if (params.newConfig.decoyTitle.trim().isEmpty) {
      return const VaultResult.failure(
        VaultValidationFailure('Decoy title must not be empty.'),
      );
    }
    if (params.newConfig.decoyArtist.trim().isEmpty) {
      return const VaultResult.failure(
        VaultValidationFailure('Decoy artist must not be empty.'),
      );
    }
    if (params.newConfig.decoyAlbum.trim().isEmpty) {
      return const VaultResult.failure(
        VaultValidationFailure('Decoy album must not be empty.'),
      );
    }

    final saveResult = await storageRepository.saveVaultConfig(params.newConfig);
    switch (saveResult) {
      case final VaultFailureResult<void> failure:
        return VaultResult.failure(failure.failure);
      case VaultSuccess<void>():
        break;
    }

    return VaultResult.success(params.newConfig);
  }
}
