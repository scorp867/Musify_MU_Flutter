import 'package:flutter/material.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/data/datasources/local_tracks_store.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_uri.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_artwork.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_header.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_theme.dart';
import 'package:musify_mu/features/player/presentation/widgets/pull_to_dismiss_scaffold.dart';
import 'package:musify_mu/features/player/presentation/widgets/spotify_scroll_physics.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/extensions/vault_storage_batch_ops.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';

/// Ingestion mode for adding local songs into the private vault.
enum VaultSongIngestionModeEnum {
  /// Reference copy: points directly to the local device file URI without moving.
  copyToVault,

  /// Physical move: relocates the file into the .nomedia sandbox and removes from local index.
  moveToVault;

  String get title => switch (this) {
        VaultSongIngestionModeEnum.copyToVault => 'Copy to Vault',
        VaultSongIngestionModeEnum.moveToVault => 'Move to Vault',
      };

  String get description => switch (this) {
        VaultSongIngestionModeEnum.copyToVault =>
          'Leaves the original file in place and creates a secured private reference.',
        VaultSongIngestionModeEnum.moveToVault =>
          'Moves the audio file into the hidden .nomedia sandbox and removes it from public storage.',
      };
}

/// Authentic bottom sheet allowing users to multi-select local songs and add them
/// to an existing [PrivatePlaylist] with Copy or Move ingestion modes.
class VaultLocalSongPickerSheet extends StatelessWidget {
  final PrivatePlaylist playlist;
  final IVaultStorageRepository? storageRepository;
  final IVaultMediaIsolationManager? isolationManager;
  final LocalTracksStore? localTracksStore;
  final AppDatabase? database;

  const VaultLocalSongPickerSheet({
    super.key,
    required this.playlist,
    this.storageRepository,
    this.isolationManager,
    this.localTracksStore,
    this.database,
  });

