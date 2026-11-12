import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/features/library/application/library_bloc.dart';
import 'package:musify_mu/features/library/domain/models/library_item.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/data/datasources/local_tracks_store.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_uri.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/image_size.dart';
import 'package:musify_mu/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:musify_mu/features/playlist/presentation/extensions/track_item_metadata_presentation.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/extensions/vault_storage_batch_ops.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_local_song_picker_sheet.dart';

/// Sealed state hierarchy for the Vault Portability subsystem.
sealed class VaultPortabilityState extends Equatable {
  const VaultPortabilityState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
final class VaultPortabilityInitialState extends VaultPortabilityState {
  const VaultPortabilityInitialState();
}

/// Loading available data sources for import and export.
final class VaultPortabilityLoadingState extends VaultPortabilityState {
  const VaultPortabilityLoadingState();
}

/// Portability dashboard loaded with available Spotify playlists, local tracks,
/// and unvaultable (sandboxed) private playlists.
final class VaultPortabilityLoadedState extends VaultPortabilityState {
  final List<LibraryItem> spotifyPlaylists;
  final int localTracksCount;
  final List<PrivatePlaylist> exportablePlaylists;
  final int totalExportableTracksCount;

  const VaultPortabilityLoadedState({
    required this.spotifyPlaylists,
    required this.localTracksCount,
    required this.exportablePlaylists,
    required this.totalExportableTracksCount,
  });

  @override
  List<Object?> get props => [
        spotifyPlaylists,
        localTracksCount,
        exportablePlaylists,
        totalExportableTracksCount,
      ];
}

/// In-progress import or export execution with progress telemetry.
final class VaultPortabilityProcessingState extends VaultPortabilityState {
  final String progressMessage;
  final int current;
  final int total;

  const VaultPortabilityProcessingState({
    required this.progressMessage,
    required this.current,
    required this.total,
  });

  @override
  List<Object?> get props => [progressMessage, current, total];
}

/// Successfully finished an import or export operation.
final class VaultPortabilitySuccessState extends VaultPortabilityState {
  final String summaryMessage;

  const VaultPortabilitySuccessState({required this.summaryMessage});

  @override
  List<Object?> get props => [summaryMessage];
}

/// Encountered an error during discovery or processing.
final class VaultPortabilityErrorState extends VaultPortabilityState {
  final String errorMessage;

