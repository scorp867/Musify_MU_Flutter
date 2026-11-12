import 'dart:async';
import 'dart:developer' as dev;

import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/player/domain/commands/stop_command.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/vault/data/strategies/continue_masked_lock_strategy.dart';
import 'package:musify_mu/features/vault/data/strategies/decoy_media_masking_strategy.dart';
import 'package:musify_mu/features/vault/data/strategies/finish_current_track_lock_strategy.dart';
import 'package:musify_mu/features/vault/data/strategies/passthrough_media_masking_strategy.dart';
import 'package:musify_mu/features/vault/data/strategies/stop_immediately_lock_strategy.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_media_masking_strategy.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/states/playback_privacy_mode.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

/// Semantic alias representing the unintercepted idle state of Region B.
typedef PlaybackPrivacyIdleState = PlaybackPrivacyPublicPassthroughState;

/// David Harel Statechart Region B: Playback Privacy Proxy.
///
/// Intercepts outgoing [ContextTrack] metadata and governs playback responses
/// to vault lock/unlock events without duplicating the underlying audio engine.
class PlaybackPrivacyProxy {
  final PlayerQueueMobiusController _mobiusController;
  final IVaultStorageRepository _storageRepository;
  final ContextPlayerControlClient? _controlClient;

  final Map<MetadataVisibilityPolicyEnum, IMediaMaskingStrategy>
  _maskingStrategies;
  final Map<LockPlaybackBehaviorEnum, ILockPlaybackStrategy> _lockStrategies;

  final StreamController<PlaybackPrivacyState> _stateController;
  final List<StreamSubscription<Object?>> _subscriptions;
  final Map<String, ContextTrack> _originalVaultTracks = <String, ContextTrack>{};
  StreamSubscription<VaultConfig>? _configSubscription;

  PlaybackPrivacyState _currentState;
  VaultConfig _cachedConfig;
  bool _isDisposed = false;
  bool _isInitialized = false;

  /// Pure constructor injection. Zero Service Locator calls.
  PlaybackPrivacyProxy({
    required PlayerQueueMobiusController mobiusController,
    required IVaultStorageRepository storageRepository,
    IVaultAuthService? vaultAuthService,
    ContextPlayerControlClient? controlClient,
    Map<MetadataVisibilityPolicyEnum, IMediaMaskingStrategy>? maskingStrategies,
    Map<LockPlaybackBehaviorEnum, ILockPlaybackStrategy>? lockStrategies,
    VaultConfig? initialConfig,
    PlaybackPrivacyState initialPrivacyState =
    const PlaybackPrivacyPublicPassthroughState(),
  })  : _mobiusController = mobiusController,
        _storageRepository = storageRepository,
        _controlClient = controlClient,
        _maskingStrategies = switch (maskingStrategies) {
          final m? => Map.unmodifiable(m),
          null => Map.unmodifiable({
            MetadataVisibilityPolicyEnum.maskWithPlaceholder:
            const DecoyMediaMaskingStrategy(),
            MetadataVisibilityPolicyEnum.showActualMetadata:
            const PassthroughMediaMaskingStrategy(),
          }),
        },
        _lockStrategies = switch (lockStrategies) {
          final l? => Map.unmodifiable(l),
          null => Map.unmodifiable({
            LockPlaybackBehaviorEnum.stopImmediately:
            const StopImmediatelyLockStrategy(),
            LockPlaybackBehaviorEnum.finishCurrentTrack:
            const FinishCurrentTrackLockStrategy(),
            LockPlaybackBehaviorEnum.continueMaskedInBackground:
            const ContinueMaskedLockStrategy(),
          }),
        },
        _cachedConfig = switch (initialConfig) {
          final c? => c,
          null => const VaultConfig.constant(),
        },
        _currentState = initialPrivacyState,
        _stateController = StreamController<PlaybackPrivacyState>.broadcast(),
        _subscriptions = <StreamSubscription<Object?>>[];

  /// Broadcast stream of Region B state transitions.
  Stream<PlaybackPrivacyState> get stateStream => _stateController.stream;

  /// Current immutable Region B state snapshot.
  PlaybackPrivacyState get currentState => _currentState;

  /// Active cached vault configuration.
  VaultConfig get cachedConfig => _cachedConfig;

