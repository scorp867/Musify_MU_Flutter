import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/player/domain/commands/options/prepare_play_options.dart';
import 'package:musify_mu/features/player/domain/models/context.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/play_origin.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';
import 'package:musify_mu/features/vault/data/services/playback_privacy_proxy.dart';
import 'package:musify_mu/features/vault/data/services/vault_audio_playback_service.dart';
import 'package:musify_mu/features/vault/data/strategies/decoy_media_masking_strategy.dart';
import 'package:musify_mu/features/vault/data/strategies/passthrough_media_masking_strategy.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

class FakeMobiusController extends ChangeNotifier
    implements PlayerQueueMobiusController {
  Context? lastPlayedContext;
  PreparePlayOptions? lastPlayOptions;
  PlayOrigin? lastPlayOrigin;
  int playContextCallCount = 0;

  final StreamController<QueueModel> _modelController =
      StreamController<QueueModel>.broadcast();
  final QueueModel _model = const QueueModel();
  bool _closed = false;

  @override
  QueueModel get model => _model;

  @override
  QueueModel get state => _model;

  @override
  QueueModel get value => _model;

  @override
  Stream<QueueModel> get stream => _modelController.stream;

  @override
  bool get isClosed => _closed;

  @override
  ContextPlayerControlClient? get controlClient => null;

  @override
  void dispatch(QueueEvent event) {}

  @override
  void add(QueueEvent event) {}

  @override
  Future<void> playContext(
    Context context, {
    PreparePlayOptions? options,
    PlayOrigin? playOrigin,
  }) async {
    playContextCallCount++;
    lastPlayedContext = context;
    lastPlayOptions = options;
    lastPlayOrigin = playOrigin;
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _modelController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeIsolationManager implements IVaultMediaIsolationManager {
  final Map<String, File> files = <String, File>{};

  @override
  Future<File> getIsolatedTrackFile(String trackId) async {
    final file = files[trackId];
    if (file case final f?) {
      return f;
    }
    return File('/data/isolated/$trackId.mp3');
  }

  @override
  String computeRelativePath(String trackId, {String? extension}) =>
      'vault_media/.nomedia/$trackId.mp3';

  @override
  Future<Directory> getVaultMediaDirectory() async =>
      Directory('/data/vault_media/.nomedia');

  @override
  Future<bool> hasIsolatedTrack(String trackId) async =>
      files.containsKey(trackId);

  @override
  Future<File> isolateLocalTrack({
    required String sourceFilePath,
    required String trackId,
  }) async =>
      File('/data/isolated/$trackId.mp3');

  @override
  Future<IsolatedTrackResult> isolateTrackDetailed({
    required String sourceFilePath,
    required String trackId,
  }) async =>
      IsolatedTrackResult(
        isolatedFile: File('/data/isolated/$trackId.mp3'),
        relativePath: 'vault_media/.nomedia/$trackId.mp3',
        deletionResult: const ScopedStorageDeletionSuccess(
          sourcePath: '/source.mp3',
        ),
      );

  @override
  Future<void> removeIsolatedTrack(String trackId) async {}

  @override
  Future<File> exportTrackToPublic({
    required String trackId,
    required String targetDirectoryPath,
  }) async =>
      File('$targetDirectoryPath/$trackId.mp3');

  @override
  Future<void> shredAllIsolatedMedia() async {}
}

class MockVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> _sessionController =
      StreamController<VaultSessionState>.broadcast();

  Stream<VaultSessionState> get sessionStateStream =>
      _sessionController.stream;

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({
    required String pin,
  }) async =>
      VaultResult.success(
        AuthSession(
          sessionToken: 'test',
          sessionStartedEpochMs: 1,
          lastActiveEpochMs: 1,
          authMethod: AuthMethodEnum.pin,
        ),
      );

  @override
  Future<VaultResult<AuthSession>> authenticateWithBiometrics() async =>
      VaultResult.success(
        AuthSession(
          sessionToken: 'bio',
          sessionStartedEpochMs: 1,
          lastActiveEpochMs: 1,
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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockVaultStorageRepository implements IVaultStorageRepository {
  VaultConfig _config = VaultConfig.constant();

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(_config);

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig config) async {
    _config = config;
    return const VaultResult.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('VaultAudioPlaybackService Unit Tests', () {
    late FakeMobiusController mobiusController;
    late FakeIsolationManager isolationManager;
    late MockVaultAuthService authService;
    late MockVaultStorageRepository storageRepository;
    late PlaybackPrivacyProxy proxy;
    late VaultAudioPlaybackService service;

    setUp(() {
      mobiusController = FakeMobiusController();
      isolationManager = FakeIsolationManager();
      authService = MockVaultAuthService();
      storageRepository = MockVaultStorageRepository();

      proxy = PlaybackPrivacyProxy(
        vaultAuthService: authService,
        mobiusController: mobiusController,
        storageRepository: storageRepository,
      );

      service = VaultAudioPlaybackService(
        mobiusController: mobiusController,
        privacyProxy: proxy,
        isolationManager: isolationManager,
        decoyStrategy: const DecoyMediaMaskingStrategy(),
        passthroughStrategy: const PassthroughMediaMaskingStrategy(),
      );
    });

    tearDown(() async {
      await proxy.dispose();
      await mobiusController.close();
    });

    final testTrack = PrivateTrackRef(
      id: 'track_alpha',
      playlistId: 'playlist_omega',
      trackUri: 'spotify:track:12345',
      title: 'Real Vault Title',
      artistName: 'Real Vault Artist',
      albumTitle: 'Real Vault Album',
      durationMs: 180000,
      sourceType: TrackSourceTypeEnum.localSandbox,
      localRelativePath: 'vault_media/.nomedia/track_alpha.mp3',
      sortOrder: 0,
      addedAtEpochMs: 1000,
    );

    test('packagePrivateTrack sets local audio keys and metadata correctly under maskWithPlaceholder', () {
      final config = VaultConfig(
        metadataVisibility: MetadataVisibilityPolicyEnum.maskWithPlaceholder,
        decoyTitle: 'Ghost Song',
        decoyArtist: 'Ghost Singer',
        decoyAlbum: 'Ghost Record',
      );

      final track = service.packagePrivateTrack(
        trackRef: testTrack,
        isolatedFilePath: '/path/to/vault_media/.nomedia/track_alpha.mp3',
        config: config,
      );

      expect(track.uid, 'vault_track_alpha');
      expect(track.uri, 'spotify:track:12345');
      expect(track.provider, 'musify_vault');
      expect(track.metadata[ContextTrackMetadata.keyIsLocal], 'true');
      expect(
        track.metadata[ContextTrackMetadata.keyLocalFilePath],
        '/path/to/vault_media/.nomedia/track_alpha.mp3',
      );
      expect(track.metadata[ContextTrackMetadata.keyDuration], '180000');
      expect(track.metadata[ContextTrackMetadata.keyIsQueued], 'false');
      expect(track.metadata['is_vault_track'], 'true');
      expect(track.metadata['vault_track_id'], 'track_alpha');
      expect(track.metadata['vault_playlist_id'], 'playlist_omega');
      expect(track.metadata[ContextTrackMetadata.keyTitle], 'Ghost Song');
      expect(track.metadata[ContextTrackMetadata.keyArtistName], 'Ghost Singer');
      expect(track.metadata[ContextTrackMetadata.keyAlbumTitle], 'Ghost Record');
    });

    test('packagePrivateTrack sets unmasked metadata under showActualMetadata', () {
      final config = VaultConfig(
        metadataVisibility: MetadataVisibilityPolicyEnum.showActualMetadata,
      );

      final track = service.packagePrivateTrack(
        trackRef: testTrack,
        isolatedFilePath: '/path/to/vault_media/.nomedia/track_alpha.mp3',
        config: config,
      );

      expect(track.metadata[ContextTrackMetadata.keyTitle], 'Real Vault Title');
      expect(track.metadata[ContextTrackMetadata.keyArtistName], 'Real Vault Artist');
      expect(track.metadata[ContextTrackMetadata.keyAlbumTitle], 'Real Vault Album');
    });

    test('playPrivateTrack dispatches Context with options and origin to Mobius controller', () async {
      await service.playPrivateTrack(
        trackRef: testTrack,
        isolatedFilePath: '/path/to/track_alpha.mp3',
      );

      expect(mobiusController.playContextCallCount, 1);
      final ctx = mobiusController.lastPlayedContext;
      expect(ctx, isNotNull);
      expect(ctx?.uri, 'spotify:internal:vault-track:track_alpha');
      expect(ctx?.url, 'context://spotify:internal:vault-track:track_alpha');

      final page = ctx?.pages?.first;
      expect(page?.tracks?.length, 1);
      final track = page?.tracks?.first;
      expect(track?.uid, 'vault_track_alpha');

      final opt = mobiusController.lastPlayOptions;
      expect(opt?.skipTo?.trackUid, 'vault_track_alpha');

      final origin = mobiusController.lastPlayOrigin;
      expect(origin?.featureIdentifier, 'vault_track');

      expect(proxy.isVaultTrackActive, isTrue);
    });

    test('playPrivatePlaylist packages all tracks and dispatches Context with skipTo tapped track', () async {
      final track2 = PrivateTrackRef(
        id: 'track_beta',
        playlistId: 'playlist_omega',
        trackUri: 'spotify:track:67890',
        title: 'Song Beta',
        artistName: 'Artist Beta',
        albumTitle: 'Album Beta',
        durationMs: 200000,
        sourceType: TrackSourceTypeEnum.localSandbox,
        localRelativePath: 'vault_media/.nomedia/track_beta.mp3',
        sortOrder: 1,
        addedAtEpochMs: 2000,
      );

      final playlist = PrivatePlaylist(
        id: 'playlist_omega',
        name: 'Private Vault Playlist',
        description: 'Classified beats',
        totalDurationMs: 380000,
        trackRefs: [testTrack, track2],
        createdAtEpochMs: 1000,
        updatedAtEpochMs: 2000,
      );

      final paths = [
        '/data/isolated/track_alpha.mp3',
        '/data/isolated/track_beta.mp3',
      ];

      await service.playPrivatePlaylist(
        playlist: playlist,
        resolvedFilePaths: paths,
        startIndex: 1,
      );

      expect(mobiusController.playContextCallCount, 1);
      final ctx = mobiusController.lastPlayedContext;
      expect(ctx?.uri, 'spotify:internal:vault-playlist:playlist_omega');
      expect(ctx?.pages?.first.tracks?.length, 2);

      final opt = mobiusController.lastPlayOptions;
      expect(opt?.skipTo?.trackUid, 'vault_track_beta');

      final origin = mobiusController.lastPlayOrigin;
      expect(origin?.featureIdentifier, 'vault_playlist');

      expect(proxy.isVaultTrackActive, isTrue);
    });

    test('playPrivatePlaylist resolves file paths via isolationManager if paths are omitted', () async {
      final playlist = PrivatePlaylist(
        id: 'playlist_auto',
        name: 'Auto Isolated Playlist',
        description: 'Auto paths',
        totalDurationMs: 180000,
        trackRefs: [testTrack],
        createdAtEpochMs: 1000,
        updatedAtEpochMs: 2000,
      );

      await service.playPrivatePlaylist(
        playlist: playlist,
        startIndex: 0,
      );

      expect(mobiusController.playContextCallCount, 1);
      final ctx = mobiusController.lastPlayedContext;
      final track = ctx?.pages?.first.tracks?.first;
      expect(
        track?.metadata[ContextTrackMetadata.keyLocalFilePath],
        '/data/isolated/track_alpha.mp3',
      );
    });

    test('playPrivatePlaylist rejects empty playlist with StateError', () async {
      final emptyPlaylist = PrivatePlaylist(
        id: 'empty',
        name: 'Empty Playlist',
        description: 'Empty',
        totalDurationMs: 0,
        trackRefs: const [],
        createdAtEpochMs: 1,
        updatedAtEpochMs: 1,
      );

      expect(
        () => service.playPrivatePlaylist(
          playlist: emptyPlaylist,
          startIndex: 0,
        ),
        throwsStateError,
      );
    });

    test('playPrivatePlaylist rejects invalid startIndex with RangeError', () async {
      final playlist = PrivatePlaylist(
        id: 'valid',
        name: 'Valid Playlist',
        description: 'Valid',
        totalDurationMs: 180000,
        trackRefs: [testTrack],
        createdAtEpochMs: 1,
        updatedAtEpochMs: 1,
      );

      expect(
        () => service.playPrivatePlaylist(
          playlist: playlist,
          startIndex: 5,
        ),
        throwsRangeError,
      );
    });
  });
}
