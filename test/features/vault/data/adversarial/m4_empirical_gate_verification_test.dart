import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/player/domain/commands/options/prepare_play_options.dart';
import 'package:musify_mu/features/player/domain/commands/pause_command.dart';
import 'package:musify_mu/features/player/domain/commands/resume_command.dart';
import 'package:musify_mu/features/player/domain/commands/skip_to_next_track_command.dart';
import 'package:musify_mu/features/player/domain/commands/stop_command.dart';
import 'package:musify_mu/features/player/domain/models/context.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/play_origin.dart';
import 'package:musify_mu/features/player/domain/models/player_response.dart';
import 'package:musify_mu/features/vault/data/services/playback_privacy_proxy.dart';
import 'package:musify_mu/features/vault/data/services/vault_audio_playback_service.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/states/playback_privacy_mode.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

class EmpiricalMockControlClient implements ContextPlayerControlClient {
  int stopCalls = 0;
  int pauseCalls = 0;
  int resumeCalls = 0;

  @override
  Future<PlayerResponse> stop(StopCommand command) async {
    stopCalls++;
    return PlayerResponse.success;
  }

  @override
  Future<PlayerResponse> pause(PauseCommand command) async {
    pauseCalls++;
    return PlayerResponse.success;
  }

  @override
  Future<PlayerResponse> resume(ResumeCommand command) async {
    resumeCalls++;
    return PlayerResponse.success;
  }

