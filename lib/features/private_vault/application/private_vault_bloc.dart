import 'dart:async';
import 'dart:collection';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:musify_mu/features/private_vault/domain/models/gesture_pattern.dart';
import 'package:musify_mu/features/private_vault/domain/models/private_playlist.dart';
import 'package:musify_mu/features/private_vault/domain/models/vault_settings.dart';
import 'package:musify_mu/features/private_vault/domain/repositories/i_vault_storage_service.dart';
import 'package:musify_mu/features/private_vault/domain/services/i_gesture_recognizer_service.dart';
import 'package:musify_mu/features/private_vault/domain/services/i_native_security_channel.dart';
import 'package:musify_mu/features/private_vault/domain/services/i_vault_auth_service.dart';
import 'package:uuid/uuid.dart';

// ============================================================================
// ENUMS & FAILURE CODES
// ============================================================================

enum VaultFailureReason {
  authenticationFailed,
  biometricsNotAvailable,
  storageDecryptionFailed,
  storageCorrupted,
  playlistNotFound,
  duplicatePlaylistName,
  invalidTrackUri,
  gestureNotEnrolled,
  gestureMismatch,
  platformChannelUnavailable,
}

// ============================================================================
// SEALED EVENT HIERARCHY
// ============================================================================

sealed class PrivateVaultEvent extends Equatable {
  const PrivateVaultEvent();

  @override
  List<Object?> get props => [];
}

final class VaultGestureStrokeReceived extends PrivateVaultEvent {
  final List<Offset> strokePoints;
  final Size canvasSize;

  VaultGestureStrokeReceived({
    required List<Offset> strokePoints,
    required this.canvasSize,
  }) : strokePoints = List<Offset>.unmodifiable(strokePoints);

  @override
  List<Object?> get props => [strokePoints, canvasSize];
}

final class VaultAuthRequested extends PrivateVaultEvent {
  const VaultAuthRequested();
}

final class VaultLockRequested extends PrivateVaultEvent {
  const VaultLockRequested();
}

final class VaultScreenExited extends PrivateVaultEvent {
  const VaultScreenExited();
}

final class VaultStandbyExpired extends PrivateVaultEvent {
  const VaultStandbyExpired();
}

final class VaultPlaylistCreateRequested extends PrivateVaultEvent {
  final String name;
  final String? description;

  const VaultPlaylistCreateRequested({
    required this.name,
    this.description,
  });

  @override
  List<Object?> get props => [name, description];
}

final class VaultPlaylistDeleteRequested extends PrivateVaultEvent {
  final String playlistId;

  const VaultPlaylistDeleteRequested({required this.playlistId});

  @override
  List<Object?> get props => [playlistId];
}

final class VaultTrackAddRequested extends PrivateVaultEvent {
  final String playlistId;
  final String trackUri;

  const VaultTrackAddRequested({
    required this.playlistId,
    required this.trackUri,
  });

  @override
  List<Object?> get props => [playlistId, trackUri];
}

final class VaultTrackRemoveRequested extends PrivateVaultEvent {
  final String playlistId;
  final String trackUri;

  const VaultTrackRemoveRequested({
    required this.playlistId,
    required this.trackUri,
  });

  @override
  List<Object?> get props => [playlistId, trackUri];
}

final class VaultSettingsUpdateRequested extends PrivateVaultEvent {
  final VaultSettings newSettings;

  const VaultSettingsUpdateRequested({required this.newSettings});

  @override
  List<Object?> get props => [newSettings];
}

final class VaultGestureEnrollmentRequested extends PrivateVaultEvent {
  final GesturePattern newPattern;

  const VaultGestureEnrollmentRequested({required this.newPattern});

  @override
  List<Object?> get props => [newPattern];
}

final class VaultLifecycleAppPaused extends PrivateVaultEvent {
  final DateTime pausedAt;

  const VaultLifecycleAppPaused({required this.pausedAt});

  @override
  List<Object?> get props => [pausedAt];
}

final class VaultLifecycleAppResumed extends PrivateVaultEvent {
  final DateTime resumedAt;

  const VaultLifecycleAppResumed({required this.resumedAt});

  @override
  List<Object?> get props => [resumedAt];
}

// ============================================================================
// SEALED STATE HIERARCHY
// ============================================================================

sealed class PrivateVaultState extends Equatable {
  final VaultSettings settings;

  const PrivateVaultState({required this.settings});

  @override
  List<Object?> get props => [settings];
}

/// 1. Vault is fully locked: keys purged from RAM, FLAG_SECURE disabled.
final class VaultStateLocked extends PrivateVaultState {
  const VaultStateLocked({super.settings = VaultSettings.defaultSettings});
}