  /// Whether the proxy has been disposed.
  bool get isDisposed => _isDisposed;

  /// Whether the proxy is currently in the public passthrough idle state.
  bool get isIdle =>
      _currentState is PlaybackPrivacyPublicPassthroughState;

  /// Whether a private vault track is actively playing or paused.
  bool get isVaultTrackActive =>
      _currentState is PlaybackPrivacyVaultTrackActiveState;

  /// Whether a lock playback strategy is actively executing.
  bool get isExecutingLockStrategy =>
      _currentState is PlaybackPrivacyExecutingLockStrategyState;

  /// Whether decoy persona strings are currently being projected.
  bool get isDecoyActive => switch (_currentState) {
    PlaybackPrivacyPublicPassthroughState() => false,
    PlaybackPrivacyVaultTrackActiveState(:final maskingStatus) =>
    maskingStatus == PlaybackMaskingStatusEnum.decoyPersonaProjected,
    PlaybackPrivacyExecutingLockStrategyState() => true,
  };

  /// Initializes subscriptions to [PlayerQueueMobiusController.stream]
  /// and optional [configStream], and loads initial [VaultConfig].
  Future<void> initialize({Stream<VaultConfig>? configStream}) async {
    if (_isDisposed || _isInitialized) return;
    _isInitialized = true;

    final configResult = await _storageRepository.loadVaultConfig();
    if (configResult case VaultSuccess(:final data)) {
      _cachedConfig = data;
    }

    if (configStream != null) {
      bindConfigStream(configStream);
    }

    _subscriptions.add(
      _mobiusController.stream.listen(
        _handlePlayerQueueChange,
        onError: _handleStreamError,
      ),
    );
  }

  /// Dynamically binds a configuration stream to automatically update proxy settings.
  /// Cancels any previous configuration subscription to prevent duplicate listeners.
  void bindConfigStream(Stream<VaultConfig> configStream) {
    if (_isDisposed) return;
    _configSubscription?.cancel();
    final subscription = configStream.listen(
      updateConfig,
      onError: _handleStreamError,
    );
    _configSubscription = subscription;
    _subscriptions.add(subscription);
  }

  /// Updates active [VaultConfig] dynamically and refreshes metadata projection & lock behavior.
  void updateConfig(VaultConfig newConfig) {
    if (_isDisposed) return;
    _cachedConfig = newConfig;

    switch (_currentState) {
      case PlaybackPrivacyVaultTrackActiveState(:final vaultTrackId):
        final newMaskingStatus = switch (_cachedConfig.metadataVisibility) {
          MetadataVisibilityPolicyEnum.maskWithPlaceholder =>
          PlaybackMaskingStatusEnum.decoyPersonaProjected,
          MetadataVisibilityPolicyEnum.showActualMetadata =>
          PlaybackMaskingStatusEnum.unmasked,
        };
        _transitionTo(
          PlaybackPrivacyVaultTrackActiveState(
            vaultTrackId: vaultTrackId,
            maskingStatus: newMaskingStatus,
            visibilityPolicy: _cachedConfig.metadataVisibility,
          ),
        );
        _reprojectActiveQueue();
      case PlaybackPrivacyExecutingLockStrategyState(
          :final activeVaultTrackId,
          :final executingBehavior,
      ):
        final newBehavior = _cachedConfig.lockPlaybackBehavior;
        if (newBehavior != executingBehavior) {
          _transitionTo(
            PlaybackPrivacyExecutingLockStrategyState(
              activeVaultTrackId: activeVaultTrackId,
              executingBehavior: newBehavior,
            ),
          );
          if (newBehavior == LockPlaybackBehaviorEnum.stopImmediately) {
            final controlClient = _resolveControlClient();
            controlClient.stop(const StopCommand());
            _mobiusController.dispatch(const ClearQueueEvent());
            _mobiusController.dispatch(const ResetQueueEvent());
            _transitionTo(const PlaybackPrivacyPublicPassthroughState());
          } else if (newBehavior == LockPlaybackBehaviorEnum.finishCurrentTrack) {
            _mobiusController.dispatch(const ClearQueueEvent());
          }
        }
        _reprojectActiveQueue();
      case PlaybackPrivacyPublicPassthroughState():
        final nowPlaying = _mobiusController.state.nowPlaying;
        if (nowPlaying != null && _isVaultTrack(nowPlaying)) {
          _reprojectActiveQueue();
        }
        break;
    }
  }