  @override
  Future<PlayerResponse> skipToNext(SkipToNextTrackCommand command) async =>
      PlayerResponse.success;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class EmpiricalMockMobiusController extends ChangeNotifier
    implements PlayerQueueMobiusController {
  final List<QueueEvent> dispatchedEvents = <QueueEvent>[];
  final StreamController<QueueModel> _modelController =
      StreamController<QueueModel>.broadcast();
  QueueModel _currentModel = const QueueModel();
  bool _closed = false;

  final EmpiricalMockControlClient client = EmpiricalMockControlClient();

  @override
  ContextPlayerControlClient get controlClient => client;

  @override
  QueueModel get model => _currentModel;

  @override
  QueueModel get state => _currentModel;

  @override
  QueueModel get value => _currentModel;

  @override
  Stream<QueueModel> get stream => _modelController.stream;

  @override
  bool get isClosed => _closed;

  void emit(QueueModel model) {
    _currentModel = model;
    if (!_closed && !_modelController.isClosed) {
      _modelController.add(model);
    }
  }

  @override
  void dispatch(QueueEvent event) {
    dispatchedEvents.add(event);
  }

  @override
  void add(QueueEvent event) => dispatch(event);

  @override
  Future<void> playContext(
    Context context, {
    PreparePlayOptions? options,
    PlayOrigin? playOrigin,
  }) async {}

  @override
  Future<void> close() async {
    _closed = true;
    await _modelController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class EmpiricalMockAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> _stateStreamController =
      StreamController<VaultSessionState>.broadcast();

  @override
  Stream<VaultSessionState> get sessionStateStream =>
      _stateStreamController.stream;

  void emit(VaultSessionState state) {
    if (!_stateStreamController.isClosed) {
      _stateStreamController.add(state);
    }
  }

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({
    required String pin,
  }) async =>
      VaultResult.success(
        AuthSession(
          sessionToken: 'emp_pin_tok',
          sessionStartedEpochMs: 100,
          lastActiveEpochMs: 100,
          authMethod: AuthMethodEnum.pin,
        ),
      );

  @override
  Future<VaultResult<AuthSession>> authenticateWithBiometrics() async =>
      VaultResult.success(
        AuthSession(
          sessionToken: 'emp_bio_tok',
          sessionStartedEpochMs: 100,
          lastActiveEpochMs: 100,
          authMethod: AuthMethodEnum.biometric,
        ),
      );

  @override
  Future<void> recordFailedAttempt() async {}

  @override
  Future<void> resetFailedAttempts() async {}

  @override
  Future<LockoutCooldownInfo> getLockoutStatus() async =>
      LockoutCooldownInfo.none();

  @override
  Future<VaultResult<void>> rotatePin({
    required String oldPin,
    required String newPin,
  }) async =>
      const VaultResult.success(null);

  @override
  Future<void> clearSessionKeysFromRam() async {}

  Future<void> close() async {
    await _stateStreamController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class EmpiricalMockStorageRepository implements IVaultStorageRepository {
  VaultConfig config = const VaultConfig.constant();

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(config);

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig newConfig) async {
    config = newConfig;
    return const VaultResult.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Empirical Challenger Verification: Phase 2 Milestone 4', () {
    late EmpiricalMockMobiusController mobiusController;
    late EmpiricalMockAuthService authService;
    late EmpiricalMockStorageRepository storageRepository;
    late PlaybackPrivacyProxy proxy;
    late VaultAudioPlaybackService playbackService;

    setUp(() {
      mobiusController = EmpiricalMockMobiusController();
      authService = EmpiricalMockAuthService();
      storageRepository = EmpiricalMockStorageRepository();

      proxy = PlaybackPrivacyProxy(
        vaultAuthService: authService,
        mobiusController: mobiusController,
        storageRepository: storageRepository,
      );

      playbackService = VaultAudioPlaybackService(
        mobiusController: mobiusController,
        privacyProxy: proxy,
      );
    });

    tearDown(() async {
      await proxy.dispose();
      await mobiusController.close();
      await authService.close();
    });

    PrivateTrackRef createSensitiveTrack({
      required String id,
      required String secretTitle,
      required String secretArtist,
      required String secretAlbum,
    }) {
      return PrivateTrackRef(
        id: id,
        playlistId: 'playlist_$id',
        trackUri: 'spotify:track:$id',
        title: secretTitle,
        artistName: secretArtist,
        albumTitle: secretAlbum,
        durationMs: 240000,
        sourceType: TrackSourceTypeEnum.localSandbox,
        localRelativePath: 'vault_media/.nomedia/$id.mp3',
        sortOrder: 0,
        addedAtEpochMs: 1234567,
      );
    }

    test('EMP-01: Zero Private Metadata Exposure Across 50 Generated Tracks', () {
      final config = VaultConfig(
        metadataVisibility: MetadataVisibilityPolicyEnum.maskWithPlaceholder,
        decoyTitle: 'Decoy Track Title',
        decoyArtist: 'Decoy Artist Name',
        decoyAlbum: 'Decoy Album Name',
      );

      for (var i = 0; i < 50; i++) {
        final secretTitle = 'PRIVATE_KEY_TITLE_$i _SECRET_#${i * 7}';
        final secretArtist = 'CONFIDENTIAL_ARTIST_$i _WHISPER';
        final secretAlbum = 'CLASSIFIED_ALBUM_$i _VAULT';

        final trackRef = createSensitiveTrack(
          id: 'track_$i',
          secretTitle: secretTitle,
          secretArtist: secretArtist,
          secretAlbum: secretAlbum,
        );

        final packaged = playbackService.packagePrivateTrack(
          trackRef: trackRef,
          isolatedFilePath: '/data/user/0/app/vault_media/.nomedia/track_$i.mp3',
          config: config,
        );

        // Assert that zero sensitive strings leak into ANY metadata value
        for (final entry in packaged.metadata.entries) {
          expect(entry.value.contains(secretTitle), isFalse,
              reason: 'Secret title leaked into metadata key: ${entry.key}');
          expect(entry.value.contains(secretArtist), isFalse,
              reason: 'Secret artist leaked into metadata key: ${entry.key}');
          expect(entry.value.contains(secretAlbum), isFalse,
              reason: 'Secret album leaked into metadata key: ${entry.key}');
        }

        // Assert artwork URLs are absent
        expect(packaged.metadata.containsKey(ContextTrackMetadata.keyImageUrl), isFalse);
        expect(packaged.metadata.containsKey(ContextTrackMetadata.keyThumbnailImageUrl), isFalse);
        expect(packaged.metadata.containsKey(ContextTrackMetadata.keyImageSmallUrl), isFalse);
        expect(packaged.metadata.containsKey(ContextTrackMetadata.keyImageLargeUrl), isFalse);

        // Assert public surface fields equal decoy persona
        expect(packaged.metadata[ContextTrackMetadata.keyTitle], config.decoyTitle);
        expect(packaged.metadata[ContextTrackMetadata.keyArtistName], config.decoyArtist);
        expect(packaged.metadata[ContextTrackMetadata.keyAlbumArtistName], config.decoyArtist);
        expect(packaged.metadata[ContextTrackMetadata.keyAlbumTitle], config.decoyAlbum);

        // Assert native C++ playback paths are preserved
        expect(
          packaged.metadata[ContextTrackMetadata.keyLocalFilePath],
          '/data/user/0/app/vault_media/.nomedia/track_$i.mp3',
        );
        expect(packaged.metadata[ContextTrackMetadata.keyIsLocal], 'true');
        expect(packaged.metadata['is_vault_track'], 'true');
      }
    });

    test('EMP-02: Concurrent Lock/Unlock Race Conditions with Active Queue Transitions', () async {
      storageRepository.config = VaultConfig(
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.continueMaskedInBackground,
        metadataVisibility: MetadataVisibilityPolicyEnum.showActualMetadata,
        decoyTitle: 'Persona Masked Title',
        decoyArtist: 'Persona Masked Artist',
        decoyAlbum: 'Persona Masked Album',
      );
      await proxy.initialize();

      final session = AuthSession(
        sessionToken: 'session_token',
        sessionStartedEpochMs: 5000,
        lastActiveEpochMs: 5000,
        authMethod: AuthMethodEnum.pin,
      );

      final trackA = playbackService.packagePrivateTrack(
        trackRef: createSensitiveTrack(
          id: 'trackA',
          secretTitle: 'Secret A',
          secretArtist: 'Artist A',
          secretAlbum: 'Album A',
        ),
        isolatedFilePath: '/data/vault_media/.nomedia/trackA.mp3',
        config: storageRepository.config,
      );

      final trackB = playbackService.packagePrivateTrack(
        trackRef: createSensitiveTrack(
          id: 'trackB',
          secretTitle: 'Secret B',
          secretArtist: 'Artist B',
          secretAlbum: 'Album B',
        ),
        isolatedFilePath: '/data/vault_media/.nomedia/trackB.mp3',
        config: storageRepository.config,
      );

      final publicTrack = ContextTrack(
        uri: 'spotify:track:public_001',
        uid: 'public_001',
        metadata: {
          ContextTrackMetadata.keyTitle: 'Public Song',
          ContextTrackMetadata.keyArtistName: 'Public Artist',
        },
      );

      // Perform 150 interleaved asynchronous state transitions
      for (var i = 0; i < 150; i++) {
        // Emit queue transition
        if (i % 3 == 0) {
          mobiusController.emit(QueueModel(currentTrack: trackA));
        } else if (i % 3 == 1) {
          mobiusController.emit(QueueModel(currentTrack: trackB));
        } else {
          mobiusController.emit(QueueModel(currentTrack: publicTrack));
        }

        // Interleave lock and unlock
        if (i % 2 == 0) {
          authService.emit(VaultLockedState(lockedAtMonotonicMs: 1000 + i));
        } else {
          authService.emit(
            VaultUnlockedState(
              session: session,
              unlockedAtMonotonicMs: 1000 + i,
              reauthDeadlineMonotonicMs: 0,
            ),
          );
        }
      }

      await Future<void>.delayed(Duration.zero);

      // Settle state to a known condition: Locked while TrackA is playing
      mobiusController.emit(QueueModel(currentTrack: trackA));
      authService.emit(const VaultLockedState(lockedAtMonotonicMs: 999999));
      await Future<void>.delayed(Duration.zero);

      // In locked state with continueMaskedInBackground:
      expect(proxy.currentState, isA<PlaybackPrivacyExecutingLockStrategyState>());
      expect(proxy.isDecoyActive, isTrue);

      final projectedUnderLock = proxy.projectTrack(trackA);
      expect(
        projectedUnderLock.metadata[ContextTrackMetadata.keyTitle],
        'Persona Masked Title',
      );
      expect(
        projectedUnderLock.metadata[ContextTrackMetadata.keyArtistName],
        'Persona Masked Artist',
      );

      // Transition to Unlocked with showActualMetadata
      authService.emit(
        VaultUnlockedState(
          session: session,
          unlockedAtMonotonicMs: 1000000,
          reauthDeadlineMonotonicMs: 0,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      // Unlocked state must recover to VaultTrackActive with unmasked projection
      expect(proxy.currentState, isA<PlaybackPrivacyVaultTrackActiveState>());
      expect(proxy.isDecoyActive, isFalse);

      final projectedUnderUnlock = proxy.projectTrack(trackA);
      expect(
        projectedUnderUnlock.metadata[ContextTrackMetadata.keyTitle],
        'Secret A',
      );
    });

    test('EMP-03: Track Progression Under ContinueMaskedInBackground While Locked', () async {
      storageRepository.config = VaultConfig(
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.continueMaskedInBackground,
        metadataVisibility: MetadataVisibilityPolicyEnum.showActualMetadata,
        decoyTitle: 'Decoy Shield Active',
        decoyArtist: 'Decoy Shield Artist',
        decoyAlbum: 'Decoy Shield Album',
      );
      await proxy.initialize();

      final track1 = playbackService.packagePrivateTrack(
        trackRef: createSensitiveTrack(
          id: 'track_prog_1',
          secretTitle: 'Secret 1',
          secretArtist: 'Artist 1',
          secretAlbum: 'Album 1',
        ),
        isolatedFilePath: '/data/vault_media/.nomedia/track_prog_1.mp3',
        config: storageRepository.config,
      );

      final track2 = playbackService.packagePrivateTrack(
        trackRef: createSensitiveTrack(
          id: 'track_prog_2',
          secretTitle: 'Secret 2',
          secretArtist: 'Artist 2',
          secretAlbum: 'Album 2',
        ),
        isolatedFilePath: '/data/vault_media/.nomedia/track_prog_2.mp3',
        config: storageRepository.config,
      );

      // Start track 1 in unlocked state
      mobiusController.emit(QueueModel(currentTrack: track1));
      await Future<void>.delayed(Duration.zero);
      expect(proxy.isVaultTrackActive, isTrue);

      // Lock vault
      authService.emit(const VaultLockedState(lockedAtMonotonicMs: 5000));
      await Future<void>.delayed(Duration.zero);
      expect(proxy.currentState, isA<PlaybackPrivacyExecutingLockStrategyState>());
      expect(proxy.isDecoyActive, isTrue);

      // Track 1 finishes and Track 2 starts in background while still locked
      mobiusController.emit(QueueModel(currentTrack: track2));
      await Future<void>.delayed(Duration.zero);

      // Must remain in executing lock strategy, maintaining decoy protection
      expect(proxy.currentState, isA<PlaybackPrivacyExecutingLockStrategyState>());
      expect(proxy.isDecoyActive, isTrue);

      // Projecting track 2 while locked MUST strictly return decoy persona
      final projectedTrack2 = proxy.projectTrack(track2);
      expect(
        projectedTrack2.metadata[ContextTrackMetadata.keyTitle],
        'Decoy Shield Active',
      );
      expect(
        projectedTrack2.metadata[ContextTrackMetadata.keyArtistName],
        'Decoy Shield Artist',
      );
    });

    test('EMP-04: StopImmediately Lock Cleans Up State Deterministically', () async {
      storageRepository.config = VaultConfig(
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.stopImmediately,
      );
      await proxy.initialize();

      final track = playbackService.packagePrivateTrack(
        trackRef: createSensitiveTrack(
          id: 'stop_immediate_track',
          secretTitle: 'Stop Me',
          secretArtist: 'Stop Artist',
          secretAlbum: 'Stop Album',
        ),
        isolatedFilePath: '/data/vault_media/.nomedia/stop.mp3',
        config: storageRepository.config,
      );

      mobiusController.emit(QueueModel(currentTrack: track));
      await Future<void>.delayed(Duration.zero);
      expect(proxy.isVaultTrackActive, isTrue);

      // Lock triggered
      authService.emit(const VaultLockedState(lockedAtMonotonicMs: 1234));
      await Future<void>.delayed(Duration.zero);

      // Stop command must have been issued
      expect(mobiusController.client.stopCalls, 1);
      // ClearQueueEvent and ResetQueueEvent must be dispatched
      expect(mobiusController.dispatchedEvents, contains(isA<ClearQueueEvent>()));
      expect(mobiusController.dispatchedEvents, contains(isA<ResetQueueEvent>()));
      // Proxy must have cleanly transitioned to PublicPassthrough
      expect(proxy.currentState, isA<PlaybackPrivacyPublicPassthroughState>());
    });

    test('EMP-05: Non-destructive Steps (Authenticating, Grace, PendingReauth) Preserve Privacy State', () async {
      storageRepository.config = VaultConfig(
        metadataVisibility: MetadataVisibilityPolicyEnum.maskWithPlaceholder,
        decoyTitle: 'Grace Decoy',
      );
      await proxy.initialize();

      final track = playbackService.packagePrivateTrack(
        trackRef: createSensitiveTrack(
          id: 'grace_track',
          secretTitle: 'Grace Secret',
          secretArtist: 'Grace Artist',
          secretAlbum: 'Grace Album',
        ),
        isolatedFilePath: '/data/vault_media/.nomedia/grace.mp3',
        config: storageRepository.config,
      );

      mobiusController.emit(QueueModel(currentTrack: track));
      await Future<void>.delayed(Duration.zero);
      expect(proxy.isVaultTrackActive, isTrue);

      // App transitions to BackgroundGrace
      final session = AuthSession(
        sessionToken: 'sess',
        sessionStartedEpochMs: 1,
        lastActiveEpochMs: 1,
        authMethod: AuthMethodEnum.pin,
      );
      authService.emit(
        VaultBackgroundGraceState(
          session: session,
          enteredBackgroundMonotonicMs: 100,
          graceTimeoutMs: 30000,
          graceDeadlineMonotonicMs: 30100,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(proxy.isVaultTrackActive, isTrue);

      // App transitions to PendingReauth
      authService.emit(
        VaultPendingReauthState(
          session: session,
          reauthTriggeredAtMonotonicMs: 200,
          remainingAttempts: 3,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(proxy.isVaultTrackActive, isTrue);

      // User enters PIN pad (Authenticating)
      authService.emit(
        const VaultAuthenticatingState(
          authSessionId: 'auth_sess_1',
          attemptNumber: 1,
          remainingAttemptsBeforeCooldown: 4,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(proxy.isVaultTrackActive, isTrue);
    });

    test('EMP-06: Idempotent Double Dispose Does Not Throw or Leak', () async {
      await proxy.initialize();
      expect(proxy.isDisposed, isFalse);

      await proxy.dispose();
      expect(proxy.isDisposed, isTrue);

      // Double dispose must succeed safely
      await proxy.dispose();
      expect(proxy.isDisposed, isTrue);

      // Post-dispose updates must be safely ignored without throwing
      proxy.updateConfig(VaultConfig.constant());
      proxy.notifyVaultTrackActivated(
        vaultTrackId: 'dummy',
        track: ContextTrack(uri: 'uri'),
      );
    });
  });
}