/// 2. Biometric prompt is actively awaiting credentials.
final class VaultStateAuthenticating extends PrivateVaultState {
  const VaultStateAuthenticating({required super.settings});
}

/// 3. Vault is active: user is actively viewing/editing private playlists.
final class VaultStateActive extends PrivateVaultState {
  final List<PrivatePlaylist> playlists;

  VaultStateActive({
    required List<PrivatePlaylist> playlists,
    required super.settings,
  }) : playlists = UnmodifiableListView(playlists);

  VaultStateActive copyWith({
    List<PrivatePlaylist>? playlists,
    VaultSettings? settings,
  }) {
    return VaultStateActive(
      playlists: playlists ?? this.playlists,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [playlists, settings];
}

/// Typedef providing backwards compatibility with existing UI listeners and tests.
typedef VaultStateUnlocked = VaultStateActive;

/// 4. Vault is in standby: user exited the vault screen, but cool-off window is active.
/// Drawing the secret gesture in this state returns immediately to VaultStateActive without biometrics!
final class VaultStateStandby extends PrivateVaultState {
  final List<PrivatePlaylist> cachedPlaylists;

  VaultStateStandby({
    required List<PrivatePlaylist> cachedPlaylists,
    required super.settings,
  }) : cachedPlaylists = UnmodifiableListView(cachedPlaylists);

  @override
  List<Object?> get props => [cachedPlaylists, settings];
}

/// 5. Failure state.
final class VaultStateFailure extends PrivateVaultState {
  final VaultFailureReason reason;
  final String technicalMessage;

  const VaultStateFailure({
    required this.reason,
    required this.technicalMessage,
    required super.settings,
  });

  @override
  List<Object?> get props => [reason, technicalMessage, settings];
}

// ============================================================================
// REACTIVE BLOC IMPLEMENTATION
// ============================================================================

final class PrivateVaultBloc extends Bloc<PrivateVaultEvent, PrivateVaultState> {
  final IVaultStorageService _storageService;
  final IVaultAuthService _authService;
  final INativeSecurityChannel _securityChannel;
  final IGestureRecognizerService _gestureRecognizer;
  final Uuid _uuid;
  Timer? _standbyTimer;

  PrivateVaultBloc({
    required IVaultStorageService storageService,
    required IVaultAuthService authService,
    required INativeSecurityChannel securityChannel,
    required IGestureRecognizerService gestureRecognizer,
    Uuid? uuid,
  })  : _storageService = storageService,
        _authService = authService,
        _securityChannel = securityChannel,
        _gestureRecognizer = gestureRecognizer,
        _uuid = uuid ?? const Uuid(),
        super(const VaultStateLocked(settings: VaultSettings.defaultSettings)) {
    // Concurrency: restartable for gestures and auth
    on<VaultGestureStrokeReceived>(_onGestureReceived, transformer: restartable());
    on<VaultAuthRequested>(_onAuthRequested, transformer: droppable());
    on<VaultLockRequested>(_onLockRequested, transformer: sequential());

    // Navigation and standby session lifecycle
    on<VaultScreenExited>(_onScreenExited, transformer: sequential());
    on<VaultStandbyExpired>(_onStandbyExpired, transformer: sequential());

    // Concurrency: sequential for data mutations
    on<VaultPlaylistCreateRequested>(_onPlaylistCreate, transformer: sequential());
    on<VaultPlaylistDeleteRequested>(_onPlaylistDelete, transformer: sequential());
    on<VaultTrackAddRequested>(_onTrackAdd, transformer: sequential());
    on<VaultTrackRemoveRequested>(_onTrackRemove, transformer: sequential());
    on<VaultSettingsUpdateRequested>(_onSettingsUpdate, transformer: sequential());
    on<VaultGestureEnrollmentRequested>(_onGestureEnroll, transformer: sequential());

    // OS Lifecycle events
    on<VaultLifecycleAppPaused>(_onAppPaused, transformer: sequential());
    on<VaultLifecycleAppResumed>(_onAppResumed, transformer: sequential());
  }

  void _startStandbyTimer(Duration duration) {
    _standbyTimer?.cancel();
    _standbyTimer = Timer(duration, () {
      add(const VaultStandbyExpired());
    });
  }

  void _cancelStandbyTimer() {
    _standbyTimer?.cancel();
    _standbyTimer = null;
  }

  @override
  Future<void> close() {
    _cancelStandbyTimer();
    return super.close();
  }

  Future<void> _onGestureReceived(
    VaultGestureStrokeReceived event,
    Emitter<PrivateVaultState> emit,
  ) async {
    final template = await _storageService.loadGesturePattern();
    final result = _gestureRecognizer.evaluate(
      rawPoints: event.strokePoints,
      canvasSize: event.canvasSize,
      template: template,
    );

    if (result != GestureRecognitionStatus.matched) {
      return;
    }

    // Pattern matched: trigger haptic feedback immediately
    HapticFeedback.mediumImpact();

    switch (state) {
      case final VaultStateStandby standby:
        // Cool-off session is active: go straight into VaultStateActive without biometrics!
        _cancelStandbyTimer();
        emit(VaultStateActive(
          playlists: standby.cachedPlaylists,
          settings: standby.settings,
        ));

      case VaultStateLocked():
        // Fully locked: prompt for biometric authentication
        add(const VaultAuthRequested());

      case VaultStateAuthenticating():
      case VaultStateActive():
      case VaultStateFailure():
        // Already active or in progress
        break;
    }
  }

  Future<void> _onAuthRequested(
    VaultAuthRequested event,
    Emitter<PrivateVaultState> emit,
  ) async {
    final currentSettings = state.settings;
    emit(VaultStateAuthenticating(settings: currentSettings));

    final authStatus = await _authService.authenticate(
      localizedReason: 'Authenticate to access Private Vault',
    );

    switch (authStatus) {
      case BiometricAuthStatus.success:
        try {
          final playlists = await _storageService.loadPlaylists();
          final settings = await _storageService.loadSettings();

          if (settings.preventScreenshots) {
            await _securityChannel.setFlagSecure(enabled: true);
          }

          emit(VaultStateActive(
            playlists: playlists,
            settings: settings,
          ));
        } catch (e) {
          emit(VaultStateFailure(
            reason: VaultFailureReason.storageDecryptionFailed,
            technicalMessage: e.toString(),
            settings: currentSettings,
          ));
        }

      case BiometricAuthStatus.canceled:
      case BiometricAuthStatus.failed:
      case BiometricAuthStatus.notAvailableOrEnrolled:
      case BiometricAuthStatus.notRequested:
      case BiometricAuthStatus.authenticating:
        emit(VaultStateLocked(settings: currentSettings));
    }
  }

  Future<void> _onScreenExited(
    VaultScreenExited event,
    Emitter<PrivateVaultState> emit,
  ) async {
    if (state case final VaultStateActive active) {
      if (active.settings.coolOffDuration == CoolOffDuration.immediate) {
        // Immediate lock
        if (active.settings.preventScreenshots) {
          await _securityChannel.setFlagSecure(enabled: false);
        }
        _storageService.purgeDecryptedMemory();
        emit(VaultStateLocked(settings: active.settings));
      } else {
        // Transition to Standby with cool-off countdown
        _cancelStandbyTimer();
        emit(VaultStateStandby(
          cachedPlaylists: active.playlists,
          settings: active.settings,
        ));
        _startStandbyTimer(active.settings.coolOffDuration.duration);
      }
    }
  }

  Future<void> _onStandbyExpired(
    VaultStandbyExpired event,
    Emitter<PrivateVaultState> emit,
  ) async {
    if (state case final VaultStateStandby standby) {
      if (standby.settings.preventScreenshots) {
        await _securityChannel.setFlagSecure(enabled: false);
      }
      _storageService.purgeDecryptedMemory();
      emit(VaultStateLocked(settings: standby.settings));
    }
  }

  Future<void> _onLockRequested(
    VaultLockRequested event,
    Emitter<PrivateVaultState> emit,
  ) async {
    _cancelStandbyTimer();
    if (state.settings.preventScreenshots) {
      await _securityChannel.setFlagSecure(enabled: false);
    }
    _storageService.purgeDecryptedMemory();
    emit(VaultStateLocked(settings: state.settings));
  }

  Future<void> _onPlaylistCreate(
    VaultPlaylistCreateRequested event,
    Emitter<PrivateVaultState> emit,
  ) async {
    if (state case final VaultStateActive active) {
      final trimmedName = event.name.trim();
      if (trimmedName.isEmpty) {
        return;
      }

      // Ensure no duplicate names
      final duplicate = active.playlists.any(
        (p) => p.name.toLowerCase() == trimmedName.toLowerCase(),
      );
      if (duplicate) {
        emit(VaultStateFailure(
          reason: VaultFailureReason.duplicatePlaylistName,
          technicalMessage: 'A playlist named "$trimmedName" already exists in the vault',
          settings: active.settings,
        ));
        // Return to active state immediately
        emit(active);
        return;
      }

      final now = DateTime.now();
      final newPlaylist = PrivatePlaylist(
        id: _uuid.v4(),
        name: trimmedName,
        description: event.description,
        createdAt: now,
        updatedAt: now,
        trackUris: const <String>[],
      );

      final updatedPlaylists = [
        newPlaylist,
        ...active.playlists,
      ];

      await _storageService.savePlaylists(updatedPlaylists);

      emit(active.copyWith(playlists: updatedPlaylists));
    }
  }

  Future<void> _onPlaylistDelete(
    VaultPlaylistDeleteRequested event,
    Emitter<PrivateVaultState> emit,
  ) async {
    if (state case final VaultStateActive active) {
      final updatedPlaylists = active.playlists
          .where((p) => p.id != event.playlistId)
          .toList(growable: false);

      await _storageService.savePlaylists(updatedPlaylists);

      emit(active.copyWith(playlists: updatedPlaylists));
    }
  }

  Future<void> _onTrackAdd(
    VaultTrackAddRequested event,
    Emitter<PrivateVaultState> emit,
  ) async {
    if (state case final VaultStateActive active) {
      final index = active.playlists.indexWhere((p) => p.id == event.playlistId);
      if (index == -1) {
        return;
      }

      final playlist = active.playlists[index];
      if (playlist.trackUris.contains(event.trackUri)) {
        return; // Idempotent: track already in private playlist
      }

      final now = DateTime.now();
      final updatedPlaylist = playlist.copyWith(
        trackUris: [...playlist.trackUris, event.trackUri],
        updatedAt: now,
      );

      final updatedList = List<PrivatePlaylist>.from(active.playlists);
      updatedList[index] = updatedPlaylist;

      await _storageService.savePlaylists(updatedList);

      emit(active.copyWith(playlists: updatedList));
    }
  }

  Future<void> _onTrackRemove(
    VaultTrackRemoveRequested event,
    Emitter<PrivateVaultState> emit,
  ) async {
    if (state case final VaultStateActive active) {
      final index = active.playlists.indexWhere((p) => p.id == event.playlistId);
      if (index == -1) {
        return;
      }

      final playlist = active.playlists[index];
      final updatedTrackUris =
          playlist.trackUris.where((uri) => uri != event.trackUri).toList();

      final now = DateTime.now();
      final updatedPlaylist = playlist.copyWith(
        trackUris: updatedTrackUris,
        updatedAt: now,
      );

      final updatedList = List<PrivatePlaylist>.from(active.playlists);
      updatedList[index] = updatedPlaylist;

      await _storageService.savePlaylists(updatedList);

      emit(active.copyWith(playlists: updatedList));
    }
  }

  Future<void> _onSettingsUpdate(
    VaultSettingsUpdateRequested event,
    Emitter<PrivateVaultState> emit,
  ) async {
    await _storageService.saveSettings(event.newSettings);

    if (state case final VaultStateActive active) {
      if (event.newSettings.preventScreenshots != active.settings.preventScreenshots) {
        await _securityChannel.setFlagSecure(
          enabled: event.newSettings.preventScreenshots,
        );
      }
      emit(active.copyWith(settings: event.newSettings));
    } else {
      emit(VaultStateLocked(settings: event.newSettings));
    }
  }

  Future<void> _onGestureEnroll(
    VaultGestureEnrollmentRequested event,
    Emitter<PrivateVaultState> emit,
  ) async {
    await _storageService.saveGesturePattern(event.newPattern);
  }

  Future<void> _onAppPaused(
    VaultLifecycleAppPaused event,
    Emitter<PrivateVaultState> emit,
  ) async {
    if (state case final VaultStateActive active) {
      if (active.settings.coolOffDuration == CoolOffDuration.immediate) {
        if (active.settings.preventScreenshots) {
          await _securityChannel.setFlagSecure(enabled: false);
        }
        _storageService.purgeDecryptedMemory();
        emit(VaultStateLocked(settings: active.settings));
      } else {
        _cancelStandbyTimer();
        emit(VaultStateStandby(
          cachedPlaylists: active.playlists,
          settings: active.settings,
        ));
        _startStandbyTimer(active.settings.coolOffDuration.duration);
      }
    }
  }

  Future<void> _onAppResumed(
    VaultLifecycleAppResumed event,
    Emitter<PrivateVaultState> emit,
  ) async {
    // If standby timer expired while app was paused, state is already VaultStateLocked.
    // If still in VaultStateStandby, it stays in standby until the user draws the gesture.
  }
}
