import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/ui/icons/spotify_encore_icons.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_uri.dart';
import 'package:musify_mu/features/player/presentation/models/more_options_entity.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_artwork.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_header.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_theme.dart';
import 'package:musify_mu/features/player/presentation/widgets/pull_to_dismiss_scaffold.dart';
import 'package:musify_mu/features/player/presentation/widgets/spotify_scroll_physics.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_entity.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_item.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/image_size.dart';
import 'package:musify_mu/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:musify_mu/features/playlist/presentation/extensions/track_item_metadata_presentation.dart';
import 'package:musify_mu/features/library/domain/models/library_item.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/extensions/vault_storage_batch_ops.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/presentation/widgets/private_playlist_selection_dialog.dart';

/// Universal, authentic modal options sheet for media entities across Musify MU.
///
/// Integrates:
/// 1. Interactive pull-to-dismiss via [PullToDismissScaffold].
/// 2. Fluid native stretch overscroll via [SpotifyStretchOverscrollIndicator].
/// 3. Design tokens from [PlayerColors], [PlayerSheetHeader], and [PlayerCircleButton].
/// 4. True Stealth gating: "Copy to Vault" and "Move to Vault" are rendered only
///    when [VaultSessionBloc] is in an active session ([VaultUnlockedState] or
///    [VaultBackgroundGraceState]). If locked or uninitialized, Vault actions are
///    completely omitted without UI leakage.
class MoreOptionsBottomSheet extends StatelessWidget {
  final MoreOptionsEntity entity;
  final VoidCallback? onRemoveFromPlaylist;
  final VaultSessionBloc? sessionBlocOverride;
  final IVaultStorageRepository? storageRepositoryOverride;
  final PlaylistRepository? playlistRepositoryOverride;

  const MoreOptionsBottomSheet({
    super.key,
    required this.entity,
    this.onRemoveFromPlaylist,
    this.sessionBlocOverride,
    this.storageRepositoryOverride,
    this.playlistRepositoryOverride,
  });

  /// Displays [MoreOptionsBottomSheet] inside a modal route.
  static Future<void> show(
    BuildContext context, {
    required MoreOptionsEntity entity,
    VoidCallback? onRemoveFromPlaylist,
    VaultSessionBloc? sessionBlocOverride,
    IVaultStorageRepository? storageRepositoryOverride,
    PlaylistRepository? playlistRepositoryOverride,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (ctx) => MoreOptionsBottomSheet(
        entity: entity,
        onRemoveFromPlaylist: onRemoveFromPlaylist,
        sessionBlocOverride: sessionBlocOverride,
        storageRepositoryOverride: storageRepositoryOverride,
        playlistRepositoryOverride: playlistRepositoryOverride,
      ),
    );
  }

  VaultSessionBloc? _resolveVaultSessionBloc(BuildContext context) {
    if (sessionBlocOverride case final bloc?) {
      return bloc;
    }
    try {
      return context.read<VaultSessionBloc>();
    } catch (_) {
      if (getIt.isRegistered<VaultSessionBloc>()) {
        return getIt<VaultSessionBloc>();
      }
      return null;
    }
  }

  IVaultStorageRepository? _resolveVaultStorageRepository(BuildContext context) {
    if (storageRepositoryOverride case final repo?) {
      return repo;
    }
    try {
      return context.read<IVaultStorageRepository>();
    } catch (_) {
      if (getIt.isRegistered<IVaultStorageRepository>()) {
        return getIt<IVaultStorageRepository>();
      }
      return null;
    }
  }