  /// Re-projects all vault tracks currently loaded in the active queue to propagate
  /// updated masking or unmasked metadata to the OS MediaSession immediately.
  void _reprojectActiveQueue() {
    final currentQueue = _mobiusController.state.playerQueue;
    final currentTrack = currentQueue.track;
    if (currentTrack != null && _isVaultTrack(currentTrack)) {
      final vaultTrackId = _resolveVaultTrackId(currentTrack);
      final original = switch (_originalVaultTracks[vaultTrackId]) {
        final orig? => orig,
        null => currentTrack,
      };
      final projectedTrack = projectTrack(original);
      final projectedNextTracks = currentQueue.nextTracks.map((t) {
        if (_isVaultTrack(t)) {
          final tId = _resolveVaultTrackId(t);
          final origT = switch (_originalVaultTracks[tId]) {
            final o? => o,
            null => t,
          };
          return projectTrack(origT);
        }
        return t;
      }).toList(growable: false);

      final updatedQueue = currentQueue.toBuilder()
          .track(projectedTrack)
          .nextTracks(projectedNextTracks)
          .build();

      _mobiusController.dispatch(QueueUpdatedEvent(updatedQueue));
    }
  }

  /// Projects [track] into a sanitized or transparent [ContextTrack]
  /// based on the active state and masking strategy.
  ContextTrack projectTrack(ContextTrack track) {
    if (!_isVaultTrack(track)) {
      return track;
    }

    switch (_currentState) {
      case PlaybackPrivacyPublicPassthroughState():
        final strategy =
        _resolveMaskingStrategy(_cachedConfig.metadataVisibility);
        return strategy.projectTrack(
          originalTrack: track,
          config: _cachedConfig,
        );

      case PlaybackPrivacyVaultTrackActiveState(:final visibilityPolicy):
        final strategy = _resolveMaskingStrategy(visibilityPolicy);
        return strategy.projectTrack(
          originalTrack: track,
          config: _cachedConfig,
        );

      case PlaybackPrivacyExecutingLockStrategyState():
        final decoyStrategy = _resolveMaskingStrategy(
          MetadataVisibilityPolicyEnum.maskWithPlaceholder,
        );
        return decoyStrategy.projectTrack(
          originalTrack: track,
          config: _cachedConfig,
        );
    }
  }

  /// Explicit notification from [VaultAudioPlaybackService] when a private track starts.
  void notifyVaultTrackActivated({
    required String vaultTrackId,
    required ContextTrack track,
  }) {
    if (_isDisposed) return;

    if (track.metadata['musify_vault_masked'] != 'true') {
      _originalVaultTracks[vaultTrackId] = track;
    }

    final maskingStatus = switch (_cachedConfig.metadataVisibility) {
      MetadataVisibilityPolicyEnum.maskWithPlaceholder =>
      PlaybackMaskingStatusEnum.decoyPersonaProjected,
      MetadataVisibilityPolicyEnum.showActualMetadata =>
      PlaybackMaskingStatusEnum.unmasked,
    };

    _transitionTo(
      PlaybackPrivacyVaultTrackActiveState(
        vaultTrackId: vaultTrackId,
        maskingStatus: maskingStatus,
        visibilityPolicy: _cachedConfig.metadataVisibility,
      ),
    );
  }

  /// Directly handles session state transition forwarded from central coordinator or session bloc.
  void handleSessionStateTransition(VaultSessionState sessionState) {
    _handleSessionStateChange(sessionState);
  }

  void _handleSessionStateChange(VaultSessionState sessionState) {
    if (_isDisposed) return;

    switch (sessionState) {
      case VaultUninitializedState():
      case VaultProvisioningState():
        _executeLockTransition();
      case VaultLockedState():
        _executeLockTransition();
      case VaultLockoutCooldownState():
        _executeLockTransition();
      case VaultAuthenticatingState():
      // Retain current privacy status while user authenticates.
        break;
      case VaultUnlockedState():
        _executeUnlockRecovery();
      case VaultBackgroundGraceState():
      // Active session remains valid during background grace.
        break;
      case VaultPendingReauthState():
      // Non-destructive step-up re-auth: audio continues uninterrupted.
        break;
    }
  }

