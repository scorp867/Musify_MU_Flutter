import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/biometric_auth_policy.dart';
import 'package:musify_mu/features/vault/domain/states/settings_mutation_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/mutate_vault_config_use_case.dart';

/// Sub-Service 5: Vault Settings & Mutation Controller.
///
/// Governs reading, updating, debouncing, step-up authentication, and immediate
/// encrypted persistence of [VaultConfig] to Drift SQLite (`vault_config` table).
///
/// Strictly adheres to David Harel's Statechart Automata, Dart 3 sealed classes,
/// non-blocking microtask error recovery, and reactive stream emission to dependent subsystems.
class SettingsMutationCubit extends Cubit<SettingsMutationState> {
  final IVaultStorageRepository _storageRepository;
  final MutateVaultConfigUseCase _mutateVaultConfigUseCase;
  final IVaultAuthService _authService;
  final IMonotonicClock _monotonicClock;

  VaultConfig _lastKnownGoodConfig;
  final StreamController<VaultConfig> _configStreamController;

  Timer? _decoyDebounceTimer;
  String? _pendingDecoyTitle;
  String? _pendingDecoyArtist;
  String? _pendingDecoyAlbum;

  Future<void> _mutationQueue = Future<void>.value();

  SettingsMutationCubit({
    required IVaultStorageRepository storageRepository,
    required MutateVaultConfigUseCase mutateVaultConfigUseCase,
    required IVaultAuthService authService,
    required IMonotonicClock monotonicClock,
    VaultConfig initialConfig = const VaultConfig.constant(),
  })  : _storageRepository = storageRepository,
        _mutateVaultConfigUseCase = mutateVaultConfigUseCase,
        _authService = authService,
        _monotonicClock = monotonicClock,
        _lastKnownGoodConfig = initialConfig,
        _configStreamController = StreamController<VaultConfig>.broadcast(),
        super(const SettingsMutationSyncedIdleState());

  /// The underlying authentication service used for step-up verification.
  IVaultAuthService get authService => _authService;

  /// Broadcast stream of configuration changes for dependent services.
  Stream<VaultConfig> get configStream => _configStreamController.stream;

  /// The active, verified last known good configuration snapshot.
  VaultConfig get currentConfig => _lastKnownGoodConfig;

  /// Initializes the cubit by loading the persisted configuration from storage.
  Future<void> initialize() async {
    final result = await _storageRepository.loadVaultConfig();
    if (isClosed) return;
    switch (result) {
      case VaultSuccess<VaultConfig>(:final data):
        _lastKnownGoodConfig = data;
        if (!_configStreamController.isClosed) {
          _configStreamController.add(_lastKnownGoodConfig);
        }
        emit(const SettingsMutationSyncedIdleState());
      case VaultFailureResult<VaultConfig>():
        emit(const SettingsMutationSyncedIdleState());
    }
  }

  /// Queues asynchronous general mutations into a FIFO sequence to prevent data loss.
  Future<void> _enqueueGeneralMutation(Future<void> Function() action) {
    final completer = Completer<void>();
    _mutationQueue = _mutationQueue.then((_) async {
      if (isClosed) {
        if (!completer.isCompleted) completer.complete();
        return;
      }
      try {
        await action();
        if (!completer.isCompleted) completer.complete();
      } catch (error, stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      }
    }).catchError((Object _) {
      // Keep mutation chain operational across caught errors
    });
    return completer.future;
  }

  /// Updates a general, non-sensitive configuration policy directly.
  ///
  /// Intercepts and rejects sensitive policy changes (`biometricAuth`) that require step-up authentication.
  Future<void> updateGeneralPolicy(VaultConfig updatedConfig) async {
    final hasSensitiveMutation =
        updatedConfig.biometricAuth != _lastKnownGoodConfig.biometricAuth;

    if (hasSensitiveMutation) {
      _rejectMutation(
        mutationType: SensitiveSettingMutationEnum.generalConfigUpdate,
        reason: 'Sensitive policy mutation attempted without step-up authentication.',
      );
      return;
    }

    await _enqueueGeneralMutation(() async {
      if (updatedConfig.biometricAuth != _lastKnownGoodConfig.biometricAuth) {
        _rejectMutation(
          mutationType: SensitiveSettingMutationEnum.generalConfigUpdate,
          reason: 'Sensitive policy mutation attempted without step-up authentication.',
        );
        return;
      }

      await _executeGeneralPolicyUpdate(updatedConfig);
    });
  }