  PlaylistRepository? _resolvePlaylistRepository(BuildContext context) {
    if (playlistRepositoryOverride case final repo?) {
      return repo;
    }
    try {
      return context.read<PlaylistRepository>();
    } catch (_) {
      if (getIt.isRegistered<PlaylistRepository>()) {
        return getIt<PlaylistRepository>();
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PullToDismissScaffold(
      builder: (scaffoldContext, dismissController) {
        return _MoreOptionsSheetContent(
          entity: entity,
          dismissController: dismissController,
          onRemoveFromPlaylist: onRemoveFromPlaylist,
          sessionBloc: _resolveVaultSessionBloc(context),
          storageRepository: _resolveVaultStorageRepository(context),
          playlistRepository: _resolvePlaylistRepository(context),
        );
      },
    );
  }
}

class _MoreOptionsSheetContent extends StatefulWidget {
  final MoreOptionsEntity entity;
  final PullToDismissController dismissController;
  final VoidCallback? onRemoveFromPlaylist;
  final VaultSessionBloc? sessionBloc;
  final IVaultStorageRepository? storageRepository;
  final PlaylistRepository? playlistRepository;

  const _MoreOptionsSheetContent({
    required this.entity,
    required this.dismissController,
    this.onRemoveFromPlaylist,
    this.sessionBloc,
    this.storageRepository,
    this.playlistRepository,
  });

  @override
  State<_MoreOptionsSheetContent> createState() =>
      _MoreOptionsSheetContentState();
}

class _MoreOptionsSheetContentState extends State<_MoreOptionsSheetContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _localFileArtworkUri(LocalFile file) {
    if (file.metadata != null) {
      return LocalFileUri.toLocalFileImageUri(LocalFileUri.fromLocalFile(file));
    }
    return LocalFileUri.toFileUri(file.path);
  }

  String? _spotifyItemArtworkUri(PlaylistItem item) {
    final primary = item.coverUrlForSize(ImageSize.large).trim();
    if (primary.isNotEmpty) return primary;
    final thumbnail = item.coverUrlForSize(ImageSize.small).trim();
    return thumbnail.isNotEmpty ? thumbnail : null;
  }

  Future<void> _handleClonePlaylistToVault(
    BuildContext context,
    PlaylistEntity playlist,
  ) async {
    final storageRepo = widget.storageRepository;
    if (storageRepo == null) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final fallbackCover = playlist.items
        .map(_spotifyItemArtworkUri)
        .whereType<String>()
        .firstOrNull;
    final createResult = await storageRepo.createPlaylist(
      name: playlist.name,
      description: playlist.description.isNotEmpty
          ? playlist.description
          : 'Cloned from public playlist',
      coverUri: playlist.pictureUrl.trim().isNotEmpty
          ? playlist.pictureUrl.trim()
          : fallbackCover,
    );

    switch (createResult) {
      case VaultSuccess<PrivatePlaylist>(:final data):
        final createdPlaylist = data;
        for (var i = 0; i < playlist.items.length; i++) {
          final item = playlist.items[i];
          final trackRef = PrivateTrackRef(
            id: 'cloned_${createdPlaylist.id}_$i',
            playlistId: createdPlaylist.id,
            trackUri: item.uri.isNotEmpty ? item.uri : 'spotify:track:cloned_$i',
            title: item.title.isNotEmpty ? item.title : 'Track ${i + 1}',
            artistName: item.subtitle.isNotEmpty ? item.subtitle : 'Unknown Artist',
            albumTitle: item.albumName.isNotEmpty ? item.albumName : 'Unknown Album',
            durationMs: item.durationMs,
            sourceType: TrackSourceTypeEnum.spotify,
            localRelativePath: null,
            sortOrder: i,
            addedAtEpochMs: nowMs,
            artworkUri: _spotifyItemArtworkUri(item),
          );
          await storageRepo.addTrackToPlaylist(
            playlistId: createdPlaylist.id,
            trackRef: trackRef,
          );
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Cloned "${playlist.name}" to Private Vault',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      case VaultFailureResult<PrivatePlaylist>():
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to clone playlist to vault',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            duration: Duration(seconds: 2),
          ),
        );
    }
  }

