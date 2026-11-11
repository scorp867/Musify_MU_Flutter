import 'dart:async';
import 'dart:io';

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
import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';
import 'package:musify_mu/features/vault/data/services/playback_privacy_proxy.dart';
import 'package:musify_mu/features/vault/data/services/vault_audio_playback_service.dart';
import 'package:musify_mu/features/vault/data/strategies/continue_masked_lock_strategy.dart';
import 'package:musify_mu/features/vault/data/strategies/finish_current_track_lock_strategy.dart';
import 'package:musify_mu/features/vault/data/strategies/stop_immediately_lock_strategy.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/states/playback_privacy_mode.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

class GateAdversarialControlClient implements ContextPlayerControlClient {
  int stopCallCount = 0;
  StopCommand? lastStopCommand;
  bool shouldThrowOnStop = false;

  @override
  Future<PlayerResponse> stop(StopCommand command) async {
    stopCallCount++;
    lastStopCommand = command;
    if (shouldThrowOnStop) {
      throw StateError('Simulated native audio engine stop failure');
    }
    return PlayerResponse.success;
  }

  @override
  Future<PlayerResponse> pause(PauseCommand command) async =>
      PlayerResponse.success;

  @override
  Future<PlayerResponse> resume(ResumeCommand command) async =>
      PlayerResponse.success;