  void _handlePlayerQueueChange(QueueModel queueModel) {
    if (_isDisposed) return;

    final nowPlaying = queueModel.nowPlaying;
    if (nowPlaying == null) {
      if (_currentState is! PlaybackPrivacyPublicPassthroughState) {
        _transitionTo(const PlaybackPrivacyPublicPassthroughState());
      }
      return;
    }

    final isVault = _isVaultTrack(nowPlaying);
    if (!isVault) {
      if (_currentState is! PlaybackPrivacyPublicPassthroughState) {
        _transitionTo(const PlaybackPrivacyPublicPassthroughState());
      }
    } else {
      final vaultTrackId = _resolveVaultTrackId(nowPlaying);
      if (nowPlaying.metadata['musify_vault_masked'] != 'true') {
        _originalVaultTracks[vaultTrackId] = nowPlaying;
      }
      switch (_currentState) {
        case PlaybackPrivacyPublicPassthroughState():
          _transitionTo(
            PlaybackPrivacyVaultTrackActiveState(
              vaultTrackId: vaultTrackId,
              maskingStatus: switch (_cachedConfig.metadataVisibility) {
                MetadataVisibilityPolicyEnum.maskWithPlaceholder =>
                PlaybackMaskingStatusEnum.decoyPersonaProjected,
                MetadataVisibilityPolicyEnum.showActualMetadata =>
                PlaybackMaskingStatusEnum.unmasked,
              },
              visibilityPolicy: _cachedConfig.metadataVisibility,
            ),
          );
        case PlaybackPrivacyVaultTrackActiveState(
        vaultTrackId: final currentId,
        ):
          if (currentId != vaultTrackId) {
            _transitionTo(
              PlaybackPrivacyVaultTrackActiveState(
                vaultTrackId: vaultTrackId,
                maskingStatus: switch (_cachedConfig.metadataVisibility) {
                  MetadataVisibilityPolicyEnum.maskWithPlaceholder =>
                  PlaybackMaskingStatusEnum.decoyPersonaProjected,
                  MetadataVisibilityPolicyEnum.showActualMetadata =>
                  PlaybackMaskingStatusEnum.unmasked,
                },
                visibilityPolicy: _cachedConfig.metadataVisibility,
              ),
            );
          }
        case PlaybackPrivacyExecutingLockStrategyState(
            :final activeVaultTrackId,
            :final executingBehavior,
        ):
          if (executingBehavior ==
              LockPlaybackBehaviorEnum.finishCurrentTrack &&
              activeVaultTrackId != vaultTrackId) {
            _haltFinishedCurrentTrackPlayback();
          }
      }
    }
  }

  Future<void> _executeLockTransition() async {
    _originalVaultTracks.clear();
    switch (_currentState) {
      case PlaybackPrivacyPublicPassthroughState():
      // No private media playing; zero action required.
        break;
      case PlaybackPrivacyVaultTrackActiveState(:final vaultTrackId):
        final behavior = _cachedConfig.lockPlaybackBehavior;
        _transitionTo(
          PlaybackPrivacyExecutingLockStrategyState(
            activeVaultTrackId: vaultTrackId,
            executingBehavior: behavior,
          ),
        );

        final strategy = _resolveLockStrategy(behavior);
        final controlClient = _resolveControlClient();
        await strategy.executeLock(
          mobiusController: _mobiusController,
          playerControlClient: controlClient,
        );

        if (behavior == LockPlaybackBehaviorEnum.stopImmediately) {
          _transitionTo(const PlaybackPrivacyPublicPassthroughState());
        }
      case PlaybackPrivacyExecutingLockStrategyState():
      // Already executing lock strategy.
        break;
    }
  }