  Future<bool> _executeGeneralPolicyUpdate(VaultConfig updatedConfig) async {
    emit(const SettingsMutationPersistingConfigState(
      mutationType: SensitiveSettingMutationEnum.generalConfigUpdate,
    ));

    final result = await _mutateVaultConfigUseCase.execute(
      MutateVaultConfigParams(
        currentConfig: _lastKnownGoodConfig,
        newConfig: updatedConfig,
        stepUpPin: null,
      ),
    );

    switch (result) {
      case VaultSuccess<VaultConfig>(:final data):
        _lastKnownGoodConfig = data;
        _configStreamController.add(_lastKnownGoodConfig);
        emit(const SettingsMutationSyncedIdleState());
        return true;
      case VaultFailureResult<VaultConfig>(:final failure):
        _rejectMutation(
          mutationType: SensitiveSettingMutationEnum.generalConfigUpdate,
          reason: failure.message,
        );
        return false;
    }
  }

  /// Debounces text input edits for decoy persona metadata by 350ms.
  void updateDecoyPersonaDebounced({
    String? title,
    String? artist,
    String? album,
  }) {
    if (title != null) _pendingDecoyTitle = title;
    if (artist != null) _pendingDecoyArtist = artist;
    if (album != null) _pendingDecoyAlbum = album;

    _decoyDebounceTimer?.cancel();
    _decoyDebounceTimer = Timer(const Duration(milliseconds: 350), () async {
      await flushDecoyPersonaImmediately();
    });
  }

  /// Flushes any pending decoy persona text immediately (e.g. on focus-loss / blur).
  Future<void> flushDecoyPersonaImmediately() async {
    _decoyDebounceTimer?.cancel();
    _decoyDebounceTimer = null;

    if (_pendingDecoyTitle == null &&
        _pendingDecoyArtist == null &&
        _pendingDecoyAlbum == null) {
      return;
    }

    final savedTitle = _pendingDecoyTitle;
    final savedArtist = _pendingDecoyArtist;
    final savedAlbum = _pendingDecoyAlbum;

    final checkTitle = savedTitle ?? _lastKnownGoodConfig.decoyTitle;
    final checkArtist = savedArtist ?? _lastKnownGoodConfig.decoyArtist;
    final checkAlbum = savedAlbum ?? _lastKnownGoodConfig.decoyAlbum;

    if (checkTitle.trim().isEmpty ||
        checkArtist.trim().isEmpty ||
        checkAlbum.trim().isEmpty) {
      _rejectMutation(
        mutationType: SensitiveSettingMutationEnum.generalConfigUpdate,
        reason: 'Decoy persona fields must not be empty or whitespace.',
      );
      return;
    }

    await _enqueueGeneralMutation(() async {
      final targetTitle = savedTitle ?? _lastKnownGoodConfig.decoyTitle;
      final targetArtist = savedArtist ?? _lastKnownGoodConfig.decoyArtist;
      final targetAlbum = savedAlbum ?? _lastKnownGoodConfig.decoyAlbum;

      if (targetTitle.trim().isEmpty ||
          targetArtist.trim().isEmpty ||
          targetAlbum.trim().isEmpty) {
        _rejectMutation(
          mutationType: SensitiveSettingMutationEnum.generalConfigUpdate,
          reason: 'Decoy persona fields must not be empty or whitespace.',
        );
        return;
      }

      final updatedConfig = _lastKnownGoodConfig.copyWith(
        decoyTitle: targetTitle,
        decoyArtist: targetArtist,
        decoyAlbum: targetAlbum,
      );

      final success = await _executeGeneralPolicyUpdate(updatedConfig);
      if (success) {
        if (_pendingDecoyTitle == savedTitle) {
          _pendingDecoyTitle = null;
        }
        if (_pendingDecoyArtist == savedArtist) {
          _pendingDecoyArtist = null;
        }
        if (_pendingDecoyAlbum == savedAlbum) {
          _pendingDecoyAlbum = null;
        }
      }
    });
  }

