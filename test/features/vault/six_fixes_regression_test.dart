import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/media/local_file_image_loader.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/data/datasources/device_music_data_source.dart';
import 'package:musify_mu/features/local_music/data/datasources/local_tracks_store.dart';
import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_play_client.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_queue_client.dart';
import 'package:musify_mu/features/player/data/queue/context_track_extensions.dart';
import 'package:musify_mu/features/player/domain/commands/play_command.dart';
import 'package:musify_mu/features/player/domain/commands/set_queue_command.dart';
import 'package:musify_mu/features/player/domain/commands/stop_command.dart';
import 'package:musify_mu/features/player/domain/commands/update_track_command.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/now_playing_view_model.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';
import 'package:musify_mu/features/player/domain/models/player_response.dart';
import 'package:musify_mu/features/player/domain/models/player_state.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_artwork.dart';
import 'package:musify_mu/features/vault/application/gesture/gesture_engine_cubit.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/data/database/dtos/vault_config_dto.dart';
import 'package:musify_mu/features/vault/data/database/dtos/vault_track_metadata_dto.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/data/services/playback_privacy_proxy.dart';
import 'package:musify_mu/features/vault/data/services/vault_audio_playback_service.dart';
import 'package:musify_mu/features/vault/data/strategies/stop_immediately_lock_strategy.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_screen_privacy_controller.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/mutate_vault_config_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/purge_vault_data_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/rotate_pin_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';
import 'package:musify_mu/features/vault/presentation/screens/private_playlist_detail_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_settings_screen.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';
import 'package:musify_mu/features/vault/presentation/widgets/reauth_blur_overlay.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_artwork_image.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_local_song_picker_sheet.dart';
import 'package:on_audio_query/on_audio_query.dart';