  void _executeUnlockRecovery() {
    switch (_currentState) {
      case PlaybackPrivacyPublicPassthroughState():
        final nowPlaying = _mobiusController.state.nowPlaying;
        if (nowPlaying != null && _isVaultTrack(nowPlaying)) {
          final vaultTrackId = _resolveVaultTrackId(nowPlaying);
          _transitionTo(
            PlaybackPrivacyVaultTrackActiveState(
              vaultTrackId: vaultTrackId,
              maskingStatus: switch (_cachedConfig.metadataVisibility) {
                MetadataVisibilityPolicyEnum.maskWithPlaceholder =>
                PlaybackMaskingStatusEnum.decoyPersonaProjected,
                MetadataVisibilityPolicyEnum.showActualMetadata =>
                PlaybackMaskingStatusEnum.unmasked,
              },
              visibilityPolicy: _cachedConfig.metadataVisibility,
            ),
          );
          _reprojectActiveQueue();
        }
      case PlaybackPrivacyExecutingLockStrategyState(
          :final activeVaultTrackId,
      ):
        final nowPlaying = _mobiusController.state.nowPlaying;
        if (nowPlaying != null && _isVaultTrack(nowPlaying)) {
          _transitionTo(
            PlaybackPrivacyVaultTrackActiveState(
              vaultTrackId: activeVaultTrackId,
              maskingStatus: switch (_cachedConfig.metadataVisibility) {
                MetadataVisibilityPolicyEnum.maskWithPlaceholder =>
                PlaybackMaskingStatusEnum.decoyPersonaProjected,
                MetadataVisibilityPolicyEnum.showActualMetadata =>
                PlaybackMaskingStatusEnum.unmasked,
              },
              visibilityPolicy: _cachedConfig.metadataVisibility,
            ),
          );
          _reprojectActiveQueue();
        } else {
          _transitionTo(const PlaybackPrivacyPublicPassthroughState());
        }
      case PlaybackPrivacyVaultTrackActiveState():
      // Already active; zero action required.
        break;
    }
  }

  Future<void> _haltFinishedCurrentTrackPlayback() async {
    final client = _resolveControlClient();
    await client.stop(const StopCommand());
    _mobiusController.dispatch(const ClearQueueEvent());
    _transitionTo(const PlaybackPrivacyPublicPassthroughState());
  }

  void _transitionTo(PlaybackPrivacyState newState) {
    if (_currentState == newState) return;
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  bool _isVaultTrack(ContextTrack track) {
    if (track.metadata['is_vault_track'] == 'true') {
      return true;
    }
    if (track.metadata.containsKey('vault_track_id')) {
      return true;
    }
    if (track.uid.startsWith('vault_')) {
      return true;
    }
    if (track.metadata[ContextTrackMetadata.keyLocalFilePath]
    case final path?) {
      if (path.contains('vault_media/.nomedia')) {
        return true;
      }
    }
    return false;
  }

  String _resolveVaultTrackId(ContextTrack track) {
    if (track.metadata['vault_track_id'] case final id? when id.isNotEmpty) {
      return id;
    }
    if (track.uid.isNotEmpty) {
      if (track.uid.startsWith('vault_')) {
        return track.uid.substring(6);
      }
      return track.uid;
    }
    return track.uri;
  }

  IMediaMaskingStrategy _resolveMaskingStrategy(
      MetadataVisibilityPolicyEnum policy,
      ) {
    final strategy = _maskingStrategies[policy];
    if (strategy case final s?) {
      return s;
    }
    throw StateError('Unregistered IMediaMaskingStrategy for policy: $policy');
  }

  ILockPlaybackStrategy _resolveLockStrategy(
      LockPlaybackBehaviorEnum behavior,
      ) {
    final strategy = _lockStrategies[behavior];
    if (strategy case final s?) {
      return s;
    }
    throw StateError(
      'Unregistered ILockPlaybackStrategy for behavior: $behavior',
    );
  }

  ContextPlayerControlClient _resolveControlClient() {
    if (_controlClient case final client?) {
      return client;
    }
    if (_mobiusController.controlClient case final ctrlClient?) {
      return ctrlClient;
    }
    throw StateError(
      'No ContextPlayerControlClient available for playback control.',
    );
  }

  void _handleStreamError(Object error, StackTrace stack) {
    dev.log(
      'PlaybackPrivacyProxy stream error: $error',
      name: 'PlaybackPrivacyProxy',
      error: error,
      stackTrace: stack,
    );
    if (!_stateController.isClosed) {
      _stateController.addError(error, stack);
    }
  }

  /// Closes internal stream controllers and cancels all stream subscriptions.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _originalVaultTracks.clear();
    await _configSubscription?.cancel();
    _configSubscription = null;
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    await _stateController.close();
  }
}