  /// Requests authorization to execute a sensitive configuration mutation.
  ///
  /// Transitions state to [SettingsMutationAwaitingStepUpAuthState].
  Future<void> requestSensitiveMutation({
    required SensitiveSettingMutationEnum mutationType,
  }) async {
    if (state is SettingsMutationPersistingConfigState) {
      return;
    }

    emit(SettingsMutationAwaitingStepUpAuthState(
      mutationType: mutationType,
      requestedAtMonotonicMs: _monotonicClock.currentMonotonicMs,
    ));
  }

  /// Confirms and executes an authorized sensitive mutation after step-up verification.
  Future<void> confirmSensitiveMutation({
    required SensitiveSettingMutationEnum mutationType,
    required Future<void> Function() onExecute,
  }) async {
    if (state is! SettingsMutationAwaitingStepUpAuthState) {
      _rejectMutation(
        mutationType: mutationType,
        reason: 'Cannot confirm sensitive mutation: not awaiting step-up authentication.',
      );
      return;
    }

    final currentState = state as SettingsMutationAwaitingStepUpAuthState;
    if (currentState.mutationType != mutationType) {
      _rejectMutation(
        mutationType: mutationType,
        reason: 'Mutation type mismatch: expected ${currentState.mutationType}, got $mutationType.',
      );
      return;
    }

    emit(SettingsMutationPersistingConfigState(mutationType: mutationType));

    try {
      await onExecute();
      final reloadResult = await _storageRepository.loadVaultConfig();
      if (reloadResult case VaultSuccess<VaultConfig>(:final data)) {
        _lastKnownGoodConfig = data;
        _configStreamController.add(_lastKnownGoodConfig);
      }
      emit(const SettingsMutationSyncedIdleState());
    } catch (error) {
      _rejectMutation(
        mutationType: mutationType,
        reason: error.toString(),
      );
    }
  }

  /// Directly updates and persists the biometric authentication policy.
  Future<void> applyBiometricPolicy(BiometricAuthPolicyEnum newPolicy) async {
    final updated = _lastKnownGoodConfig.copyWith(biometricAuth: newPolicy);
    await _storageRepository.saveVaultConfig(updated);
    _lastKnownGoodConfig = updated;
    _configStreamController.add(_lastKnownGoodConfig);
  }

  /// Cancels an in-flight sensitive mutation request.
  void cancelSensitiveMutation({
    required SensitiveSettingMutationEnum mutationType,
  }) {
    if (state is! SettingsMutationAwaitingStepUpAuthState) {
      return;
    }

    _rejectMutation(
      mutationType: mutationType,
      reason: 'Step-up authentication cancelled by user.',
    );
  }

  /// Emits [SettingsMutationMutationRejectedState], reverts draft state,
  /// and resets back to [SettingsMutationSyncedIdleState] on the next microtask
  /// only if state is still [SettingsMutationMutationRejectedState].
  void _rejectMutation({
    required SensitiveSettingMutationEnum mutationType,
    required String reason,
  }) {
    emit(SettingsMutationMutationRejectedState(
      mutationType: mutationType,
      rejectionReason: reason,
    ));

    scheduleMicrotask(() {
      if (!isClosed && state is SettingsMutationMutationRejectedState) {
        emit(const SettingsMutationSyncedIdleState());
      }
    });
  }

  @override
  Future<void> close() {
    _decoyDebounceTimer?.cancel();
    _decoyDebounceTimer = null;
    _configStreamController.close();
    return super.close();
  }
}
