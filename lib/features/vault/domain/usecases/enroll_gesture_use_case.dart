import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';

/// Parameter carrying recorded gesture stroke samples and authorization PIN for enrollment.
@immutable
class EnrollGestureParams extends Equatable {
  /// Exactly 3 recorded gesture stroke samples.
  final List<GestureSample> samples;

  /// User's 6-digit PIN authorizing credential enrollment.
  final String authorizationPin;

  const EnrollGestureParams({
    required this.samples,
    required this.authorizationPin,
  });

  @override
  List<Object?> get props => [samples, authorizationPin];
}

/// Use case interactor coordinating gesture stroke enrollment, sample consistency verification,
/// DTW Barycenter Averaging template synthesis, and secure persistence.
@immutable
class EnrollGestureUseCase {
  final IVaultAuthService authService;
  final IGestureRecognizer recognizer;
  final IVaultStorageRepository storageRepository;

  const EnrollGestureUseCase({
    required this.authService,
    required this.recognizer,
    required this.storageRepository,
  });

  /// Executes gesture credential enrollment under the provided [params].
  ///
  /// Enforces:
  /// 1. Exactly 3 recorded stroke samples.
  /// 2. Valid PIN authentication via [IVaultAuthService].
  /// 3. Pairwise consistency validation via [IGestureRecognizer].
  /// 4. Master template synthesis via [IGestureRecognizer].
  /// 5. Persistence via [IVaultStorageRepository].
  Future<VaultResult<GestureTemplate>> execute(EnrollGestureParams params) async {
    if (params.samples.length != 3) {
      return const VaultResult.failure(
        VaultValidationFailure('Exactly 3 gesture samples are required for enrollment.'),
      );
    }

    final pinResult = await authService.authenticateWithPin(
      pin: params.authorizationPin,
    );
    switch (pinResult) {
      case final VaultFailureResult<AuthSession> failure:
        return VaultResult.failure(
          VaultAuthFailure(
            'PIN authorization failed for gesture enrollment: ${failure.failure.message}',
            cause: failure.failure.cause,
          ),
        );
      case VaultSuccess<AuthSession>():
        break;
    }

    final consistencyResult = await recognizer.validateSampleConsistency(
      samples: params.samples,
    );
    switch (consistencyResult) {
      case final VaultFailureResult<void> failure:
        return VaultResult.failure(failure.failure);
      case VaultSuccess<void>():
        break;
    }

    final synthesisResult = await recognizer.synthesizeMasterTemplate(
      samples: params.samples,
    );
    final GestureTemplate template;
    switch (synthesisResult) {
      case final VaultFailureResult<GestureTemplate> failure:
        return VaultResult.failure(failure.failure);
      case final VaultSuccess<GestureTemplate> success:
        template = success.data;
    }

    final saveResult = await storageRepository.saveGestureTemplate(template);
    switch (saveResult) {
      case final VaultFailureResult<void> failure:
        return VaultResult.failure(failure.failure);
      case VaultSuccess<void>():
        break;
    }

    return VaultResult.success(template);
  }
}