  /// Displays [VaultLocalSongPickerSheet] inside a modal route.
  static Future<bool?> show(
    BuildContext context, {
    required PrivatePlaylist playlist,
    IVaultStorageRepository? storageRepository,
    IVaultMediaIsolationManager? isolationManager,
    LocalTracksStore? localTracksStore,
    AppDatabase? database,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => VaultLocalSongPickerSheet(
        playlist: playlist,
        storageRepository: storageRepository,
        isolationManager: isolationManager,
        localTracksStore: localTracksStore,
        database: database,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PullToDismissScaffold(
      builder: (scaffoldContext, dismissController) {
        return _VaultLocalSongPickerContent(
          playlist: playlist,
          dismissController: dismissController,
          storageRepository: storageRepository,
          isolationManager: isolationManager,
          localTracksStore: localTracksStore,
          database: database,
        );
      },
    );
  }
}

class _VaultLocalSongPickerContent extends StatefulWidget {
  final PrivatePlaylist playlist;
  final PullToDismissController dismissController;
  final IVaultStorageRepository? storageRepository;
  final IVaultMediaIsolationManager? isolationManager;
  final LocalTracksStore? localTracksStore;
  final AppDatabase? database;

  const _VaultLocalSongPickerContent({
    required this.playlist,
    required this.dismissController,
    this.storageRepository,
    this.isolationManager,
    this.localTracksStore,
    this.database,
  });

  @override
  State<_VaultLocalSongPickerContent> createState() =>
      _VaultLocalSongPickerContentState();
}

class _VaultLocalSongPickerContentState
    extends State<_VaultLocalSongPickerContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  VaultSongIngestionModeEnum _ingestionMode =
      VaultSongIngestionModeEnum.copyToVault;
  List<LocalTrack> _allTracks = const [];
  bool _isLoading = true;
  String? _errorMessage;

  final Set<String> _selectedTrackPaths = <String>{};
  bool _isProcessing = false;
  int _processingCurrent = 0;
  int _processingTotal = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadLocalTracks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadLocalTracks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      LocalTracksStore? store = widget.localTracksStore;
      if (store == null && getIt.isRegistered<LocalTracksStore>()) {
        store = getIt<LocalTracksStore>();
      }

      if (store case final resolvedStore?) {
        final tracks = await resolvedStore.getAll();
        if (mounted) {
          setState(() {
            _allTracks = tracks;
            _isLoading = false;
          });
        }
      } else {
        AppDatabase? db = widget.database;
        if (db == null && getIt.isRegistered<AppDatabase>()) {
          db = getIt<AppDatabase>();
        }
        if (db case final resolvedDb?) {
          final tracks = await resolvedDb.getAllTracks();
          if (mounted) {
            setState(() {
              _allTracks = tracks;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = 'Local audio database is not registered.';
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load local tracks: $e';
          _isLoading = false;
        });
      }
    }
  }

  Set<String> _buildExistingIdentifiers() {
    final ids = <String>{};
    for (final ref in widget.playlist.trackRefs) {
      ids.add(ref.trackUri);
      if (ref.localRelativePath case final rel? when rel.isNotEmpty) {
        ids.add(rel);
      }
      final canonicalKey =
          '${ref.title.trim().toLowerCase()}|${ref.artistName.trim().toLowerCase()}';
      ids.add(canonicalKey);
    }
    return ids;
  }

  bool _isTrackAlreadyInPlaylist(
      LocalTrack track, Set<String> existingIdentifiers) {
    if (existingIdentifiers.contains(track.dataPath)) {
      return true;
    }
    final fileName = track.dataPath.split('/').last;
    if (existingIdentifiers.contains(fileName)) {
      return true;
    }
    final artistStr = switch (track.artist) {
      final a? => a.trim().toLowerCase(),
      null => '',
    };
    final canonicalKey = '${track.title.trim().toLowerCase()}|$artistStr';
    if (existingIdentifiers.contains(canonicalKey)) {
      return true;
    }
    return false;
  }

  List<LocalTrack> _filteredTracks(Set<String> existingIdentifiers) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _allTracks;
    }
    return _allTracks.where((track) {
      final titleMatch = track.title.toLowerCase().contains(query);
      final artist = switch (track.artist) {
        final a? => a.toLowerCase(),
        null => '',
      };
      final artistMatch = artist.contains(query);
      return titleMatch || artistMatch;
    }).toList();
  }

  void _toggleTrackSelection(LocalTrack track, bool isAlreadyAdded) {
    if (isAlreadyAdded || _isProcessing) return;
    setState(() {
      if (_selectedTrackPaths.contains(track.dataPath)) {
        _selectedTrackPaths.remove(track.dataPath);
      } else {
        _selectedTrackPaths.add(track.dataPath);
      }
    });
  }

  void _toggleSelectAllFiltered(
      List<LocalTrack> filtered, Set<String> existingIdentifiers) {
    if (_isProcessing) return;
    final selectablePaths = filtered
        .where((t) => !_isTrackAlreadyInPlaylist(t, existingIdentifiers))
        .map((t) => t.dataPath)
        .toList();

    setState(() {
      final allSelected =
          selectablePaths.every(_selectedTrackPaths.contains);
      if (allSelected) {
        for (final p in selectablePaths) {
          _selectedTrackPaths.remove(p);
        }
      } else {
        _selectedTrackPaths.addAll(selectablePaths);
      }
    });
  }

  String _localTrackArtworkUri(LocalTrack track) {
    final durationSeconds = switch (track.duration) {
      final d? when d > 0 => d ~/ 1000,
      _ => 0,
    };
    return LocalFileUri.toLocalFileImageUri(
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
  }

  Future<void> _commitAddition() async {
    if (_selectedTrackPaths.isEmpty || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _processingCurrent = 0;
      _processingTotal = _selectedTrackPaths.length;
    });

    IVaultStorageRepository? storageRepo = widget.storageRepository;
    if (storageRepo == null && getIt.isRegistered<IVaultStorageRepository>()) {
      storageRepo = getIt<IVaultStorageRepository>();
    }

    if (storageRepo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage repository unavailable.')),
      );
      setState(() => _isProcessing = false);
      return;
    }

    IVaultMediaIsolationManager? isolationManager = widget.isolationManager;
    if (isolationManager == null &&
        getIt.isRegistered<IVaultMediaIsolationManager>()) {
      isolationManager = getIt<IVaultMediaIsolationManager>();
    }

    AppDatabase? db = widget.database;
    if (db == null && getIt.isRegistered<AppDatabase>()) {
      db = getIt<AppDatabase>();
    }

    final selectedList = _allTracks
        .where((t) => _selectedTrackPaths.contains(t.dataPath))
        .toList();

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final pendingTrackRefs = <PrivateTrackRef>[];
    final movedSongIds = <int>{};
    final movedDataPaths = <String>[];
    var index = 0;

    for (final track in selectedList) {
      index++;
      if (!mounted) return;
      setState(() => _processingCurrent = index);

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

      final referenceArtworkUri = _localTrackArtworkUri(track);

      if (_ingestionMode == VaultSongIngestionModeEnum.copyToVault) {
        final trackId = 'ref_${widget.playlist.id}_${nowMs}_$index';
        pendingTrackRefs.add(
          PrivateTrackRef(
            id: trackId,
            playlistId: widget.playlist.id,
            trackUri: track.dataPath,
            title: trackTitle,
            artistName: trackArtist,
            albumTitle: trackAlbum,
            durationMs: trackDuration,
            sourceType: TrackSourceTypeEnum.localReference,
            localRelativePath: null,
            sortOrder: widget.playlist.trackCount + index,
            addedAtEpochMs: nowMs,
            artworkUri: referenceArtworkUri,
          ),
        );
      } else {
        final trackId = 'iso_${widget.playlist.id}_${nowMs}_$index';
        String finalUri = track.dataPath;
        String finalRelPath = track.dataPath.split('/').last;

        if (isolationManager case final iso?) {
          try {
            final isolatedResult = await iso.isolateTrackDetailed(
              sourceFilePath: track.dataPath,
              trackId: trackId,
            );
            finalUri = isolatedResult.isolatedFile.path;
            finalRelPath = isolatedResult.relativePath;
          } catch (_) {
            finalUri = track.dataPath;
            finalRelPath = track.dataPath.split('/').last;
          }
        }

        movedSongIds.add(track.songId);
        movedDataPaths.add(track.dataPath);

        pendingTrackRefs.add(
          PrivateTrackRef(
            id: trackId,
            playlistId: widget.playlist.id,
            trackUri: finalUri,
            title: trackTitle,
            artistName: trackArtist,
            albumTitle: trackAlbum,
            durationMs: trackDuration,
            sourceType: TrackSourceTypeEnum.localSandbox,
            localRelativePath: finalRelPath,
            sortOrder: widget.playlist.trackCount + index,
            addedAtEpochMs: nowMs,
            artworkUri: LocalFileUri.toFileUri(finalUri),
          ),
        );
      }
    }

    if (movedSongIds.isNotEmpty) {
      if (widget.localTracksStore case final store?) {
        try {
          await store.deleteBySongIds(movedSongIds);
        } catch (_) {}
      } else if (db case final appDb?) {
        try {
          await (appDb.delete(appDb.localTracks)
                ..where((tbl) => tbl.dataPath.isIn(movedDataPaths)))
              .go();
        } catch (_) {}
      }
    }

    await storageRepo.addTracksToPlaylist(
      playlistId: widget.playlist.id,
      trackRefs: pendingTrackRefs,
    );

    if (mounted) {
      final count = selectedList.length;
      final modeVerb =
          _ingestionMode == VaultSongIngestionModeEnum.copyToVault
              ? 'Added'
              : 'Moved';
      final msg = '$modeVerb $count songs to "${widget.playlist.name}"';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingIdentifiers = _buildExistingIdentifiers();
    final filtered = _filteredTracks(existingIdentifiers);

    return Material(
      color: PlayerColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              // 1. Drag Handle & Sheet Header
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Add Local Songs',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.playlist.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: PlayerColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PlayerCircleButton(
                          icon: Icons.close_rounded,
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Segmented Mode Control [ Copy to Vault | Move to Vault ]
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: _buildSegmentedControl(),
              ),

              // Mode description subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _ingestionMode.description,
                    style: TextStyle(
                      fontFamily: VaultTheme.fontFamily,
                      fontSize: 11.5,
                      color: PlayerColors.textSecondary,
                    ),
                  ),
                ),
              ),

              // 3. Search and Selection Summary Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40.0,
                        decoration: BoxDecoration(
                          color: PlayerColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1.0,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Filter local songs...',
                            hintStyle: const TextStyle(
                              color: PlayerColors.textSecondary,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: PlayerColors.textSecondary,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: PlayerColors.textSecondary,
                                    ),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _toggleSelectAllFiltered(
                          filtered, existingIdentifiers),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1DB954),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      child: const Text(
                        'Toggle All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: PlayerColors.divider, height: 1),

              // 4. Songs List
              Expanded(
                child: _buildTracksBody(filtered, existingIdentifiers),
              ),

              // 5. Sticky Bottom Action Bar
              _buildBottomActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: PlayerColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(
              mode: VaultSongIngestionModeEnum.copyToVault,
              icon: Icons.copy_rounded,
            ),
          ),
          Expanded(
            child: _buildSegmentButton(
              mode: VaultSongIngestionModeEnum.moveToVault,
              icon: Icons.drive_file_move_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required VaultSongIngestionModeEnum mode,
    required IconData icon,
  }) {
    final isSelected = _ingestionMode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isProcessing
            ? null
            : () {
                setState(() => _ingestionMode = mode);
              },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1DB954) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.black : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                mode.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.black : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTracksBody(
    List<LocalTrack> tracks,
    Set<String> existingIdentifiers,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1DB954)),
      );
    }

    if (_errorMessage case final err?) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              Text(
                err,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadLocalTracks,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1DB954),
                  side: const BorderSide(color: Color(0xFF1DB954)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (tracks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.music_off_outlined,
                  color: PlayerColors.textSecondary, size: 44),
              const SizedBox(height: 12),
              const Text(
                'No local tracks found.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _searchController.text.isNotEmpty
                    ? 'Try adjusting your search query.'
                    : 'Ensure audio files are present on the device.',
                style: const TextStyle(
                  color: PlayerColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SpotifyStretchOverscrollIndicator(
      axisDirection: AxisDirection.down,
      child: ListView.builder(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          final isAlreadyAdded =
              _isTrackAlreadyInPlaylist(track, existingIdentifiers);
          final isSelected = _selectedTrackPaths.contains(track.dataPath);

          return _buildTrackPickerTile(
            track: track,
            isAlreadyAdded: isAlreadyAdded,
            isSelected: isSelected,
          );
        },
      ),
    );
  }

  Widget _buildTrackPickerTile({
    required LocalTrack track,
    required bool isAlreadyAdded,
    required bool isSelected,
  }) {
    final title = track.title.isNotEmpty ? track.title : track.dataPath.split('/').last;
    final artist = switch (track.artist) {
      final a? when a.isNotEmpty => a,
      _ => 'Unknown Artist',
    };
    final durationStr = switch (track.duration) {
      final d? when d > 0 => DurationFormatter.milliseconds(d),
      _ => '',
    };

    return Opacity(
      opacity: isAlreadyAdded ? 0.45 : 1.0,
      child: ListTile(
        key: ValueKey('picker_track_${track.dataPath}'),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
        onTap: isAlreadyAdded
            ? null
            : () => _toggleTrackSelection(track, isAlreadyAdded),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 44,
            height: 44,
            child: PlayerArtworkImage(
              imageUrl: _localTrackArtworkUri(track),
              artworkWidth: 44,
              artworkHeight: 44,
              placeholderIconSize: 22,
              placeholderIcon: Icons.music_note,
            ),
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isAlreadyAdded ? Colors.white60 : Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          durationStr.isNotEmpty ? '$artist \u2022 $durationStr' : artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: PlayerColors.textSecondary,
            fontSize: 12.5,
          ),
        ),
        trailing: isAlreadyAdded
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                ),
                child: const Text(
                  'Added',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : Checkbox(
                value: isSelected,
                activeColor: const Color(0xFF1DB954),
                checkColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: _isProcessing
                    ? null
                    : (_) => _toggleTrackSelection(track, isAlreadyAdded),
              ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final count = _selectedTrackPaths.length;
    final canCommit = count > 0 && !_isProcessing;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: PlayerColors.surface,
        border: Border(
          top: BorderSide(color: PlayerColors.divider, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            key: const ValueKey('picker_commit_add_songs_button'),
            onPressed: canCommit ? _commitAddition : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
              disabledBackgroundColor:
                  const Color(0xFF1DB954).withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: _isProcessing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Processing $_processingCurrent / $_processingTotal...',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                : Text(
                    count == 0
                        ? 'Select Songs'
                        : 'Add $count ${count == 1 ? 'Song' : 'Songs'} to Playlist',
                    style: TextStyle(
                      color: canCommit ? Colors.black : Colors.white38,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