final Uint8List kValid1x1PngBytes = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
  0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99,
  0x3D, 0x1D, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
  0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _FakeMonotonicClock implements IMonotonicClock {
  int nowMs = 5000;

  @override
  int get currentMonotonicMs => nowMs;

  @override
  int get elapsedMilliseconds => nowMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class _FakeScreenPrivacyController implements IScreenPrivacyController {
  final StreamController<ScreenPrivacyStateEnum> _controller =
      StreamController<ScreenPrivacyStateEnum>.broadcast();
  ScreenPrivacyStateEnum _state = ScreenPrivacyStateEnum.publicUnrestricted;

  @override
  ScreenPrivacyStateEnum get currentState => _state;

  @override
  Stream<ScreenPrivacyStateEnum> get stateStream => _controller.stream;

  @override
  Future<void> enableSecureFlag() async {
    _state = ScreenPrivacyStateEnum.secureFlagEngaged;
    _controller.add(_state);
  }

  @override
  Future<void> disableSecureFlag() async {
    _state = ScreenPrivacyStateEnum.publicUnrestricted;
    _controller.add(_state);
  }

  Future<void> dispose() => _controller.close();
}

class _FakeVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> controller =
      StreamController<VaultSessionState>.broadcast();

  Stream<VaultSessionState> get sessionStateStream => controller.stream;

  @override
  Future<LockoutCooldownInfo> getLockoutStatus() async =>
      LockoutCooldownInfo(
        tier: LockoutCooldownTierEnum.none,
        remainingCooldownSeconds: 0,
        deadlineMonotonicMs: 0,
        consecutiveFailedAttempts: 0,
      );

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({
    required String pin,
  }) async =>
      VaultResult.success(
        AuthSession(
          sessionToken: 'token',
          sessionStartedEpochMs: 1000,
          lastActiveEpochMs: 1000,
          authMethod: AuthMethodEnum.pin,
        ),
      );

  @override
  void clearSessionKeysFromRam() {}

  @override
  Future<void> resetFailedAttempts() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeVaultStorageRepository implements IVaultStorageRepository {
  VaultConfig currentConfig;
  final Map<String, PrivatePlaylist> playlists = {};
  int saveConfigCalls = 0;

  _FakeVaultStorageRepository([VaultConfig? initialConfig])
      : currentConfig = initialConfig ?? const VaultConfig.constant();

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(currentConfig);

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig config) async {
    saveConfigCalls++;
    currentConfig = config;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<PrivatePlaylist>> getPlaylistById(String id) async {
    final playlist = playlists[id];
    if (playlist != null) {
      return VaultResult.success(playlist);
    }
    return const VaultResult.failure(VaultStorageFailure('Playlist not found'));
  }

  @override
  Future<int?> getPersistedLockoutDeadlineMs() async => null;

  @override
  Future<void> clearPersistedLockoutDeadline() async {}

  @override
  Future<VaultResult<GestureTemplate>> loadGestureTemplate() async =>
      VaultResult.success(DefaultGestureTemplate.canonicalVShape);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGestureRecognizer implements IGestureRecognizer {
  @override
  Future<VaultResult<RecognitionScore>> evaluateStroke({
    required GestureSample liveStroke,
    required GestureTemplate template,
    required GestureSensitivityTierEnum sensitivityTier,
  }) async =>
      VaultResult.success(
        RecognitionScore(
          dollarOneScore: 0.95,
          dtwScore: 0.92,
          featureScore: 0.90,
          ensembleScore: 0.93,
          decision: GestureMatchDecisionEnum.matched,
        ),
      );

  @override
  Future<VaultResult<GestureTemplate>> synthesizeMasterTemplate({
    required List<GestureSample> samples,
  }) async =>
      VaultResult.success(DefaultGestureTemplate.canonicalVShape);

  @override
  Future<VaultResult<void>> validateSampleConsistency({
    required List<GestureSample> samples,
  }) async =>
      const VaultResult.success(null);
}

class _FakePlayClient implements ContextPlayerPlayClient {
  final List<ContextTrack> updatedTracks = [];
  final List<PlayCommand> playCommands = [];
  void Function(ContextTrack track)? onTrackUpdated;

  @override
  Future<void> updateTrack(UpdateTrackCommand command) async {
    updatedTracks.add(command.track);
    onTrackUpdated?.call(command.track);
  }

  @override
  Future<PlayerResponse> play(PlayCommand command) async {
    playCommands.add(command);
    return PlayerResponse.success;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQueueClient implements ContextPlayerQueueClient {
  final StreamController<PlayerQueue> _controller =
      StreamController<PlayerQueue>.broadcast();
  final List<SetQueueCommand> setQueueCommands = [];
  ContextTrack? activeTrack;

  @override
  Stream<PlayerQueue> get queueStream => _controller.stream;

  @override
  Stream<PlayerQueue> getQueueStream() => _controller.stream;

  void emitQueue(PlayerQueue queue) {
    activeTrack = queue.track;
    if (!_controller.isClosed) {
      _controller.add(queue);
    }
  }

  @override
  Future<PlayerResponse> setQueue(SetQueueCommand command) async {
    setQueueCommands.add(command);
    final isReset = command.queueRevision.isEmpty &&
        command.nextTracks.isEmpty &&
        command.prevTracks.isEmpty;
    final nextTrack = isReset ? null : activeTrack;
    emitQueue(
      PlayerQueue(
        revision: command.queueRevision,
        track: nextTrack,
        nextTracks: command.nextTracks,
        prevTracks: command.prevTracks,
      ),
    );
    return PlayerResponse.success;
  }

  Future<void> dispose() => _controller.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeControlClient implements ContextPlayerControlClient {
  int stopCount = 0;

  @override
  Future<PlayerResponse> stop(StopCommand command) async {
    stopCount++;
    return PlayerResponse.success;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocalTracksStore implements LocalTracksStore {
  final List<LocalTrack> tracks;

  _FakeLocalTracksStore(this.tracks);

  @override
  Future<List<LocalTrack>> getAll() async => tracks;

  @override
  Stream<List<LocalTrack>> watchAll() => Stream.value(tracks);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDeviceMusicDataSource implements DeviceMusicDataSource {
  @override
  Future<Uint8List?> queryArtwork(int songId, {int size = 200}) async => null;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<List<SongModel>> querySongs() async => const [];

  @override
  Stream<void> get changes => const Stream.empty();
}

class _FakeIsolationManager implements IVaultMediaIsolationManager {
  final Map<String, File> files = {};
  final List<String> requestedTrackIds = <String>[];

  @override
  Future<File> getIsolatedTrackFile(String trackId) async {
    requestedTrackIds.add(trackId);
    final f = files[trackId];
    if (f != null) return f;
    throw FileSystemException('Track not found in fake isolation', trackId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _drainAsyncQueue() async {
  await Future<void>.delayed(const Duration(milliseconds: 30));
  await Future<void>.delayed(const Duration(milliseconds: 30));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bug 1: Decoy Persona Save Button & Immediate Queue Reactivity', () {
    late _FakeMonotonicClock clock;
    late _FakeScreenPrivacyController privacyController;
    late _FakeVaultAuthService authService;
    late _FakeVaultStorageRepository storage;
    late _FakeGestureRecognizer recognizer;
    late SettingsMutationCubit settingsCubit;
    late VaultSessionBloc sessionBloc;
    late ScreenPrivacyCubit screenPrivacyCubit;
    late GestureEngineCubit gestureCubit;
    late PinPadCubit pinPadCubit;

    setUp(() {
      clock = _FakeMonotonicClock();
      privacyController = _FakeScreenPrivacyController();
      authService = _FakeVaultAuthService();
      storage = _FakeVaultStorageRepository();
      recognizer = _FakeGestureRecognizer();
    });

    testWidgets(
      'Privacy screen does NOT auto-save per keystroke, rejects blank fields, and persists trimmed decoy on explicit Save button tap',
      (tester) async {
        final mutateUseCase = MutateVaultConfigUseCase(
          storageRepository: storage,
          authService: authService,
        );
        final unlockUseCase = UnlockVaultUseCase(authService: authService);
        final coolOffUseCase = VerifySessionCoolOffUseCase(clock: clock);

        settingsCubit = SettingsMutationCubit(
          storageRepository: storage,
          mutateVaultConfigUseCase: mutateUseCase,
          authService: authService,
          monotonicClock: clock,
        );
        await settingsCubit.initialize();

        sessionBloc = VaultSessionBloc(
          authService: authService,
          storageRepository: storage,
          monotonicClock: clock,
          verifyCoolOffUseCase: coolOffUseCase,
        );
        screenPrivacyCubit = ScreenPrivacyCubit(
          privacyController: privacyController,
          monotonicClock: clock,
        );
        gestureCubit = GestureEngineCubit(
          recognizer: recognizer,
          storageRepository: storage,
          vaultAuthService: authService,
        );
        pinPadCubit = PinPadCubit(
          unlockVaultUseCase: unlockUseCase,
          authService: authService,
          monotonicClock: clock,
        );

        addTearDown(() async {
          await settingsCubit.close();
          await sessionBloc.close();
          await screenPrivacyCubit.close();
          await gestureCubit.close();
          await pinPadCubit.close();
          await authService.controller.close();
          await privacyController.dispose();
        });

        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<SettingsMutationCubit>.value(value: settingsCubit),
              BlocProvider<VaultSessionBloc>.value(value: sessionBloc),
              BlocProvider<ScreenPrivacyCubit>.value(value: screenPrivacyCubit),
              BlocProvider<GestureEngineCubit>.value(value: gestureCubit),
              BlocProvider<PinPadCubit>.value(value: pinPadCubit),
            ],
            child: VaultTheme(
              data: VaultThemeData.fromConfig(storage.currentConfig),
              child: MaterialApp(
                home: VaultSettingsScreen(
                  settingsMutationCubit: settingsCubit,
                  sessionBloc: sessionBloc,
                  screenPrivacyCubit: screenPrivacyCubit,
                  gestureEngineCubit: gestureCubit,
                  storageRepository: storage,
                  authService: authService,
                  rotatePinUseCase: RotatePinUseCase(authService: authService),
                  purgeVaultDataUseCase: PurgeVaultDataUseCase(
                    authService: authService,
                    storageRepository: storage,
                  ),
                  unlockVaultUseCase: UnlockVaultUseCase(authService: authService),
                  monotonicClock: clock,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('nav_tile_privacy')));
        await tester.pumpAndSettle();

        final saveBtnFinder = find.byKey(const ValueKey('decoy_save_button'));
        expect(saveBtnFinder, findsOneWidget);

        final ElevatedButton saveBtn = tester.widget(saveBtnFinder);
        final shape = saveBtn.style?.shape?.resolve({});
        expect(shape, isA<RoundedRectangleBorder>());
        expect(
          (shape as RoundedRectangleBorder).borderRadius,
          equals(VaultTheme.borderRadius8),
        );

        final initialSaveCalls = storage.saveConfigCalls;

        // Typing must not trigger auto-save even after >350ms
        await tester.enterText(
          find.byKey(const ValueKey('decoy_title_field')),
          '  Podcast Episode 42  ',
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(storage.saveConfigCalls, equals(initialSaveCalls));
        expect(storage.currentConfig.decoyTitle, equals('System Audio'));

        // Whitespace-only input fails validation on explicit Save
        await tester.enterText(
          find.byKey(const ValueKey('decoy_title_field')),
          '   ',
        );
        await tester.ensureVisible(saveBtnFinder);
        await tester.tap(saveBtnFinder);
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('decoy_validation_error')), findsOneWidget);
        expect(storage.saveConfigCalls, equals(initialSaveCalls));

        // Valid fields save trimmed values on explicit Save
        await tester.enterText(
          find.byKey(const ValueKey('decoy_title_field')),
          '  Podcast Episode 42  ',
        );
        await tester.enterText(
          find.byKey(const ValueKey('decoy_artist_field')),
          '  Public Broadcaster  ',
        );
        await tester.enterText(
          find.byKey(const ValueKey('decoy_album_field')),
          '  Daily Briefing  ',
        );
        await tester.ensureVisible(saveBtnFinder);
        await tester.pumpAndSettle();
        expect(tester.widget<ElevatedButton>(saveBtnFinder).onPressed, isNotNull);
        await tester.tap(saveBtnFinder);
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('decoy_validation_error')), findsNothing);
        expect(storage.currentConfig.decoyTitle, equals('Podcast Episode 42'));
        expect(storage.currentConfig.decoyArtist, equals('Public Broadcaster'));
        expect(storage.currentConfig.decoyAlbum, equals('Daily Briefing'));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    test(
      'Saving new decoy persona immediately re-projects active track & lookahead queue to Mobius and native engine',
      () async {
        final playClient = _FakePlayClient();
        final queueClient = _FakeQueueClient();
        playClient.onTrackUpdated = (t) => queueClient.activeTrack = t;
        final controlClient = _FakeControlClient();
        final storageRepo = _FakeVaultStorageRepository(
          const VaultConfig.constant(
            metadataVisibility: MetadataVisibilityPolicyEnum.maskWithPlaceholder,
          ),
        );
        final mobius = PlayerQueueMobiusController(
          queueClient: queueClient,
          controlClient: controlClient,
          playClient: playClient,
        );
        final proxy = PlaybackPrivacyProxy(
          mobiusController: mobius,
          storageRepository: storageRepo,
          playClient: playClient,
          queueClient: queueClient,
          controlClient: controlClient,
          initialConfig: storageRepo.currentConfig,
        );

        addTearDown(() async {
          proxy.dispose();
          await mobius.close();
          await queueClient.dispose();
        });

        final originalTrack1 = ContextTrack(
          uri: 'spotify:track:sp_1',
          uid: 'vault_tr_1',
          provider: 'musify_vault',
          metadata: const {
            ContextTrackMetadata.keyTitle: 'Real Secret Title 1',
            ContextTrackMetadata.keyArtistName: 'Real Secret Artist 1',
            ContextTrackMetadata.keyAlbumTitle: 'Real Secret Album 1',
            ContextTrackMetadata.keyImageUrl: 'https://i.scdn.co/image/secret_1',
            ContextTrackMetadata.keyImageLargeUrl: 'https://i.scdn.co/image/secret_1_lg',
            'is_vault_track': 'true',
            'vault_track_id': 'tr_1',
          },
        );
        final originalTrack2 = ContextTrack(
          uri: 'spotify:track:sp_2',
          uid: 'vault_tr_2',
          provider: 'musify_vault',
          metadata: const {
            ContextTrackMetadata.keyTitle: 'Real Secret Title 2',
            ContextTrackMetadata.keyArtistName: 'Real Secret Artist 2',
            ContextTrackMetadata.keyAlbumTitle: 'Real Secret Album 2',
            ContextTrackMetadata.keyImageUrl: 'https://i.scdn.co/image/secret_2',
            'is_vault_track': 'true',
            'vault_track_id': 'tr_2',
          },
        );

        proxy.registerOriginalVaultTracks([originalTrack1, originalTrack2]);
        await proxy.initialize();

        final initialMasked1 = proxy.projectTrack(originalTrack1);
        final initialMasked2 = proxy.projectTrack(originalTrack2);
        queueClient.activeTrack = initialMasked1;
        mobius.dispatch(
          QueueUpdatedEvent(
            PlayerQueue(
              revision: 'rev_1',
              track: initialMasked1,
              nextTracks: [initialMasked2],
            ),
          ),
        );
        await _drainAsyncQueue();

        // Update decoy persona while masked queue is active
        proxy.updateConfig(
          storageRepo.currentConfig.copyWith(
            decoyTitle: 'Morning News Brief',
            decoyArtist: 'FM Studio',
            decoyAlbum: 'Public Feed',
          ),
        );
        await _drainAsyncQueue();

        expect(mobius.model.currentTrack?.title, equals('Morning News Brief'));
        expect(mobius.model.currentTrack?.artist, equals('FM Studio'));
        expect(mobius.model.currentTrack?.album, equals('Public Feed'));
        expect(mobius.model.playerQueue.nextTracks.first.title, equals('Morning News Brief'));
        expect(playClient.updatedTracks.last.title, equals('Morning News Brief'));
        expect(
          queueClient.setQueueCommands.last.nextTracks.first.title,
          equals('Morning News Brief'),
        );
      },
    );
  });

  group('Bug 2: Metadata Masking Artwork Leak Prevention & Unmask Reactivity', () {
    test(
      'Masking strips Spotify artwork across packaging and NowPlayingViewModel, and toggling masking OFF restores original Spotify artwork & metadata',
      () async {
        final playClient = _FakePlayClient();
        final queueClient = _FakeQueueClient();
        playClient.onTrackUpdated = (t) => queueClient.activeTrack = t;
        final controlClient = _FakeControlClient();
        final storageRepo = _FakeVaultStorageRepository(
          const VaultConfig.constant(
            metadataVisibility: MetadataVisibilityPolicyEnum.maskWithPlaceholder,
            decoyTitle: 'Study Ambient',
            decoyArtist: 'Focus Engine',
            decoyAlbum: 'Vault Focus Session',
          ),
        );
        final mobius = PlayerQueueMobiusController(
          queueClient: queueClient,
          controlClient: controlClient,
          playClient: playClient,
        );
        final proxy = PlaybackPrivacyProxy(
          mobiusController: mobius,
          storageRepository: storageRepo,
          playClient: playClient,
          queueClient: queueClient,
          controlClient: controlClient,
          initialConfig: storageRepo.currentConfig,
        );
        final playbackService = VaultAudioPlaybackService(
          mobiusController: mobius,
          privacyProxy: proxy,
        );

        addTearDown(() async {
          proxy.dispose();
          await mobius.close();
          await queueClient.dispose();
        });

        await proxy.initialize();

        final spotifyTrackRef = PrivateTrackRef(
          id: 'sp_hidden_1',
          playlistId: 'pl_secret',
          trackUri: 'spotify:track:abc123',
          title: 'Secret Spotify Anthem',
          artistName: 'Hidden Musician',
          albumTitle: 'Private LP',
          artworkUri: 'https://i.scdn.co/image/real_cover_99',
          durationMs: 215000,
          sourceType: TrackSourceTypeEnum.spotify,
          sortOrder: 0,
          addedAtEpochMs: 1700000000000,
        );

        final playlist = PrivatePlaylist(
          id: 'pl_secret',
          name: 'Ultra Secret Playlist',
          description: 'Do not leak',
          coverUri: 'https://i.scdn.co/image/real_cover_99',
          totalDurationMs: 215000,
          createdAtEpochMs: 1700000000000,
          updatedAtEpochMs: 1700000000000,
          trackRefs: [spotifyTrackRef],
        );

        // Play playlist under live proxy config (maskWithPlaceholder)
        await playbackService.playPrivatePlaylist(
          playlist: playlist,
          startIndex: 0,
        );

        expect(playClient.playCommands, hasLength(1));
        final playedCmd = playClient.playCommands.single;
        expect(
          playedCmd.context.metadata[ContextTrackMetadata.keyTitle],
          equals('Vault Focus Session'),
        );

        final packagedTrack = playedCmd.context.pages!.first.tracks!.single;
        expect(packagedTrack.title, equals('Study Ambient'));
        expect(packagedTrack.metadata['musify_vault_masked'], equals('true'));
        expect(packagedTrack.metadata.containsKey(ContextTrackMetadata.keyImageUrl), isFalse);
        expect(packagedTrack.metadata.containsKey(ContextTrackMetadata.keyImageSmallUrl), isFalse);
        expect(packagedTrack.metadata.containsKey(ContextTrackMetadata.keyImageLargeUrl), isFalse);
        expect(packagedTrack.metadata.containsKey(ContextTrackMetadata.keyImageXlargeUrl), isFalse);
        expect(packagedTrack.metadata.containsKey(ContextTrackMetadata.keyThumbnailImageUrl), isFalse);

        // Simulate active masked queue inside Mobius
        mobius.dispatch(
          QueueUpdatedEvent(
            PlayerQueue(
              revision: 'rev_masked',
              track: packagedTrack,
            ),
          ),
        );
        await _drainAsyncQueue();

        // Verify NowPlayingViewModel blocks Spotify artwork/title fallback while masked
        final maskedVm = NowPlayingViewModel.fromPlayerQueueState(
          mobius.model,
          fallbackTrack: ContextTrack(
            uri: spotifyTrackRef.trackUri,
            metadata: const {
              ContextTrackMetadata.keyTitle: 'Leaked Fallback Title',
              ContextTrackMetadata.keyImageUrl: 'https://i.scdn.co/image/leaked_fallback',
            },
          ),
          fallbackTitle: 'Leaked Title String',
          fallbackImageUrl: 'https://i.scdn.co/image/leaked_fallback_url',
        );
        expect(maskedVm.imageUrl, isNull);
        expect(maskedVm.title, equals('Study Ambient'));

        // Toggle metadata masking OFF -> must restore original Spotify metadata + artwork immediately
        proxy.updateConfig(
          storageRepo.currentConfig.copyWith(
            metadataVisibility: MetadataVisibilityPolicyEnum.showActualMetadata,
          ),
        );
        await _drainAsyncQueue();

        final restoredTrack = mobius.model.currentTrack!;
        expect(restoredTrack.metadata['musify_vault_masked'], isNot('true'));
        expect(restoredTrack.title, equals('Secret Spotify Anthem'));
        expect(restoredTrack.artist, equals('Hidden Musician'));
        expect(restoredTrack.album, equals('Private LP'));
        expect(
          restoredTrack.metadata[ContextTrackMetadata.keyImageUrl],
          equals('https://i.scdn.co/image/real_cover_99'),
        );
        expect(
          restoredTrack.metadata[ContextTrackMetadata.keyImageLargeUrl],
          equals('https://i.scdn.co/image/real_cover_99'),
        );
        expect(
          playClient.updatedTracks.last.metadata[ContextTrackMetadata.keyImageUrl],
          equals('https://i.scdn.co/image/real_cover_99'),
        );

        final restoredVm = NowPlayingViewModel.fromPlayerQueueState(mobius.model);
        expect(restoredVm.imageUrl, equals('https://i.scdn.co/image/real_cover_99'));
        expect(restoredVm.title, equals('Secret Spotify Anthem'));
      },
    );
  });

  group('Bug 3: Stop Immediately Lock Behavior Clears Queue', () {
    test(
      'Locking vault with LockPlaybackBehaviorEnum.stopImmediately stops native player and clears currentTrack & entire queue',
      () async {
        final playClient = _FakePlayClient();
        final queueClient = _FakeQueueClient();
        playClient.onTrackUpdated = (t) => queueClient.activeTrack = t;
        final controlClient = _FakeControlClient();
        final storageRepo = _FakeVaultStorageRepository(
          const VaultConfig.constant(
            lockPlaybackBehavior: LockPlaybackBehaviorEnum.stopImmediately,
          ),
        );
        final mobius = PlayerQueueMobiusController(
          queueClient: queueClient,
          controlClient: controlClient,
          playClient: playClient,
        );
        final proxy = PlaybackPrivacyProxy(
          mobiusController: mobius,
          storageRepository: storageRepo,
          playClient: playClient,
          queueClient: queueClient,
          controlClient: controlClient,
          initialConfig: storageRepo.currentConfig,
        );

        addTearDown(() async {
          proxy.dispose();
          await mobius.close();
          await queueClient.dispose();
        });

        await proxy.initialize();

        final track1 = ContextTrack(
          uri: 'spotify:track:v1',
          uid: 'vault_v1',
          provider: 'musify_vault',
          metadata: const {
            ContextTrackMetadata.keyTitle: 'Private Song 1',
            'is_vault_track': 'true',
            'vault_track_id': 'v1',
          },
        );
        final track2 = ContextTrack(
          uri: 'spotify:track:v2',
          uid: 'vault_v2',
          provider: 'musify_vault',
          metadata: const {
            ContextTrackMetadata.keyTitle: 'Private Song 2',
            'is_vault_track': 'true',
            'vault_track_id': 'v2',
          },
        );

        mobius.dispatch(
          QueueUpdatedEvent(
            PlayerQueue(
              revision: 'rev_active',
              track: track1,
              nextTracks: [track2],
            ),
          ),
        );
        mobius.dispatch(
          PlayerStateChangedEvent(
            PlayerState(track: track1, isPlaying: true, isPaused: false),
          ),
        );
        await _drainAsyncQueue();

        expect(mobius.model.nowPlaying, isNotNull);
        expect(mobius.model.contextTracks, isNotEmpty);

        proxy.handleSessionStateTransition(
          const VaultLockedState(lockedAtMonotonicMs: 6000),
        );
        await _drainAsyncQueue();

        expect(controlClient.stopCount, equals(1));
        expect(mobius.model.currentTrack, isNull);
        expect(mobius.model.nowPlaying, isNull);
        expect(mobius.model.nextTrack, isNull);
        expect(mobius.model.userQueue, isEmpty);
        expect(mobius.model.contextTracks, isEmpty);
        expect(mobius.model.playerQueue, equals(PlayerQueue.empty));
        expect(queueClient.setQueueCommands.last.nextTracks, isEmpty);
        expect(
          queueClient.setQueueCommands.last.options?.overrideRestrictions,
          isTrue,
        );
      },
    );

    test('StopImmediatelyLockStrategy.executeLock clears populated queue directly', () async {
      final queueClient = _FakeQueueClient();
      final controlClient = _FakeControlClient();
      final mobius = PlayerQueueMobiusController(
        queueClient: queueClient,
        controlClient: controlClient,
      );
      addTearDown(() async {
        await mobius.close();
        await queueClient.dispose();
      });

      final t = ContextTrack(
        uri: 'spotify:track:q1',
        uid: 'vault_q1',
        metadata: const {ContextTrackMetadata.keyIsQueued: 'true'},
      );
      mobius.dispatch(
        QueueUpdatedEvent(
          PlayerQueue(revision: 'r1', track: t, nextTracks: [t]),
        ),
      );
      await _drainAsyncQueue();

      await const StopImmediatelyLockStrategy().executeLock(
        mobiusController: mobius,
        playerControlClient: controlClient,
      );
      await _drainAsyncQueue();

      expect(controlClient.stopCount, equals(1));
      expect(mobius.model.nowPlaying, isNull);
      expect(mobius.model.userQueue, isEmpty);
      expect(queueClient.setQueueCommands.last.nextTracks, isEmpty);
    });
  });

  group('Bug 4: EOS Empty-Queue Safety Invariant', () {
    test(
      'PlayerStateChangedEvent with null track & stopped flags clears stale currentTrack cleanly at EOS',
      () {
        const activeTrack = ContextTrack(
          uri: 'spotify:track:eos_track',
          uid: 'eos_1',
        );
        const initialModel = QueueModel(
          currentTrack: activeTrack,
          playerQueue: PlayerQueue(revision: 'rev_eos', track: activeTrack),
          isLoading: false,
        );

        final eosPlayerState = PlayerState(
          track: null,
          isPlaying: false,
          isPaused: false,
          isBuffering: false,
        );

        final next = queueMobiusUpdate(
          initialModel,
          PlayerStateChangedEvent(eosPlayerState),
        );
        final nextModel = next.model;
        expect(nextModel, isNotNull);
        expect(nextModel?.currentTrack, isNull);

        final clearedQueueNext = queueMobiusUpdate(
          nextModel ?? initialModel,
          const QueueUpdatedEvent(PlayerQueue.empty),
        );
        expect(clearedQueueNext.model?.nowPlaying, isNull);
        expect(clearedQueueNext.model?.playerQueue, equals(PlayerQueue.empty));
      },
    );
  });

  group('Bug 5: Album Art Display in Detail, Picker, DTO & Sandbox Extraction', () {
    test(
      'VaultTrackMetadataDto preserves optional artworkUri, stays backward-compatible with legacy rows, and validates malformed URIs',
      () {
        final legacyJson = <String, Object?>{
          'trackUri': '/storage/emulated/0/Music/legacy.mp3',
          'sourceType': TrackSourceTypeEnum.localReference.name,
          'addedAtEpochMs': 1700000000000,
        };
        final legacyDto = VaultTrackMetadataDto.fromJson(legacyJson);
        expect(legacyDto.artworkUri, isNull);
        expect(legacyDto.toJson().containsKey('artworkUri'), isFalse);

        final modernDto = VaultTrackMetadataDto(
          trackUri: 'spotify:track:modern',
          sourceType: TrackSourceTypeEnum.spotify,
          addedAtEpochMs: 1700000000001,
          artworkUri: 'https://i.scdn.co/image/cover123',
        );
        final roundTripped = VaultTrackMetadataDto.fromJson(modernDto.toJson());
        expect(roundTripped.artworkUri, equals('https://i.scdn.co/image/cover123'));

        expect(
          () => VaultTrackMetadataDto.fromJson({
            ...legacyJson,
            'artworkUri': '   ',
          }),
          throwsA(isA<FormatException>()),
        );
      },
    );

    testWidgets(
      'VaultArtworkImage extracts embedded artwork for .nomedia sandbox tracks via native local_artwork channel and falls back on playlists',
      (tester) async {
        const channel = MethodChannel('um.musify.mu/local_artwork');
        final calls = <MethodCall>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            calls.add(call);
            if (call.method == 'extractEmbeddedArtwork') {
              return kValid1x1PngBytes;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );

        final loader = LocalFileImageLoader(
          store: _FakeLocalTracksStore(const []),
          deviceMusic: _FakeDeviceMusicDataSource(),
        );
        addTearDown(loader.dispose);

        final sandboxTrack = PrivateTrackRef(
          id: 'sandbox_art_1',
          playlistId: 'pl_art',
          trackUri: 'file:///vault_media/.nomedia/secret_track.mp3',
          title: 'Sandbox Song',
          artistName: 'Vault Artist',
          albumTitle: 'Secret Tape',
          artworkUri: null,
          durationMs: 190000,
          sourceType: TrackSourceTypeEnum.localSandbox,
          localRelativePath: 'secret_track.mp3',
          sortOrder: 0,
          addedAtEpochMs: 1700000000000,
        );

        final playlistWithoutCover = PrivatePlaylist(
          id: 'pl_art',
          name: 'Sandbox Collection',
          description: 'Uses track fallback art',
          coverUri: null,
          totalDurationMs: 190000,
          createdAtEpochMs: 1700000000000,
          updatedAtEpochMs: 1700000000000,
          trackRefs: [sandboxTrack],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: VaultTheme(
              data: VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.warmEspresso),
              child: Scaffold(
                body: Center(
                  child: VaultArtworkImage.forPlaylist(
                    playlistWithoutCover,
                    localFileImageLoader: loader,
                    isolationManager: _FakeIsolationManager(),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          calls.where((c) => c.method == 'extractEmbeddedArtwork'),
          isNotEmpty,
        );
        final extractCall = calls.firstWhere(
          (c) => c.method == 'extractEmbeddedArtwork',
        );
        expect(
          (extractCall.arguments as Map)['filePath'],
          equals('/vault_media/.nomedia/secret_track.mp3'),
        );
        expect(find.byType(Image), findsOneWidget);
      },
    );

    testWidgets(
      'VaultArtworkImage caps fallback track scanning and sandbox recovery to 4 tracks and skips known-missing tracks synchronously',
      (tester) async {
        const channel = MethodChannel('um.musify.mu/local_artwork');
        final calls = <MethodCall>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            calls.add(call);
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );

        final loader = LocalFileImageLoader(
          store: _FakeLocalTracksStore(const []),
          deviceMusic: _FakeDeviceMusicDataSource(),
        );
        addTearDown(loader.dispose);
        final isolation = _FakeIsolationManager();

        final artlessRefTracks = List<PrivateTrackRef>.generate(
          10,
          (i) => PrivateTrackRef(
            id: 'artless_ref_$i',
            playlistId: 'pl_cap',
            trackUri: 'file:///vault_media/artless_$i.mp3',
            title: 'Artless Track $i',
            artistName: 'Artist',
            albumTitle: 'Album',
            artworkUri: null,
            durationMs: 180000,
            sourceType: TrackSourceTypeEnum.localReference,
            sortOrder: i,
            addedAtEpochMs: 1700000000000 + i,
          ),
        );

        final sandboxRecoveryTracks = List<PrivateTrackRef>.generate(
          10,
          (i) => PrivateTrackRef(
            id: 'artless_sandbox_$i',
            playlistId: 'pl_sandbox_cap',
            trackUri: 'vault://sandbox/artless_$i',
            title: 'Sandbox Track $i',
            artistName: 'Artist',
            albumTitle: 'Album',
            artworkUri: null,
            durationMs: 180000,
            sourceType: TrackSourceTypeEnum.localSandbox,
            localRelativePath: 'artless_$i.mp3',
            sortOrder: i,
            addedAtEpochMs: 1700000000000 + i,
          ),
        );

        // First render of 10 artless localReference tracks scans at most 4 candidates.
        await tester.pumpWidget(
          MaterialApp(
            home: VaultTheme(
              data: VaultThemeData.fromPalette(
                VaultThemePalettePolicyEnum.warmEspresso,
              ),
              child: Scaffold(
                body: VaultArtworkImage(
                  fallbackTracks: artlessRefTracks,
                  width: 140,
                  height: 140,
                  localFileImageLoader: loader,
                  isolationManager: isolation,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          calls.where((c) => c.method == 'extractEmbeddedArtwork').length,
          equals(4),
        );

        // Re-rendering with the same 4 known-missing candidates triggers zero additional platform calls.
        calls.clear();
        await tester.pumpWidget(
          MaterialApp(
            home: VaultTheme(
              data: VaultThemeData.fromPalette(
                VaultThemePalettePolicyEnum.warmEspresso,
              ),
              child: Scaffold(
                body: VaultArtworkImage(
                  key: const ValueKey('second_known_missing_check'),
                  fallbackTracks: artlessRefTracks,
                  width: 140,
                  height: 140,
                  localFileImageLoader: loader,
                  isolationManager: isolation,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(calls, isEmpty);

        // Rendering 10 sandbox tracks without paths caps getIsolatedTrackFile calls to 4.
        await tester.pumpWidget(
          MaterialApp(
            home: VaultTheme(
              data: VaultThemeData.fromPalette(
                VaultThemePalettePolicyEnum.warmEspresso,
              ),
              child: Scaffold(
                body: VaultArtworkImage(
                  fallbackTracks: sandboxRecoveryTracks,
                  width: 140,
                  height: 140,
                  localFileImageLoader: loader,
                  isolationManager: isolation,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(isolation.requestedTrackIds.length, equals(4));
      },
    );

    testWidgets(
      'VaultLocalSongPickerSheet renders PlayerArtworkImage tiles and PrivatePlaylistDetailScreen renders VaultArtworkImage cleanly for Spotify & sandbox tracks',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        const channel = MethodChannel('um.musify.mu/local_artwork');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            if (call.method == 'extractEmbeddedArtwork') {
              return kValid1x1PngBytes;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );

        final localTrack = LocalTrack(
          id: 1,
          songId: 501,
          title: 'Local Studio Bounce',
          artist: 'Producer X',
          album: 'Sessions',
          dataPath: '/storage/emulated/0/Music/studio_bounce.flac',
          duration: 205000,
          dateModified: 1700000000,
        );
        final tracksStore = _FakeLocalTracksStore([localTrack]);
        final deviceMusic = _FakeDeviceMusicDataSource();
        final loader = LocalFileImageLoader(
          store: tracksStore,
          deviceMusic: deviceMusic,
        );
        final isolationManager = _FakeIsolationManager();

        await getIt.reset();
        getIt.registerSingleton<LocalFileImageLoader>(loader);
        getIt.registerSingleton<IVaultMediaIsolationManager>(isolationManager);
        addTearDown(() async {
          loader.dispose();
          await getIt.reset();
        });

        final playlist = PrivatePlaylist(
          id: 'pl_detail_art',
          name: 'Mixed Vault Art',
          description: 'Spotify + Sandbox artwork',
          coverUri: null,
          totalDurationMs: 395000,
          createdAtEpochMs: 1700000000000,
          updatedAtEpochMs: 1700000000000,
          trackRefs: [
            PrivateTrackRef(
              id: 'sp_1',
              playlistId: 'pl_detail_art',
              trackUri: 'spotify:track:art_sp_1',
              title: 'Spotify Art Track',
              artistName: 'Cloud Artist',
              albumTitle: 'Cloud LP',
              artworkUri: 'https://i.scdn.co/image/test_cover_1',
              durationMs: 190000,
              sourceType: TrackSourceTypeEnum.spotify,
              sortOrder: 0,
              addedAtEpochMs: 1700000000000,
            ),
            PrivateTrackRef(
              id: 'sb_1',
              playlistId: 'pl_detail_art',
              trackUri: 'file:///vault_media/.nomedia/sb_1.flac',
              title: 'Isolated Sandbox Track',
              artistName: 'Vault Artist',
              albumTitle: 'Vault LP',
              artworkUri: null,
              durationMs: 205000,
              sourceType: TrackSourceTypeEnum.localSandbox,
              localRelativePath: 'sb_1.flac',
              sortOrder: 1,
              addedAtEpochMs: 1700000000001,
            ),
          ],
        );

        final storageRepo = _FakeVaultStorageRepository()
          ..playlists[playlist.id] = playlist;
        final clock = _FakeMonotonicClock();
        final privacyController = _FakeScreenPrivacyController();
        final authService = _FakeVaultAuthService();
        final privacyCubit = ScreenPrivacyCubit(
          privacyController: privacyController,
          monotonicClock: clock,
        );
        final sessionBloc = VaultSessionBloc(
          authService: authService,
          storageRepository: storageRepo,
          monotonicClock: clock,
          verifyCoolOffUseCase: VerifySessionCoolOffUseCase(clock: clock),
          initialState: VaultUnlockedState(
            session: AuthSession(
              sessionToken: 't',
              sessionStartedEpochMs: 1000,
              lastActiveEpochMs: 1000,
              authMethod: AuthMethodEnum.pin,
            ),
            unlockedAtMonotonicMs: 1000,
            reauthDeadlineMonotonicMs: 90000,
          ),
        );
        final mobius = PlayerQueueMobiusController();
        final playbackService = VaultAudioPlaybackService(
          mobiusController: mobius,
          isolationManager: isolationManager,
        );

        addTearDown(() async {
          await privacyCubit.close();
          await sessionBloc.close();
          await mobius.close();
          await authService.controller.close();
          await privacyController.dispose();
        });

        // Verify VaultLocalSongPickerSheet renders PlayerArtworkImage for local tracks
        await tester.pumpWidget(
          MaterialApp(
            home: VaultTheme(
              data: VaultThemeData.fromConfig(storageRepo.currentConfig),
              child: Scaffold(
                body: VaultLocalSongPickerSheet(
                  playlist: playlist,
                  storageRepository: storageRepo,
                  isolationManager: isolationManager,
                  localTracksStore: tracksStore,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PlayerArtworkImage), findsOneWidget);

        // Verify PrivatePlaylistDetailScreen renders VaultArtworkImage for header + both track rows
        await tester.pumpWidget(
          MaterialApp(
            home: VaultTheme(
              data: VaultThemeData.fromConfig(storageRepo.currentConfig),
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<VaultSessionBloc>.value(value: sessionBloc),
                  BlocProvider<ScreenPrivacyCubit>.value(value: privacyCubit),
                ],
                child: PrivatePlaylistDetailScreen(
                  playlistId: playlist.id,
                  storageRepository: storageRepo,
                  audioPlaybackService: playbackService,
                  sessionBloc: sessionBloc,
                  screenPrivacyCubit: privacyCubit,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(VaultArtworkImage), findsNWidgets(3));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  });

  group('Bug 6: Frosted Glass Blur Calibration Persistence & Reactive Effect', () {
    test(
      'VaultConfig & VaultConfigDto validate [4.0, 24.0] frostedBlurSigma, default legacy configs to 12.0, and round-trip JSON',
      () {
        expect(const VaultConfig.constant().frostedBlurSigma, equals(12.0));

        expect(
          () => VaultConfig.constant(frostedBlurSigma: 3.9),
          throwsAssertionError,
        );
        expect(
          () => VaultConfig.constant(frostedBlurSigma: 24.1),
          throwsAssertionError,
        );
        expect(
          () => VaultConfig.constant(frostedBlurSigma: double.nan),
          throwsAssertionError,
        );

        final customConfig = const VaultConfig.constant(frostedBlurSigma: 20.5);
        final json = VaultConfigDto.toJson(customConfig);
        expect(json['frostedBlurSigma'], equals(20.5));
        final decoded = VaultConfigDto.fromJson(json);
        expect(decoded.frostedBlurSigma, equals(20.5));

        final legacyJson = Map<String, Object?>.from(json)
          ..remove('frostedBlurSigma');
        expect(
          VaultConfigDto.fromJson(legacyJson).frostedBlurSigma,
          equals(12.0),
        );

        expect(
          () => VaultConfigDto.fromJson({...json, 'frostedBlurSigma': 'bad'}),
          throwsA(isA<FormatException>()),
        );
      },
    );

    testWidgets(
      'Appearance blur_slider persists frostedBlurSigma on change end and VaultTheme reactively updates ReauthBlurOverlay BackdropFilter sigma',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final clock = _FakeMonotonicClock();
        final privacyController = _FakeScreenPrivacyController();
        final authService = _FakeVaultAuthService();
        final storage = _FakeVaultStorageRepository();
        final recognizer = _FakeGestureRecognizer();
        final settingsCubit = SettingsMutationCubit(
          storageRepository: storage,
          mutateVaultConfigUseCase: MutateVaultConfigUseCase(
            storageRepository: storage,
            authService: authService,
          ),
          authService: authService,
          monotonicClock: clock,
        );
        await settingsCubit.initialize();

        final sessionBloc = VaultSessionBloc(
          authService: authService,
          storageRepository: storage,
          monotonicClock: clock,
          verifyCoolOffUseCase: VerifySessionCoolOffUseCase(clock: clock),
        );
        final screenPrivacyCubit = ScreenPrivacyCubit(
          privacyController: privacyController,
          monotonicClock: clock,
        );
        final gestureCubit = GestureEngineCubit(
          recognizer: recognizer,
          storageRepository: storage,
          vaultAuthService: authService,
        );
        final pinPadCubit = PinPadCubit(
          unlockVaultUseCase: UnlockVaultUseCase(authService: authService),
          authService: authService,
          monotonicClock: clock,
        );

        addTearDown(() async {
          await settingsCubit.close();
          await sessionBloc.close();
          await screenPrivacyCubit.close();
          await gestureCubit.close();
          await pinPadCubit.close();
          await authService.controller.close();
          await privacyController.dispose();
        });

        await tester.pumpWidget(
          StreamBuilder<VaultConfig>(
            stream: settingsCubit.configStream,
            initialData: settingsCubit.currentConfig,
            builder: (context, snapshot) {
              final activeConfig = snapshot.data ?? settingsCubit.currentConfig;
              return MultiBlocProvider(
                providers: [
                  BlocProvider<SettingsMutationCubit>.value(value: settingsCubit),
                  BlocProvider<VaultSessionBloc>.value(value: sessionBloc),
                  BlocProvider<ScreenPrivacyCubit>.value(value: screenPrivacyCubit),
                  BlocProvider<GestureEngineCubit>.value(value: gestureCubit),
                  BlocProvider<PinPadCubit>.value(value: pinPadCubit),
                ],
                child: VaultTheme(
                  data: VaultThemeData.fromConfig(activeConfig),
                  child: MaterialApp(
                    home: VaultSettingsScreen(
                      settingsMutationCubit: settingsCubit,
                      sessionBloc: sessionBloc,
                      screenPrivacyCubit: screenPrivacyCubit,
                      gestureEngineCubit: gestureCubit,
                      storageRepository: storage,
                      authService: authService,
                      rotatePinUseCase: RotatePinUseCase(authService: authService),
                      purgeVaultDataUseCase: PurgeVaultDataUseCase(
                        authService: authService,
                        storageRepository: storage,
                      ),
                      unlockVaultUseCase: UnlockVaultUseCase(authService: authService),
                      monotonicClock: clock,
                    ),
                  ),
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('nav_tile_appearance')));
        await tester.pumpAndSettle();

        final sliderFinder = find.byKey(const ValueKey('blur_slider'));
        expect(sliderFinder, findsOneWidget);
        expect(storage.currentConfig.frostedBlurSigma, equals(12.0));

        // Drag slider to increase blur sigma and release (triggers onChangeEnd)
        await tester.drag(sliderFinder, const Offset(250.0, 0.0));
        await tester.pumpAndSettle();

        expect(storage.currentConfig.frostedBlurSigma, greaterThan(12.0));

        // Verify preview ImageFiltered updated reactively
        final previewFilter = tester.widget<ImageFiltered>(
          find.descendant(
            of: find.byKey(const ValueKey('blur_preview_container')),
            matching: find.byType(ImageFiltered),
          ),
        );
        final savedSigma = storage.currentConfig.frostedBlurSigma;
        expect(
          previewFilter.imageFilter,
          equals(ImageFilter.blur(sigmaX: savedSigma, sigmaY: savedSigma)),
        );

        // Verify ReauthBlurOverlay applies VaultTheme.blurSigma reactively
        await tester.pumpWidget(
          VaultTheme(
            data: VaultThemeData.fromConfig(
              const VaultConfig.constant(frostedBlurSigma: 22.0),
            ),
            child: MaterialApp(
              home: ReauthBlurOverlay(
                isBlurActive: true,
                onReauthRequested: () {},
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final overlayBlur22 = tester.widget<BackdropFilter>(
          find.byType(BackdropFilter),
        );
        expect(
          overlayBlur22.filter,
          equals(ImageFilter.blur(sigmaX: 22.0, sigmaY: 22.0)),
        );

        await tester.pumpWidget(
          VaultTheme(
            data: VaultThemeData.fromConfig(
              const VaultConfig.constant(frostedBlurSigma: 6.0),
            ),
            child: MaterialApp(
              home: ReauthBlurOverlay(
                isBlurActive: true,
                onReauthRequested: () {},
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final overlayBlur6 = tester.widget<BackdropFilter>(
          find.byType(BackdropFilter),
        );
        expect(
          overlayBlur6.filter,
          equals(ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0)),
        );
      },
    );
  });
}