  Future<void> _handleCloneLibraryPlaylistToVault(
    BuildContext context,
    LibraryItem item,
  ) async {
    final storageRepo = widget.storageRepository;
    if (storageRepo == null) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    PlaylistRepository? playlistRepo = widget.playlistRepository;
    if (playlistRepo == null && getIt.isRegistered<PlaylistRepository>()) {
      playlistRepo = getIt<PlaylistRepository>();
    }

    if (playlistRepo == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Playlist repository unavailable',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final spotifyPlaylist = await playlistRepo.getPlaylist(item.uri);
      final tracks = spotifyPlaylist.items;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final fallbackTrackCover = tracks
          .map(_spotifyItemArtworkUri)
          .whereType<String>()
          .firstOrNull;
      final playlistPicture = spotifyPlaylist.pictureUrl.trim();
      final itemImage = item.imageUrl?.trim() ?? '';
      final resolvedCover = playlistPicture.isNotEmpty
          ? playlistPicture
          : (itemImage.isNotEmpty ? itemImage : fallbackTrackCover);

      final createResult = await storageRepo.createPlaylist(
        name: item.name,
        description: 'Cloned from library playlist',
        coverUri: resolvedCover,
      );

      switch (createResult) {
        case VaultSuccess<PrivatePlaylist>(:final data):
          final createdPlaylist = data;
          final pendingRefs = <PrivateTrackRef>[
            for (var i = 0; i < tracks.length; i++)
              PrivateTrackRef(
                id: 'cloned_${createdPlaylist.id}_$i',
                playlistId: createdPlaylist.id,
                trackUri: tracks[i].uri.isNotEmpty
                    ? tracks[i].uri
                    : 'spotify:track:cloned_$i',
                title: tracks[i].title.isNotEmpty
                    ? tracks[i].title
                    : 'Track ${i + 1}',
                artistName: tracks[i].subtitle.isNotEmpty
                    ? tracks[i].subtitle
                    : 'Unknown Artist',
                albumTitle: tracks[i].albumName.isNotEmpty
                    ? tracks[i].albumName
                    : 'Unknown Album',
                durationMs: tracks[i].durationMs,
                sourceType: TrackSourceTypeEnum.spotify,
                localRelativePath: null,
                sortOrder: i,
                addedAtEpochMs: nowMs,
                artworkUri: _spotifyItemArtworkUri(tracks[i]),
              ),
          ];
          await storageRepo.addTracksToPlaylist(
            playlistId: createdPlaylist.id,
            trackRefs: pendingRefs,
          );
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Cloned "${item.name}" to Private Vault',
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        case VaultFailureResult<PrivatePlaylist>(:final failure):
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Failed to clone playlist: ${failure.message}',
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Error cloning playlist: $e',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleAddToPrivatePlaylists(
    BuildContext context,
    PlaylistItem item,
  ) async {
    final storageRepo = widget.storageRepository;
    if (storageRepo == null) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    final selected = await PrivatePlaylistSelectionDialog.show(
      context,
      storageRepository: storageRepo,
    );

    if (selected case final playlist?) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final trackRef = PrivateTrackRef(
        id: 'track_${playlist.id}_${playlist.trackCount}_$nowMs',
        playlistId: playlist.id,
        trackUri: item.uri.isNotEmpty ? item.uri : 'spotify:track:picked',
        title: item.title.isNotEmpty ? item.title : 'Unknown Track',
        artistName: item.subtitle.isNotEmpty ? item.subtitle : 'Unknown Artist',
        albumTitle: item.albumName.isNotEmpty ? item.albumName : 'Unknown Album',
        durationMs: item.durationMs,
        sourceType: TrackSourceTypeEnum.spotify,
        localRelativePath: null,
        sortOrder: playlist.trackCount,
        addedAtEpochMs: nowMs,
        artworkUri: _spotifyItemArtworkUri(item),
      );

      await storageRepo.addTrackToPlaylist(
        playlistId: playlist.id,
        trackRef: trackRef,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Added "${item.title}" to "${playlist.name}"',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleCopyLocalToVault(
    BuildContext context,
    LocalFile file,
  ) async {
    final storageRepo = widget.storageRepository;
    if (storageRepo == null) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    final selected = await PrivatePlaylistSelectionDialog.show(
      context,
      storageRepository: storageRepo,
    );

    if (selected case final playlist?) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final metaTitle = switch (file.metadata?.title) {
        final t? when t.trim().isNotEmpty => t,
        _ => file.path.split('/').last,
      };
      final metaArtist = switch (file.metadata?.artist) {
        final a? when a.trim().isNotEmpty => a,
        _ => 'Unknown Artist',
      };
      final metaAlbum = switch (file.metadata?.album) {
        final al? when al.trim().isNotEmpty => al,
        _ => 'Local Music',
      };
      final metaDuration = switch (file.metadata?.duration) {
        final d? when d > 0 => d * 1000,
        _ => 0,
      };

      final trackRef = PrivateTrackRef(
        id: 'local_ref_${playlist.id}_$nowMs',
        playlistId: playlist.id,
        trackUri: file.path,
        title: metaTitle,
        artistName: metaArtist,
        albumTitle: metaAlbum,
        durationMs: metaDuration,
        sourceType: TrackSourceTypeEnum.localReference,
        localRelativePath: null,
        sortOrder: playlist.trackCount,
        addedAtEpochMs: nowMs,
        artworkUri: _localFileArtworkUri(file),
      );

      await storageRepo.addTrackToPlaylist(
        playlistId: playlist.id,
        trackRef: trackRef,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Added "$metaTitle" to "${playlist.name}"',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleMoveLocalToVault(
    BuildContext context,
    LocalFile file,
  ) async {
    final storageRepo = widget.storageRepository;
    if (storageRepo == null) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    final selected = await PrivatePlaylistSelectionDialog.show(
      context,
      storageRepository: storageRepo,
    );

    if (selected case final playlist?) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final trackId = 'iso_${playlist.id}_$nowMs';

      IVaultMediaIsolationManager? isolationManager;
      if (getIt.isRegistered<IVaultMediaIsolationManager>()) {
        isolationManager = getIt<IVaultMediaIsolationManager>();
      }

      AppDatabase? db;
      if (getIt.isRegistered<AppDatabase>()) {
        db = getIt<AppDatabase>();
      }

      String isolatedPath;
      String relativePath;
      if (isolationManager case final iso?) {
        try {
          final isolatedResult = await iso.isolateTrackDetailed(
            sourceFilePath: file.path,
            trackId: trackId,
          );
          isolatedPath = isolatedResult.isolatedFile.path;
          relativePath = isolatedResult.relativePath;
        } catch (_) {
          isolatedPath = file.path;
          relativePath = file.path.split('/').last;
        }
      } else {
        isolatedPath = file.path;
        relativePath = file.path.split('/').last;
      }

      if (db case final appDb?) {
        try {
          await (appDb.delete(appDb.localTracks)
                ..where((tbl) => tbl.dataPath.equals(file.path)))
              .go();
        } catch (_) {}
      }

      final metaTitle = switch (file.metadata?.title) {
        final t? when t.trim().isNotEmpty => t,
        _ => file.path.split('/').last,
      };
      final metaArtist = switch (file.metadata?.artist) {
        final a? when a.trim().isNotEmpty => a,
        _ => 'Unknown Artist',
      };
      final metaAlbum = switch (file.metadata?.album) {
        final al? when al.trim().isNotEmpty => al,
        _ => 'Local Music',
      };
      final metaDuration = switch (file.metadata?.duration) {
        final d? when d > 0 => d * 1000,
        _ => 0,
      };

      final trackRef = PrivateTrackRef(
        id: trackId,
        playlistId: playlist.id,
        trackUri: isolatedPath,
        title: metaTitle,
        artistName: metaArtist,
        albumTitle: metaAlbum,
        durationMs: metaDuration,
        sourceType: TrackSourceTypeEnum.localSandbox,
        localRelativePath: relativePath,
        sortOrder: playlist.trackCount,
        addedAtEpochMs: nowMs,
        artworkUri: LocalFileUri.toFileUri(isolatedPath),
      );

      await storageRepo.addTrackToPlaylist(
        playlistId: playlist.id,
        trackRef: trackRef,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Moved "$metaTitle" into Vault sandbox',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleCopyLocalPlaylistToVault(
    BuildContext context,
    LocalPlaylistOptionsEntity entity,
  ) async {
    final storageRepo = widget.storageRepository;
    if (storageRepo == null) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final createResult = await storageRepo.createPlaylist(
      name: entity.playlistName,
      description: 'Local playlist referenced in vault',
      coverUri: entity.coverArtworkUrl,
    );

    switch (createResult) {
      case VaultSuccess<PrivatePlaylist>(:final data):
        final createdPlaylist = data;
        for (var i = 0; i < entity.files.length; i++) {
          final file = entity.files[i];
          final metaTitle = switch (file.metadata?.title) {
            final t? when t.trim().isNotEmpty => t,
            _ => file.path.split('/').last,
          };
          final metaArtist = switch (file.metadata?.artist) {
            final a? when a.trim().isNotEmpty => a,
            _ => 'Unknown Artist',
          };
          final metaAlbum = switch (file.metadata?.album) {
            final al? when al.trim().isNotEmpty => al,
            _ => 'Local Music',
          };
          final metaDuration = switch (file.metadata?.duration) {
            final d? when d > 0 => d * 1000,
            _ => 0,
          };

          final trackRef = PrivateTrackRef(
            id: 'local_ref_${createdPlaylist.id}_$i',
            playlistId: createdPlaylist.id,
            trackUri: file.path,
            title: metaTitle,
            artistName: metaArtist,
            albumTitle: metaAlbum,
            durationMs: metaDuration,
            sourceType: TrackSourceTypeEnum.localReference,
            localRelativePath: null,
            sortOrder: i,
            addedAtEpochMs: nowMs,
            artworkUri: _localFileArtworkUri(file),
          );

          await storageRepo.addTrackToPlaylist(
            playlistId: createdPlaylist.id,
            trackRef: trackRef,
          );
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Copied "${entity.playlistName}" (${entity.files.length} tracks) to Vault',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      case VaultFailureResult<PrivatePlaylist>():
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to copy local playlist to vault',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            duration: Duration(seconds: 2),
          ),
        );
    }
  }

  Future<void> _handleMoveLocalPlaylistToVault(
    BuildContext context,
    LocalPlaylistOptionsEntity entity,
  ) async {
    final storageRepo = widget.storageRepository;
    if (storageRepo == null) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    IVaultMediaIsolationManager? isolationManager;
    if (getIt.isRegistered<IVaultMediaIsolationManager>()) {
      isolationManager = getIt<IVaultMediaIsolationManager>();
    }

    AppDatabase? db;
    if (getIt.isRegistered<AppDatabase>()) {
      db = getIt<AppDatabase>();
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final createResult = await storageRepo.createPlaylist(
      name: entity.playlistName,
      description: 'Local playlist isolated in vault sandbox',
      coverUri: entity.coverArtworkUrl,
    );

    switch (createResult) {
      case VaultSuccess<PrivatePlaylist>(:final data):
        final createdPlaylist = data;
        for (var i = 0; i < entity.files.length; i++) {
          final file = entity.files[i];
          final trackId = 'iso_${createdPlaylist.id}_$i';

          String isolatedPath;
          String relativePath;
          if (isolationManager case final iso?) {
            try {
              final isolatedResult = await iso.isolateTrackDetailed(
                sourceFilePath: file.path,
                trackId: trackId,
              );
              isolatedPath = isolatedResult.isolatedFile.path;
              relativePath = isolatedResult.relativePath;
            } catch (_) {
              isolatedPath = file.path;
              relativePath = file.path.split('/').last;
            }
          } else {
            isolatedPath = file.path;
            relativePath = file.path.split('/').last;
          }

          if (db case final appDb?) {
            try {
              await (appDb.delete(appDb.localTracks)
                    ..where((tbl) => tbl.dataPath.equals(file.path)))
                  .go();
            } catch (_) {}
          }

          final metaTitle = switch (file.metadata?.title) {
            final t? when t.trim().isNotEmpty => t,
            _ => file.path.split('/').last,
          };
          final metaArtist = switch (file.metadata?.artist) {
            final a? when a.trim().isNotEmpty => a,
            _ => 'Unknown Artist',
          };
          final metaAlbum = switch (file.metadata?.album) {
            final al? when al.trim().isNotEmpty => al,
            _ => 'Local Music',
          };
          final metaDuration = switch (file.metadata?.duration) {
            final d? when d > 0 => d * 1000,
            _ => 0,
          };

          final trackRef = PrivateTrackRef(
            id: trackId,
            playlistId: createdPlaylist.id,
            trackUri: isolatedPath,
            title: metaTitle,
            artistName: metaArtist,
            albumTitle: metaAlbum,
            durationMs: metaDuration,
            sourceType: TrackSourceTypeEnum.localSandbox,
            localRelativePath: relativePath,
            sortOrder: i,
            addedAtEpochMs: nowMs,
            artworkUri: LocalFileUri.toFileUri(isolatedPath),
          );

          await storageRepo.addTrackToPlaylist(
            playlistId: createdPlaylist.id,
            trackRef: trackRef,
          );
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Moved "${entity.playlistName}" (${entity.files.length} tracks) to Vault sandbox',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      case VaultFailureResult<PrivatePlaylist>():
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to move local playlist to vault',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            duration: Duration(seconds: 2),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PlayerColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Handle & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'More Options',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      PlayerCircleButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Entity Metadata Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 52,
                      height: 52,
                      color: PlayerColors.surfaceHigh,
                      child: PlayerArtworkImage(
                        imageUrl: widget.entity.artworkUrl,
                        artworkWidth: 52,
                        artworkHeight: 52,
                        placeholderIconSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.entity.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: PlayerColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.entity.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: PlayerColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: PlayerColors.divider, height: 1),

            // Options List wrapped in Spotify stretch overscroll
            Flexible(
              child: SpotifyStretchOverscrollIndicator(
                axisDirection: AxisDirection.down,
                child: ListView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  children: [
                    ..._buildPublicOptions(context),
                    _buildVaultSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPublicOptions(BuildContext context) {
    return switch (widget.entity) {
      SpotifyPlaylistOptionsEntity(:final playlist) => [
          ListTile(
            leading: SpotifyIcon.download(size: 24, color: Colors.white),
            title: const Text('Download', style: TextStyle(color: Colors.white, fontSize: 15)),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: SpotifyIcon.share(size: 24, color: Colors.white),
            title: const Text('Share', style: TextStyle(color: Colors.white, fontSize: 15)),
            onTap: () => Navigator.of(context).pop(),
          ),
          if (playlist.metadata.canEdit) ...[
            ListTile(
              leading: SpotifyIcon.edit(size: 24, color: Colors.white),
              title: const Text('Edit playlist', style: TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: SpotifyIcon.plusCircle(size: 24, color: Colors.white),
              title: const Text('Invite collaborators', style: TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: SpotifyIcon.delete(size: 24, color: const Color(0xFFE91429)),
              title: const Text('Delete playlist', style: TextStyle(color: Color(0xFFE91429), fontSize: 15)),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ],
      SpotifyTrackOptionsEntity() => [
          ListTile(
            leading: SpotifyIcon.addToPlaylist(size: 24, color: Colors.white),
            title: const Text('Add to playlist', style: TextStyle(color: Colors.white, fontSize: 15)),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: SpotifyIcon.addToQueue(size: 24, color: Colors.white),
            title: const Text('Add to queue', style: TextStyle(color: Colors.white, fontSize: 15)),
            onTap: () => Navigator.of(context).pop(),
          ),
          if (widget.onRemoveFromPlaylist case final onRemove?)
            ListTile(
              leading: SpotifyIcon.minusCircle(size: 24, color: Colors.white),
              title: const Text('Remove from this playlist', style: TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () {
                Navigator.of(context).pop();
                onRemove();
              },
            ),
          ListTile(
            leading: SpotifyIcon.album(size: 24, color: Colors.white),
            title: const Text('View album', style: TextStyle(color: Colors.white, fontSize: 15)),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: SpotifyIcon.user(size: 24, color: Colors.white),
            title: const Text('View artist', style: TextStyle(color: Colors.white, fontSize: 15)),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: SpotifyIcon.share(size: 24, color: Colors.white),
            title: const Text('Share', style: TextStyle(color: Colors.white, fontSize: 15)),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      LocalTrackOptionsEntity() => [
          ListTile(
            leading: SpotifyIcon.addToPlaylist(size: 24, color: Colors.white),
            title: const Text('Add to playlist', style: TextStyle(color: Colors.white, fontSize: 15)),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: SpotifyIcon.addToQueue(size: 24, color: Colors.white),
            title: const Text('Add to queue', style: TextStyle(color: Colors.white, fontSize: 15)),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: SpotifyIcon.share(size: 24, color: Colors.white),
            title: const Text('Share', style: TextStyle(color: Colors.white, fontSize: 15)),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      LocalPlaylistOptionsEntity() => [
          ListTile(
            leading: SpotifyIcon.addToQueue(size: 24, color: Colors.white),
            title: const Text('Add to queue', style: TextStyle(color: Colors.white, fontSize: 15)),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: SpotifyIcon.share(size: 24, color: Colors.white),
            title: const Text('Share', style: TextStyle(color: Colors.white, fontSize: 15)),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      LibraryItemOptionsEntity() => [
          ListTile(
            leading: SpotifyIcon.share(size: 24, color: Colors.white),
            title: const Text('Share', style: TextStyle(color: Colors.white, fontSize: 15)),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
    };
  }

  Widget _buildVaultSection(BuildContext context) {
    if (widget.sessionBloc case final bloc?) {
      return BlocBuilder<VaultSessionBloc, VaultSessionState>(
        bloc: bloc,
        buildWhen: (prev, curr) {
          final prevActive = prev is VaultUnlockedState || prev is VaultBackgroundGraceState;
          final currActive = curr is VaultUnlockedState || curr is VaultBackgroundGraceState;
          return prevActive != currActive;
        },
        builder: (ctx, sessionState) {
          final isVaultActive = sessionState is VaultUnlockedState ||
              sessionState is VaultBackgroundGraceState;
          if (!isVaultActive) {
            return const SizedBox.shrink();
          }
          return _buildVaultActionsContent(context);
        },
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildVaultActionsContent(BuildContext context) {
    return switch (widget.entity) {
      SpotifyPlaylistOptionsEntity(:final playlist) => ListTile(
          key: const ValueKey('menu_clone_to_private_vault'),
          leading: const Icon(Icons.shield_outlined, size: 24, color: PlayerColors.accent),
          title: const Text(
            'Copy to Vault',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'Poppins',
            ),
          ),
          subtitle: const Text(
            'Clone to Private Vault',
            style: TextStyle(
              color: Color(0xFFB3B3B3),
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
          onTap: () => _handleClonePlaylistToVault(context, playlist),
        ),
      SpotifyTrackOptionsEntity(:final item) => ListTile(
          key: const ValueKey('menu_add_to_private_playlists'),
          leading: const Icon(Icons.shield_outlined, size: 24, color: PlayerColors.accent),
          title: const Text(
            'Copy to Vault',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'Poppins',
            ),
          ),
          subtitle: const Text(
            'Add to Private Playlists',
            style: TextStyle(
              color: Color(0xFFB3B3B3),
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
          onTap: () => _handleAddToPrivatePlaylists(context, item),
        ),
      LocalTrackOptionsEntity(:final file) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('menu_copy_local_to_vault'),
              leading: const Icon(Icons.copy_rounded, size: 24, color: PlayerColors.accent),
              title: const Text(
                'Copy to Vault',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: 'Poppins',
                ),
              ),
              subtitle: const Text(
                'Reference in private playlist',
                style: TextStyle(
                  color: Color(0xFFB3B3B3),
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
              onTap: () => _handleCopyLocalToVault(context, file),
            ),
            ListTile(
              key: const ValueKey('menu_move_local_to_vault'),
              leading: const Icon(Icons.drive_file_move_outlined, size: 24, color: PlayerColors.accent),
              title: const Text(
                'Move to Vault',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: 'Poppins',
                ),
              ),
              subtitle: const Text(
                'Isolate into private sandbox (.nomedia)',
                style: TextStyle(
                  color: Color(0xFFB3B3B3),
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
              onTap: () => _handleMoveLocalToVault(context, file),
            ),
          ],
        ),
      LocalPlaylistOptionsEntity() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('menu_copy_local_playlist_to_vault'),
              leading: const Icon(Icons.copy_rounded, size: 24, color: PlayerColors.accent),
              title: const Text(
                'Copy to Vault',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: 'Poppins',
                ),
              ),
              subtitle: const Text(
                'Reference all tracks in private playlist',
                style: TextStyle(
                  color: Color(0xFFB3B3B3),
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
              onTap: () => _handleCopyLocalPlaylistToVault(
                context,
                widget.entity as LocalPlaylistOptionsEntity,
              ),
            ),
            ListTile(
              key: const ValueKey('menu_move_local_playlist_to_vault'),
              leading: const Icon(Icons.drive_file_move_outlined, size: 24, color: PlayerColors.accent),
              title: const Text(
                'Move to Vault',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: 'Poppins',
                ),
              ),
              subtitle: const Text(
                'Isolate all tracks into sandbox (.nomedia)',
                style: TextStyle(
                  color: Color(0xFFB3B3B3),
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
              onTap: () => _handleMoveLocalPlaylistToVault(
                context,
                widget.entity as LocalPlaylistOptionsEntity,
              ),
            ),
          ],
        ),
      LibraryItemOptionsEntity(:final item) => item.type == 'playlist'
          ? ListTile(
              key: const ValueKey('menu_clone_library_to_private_vault'),
              leading: const Icon(Icons.shield_outlined, size: 24, color: PlayerColors.accent),
              title: const Text(
                'Copy to Vault',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: 'Poppins',
                ),
              ),
              subtitle: const Text(
                'Clone to Private Vault',
                style: TextStyle(
                  color: Color(0xFFB3B3B3),
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
              onTap: () => _handleCloneLibraryPlaylistToVault(context, item),
            )
          : const SizedBox.shrink(),
    };
  }
}
