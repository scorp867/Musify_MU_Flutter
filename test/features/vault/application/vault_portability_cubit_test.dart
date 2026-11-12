import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_entity.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_item.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_metadata.dart';
import 'package:musify_mu/features/playlist/domain/models/sort_order.dart';
import 'package:musify_mu/features/playlist/domain/models/track_item_metadata.dart';
import 'package:musify_mu/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:musify_mu/features/vault/application/portability/vault_portability_cubit.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_local_song_picker_sheet.dart';

class FakeVaultStorageRepository implements IVaultStorageRepository {
  final Map<String, PrivatePlaylist> playlists = {};
  bool failNextCreate = false;
  bool failNextGet = false;

  @override
  Future<VaultResult<List<PrivatePlaylist>>> getPlaylists() async {
    if (failNextGet) {
      return const VaultResult.failure(VaultStorageFailure('Simulated get error'));
    }
    return VaultResult.success(playlists.values.toList());
  }

  @override
  Future<VaultResult<PrivatePlaylist>> getPlaylistById(String id) async {
    final p = playlists[id];
    if (p != null) {
      return VaultResult.success(p);
    }
    return const VaultResult.failure(VaultStorageFailure('Not found'));
  }

  @override
  Future<VaultResult<PrivatePlaylist>> createPlaylist({
    required String name,
    required String description,
    String? coverUri,
  }) async {
    if (failNextCreate) {
      return const VaultResult.failure(VaultStorageFailure('Simulated create failure'));
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = 'pl_${playlists.length + 1}';
    final playlist = PrivatePlaylist(
      id: id,
      name: name,
      description: description,
      coverUri: coverUri,
      totalDurationMs: 0,
      createdAtEpochMs: now,
      updatedAtEpochMs: now,
      trackRefs: const [],
    );
    playlists[id] = playlist;
    return VaultResult.success(playlist);
  }

  @override
  Future<VaultResult<void>> addTrackToPlaylist({
    required String playlistId,
    required PrivateTrackRef trackRef,
  }) async {
    final existing = playlists[playlistId];
    if (existing == null) {
      return const VaultResult.failure(VaultStorageFailure('Playlist not found'));
    }
    final updatedTracks = List<PrivateTrackRef>.from(existing.trackRefs)..add(trackRef);
    playlists[playlistId] = existing.copyWith(
      trackRefs: updatedTracks,
      totalDurationMs: existing.totalDurationMs + trackRef.durationMs,
    );
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    final existing = playlists[playlistId];
    if (existing == null) {
      return const VaultResult.failure(VaultStorageFailure('Playlist not found'));
    }
    final updatedTracks = existing.trackRefs.where((t) => t.id != trackId).toList();
    playlists[playlistId] = existing.copyWith(trackRefs: updatedTracks);
    return const VaultResult.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePlaylistRepository implements PlaylistRepository {
  final Map<String, PlaylistEntity> mockPlaylists = {};

  @override
  Future<PlaylistEntity> getPlaylist(
    String playlistUri, {
    ProvidedSortOrder sortOrder = ProvidedSortOrder.custom,
  }) async {
    final playlist = mockPlaylists[playlistUri];
    if (playlist != null) {
      return playlist;
    }
    throw Exception('Playlist not found: $playlistUri');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMediaIsolationManager implements IVaultMediaIsolationManager {
  final Map<String, String> isolatedTracks = {};
  Directory? tempDir;

  @override
  Future<IsolatedTrackResult> isolateTrackDetailed({
    required String sourceFilePath,
    required String trackId,
  }) async {
    isolatedTracks[trackId] = sourceFilePath;
    final targetDir = tempDir;
    final filePath = targetDir != null
        ? '${targetDir.path}/$trackId.isolated'
        : '/sandbox/$trackId.isolated';
    return IsolatedTrackResult(
      isolatedFile: File(filePath),
      relativePath: '$trackId.isolated',
      deletionResult: ScopedStorageDeletionSuccess(sourcePath: sourceFilePath),
    );
  }

  @override
  Future<File> exportTrackToPublic({
    required String trackId,
    required String targetDirectoryPath,
  }) async {
    final file = File('$targetDirectoryPath/$trackId.mp3');
    await file.create(recursive: true);
    return file;
  }

  @override
  Future<void> removeIsolatedTrack(String trackId) async {
    isolatedTracks.remove(trackId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VaultPortabilityCubit Unit Tests', () {
    late FakeVaultStorageRepository storageRepo;
    late FakePlaylistRepository playlistRepo;
    late FakeMediaIsolationManager isolationManager;
    late AppDatabase database;
    late Directory tempDir;
    late Directory appStorageDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('vault_portability_test_');
      appStorageDir = Directory('${tempDir.path}/app_storage')..createSync(recursive: true);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return appStorageDir.path;
          }
          return null;
        },
      );

      storageRepo = FakeVaultStorageRepository();
      playlistRepo = FakePlaylistRepository();
      isolationManager = FakeMediaIsolationManager();
      database = AppDatabase();
      isolationManager.tempDir = tempDir;
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
      await database.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('loadPortabilityData emits VaultPortabilityLoadedState with counts', () async {
      final cubit = VaultPortabilityCubit(
        storageRepository: storageRepo,
        isolationManager: isolationManager,
        database: database,
      );

      // Populate 1 sandbox track in 1 playlist
      final now = DateTime.now().millisecondsSinceEpoch;
      final sandboxRef = PrivateTrackRef(
        id: 'iso_track_1',
        playlistId: 'pl_test',
        trackUri: '/path/sandbox.mp3',
        title: 'Sandbox Song',
        artistName: 'Musify Artist',
        albumTitle: 'Musify Album',
        durationMs: 180000,
        sourceType: TrackSourceTypeEnum.localSandbox,
        localRelativePath: 'sandbox.mp3',
        sortOrder: 0,
        addedAtEpochMs: now,
      );
      storageRepo.playlists['pl_test'] = PrivatePlaylist(
        id: 'pl_test',
        name: 'Exportable Vault Playlist',
        description: 'Contains sandbox tracks',
        totalDurationMs: 180000,
        createdAtEpochMs: now,
        updatedAtEpochMs: now,
        trackRefs: [sandboxRef],
      );

      await cubit.loadPortabilityData();

      expect(cubit.state, isA<VaultPortabilityLoadedState>());
      final loaded = cubit.state as VaultPortabilityLoadedState;
      expect(loaded.totalExportableTracksCount, equals(1));
      expect(loaded.exportablePlaylists.length, equals(1));
    });

    test('importSpotifyPlaylist resolves tracks and creates private playlist with streaming refs', () async {
      final cubit = VaultPortabilityCubit(
        storageRepository: storageRepo,
        playlistRepository: playlistRepo,
        isolationManager: isolationManager,
        database: database,
      );

      final spotifyItem = PlaylistItem(
        uri: 'spotify:track:test_1',
        uid: 'uid_test_1',
        rowPosition: 0,
        trackMetadata: const TrackItemMetadata(
          title: 'Midnight Vibes',
          uri: 'spotify:track:test_1',
          albumName: 'Chill Nights',
          artists: ['Lofi Beats'],
          durationMs: 150000,
        ),
      );

      playlistRepo.mockPlaylists['spotify:playlist:test_pl'] = PlaylistEntity(
        metadata: const PlaylistMetadata(
          uri: 'spotify:playlist:test_pl',
          name: 'Chill Vibes',
          description: 'Test Spotify playlist',
        ),
        items: [spotifyItem],
      );

      await cubit.importSpotifyPlaylist(
        playlistUri: 'spotify:playlist:test_pl',
        playlistName: 'Imported Chill Vibes',
      );

      expect(cubit.state, isA<VaultPortabilitySuccessState>());
      final success = cubit.state as VaultPortabilitySuccessState;
      expect(success.summaryMessage, contains('Imported "Imported Chill Vibes"'));

      expect(storageRepo.playlists.length, equals(1));
      final createdPlaylist = storageRepo.playlists.values.first;
      expect(createdPlaylist.name, equals('Imported Chill Vibes'));
      expect(createdPlaylist.trackRefs.length, equals(1));
      expect(createdPlaylist.trackRefs.first.sourceType, equals(TrackSourceTypeEnum.spotify));
      expect(createdPlaylist.trackRefs.first.trackUri, equals('spotify:track:test_1'));
    });

    test('importLocalTracks under copyToVault preserves files and records localReference', () async {
      final cubit = VaultPortabilityCubit(
        storageRepository: storageRepo,
        isolationManager: isolationManager,
        database: database,
      );

      final trackPath = '${tempDir.path}/test_acoustic.mp3';
      await File(trackPath).writeAsString('audio_content');

      // Insert dummy track in database
      await database.into(database.localTracks).insert(
            LocalTracksCompanion.insert(
              songId: 101,
              title: 'Acoustic Guitar',
              dataPath: trackPath,
            ),
          );

      await cubit.importLocalTracks(
        playlistName: 'Local Favorites',
        ingestionMode: VaultSongIngestionModeEnum.copyToVault,
      );

      expect(cubit.state, isA<VaultPortabilitySuccessState>());
      final success = cubit.state as VaultPortabilitySuccessState;
      expect(success.summaryMessage, contains('copied'));

      expect(storageRepo.playlists.length, equals(1));
      final pl = storageRepo.playlists.values.first;
      expect(pl.trackRefs.length, equals(1));
      expect(pl.trackRefs.first.sourceType, equals(TrackSourceTypeEnum.localReference));
      expect(pl.trackRefs.first.trackUri, equals(trackPath));
    });

    test('exportSandboxTracks relocates sandbox files back to public storage and restores db entries', () async {
      final cubit = VaultPortabilityCubit(
        storageRepository: storageRepo,
        isolationManager: isolationManager,
        database: database,
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      final sandboxRef = PrivateTrackRef(
        id: 'iso_export_test_1',
        playlistId: 'pl_export',
        trackUri: '${tempDir.path}/secret_track.isolated',
        title: 'Secret Master',
        artistName: 'Vault Artist',
        albumTitle: 'Vault Album',
        durationMs: 200000,
        sourceType: TrackSourceTypeEnum.localSandbox,
        localRelativePath: 'secret_track.isolated',
        sortOrder: 0,
        addedAtEpochMs: now,
      );

      storageRepo.playlists['pl_export'] = PrivatePlaylist(
        id: 'pl_export',
        name: 'Export Test Playlist',
        description: 'For export testing',
        totalDurationMs: 200000,
        createdAtEpochMs: now,
        updatedAtEpochMs: now,
        trackRefs: [sandboxRef],
      );

      await cubit.exportSandboxTracks();

      expect(cubit.state, isA<VaultPortabilitySuccessState>());
      final success = cubit.state as VaultPortabilitySuccessState;
      expect(success.summaryMessage, contains('Successfully exported 1 tracks'));

      // Invariant: Removed from private playlist in the vault
      final plAfter = storageRepo.playlists['pl_export'];
      expect(plAfter, isNotNull);
      expect(plAfter?.trackRefs.isEmpty, isTrue);
    });

    test('exportSandboxTracks emits error when no sandbox tracks exist', () async {
      final cubit = VaultPortabilityCubit(
        storageRepository: storageRepo,
        isolationManager: isolationManager,
        database: database,
      );

      await cubit.exportSandboxTracks();

      expect(cubit.state, isA<VaultPortabilityErrorState>());
      final error = cubit.state as VaultPortabilityErrorState;
      expect(error.errorMessage, contains('No physically moved'));
    });
  });
}