  @override
  Future<PlayerResponse> skipToNext(SkipToNextTrackCommand command) async =>
      PlayerResponse.success;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class GateAdversarialMobiusController extends ChangeNotifier
    implements PlayerQueueMobiusController {
  final List<QueueEvent> dispatchedEvents = <QueueEvent>[];
  final StreamController<QueueModel> _modelController =
      StreamController<QueueModel>.broadcast();
  QueueModel _currentModel = const QueueModel();
  bool _isClosed = false;

  final GateAdversarialControlClient client = GateAdversarialControlClient();

  Context? lastPlayedContext;
  PreparePlayOptions? lastPlayOptions;
  PlayOrigin? lastPlayOrigin;
  int playContextCalls = 0;

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
  bool get isClosed => _isClosed;

  void emit(QueueModel model) {
    _currentModel = model;
    if (!_isClosed) {
      _modelController.add(model);
    }
  }

  void emitError(Object error, [StackTrace? stack]) {
    if (!_isClosed) {
      _modelController.addError(error, stack);
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
  }) async {
    playContextCalls++;
    lastPlayedContext = context;
    lastPlayOptions = options;
    lastPlayOrigin = playOrigin;
  }

  @override
  Future<void> close() async {
    _isClosed = true;
    await _modelController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class GateAdversarialAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> _stateController =
      StreamController<VaultSessionState>.broadcast();

  @override
  Stream<VaultSessionState> get sessionStateStream => _stateController.stream;

  void emit(VaultSessionState state) {
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  void emitError(Object error, [StackTrace? stack]) {
    if (!_stateController.isClosed) {
      _stateController.addError(error, stack);
    }
  }

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({
    required String pin,
  }) async =>
      VaultResult.success(
        AuthSession(
          sessionToken: 'test_token',
          sessionStartedEpochMs: 100,
          lastActiveEpochMs: 100,
          authMethod: AuthMethodEnum.pin,
        ),
      );

  @override
  Future<VaultResult<AuthSession>> authenticateWithBiometrics() async =>
      VaultResult.success(
        AuthSession(
          sessionToken: 'test_token',
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

  Future<void> dispose() async {
    await _stateController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class GateAdversarialStorageRepository implements IVaultStorageRepository {
  VaultConfig currentConfig = const VaultConfig.constant();

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(currentConfig);

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig newConfig) async {
    currentConfig = newConfig;
    return const VaultResult.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class GateAdversarialIsolationManager implements IVaultMediaIsolationManager {
  final Map<String, File> files = {};

  @override
  Future<File> getIsolatedTrackFile(String trackId) async {
    if (files.containsKey(trackId)) {
      return files[trackId]!;
    }
    return File('/app_storage/vault_media/.nomedia/$trackId.mp3');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Empirical Gate Verification Suite: Phase 2 Milestone 4 (R6)', () {
    late GateAdversarialMobiusController mobiusController;
    late GateAdversarialAuthService authService;
    late GateAdversarialStorageRepository storageRepository;
    late GateAdversarialIsolationManager isolationManager;
    late PlaybackPrivacyProxy proxy;
    late VaultAudioPlaybackService playbackService;

    setUp(() {
      mobiusController = GateAdversarialMobiusController();
      authService = GateAdversarialAuthService();
      storageRepository = GateAdversarialStorageRepository();
      isolationManager = GateAdversarialIsolationManager();

      proxy = PlaybackPrivacyProxy(
        vaultAuthService: authService,
        mobiusController: mobiusController,
        storageRepository: storageRepository,
      );

      playbackService = VaultAudioPlaybackService(
        mobiusController: mobiusController,
        privacyProxy: proxy,
        isolationManager: isolationManager,
      );
    });

    tearDown(() async {
      await proxy.dispose();
      await mobiusController.close();
      await authService.dispose();
    });

    final testTrackRef = PrivateTrackRef(
      id: 'adv_track_101',
      playlistId: 'adv_playlist_999',
      trackUri: 'spotify:track:adv_sample_101',
      title: 'Top Secret Opus No. 5',
      artistName: 'Stealth Maestro',
      albumTitle: 'Encrypted Symphony',
      durationMs: 245000,
      sourceType: TrackSourceTypeEnum.localSandbox,
      localRelativePath: 'vault_media/.nomedia/adv_track_101.mp3',
      sortOrder: 0,
      addedAtEpochMs: 1700000000,
    );

    final standardSession = AuthSession(
      sessionToken: 'test_token',
      sessionStartedEpochMs: 1000,
      lastActiveEpochMs: 1000,
      authMethod: AuthMethodEnum.pin,
    );

    group('Challenge Group 1: VaultAudioPlaybackService Packaging & Dispatch Boundaries', () {
      test('1.1 Empty private playlist rejected with StateError', () async {
        final emptyPlaylist = PrivatePlaylist(
          id: 'empty_pl_01',
          name: 'Empty Playlist',
          description: 'Empty Description',
          totalDurationMs: 0,
          createdAtEpochMs: 1700000000,
          updatedAtEpochMs: 1700000000,
          trackRefs: const [],
        );

        expect(
          () => playbackService.playPrivatePlaylist(
            playlist: emptyPlaylist,
            startIndex: 0,
          ),
          throwsA(isA<StateError>()),
        );
      });

      test('1.2 Invalid startIndex rejected with RangeError', () async {
        final playlist = PrivatePlaylist(
          id: 'single_pl_01',
          name: 'Single Track Playlist',
          description: 'Single Description',
          totalDurationMs: 245000,
          createdAtEpochMs: 1700000000,
          updatedAtEpochMs: 1700000000,
          trackRefs: [testTrackRef],
        );

        expect(
          () => playbackService.playPrivatePlaylist(
            playlist: playlist,
            startIndex: -1,
          ),
          throwsA(isA<RangeError>()),
        );

        expect(
          () => playbackService.playPrivatePlaylist(
            playlist: playlist,
            startIndex: 1,
          ),
          throwsA(isA<RangeError>()),
        );
      });

      test('1.3 Mismatched resolvedFilePaths rejected with RangeError', () async {
        final multiTrackPlaylist = PrivatePlaylist(
          id: 'multi_pl_01',
          name: 'Multi Track Playlist',
          description: 'Multi Description',
          totalDurationMs: 490000,
          createdAtEpochMs: 1700000000,
          updatedAtEpochMs: 1700000000,
          trackRefs: [
            testTrackRef,
            testTrackRef.copyWith(id: 'adv_track_102', sortOrder: 1),
          ],
        );

        // Only 1 path provided for 2 tracks
        expect(
          () => playbackService.playPrivatePlaylist(
            playlist: multiTrackPlaylist,
            resolvedFilePaths: ['/path/to/track1.mp3'],
            startIndex: 0,
          ),
          throwsA(isA<RangeError>()),
        );
      });

      test('1.4 Missing file path resolver rejected with StateError', () async {
        final noResolverService = VaultAudioPlaybackService(
          mobiusController: mobiusController,
          privacyProxy: proxy,
          isolationManager: null,
        );

        final playlist = PrivatePlaylist(
          id: 'pl_01',
          name: 'Test Playlist',
          description: 'Test Description',
          totalDurationMs: 245000,
          createdAtEpochMs: 1700000000,
          updatedAtEpochMs: 1700000000,
          trackRefs: [testTrackRef],
        );

        expect(
          () => noResolverService.playPrivatePlaylist(
            playlist: playlist,
            resolvedFilePaths: null,
            startIndex: 0,
          ),
          throwsA(isA<StateError>()),
        );
      });

      test('1.5 Local file URI is properly packaged into ContextTrack', () {
        final localTrack = testTrackRef.copyWith(
          trackUri: 'file:///data/user/0/vault_media/.nomedia/adv_track_101.mp3',
        );
        final packaged = playbackService.packagePrivateTrack(
          trackRef: localTrack,
          isolatedFilePath: '/data/user/0/vault_media/.nomedia/adv_track_101.mp3',
        );

        expect(
          packaged.uri,
          equals('file:///data/user/0/vault_media/.nomedia/adv_track_101.mp3'),
        );
      });

      test('1.6 Packaged ContextTrack contains unmodifiable metadata', () {
        final packaged = playbackService.packagePrivateTrack(
          trackRef: testTrackRef,
          isolatedFilePath: '/data/user/0/vault_media/.nomedia/adv_track_101.mp3',
        );

        expect(
          () => packaged.metadata['title'] = 'Hacked Title',
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('1.7 playPrivateTrack dispatches canonical Context and options to Mobius', () async {
        await playbackService.playPrivateTrack(
          trackRef: testTrackRef,
          isolatedFilePath: '/storage/vault_media/.nomedia/adv_track_101.mp3',
        );

        expect(mobiusController.playContextCalls, equals(1));
        final context = mobiusController.lastPlayedContext;
        expect(context, isNotNull);
        expect(context!.uri, equals('spotify:internal:vault-track:adv_track_101'));
        expect(context.url, equals('context://spotify:internal:vault-track:adv_track_101'));
        expect(context.metadata['is_vault_context'], equals('true'));
        expect(context.metadata['vault_track_id'], equals('adv_track_101'));

        final options = mobiusController.lastPlayOptions;
        expect(options, isNotNull);
        expect(options!.skipTo?.trackUid, equals('vault_adv_track_101'));

        final origin = mobiusController.lastPlayOrigin;
        expect(origin, isNotNull);
        expect(origin!.featureIdentifier, equals('vault_track'));
      });
    });

    group('Challenge Group 2: Lock Playback Strategies Stress & Error Handling', () {
      test('2.1 StopImmediatelyLockStrategy dispatches StopCommand, ClearQueue, and ResetQueue', () async {
        const strategy = StopImmediatelyLockStrategy();
        expect(strategy.behavior, equals(LockPlaybackBehaviorEnum.stopImmediately));

        await strategy.executeLock(
          mobiusController: mobiusController,
          playerControlClient: mobiusController.client,
        );

        expect(mobiusController.client.stopCallCount, equals(1));
        expect(mobiusController.dispatchedEvents, contains(const ClearQueueEvent()));
        expect(mobiusController.dispatchedEvents, contains(const ResetQueueEvent()));
      });

      test('2.2 FinishCurrentTrackLockStrategy dispatches ClearQueue only, leaving playback running', () async {
        const strategy = FinishCurrentTrackLockStrategy();
        expect(strategy.behavior, equals(LockPlaybackBehaviorEnum.finishCurrentTrack));

        await strategy.executeLock(
          mobiusController: mobiusController,
          playerControlClient: mobiusController.client,
        );

        expect(mobiusController.client.stopCallCount, equals(0));
        expect(mobiusController.dispatchedEvents, contains(const ClearQueueEvent()));
        expect(mobiusController.dispatchedEvents, isNot(contains(const ResetQueueEvent())));
      });

      test('2.3 ContinueMaskedLockStrategy leaves both player and queue completely untouched', () async {
        const strategy = ContinueMaskedLockStrategy();
        expect(strategy.behavior, equals(LockPlaybackBehaviorEnum.continueMaskedInBackground));

        await strategy.executeLock(
          mobiusController: mobiusController,
          playerControlClient: mobiusController.client,
        );

        expect(mobiusController.client.stopCallCount, equals(0));
        expect(mobiusController.dispatchedEvents, isEmpty);
      });

      test('2.4 StopImmediatelyLockStrategy bubbles up client failure cleanly when stop fails', () async {
        mobiusController.client.shouldThrowOnStop = true;
        const strategy = StopImmediatelyLockStrategy();

        expect(
          () => strategy.executeLock(
            mobiusController: mobiusController,
            playerControlClient: mobiusController.client,
          ),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('Challenge Group 3: PlaybackPrivacyProxy (Region B) Statechart & Queue Events', () {
      test('3.1 Proxy initializes in PublicPassthrough state with cached config', () async {
        await proxy.initialize();

        expect(proxy.currentState, isA<PlaybackPrivacyPublicPassthroughState>());
        expect(proxy.isIdle, isTrue);
        expect(proxy.isVaultTrackActive, isFalse);
        expect(proxy.isExecutingLockStrategy, isFalse);
        expect(proxy.isDecoyActive, isFalse);
      });

      test('3.2 Uninitialized and empty queues maintain PublicPassthrough state', () async {
        await proxy.initialize();

        mobiusController.emit(const QueueModel(currentTrack: null));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(proxy.currentState, isA<PlaybackPrivacyPublicPassthroughState>());
        expect(proxy.isIdle, isTrue);
      });

      test('3.3 Non-vault public track maintains PublicPassthrough state', () async {
        await proxy.initialize();

        const publicTrack = ContextTrack(
          uri: 'spotify:track:public_song_01',
          uid: 'public_uid_01',
          metadata: {
            ContextTrackMetadata.keyTitle: 'Public Pop Song',
            ContextTrackMetadata.keyArtistName: 'Public Artist',
          },
          provider: 'spotify',
        );

        mobiusController.emit(const QueueModel(currentTrack: publicTrack));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(proxy.currentState, isA<PlaybackPrivacyPublicPassthroughState>());
        expect(proxy.isIdle, isTrue);
      });

      test('3.4 Vault track transition from QueueModel activates VaultTrackActive state', () async {
        await proxy.initialize();

        final vaultContextTrack = playbackService.packagePrivateTrack(
          trackRef: testTrackRef,
          isolatedFilePath: '/storage/vault_media/.nomedia/adv_track_101.mp3',
        );

        mobiusController.emit(QueueModel(currentTrack: vaultContextTrack));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(proxy.currentState, isA<PlaybackPrivacyVaultTrackActiveState>());
        expect(proxy.isVaultTrackActive, isTrue);
        final state = proxy.currentState as PlaybackPrivacyVaultTrackActiveState;
        expect(state.vaultTrackId, equals('adv_track_101'));
      });

      test('3.5 Track ending (currentTrack == null) transitions back to PublicPassthrough', () async {
        await proxy.initialize();

        final vaultContextTrack = playbackService.packagePrivateTrack(
          trackRef: testTrackRef,
          isolatedFilePath: '/storage/vault_media/.nomedia/adv_track_101.mp3',
        );

        mobiusController.emit(QueueModel(currentTrack: vaultContextTrack));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(proxy.isVaultTrackActive, isTrue);

        // Track completes, player queue nowPlaying/currentTrack becomes null
        mobiusController.emit(const QueueModel(currentTrack: null));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(proxy.currentState, isA<PlaybackPrivacyPublicPassthroughState>());
        expect(proxy.isIdle, isTrue);
      });

      test('3.6 Lock with stopImmediately halts playback and returns to PublicPassthrough', () async {
        storageRepository.currentConfig = VaultConfig(
          lockPlaybackBehavior: LockPlaybackBehaviorEnum.stopImmediately,
        );
        await proxy.initialize();

        final vaultTrack = playbackService.packagePrivateTrack(
          trackRef: testTrackRef,
          isolatedFilePath: '/storage/vault_media/.nomedia/adv_track_101.mp3',
        );
        proxy.notifyVaultTrackActivated(vaultTrackId: testTrackRef.id, track: vaultTrack);
        expect(proxy.isVaultTrackActive, isTrue);

        authService.emit(const VaultLockedState(lockedAtMonotonicMs: 1000));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(mobiusController.client.stopCallCount, equals(1));
        expect(mobiusController.dispatchedEvents, contains(const ClearQueueEvent()));
        expect(mobiusController.dispatchedEvents, contains(const ResetQueueEvent()));
        expect(proxy.currentState, isA<PlaybackPrivacyPublicPassthroughState>());
      });

      test('3.7 Lock with finishCurrentTrack enters ExecutingLockStrategy, then halts on track change', () async {
        storageRepository.currentConfig = VaultConfig(
          lockPlaybackBehavior: LockPlaybackBehaviorEnum.finishCurrentTrack,
        );
        await proxy.initialize();

        final vaultTrack1 = playbackService.packagePrivateTrack(
          trackRef: testTrackRef,
          isolatedFilePath: '/storage/vault_media/.nomedia/adv_track_101.mp3',
        );
        mobiusController.emit(QueueModel(currentTrack: vaultTrack1));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(proxy.isVaultTrackActive, isTrue);

        // Lock vault
        authService.emit(const VaultLockedState(lockedAtMonotonicMs: 1000));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // State is ExecutingLockStrategy
        expect(proxy.currentState, isA<PlaybackPrivacyExecutingLockStrategyState>());
        expect(proxy.isExecutingLockStrategy, isTrue);
        expect(proxy.isDecoyActive, isTrue);
        expect(mobiusController.dispatchedEvents, contains(const ClearQueueEvent()));
        expect(mobiusController.client.stopCallCount, equals(0));

        // When track 1 finishes and player advances or currentTrack becomes null
        mobiusController.emit(const QueueModel(currentTrack: null));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(proxy.currentState, isA<PlaybackPrivacyPublicPassthroughState>());
        expect(proxy.isIdle, isTrue);
      });

      test('3.8 Lock with continueMaskedInBackground maintains ExecutingLockStrategy and active decoy', () async {
        storageRepository.currentConfig = VaultConfig(
          lockPlaybackBehavior: LockPlaybackBehaviorEnum.continueMaskedInBackground,
        );
        await proxy.initialize();

        final vaultTrack = playbackService.packagePrivateTrack(
          trackRef: testTrackRef,
          isolatedFilePath: '/storage/vault_media/.nomedia/adv_track_101.mp3',
        );
        mobiusController.emit(QueueModel(currentTrack: vaultTrack));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        authService.emit(const VaultLockedState(lockedAtMonotonicMs: 1000));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(proxy.currentState, isA<PlaybackPrivacyExecutingLockStrategyState>());
        expect(proxy.isExecutingLockStrategy, isTrue);
        expect(proxy.isDecoyActive, isTrue);
        expect(mobiusController.client.stopCallCount, equals(0));
        expect(mobiusController.dispatchedEvents, isEmpty);
      });

      test('3.9 Re-unlock recovery restores VaultTrackActive with correct metadata policy', () async {
        storageRepository.currentConfig = VaultConfig(
          lockPlaybackBehavior: LockPlaybackBehaviorEnum.continueMaskedInBackground,
          metadataVisibility: MetadataVisibilityPolicyEnum.showActualMetadata,
        );
        await proxy.initialize();

        final vaultTrack = playbackService.packagePrivateTrack(
          trackRef: testTrackRef,
          isolatedFilePath: '/storage/vault_media/.nomedia/adv_track_101.mp3',
          config: storageRepository.currentConfig,
        );
        mobiusController.emit(QueueModel(currentTrack: vaultTrack));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Lock vault
        authService.emit(const VaultLockedState(lockedAtMonotonicMs: 1000));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(proxy.isExecutingLockStrategy, isTrue);
        expect(proxy.isDecoyActive, isTrue);

        // Re-unlock while vault track is still playing
        authService.emit(
          VaultUnlockedState(
            session: standardSession,
            unlockedAtMonotonicMs: 2000,
            reauthDeadlineMonotonicMs: 3000,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(proxy.currentState, isA<PlaybackPrivacyVaultTrackActiveState>());
        expect(proxy.isVaultTrackActive, isTrue);
        final state = proxy.currentState as PlaybackPrivacyVaultTrackActiveState;
        expect(state.maskingStatus, equals(PlaybackMaskingStatusEnum.unmasked));
        expect(proxy.isDecoyActive, isFalse);
      });

      test('3.10 Non-destructive states (BackgroundGrace, PendingReauth, Authenticating) do not lock audio', () async {
        await proxy.initialize();

        final vaultTrack = playbackService.packagePrivateTrack(
          trackRef: testTrackRef,
          isolatedFilePath: '/storage/vault_media/.nomedia/adv_track_101.mp3',
        );
        proxy.notifyVaultTrackActivated(vaultTrackId: testTrackRef.id, track: vaultTrack);
        expect(proxy.isVaultTrackActive, isTrue);

        // PendingReauth
        authService.emit(
          VaultPendingReauthState(
            session: standardSession,
            reauthTriggeredAtMonotonicMs: 1500,
            remainingAttempts: 3,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(proxy.isVaultTrackActive, isTrue);
        expect(mobiusController.client.stopCallCount, equals(0));

        // BackgroundGrace
        authService.emit(
          VaultBackgroundGraceState(
            session: standardSession,
            enteredBackgroundMonotonicMs: 2000,
            graceTimeoutMs: 30000,
            graceDeadlineMonotonicMs: 32000,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(proxy.isVaultTrackActive, isTrue);
        expect(mobiusController.client.stopCallCount, equals(0));

        // Authenticating
        authService.emit(
          const VaultAuthenticatingState(
            authSessionId: 'sess_auth_01',
            attemptNumber: 1,
            remainingAttemptsBeforeCooldown: 5,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(proxy.isVaultTrackActive, isTrue);
        expect(mobiusController.client.stopCallCount, equals(0));
      });

      test('3.11 Stream errors are handled gracefully without terminating proxy', () async {
        await proxy.initialize();

        authService.emitError(Exception('Network glitch in session stream'));
        mobiusController.emitError(Exception('Queue stream error'));
        await Future<void>.delayed(const Duration(milliseconds: 15));

        expect(proxy.isDisposed, isFalse);
        expect(proxy.currentState, isA<PlaybackPrivacyPublicPassthroughState>());
      });

      test('3.12 Double disposal is safe and idempotent', () async {
        await proxy.initialize();
        expect(proxy.isDisposed, isFalse);

        await proxy.dispose();
        expect(proxy.isDisposed, isTrue);

        // Second dispose call should not throw
        await proxy.dispose();
        expect(proxy.isDisposed, isTrue);
      });
    });

    group('Challenge Group 4: Forbidden Audio Frameworks AST Audit', () {
      test('4.1 Zero imports of just_audio, audio_service, or exoplayer in vault code', () {
        final vaultDir = Directory('lib/features/vault');
        expect(vaultDir.existsSync(), isTrue);

        final dartFiles = vaultDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        final forbiddenPatterns = <Pattern>[
          'just_audio',
          'package:just_audio',
          'audio_service',
          'package:audio_service',
          'exoplayer',
          'ExoPlayer',
        ];

        for (final file in dartFiles) {
          final content = file.readAsStringSync();
          for (final pattern in forbiddenPatterns) {
            expect(
              content.contains(pattern),
              isFalse,
              reason: 'File ${file.path} contains forbidden pattern: $pattern',
            );
          }
        }
      });
    });
  });
}