  const VaultPortabilityErrorState({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

/// Cubit managing Vault data portability (Importing Spotify / Local playlists,
/// and Option A Unvault / Move Back Exporting).
class VaultPortabilityCubit extends Cubit<VaultPortabilityState> {
  final IVaultStorageRepository? _storageRepository;
  final IVaultMediaIsolationManager? _isolationManager;
  final PlaylistRepository? _playlistRepository;
  final LocalTracksStore? _localTracksStore;
  final AppDatabase? _database;
  final LibraryBloc? _libraryBloc;

  VaultPortabilityCubit({
    IVaultStorageRepository? storageRepository,
    IVaultMediaIsolationManager? isolationManager,
    PlaylistRepository? playlistRepository,
    LocalTracksStore? localTracksStore,
    AppDatabase? database,
    LibraryBloc? libraryBloc,
  })  : _storageRepository = storageRepository,
        _isolationManager = isolationManager,
        _playlistRepository = playlistRepository,
        _localTracksStore = localTracksStore,
        _database = database,
        _libraryBloc = libraryBloc,
        super(const VaultPortabilityInitialState());

  IVaultStorageRepository? get _resolvedStorageRepo {
    if (_storageRepository case final r?) return r;
    if (getIt.isRegistered<IVaultStorageRepository>()) {
      return getIt<IVaultStorageRepository>();
    }
    return null;
  }

  IVaultMediaIsolationManager? get _resolvedIsolationManager {
    if (_isolationManager case final m?) return m;
    if (getIt.isRegistered<IVaultMediaIsolationManager>()) {
      return getIt<IVaultMediaIsolationManager>();
    }
    return null;
  }

  PlaylistRepository? get _resolvedPlaylistRepo {
    if (_playlistRepository case final p?) return p;
    if (getIt.isRegistered<PlaylistRepository>()) {
      return getIt<PlaylistRepository>();
    }
    return null;
  }

  LocalTracksStore? get _resolvedTracksStore {
    if (_localTracksStore case final s?) return s;
    if (getIt.isRegistered<LocalTracksStore>()) {
      return getIt<LocalTracksStore>();
    }
    return null;
  }

  AppDatabase? get _resolvedDatabase {
    if (_database case final d?) return d;
    if (getIt.isRegistered<AppDatabase>()) {
      return getIt<AppDatabase>();
    }
    return null;
  }

  LibraryBloc? get _resolvedLibraryBloc {
    if (_libraryBloc case final l?) return l;
    if (getIt.isRegistered<LibraryBloc>()) {
      return getIt<LibraryBloc>();
    }
    return null;
  }

  /// Scans available public sources (Spotify playlists, local device files)
  /// and private vault playlists containing isolated sandbox media.
  Future<void> loadPortabilityData() async {
    emit(const VaultPortabilityLoadingState());

    try {
      // 1. Discover Spotify Playlists
      var spotifyPlaylists = <LibraryItem>[];
      final libraryBloc = _resolvedLibraryBloc;
      if (libraryBloc case final bloc?) {
        final state = bloc.state;
        if (state is LibraryLoaded) {
          spotifyPlaylists = state.data
              .filterByType('playlist')
              .where((item) => item.uri.startsWith('spotify:playlist:'))
              .toList();
        }
      }

      // 2. Discover Local Tracks Count
      var localTracksCount = 0;
      final store = _resolvedTracksStore;
      if (store case final resolvedStore?) {
        final localTracks = await resolvedStore.getAll();
        localTracksCount = localTracks.length;
      } else if (_resolvedDatabase case final db?) {
        final localTracks = await db.getAllTracks();
        localTracksCount = localTracks.length;
      }

      // 3. Discover Exportable Vault Tracks & Playlists
      final storageRepo = _resolvedStorageRepo;
      final exportablePlaylists = <PrivatePlaylist>[];
      var totalExportableTracksCount = 0;

      if (storageRepo case final repo?) {
        final playlistsResult = await repo.getPlaylists();
        playlistsResult.fold(
          onSuccess: (playlists) {
            for (final playlist in playlists) {
              final sandboxTracks = playlist.trackRefs.where(
                (track) => track.sourceType == TrackSourceTypeEnum.localSandbox,
              );
              if (sandboxTracks.isNotEmpty) {
                exportablePlaylists.add(playlist);
                totalExportableTracksCount += sandboxTracks.length;
              }
            }
          },
          onFailure: (_) {},
        );
      }

      emit(
        VaultPortabilityLoadedState(
          spotifyPlaylists: spotifyPlaylists,
          localTracksCount: localTracksCount,
          exportablePlaylists: exportablePlaylists,
          totalExportableTracksCount: totalExportableTracksCount,
        ),
      );
    } catch (e) {
      emit(VaultPortabilityErrorState(errorMessage: 'Failed to load portability data: $e'));
    }
  }

  /// Imports a Spotify playlist by resolving all its track items and creating
  /// a new [PrivatePlaylist] containing [TrackSourceTypeEnum.spotify] references.
  Future<void> importSpotifyPlaylist({
    required String playlistUri,
    required String playlistName,
  }) async {
    final storageRepo = _resolvedStorageRepo;
    if (storageRepo == null) {
      emit(const VaultPortabilityErrorState(errorMessage: 'Vault storage is unavailable.'));
      return;
    }

    final playlistRepo = _resolvedPlaylistRepo;
    if (playlistRepo == null) {
      emit(const VaultPortabilityErrorState(errorMessage: 'Playlist repository is unavailable.'));
      return;
    }

    emit(const VaultPortabilityProcessingState(
      progressMessage: 'Fetching Spotify playlist tracks...',
      current: 0,
      total: 1,
    ));

    try {
      final spotifyPlaylist = await playlistRepo.getPlaylist(playlistUri);
      final tracks = spotifyPlaylist.items;

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final fallbackCover = tracks
          .map((item) => item.coverUrlForSize(ImageSize.large).trim())
          .where((url) => url.isNotEmpty)
          .firstOrNull;
      final playlistPicture = spotifyPlaylist.pictureUrl.trim();
      final resolvedCover =
          playlistPicture.isNotEmpty ? playlistPicture : fallbackCover;

      final createResult = await storageRepo.createPlaylist(
        name: playlistName,
        description: 'Imported from Spotify (${tracks.length} tracks)',
        coverUri: resolvedCover,
      );

      if (createResult is VaultFailureResult<PrivatePlaylist>) {
        emit(VaultPortabilityErrorState(
          errorMessage: 'Failed to create vault playlist: ${createResult.failure.message}',
        ));
        return;
      }

      final newPlaylist = (createResult as VaultSuccess<PrivatePlaylist>).data;
      final newPlaylistId = newPlaylist.id;
      final pendingTracks = <PrivateTrackRef>[];

      var index = 0;
      for (final item in tracks) {
        index++;
        emit(VaultPortabilityProcessingState(
          progressMessage: 'Preparing track $index of ${tracks.length}...',
          current: index,
          total: tracks.length,
        ));

        final primaryArt = item.coverUrlForSize(ImageSize.large).trim();
        final thumbArt = item.coverUrlForSize(ImageSize.small).trim();
        final resolvedArt = primaryArt.isNotEmpty
            ? primaryArt
            : (thumbArt.isNotEmpty ? thumbArt : null);

        pendingTracks.add(
          PrivateTrackRef(
            id: 'sp_${newPlaylistId}_$index',
            playlistId: newPlaylistId,
            trackUri: item.uri,
            title: item.title.isNotEmpty ? item.title : 'Unknown Track',
            artistName: item.subtitle.isNotEmpty ? item.subtitle : 'Unknown Artist',
            albumTitle: item.albumName.isNotEmpty ? item.albumName : 'Spotify Album',
            durationMs: item.durationMs,
            sourceType: TrackSourceTypeEnum.spotify,
            localRelativePath: null,
            sortOrder: index - 1,
            addedAtEpochMs: nowMs,
            artworkUri: resolvedArt,
          ),
        );
      }

      emit(VaultPortabilityProcessingState(
        progressMessage: 'Encrypting ${tracks.length} tracks...',
        current: tracks.length,
        total: tracks.length,
      ));

      final batchResult = await storageRepo.addTracksToPlaylist(
        playlistId: newPlaylistId,
        trackRefs: pendingTracks,
      );
      if (batchResult case VaultFailureResult<void>(:final failure)) {
        emit(VaultPortabilityErrorState(
          errorMessage: 'Error importing Spotify playlist: ${failure.message}',
        ));
        return;
      }

      emit(VaultPortabilitySuccessState(
        summaryMessage: 'Imported "$playlistName" with ${tracks.length} tracks into Private Vault.',
      ));
    } catch (e) {
      emit(VaultPortabilityErrorState(errorMessage: 'Error importing Spotify playlist: $e'));
    }
  }

  /// Imports all local device tracks into a dedicated [PrivatePlaylist] under either
  /// [VaultSongIngestionModeEnum.copyToVault] or [VaultSongIngestionModeEnum.moveToVault].
  Future<void> importLocalTracks({
    required String playlistName,
    required VaultSongIngestionModeEnum ingestionMode,
  }) async {
    final storageRepo = _resolvedStorageRepo;
    if (storageRepo == null) {
      emit(const VaultPortabilityErrorState(errorMessage: 'Vault storage is unavailable.'));
      return;
    }

    emit(const VaultPortabilityProcessingState(
      progressMessage: 'Loading local audio files...',
      current: 0,
      total: 1,
    ));

    try {
      List<LocalTrack> tracks = const [];
      if (_resolvedTracksStore case final store?) {
        tracks = await store.getAll();
      } else if (_resolvedDatabase case final db?) {
        tracks = await db.getAllTracks();
      }

      if (tracks.isEmpty) {
        emit(const VaultPortabilityErrorState(errorMessage: 'No local audio files found on device.'));
        return;
      }

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final createResult = await storageRepo.createPlaylist(
        name: playlistName,
        description: 'Imported from local files (${tracks.length} tracks)',
      );

      if (createResult is VaultFailureResult<PrivatePlaylist>) {
        emit(VaultPortabilityErrorState(
          errorMessage: 'Failed to create vault playlist: ${createResult.failure.message}',
        ));
        return;
      }

      final newPlaylist = (createResult as VaultSuccess<PrivatePlaylist>).data;
      final newPlaylistId = newPlaylist.id;

      final isolationManager = _resolvedIsolationManager;
      final store = _resolvedTracksStore;
      final db = _resolvedDatabase;
      final pendingTracks = <PrivateTrackRef>[];
      final movedSongIds = <int>{};
      final movedDataPaths = <String>[];

      var index = 0;
      for (final track in tracks) {
        index++;
        emit(VaultPortabilityProcessingState(
          progressMessage: 'Processing track $index of ${tracks.length}...',
          current: index,
          total: tracks.length,
        ));

        final trackTitle = track.title.trim().isNotEmpty
            ? track.title
            : track.dataPath.split('/').last;
        final trackArtist = switch (track.artist) {
          final a? when a.trim().isNotEmpty => a,
          _ => 'Unknown Artist',
        };
        final trackAlbum = switch (track.album) {
          final al? when al.trim().isNotEmpty => al,
          _ => 'Local Music',
        };
        final trackDuration = switch (track.duration) {
          final d? when d > 0 => d,
          _ => 0,
        };
        final durationSeconds = trackDuration > 0 ? trackDuration ~/ 1000 : 0;
        final referenceArtworkUri = LocalFileUri.toLocalFileImageUri(
          LocalFileUri.fromMetadata(
            artist: switch (track.artist) {
              final a? => a,
              null => '',
            },
            album: switch (track.album) {
              final al? => al,
              null => '',
            },
            title: track.title,
            durationSeconds: durationSeconds,
          ),
        );

        if (ingestionMode == VaultSongIngestionModeEnum.copyToVault) {
          pendingTracks.add(
            PrivateTrackRef(
              id: 'ref_${newPlaylistId}_$index',
              playlistId: newPlaylistId,
              trackUri: track.dataPath,
              title: trackTitle,
              artistName: trackArtist,
              albumTitle: trackAlbum,
              durationMs: trackDuration,
              sourceType: TrackSourceTypeEnum.localReference,
              localRelativePath: null,
              sortOrder: index - 1,
              addedAtEpochMs: nowMs,
              artworkUri: referenceArtworkUri,
            ),
          );
        } else {
          final trackId = 'iso_${newPlaylistId}_$index';
          String finalUri = track.dataPath;
          String finalRelPath = track.dataPath.split('/').last;

          if (isolationManager case final iso?) {
            try {
              final result = await iso.isolateTrackDetailed(
                sourceFilePath: track.dataPath,
                trackId: trackId,
              );
              finalUri = result.isolatedFile.path;
              finalRelPath = result.relativePath;
            } catch (_) {}
          }

          movedSongIds.add(track.songId);
          movedDataPaths.add(track.dataPath);

          pendingTracks.add(
            PrivateTrackRef(
              id: trackId,
              playlistId: newPlaylistId,
              trackUri: finalUri,
              title: trackTitle,
              artistName: trackArtist,
              albumTitle: trackAlbum,
              durationMs: trackDuration,
              sourceType: TrackSourceTypeEnum.localSandbox,
              localRelativePath: finalRelPath,
              sortOrder: index - 1,
              addedAtEpochMs: nowMs,
              artworkUri: LocalFileUri.toFileUri(finalUri),
            ),
          );
        }
      }

      if (movedSongIds.isNotEmpty) {
        if (store case final resolvedStore?) {
          try {
            await resolvedStore.deleteBySongIds(movedSongIds);
          } catch (_) {}
        } else if (db case final appDb?) {
          try {
            await (appDb.delete(appDb.localTracks)
                  ..where((tbl) => tbl.dataPath.isIn(movedDataPaths)))
                .go();
          } catch (_) {}
        }
      }

      final batchResult = await storageRepo.addTracksToPlaylist(
        playlistId: newPlaylistId,
        trackRefs: pendingTracks,
      );
      if (batchResult case VaultFailureResult<void>(:final failure)) {
        emit(VaultPortabilityErrorState(
          errorMessage: 'Error importing local tracks: ${failure.message}',
        ));
        return;
      }

      final modeName = ingestionMode == VaultSongIngestionModeEnum.copyToVault
          ? 'copied'
          : 'moved';
      emit(VaultPortabilitySuccessState(
        summaryMessage: 'Successfully $modeName ${tracks.length} tracks into "$playlistName".',
      ));
    } catch (e) {
      emit(VaultPortabilityErrorState(errorMessage: 'Error importing local tracks: $e'));
    }
  }

  /// Exports isolated sandbox tracks back to public storage (Option A - Unvault / Move Back).
  ///
  /// Steps:
  /// 1. Discovers tracks with [TrackSourceTypeEnum.localSandbox].
  /// 2. Relocates files back to public storage (/storage/emulated/0/Music/Musify_Exported/ or external storage).
  /// 3. Re-inserts track metadata into [AppDatabase.localTracks] so the device player sees them.
  /// 4. Removes the exported tracks from the private playlist in the vault.
  Future<void> exportSandboxTracks({String? specificPlaylistId}) async {
    final storageRepo = _resolvedStorageRepo;
    if (storageRepo == null) {
      emit(const VaultPortabilityErrorState(errorMessage: 'Vault storage is unavailable.'));
      return;
    }

    final isolationManager = _resolvedIsolationManager;
    if (isolationManager == null) {
      emit(const VaultPortabilityErrorState(errorMessage: 'Media isolation manager is unavailable.'));
      return;
    }

    final db = _resolvedDatabase;
    if (db == null) {
      emit(const VaultPortabilityErrorState(errorMessage: 'Local tracks database is unavailable.'));
      return;
    }

    emit(const VaultPortabilityProcessingState(
      progressMessage: 'Identifying isolated vault media...',
      current: 0,
      total: 1,
    ));

    try {
      final playlistsResult = await storageRepo.getPlaylists();
      final tracksToExport = <PrivateTrackRef>[];

      playlistsResult.fold(
        onSuccess: (playlists) {
          for (final pl in playlists) {
            if (specificPlaylistId == null || pl.id == specificPlaylistId) {
              for (final ref in pl.trackRefs) {
                if (ref.sourceType == TrackSourceTypeEnum.localSandbox) {
                  tracksToExport.add(ref);
                }
              }
            }
          }
        },
        onFailure: (err) => throw Exception(err.message),
      );

      if (tracksToExport.isEmpty) {
        emit(const VaultPortabilityErrorState(
          errorMessage: 'No physically moved (.nomedia sandbox) tracks found to export.',
        ));
        return;
      }

      // Resolve export directory
      Directory exportDir;
      final publicMusicExportDir = Directory('/storage/emulated/0/Music/Musify_Exported');
      try {
        if (!await publicMusicExportDir.exists()) {
          await publicMusicExportDir.create(recursive: true);
        }
        exportDir = publicMusicExportDir;
      } catch (_) {
        final docDir = await getApplicationDocumentsDirectory();
        exportDir = Directory('${docDir.path}/Musify_Exported');
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
      }

      var index = 0;
      for (final track in tracksToExport) {
        index++;
        emit(VaultPortabilityProcessingState(
          progressMessage: 'Exporting track $index of ${tracksToExport.length}: "${track.title}"...',
          current: index,
          total: tracksToExport.length,
        ));

        // 1. Export file from sandbox to public destination
        File exportedFile;
        try {
          exportedFile = await isolationManager.exportTrackToPublic(
            trackId: track.id,
            targetDirectoryPath: exportDir.path,
          );
        } catch (_) {
          final sandboxFile = File(track.trackUri);
          final relName = switch (track.localRelativePath) {
            final r? => r.split('/').last,
            null => 'track_$index.mp3',
          };
          final targetPath = '${exportDir.path}/$relName';
          exportedFile = await sandboxFile.copy(targetPath);
        }

        // 2. Remove isolated file from sandbox
        try {
          await isolationManager.removeIsolatedTrack(track.id);
        } catch (_) {}

        // 3. Re-insert into AppDatabase.localTracks
        final songId = (track.id.hashCode & 0x7FFFFFFF);
        final companion = LocalTracksCompanion.insert(
          songId: songId,
          title: track.title,
          artist: drift.Value(track.artistName),
          album: drift.Value(track.albumTitle),
          dataPath: exportedFile.path,
          duration: drift.Value(track.durationMs),
          dateModified: drift.Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
        );
        await db.insertTracks([companion]);

        // 4. Remove track from the private playlist
        await storageRepo.removeTrackFromPlaylist(
          playlistId: track.playlistId,
          trackId: track.id,
        );
      }

      emit(VaultPortabilitySuccessState(
        summaryMessage: 'Successfully exported ${tracksToExport.length} tracks to "${exportDir.path}" and restored them to your device library.',
      ));
    } catch (e) {
      emit(VaultPortabilityErrorState(errorMessage: 'Error during vault export: $e'));
    }
  }
}
