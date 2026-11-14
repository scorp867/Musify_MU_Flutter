import 'package:flutter/material.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/data/datasources/local_tracks_store.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_uri.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_artwork.dart';
import 'package:musify_mu/features/player/presentation/widgets/pull_to_dismiss_scaffold.dart';
import 'package:musify_mu/features/player/presentation/widgets/spotify_scroll_physics.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/extensions/vault_storage_batch_ops.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_settings_components.dart';

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
          'Keeps the original file in your library and links it privately.',
        VaultSongIngestionModeEnum.moveToVault =>
          'Moves the audio file into private storage and hides it from public apps.',
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
  final VaultThemeData? vaultTheme;

  const VaultLocalSongPickerSheet({
    super.key,
    required this.playlist,
    this.storageRepository,
    this.isolationManager,
    this.localTracksStore,
    this.database,
    this.vaultTheme,
  });

  /// Displays [VaultLocalSongPickerSheet] inside a modal route.
  static Future<bool?> show(
    BuildContext context, {
    required PrivatePlaylist playlist,
    IVaultStorageRepository? storageRepository,
    IVaultMediaIsolationManager? isolationManager,
    LocalTracksStore? localTracksStore,
    AppDatabase? database,
    VaultThemeData? vaultTheme,
  }) {
    final resolvedTheme = resolveVaultTheme(context, vaultTheme);
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) => VaultTheme(
        data: resolvedTheme,
        child: VaultLocalSongPickerSheet(
          playlist: playlist,
          storageRepository: storageRepository,
          isolationManager: isolationManager,
          localTracksStore: localTracksStore,
          database: database,
          vaultTheme: resolvedTheme,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = resolveVaultTheme(context, vaultTheme);
    return PullToDismissScaffold(
      builder: (scaffoldContext, dismissController) {
        return _VaultLocalSongPickerContent(
          playlist: playlist,
          dismissController: dismissController,
          vaultTheme: resolvedTheme,
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
  final VaultThemeData vaultTheme;
  final IVaultStorageRepository? storageRepository;
  final IVaultMediaIsolationManager? isolationManager;
  final LocalTracksStore? localTracksStore;
  final AppDatabase? database;

  const _VaultLocalSongPickerContent({
    required this.playlist,
    required this.dismissController,
    required this.vaultTheme,
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
  static const double _pickerRowHeight = 70.0;
  static const double _pickerRowSpacing = 8.0;
  static const double _pickerItemExtent = _pickerRowHeight + _pickerRowSpacing;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<_FilteredTracksSnapshot> _filteredSnapshot =
      ValueNotifier<_FilteredTracksSnapshot>(
    const _FilteredTracksSnapshot(
      entries: <_PickerTrackEntry>[],
      selectablePaths: <String>[],
      isFiltering: false,
    ),
  );
  final ValueNotifier<int> _selectionVersion = ValueNotifier<int>(0);

  VaultSongIngestionModeEnum _ingestionMode =
      VaultSongIngestionModeEnum.copyToVault;
  List<LocalTrack> _allTracks = const [];
  List<_PickerTrackEntry> _allEntries = const <_PickerTrackEntry>[];
  Set<String> _existingIdentifiers = const <String>{};
  bool _isLoading = true;
  String? _errorMessage;

  final Set<String> _selectedTrackPaths = <String>{};
  bool _isProcessing = false;
  int _processingCurrent = 0;
  int _processingTotal = 0;

  @override
  void initState() {
    super.initState();
    _existingIdentifiers = _buildExistingIdentifiers();
    _searchController.addListener(_onSearchChanged);
    _loadLocalTracks();
  }

  @override
  void didUpdateWidget(covariant _VaultLocalSongPickerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playlist != widget.playlist) {
      _existingIdentifiers = _buildExistingIdentifiers();
      _rebuildEntriesAndFilter(_allTracks);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _filteredSnapshot.dispose();
    _selectionVersion.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    _applySearchFilter();
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
          _allTracks = tracks;
          _rebuildEntriesAndFilter(tracks);
          setState(() {
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
            _allTracks = tracks;
            _rebuildEntriesAndFilter(tracks);
            setState(() {
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

  _PickerTrackEntry _createEntry(LocalTrack track) {
    final isAlreadyAdded =
        _isTrackAlreadyInPlaylist(track, _existingIdentifiers);
    final displayTitle =
        track.title.isNotEmpty ? track.title : track.dataPath.split('/').last;
    final artist = switch (track.artist) {
      final a? when a.isNotEmpty => a,
      _ => 'Unknown Artist',
    };
    final durationStr = switch (track.duration) {
      final d? when d > 0 => DurationFormatter.milliseconds(d),
      _ => '',
    };
    final displaySubtitle =
        durationStr.isNotEmpty ? '$artist \u2022 $durationStr' : artist;

    return _PickerTrackEntry(
      track: track,
      isAlreadyAdded: isAlreadyAdded,
      titleLower: track.title.toLowerCase(),
      artistLower: switch (track.artist) {
        final a? => a.toLowerCase(),
        null => '',
      },
      displayTitle: displayTitle,
      displaySubtitle: displaySubtitle,
      artworkUri: _localTrackArtworkUri(track),
    );
  }

  void _rebuildEntriesAndFilter(List<LocalTrack> tracks) {
    _allEntries =
        List<_PickerTrackEntry>.unmodifiable(tracks.map(_createEntry));
    _applySearchFilter();
  }

  void _applySearchFilter() {
    final query = _searchController.text.trim().toLowerCase();
    final List<_PickerTrackEntry> matched = query.isEmpty
        ? _allEntries
        : _allEntries
            .where(
              (entry) =>
                  entry.titleLower.contains(query) ||
                  entry.artistLower.contains(query),
            )
            .toList(growable: false);

    final List<String> selectablePaths = matched
        .where((entry) => !entry.isAlreadyAdded)
        .map((entry) => entry.track.dataPath)
        .toList(growable: false);

    _filteredSnapshot.value = _FilteredTracksSnapshot(
      entries: matched,
      selectablePaths: selectablePaths,
      isFiltering: query.isNotEmpty,
    );
  }

  void _toggleTrackSelection(LocalTrack track, bool isAlreadyAdded) {
    if (isAlreadyAdded || _isProcessing) return;
    if (_selectedTrackPaths.contains(track.dataPath)) {
      _selectedTrackPaths.remove(track.dataPath);
    } else {
      _selectedTrackPaths.add(track.dataPath);
    }
    _selectionVersion.value++;
  }

  void _toggleSelectAllFiltered(List<String> selectablePaths) {
    if (_isProcessing) return;
    final allSelected = selectablePaths.every(_selectedTrackPaths.contains);
    if (allSelected) {
      for (final p in selectablePaths) {
        _selectedTrackPaths.remove(p);
      }
    } else {
      _selectedTrackPaths.addAll(selectablePaths);
    }
    _selectionVersion.value++;
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
      if (mounted) {
        showVaultSettingsSnackBar(
          context,
          widget.vaultTheme,
          message: 'Unable to save tracks right now.',
          isError: true,
        );
      }
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
      final noun = count == 1 ? 'song' : 'songs';
      showVaultSettingsSnackBar(
        context,
        widget.vaultTheme,
        message: '$modeVerb $count $noun to "${widget.playlist.name}"',
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultTheme = widget.vaultTheme;

    return VaultSheetScaffold(
      vaultTheme: vaultTheme,
      title: 'Add Local Songs',
      subtitle: widget.playlist.name,
      heightFactor: 0.85,
      expandBody: true,
      onClose: () => Navigator.of(context).pop(false),
      bottomBar: _buildBottomActionBar(vaultTheme),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
            child: VaultSegmentedControl<VaultSongIngestionModeEnum>(
              vaultTheme: vaultTheme,
              selectedValue: _ingestionMode,
              onChanged: _isProcessing
                  ? null
                  : (mode) => setState(() => _ingestionMode = mode),
              options: const [
                VaultSegmentOption(
                  value: VaultSongIngestionModeEnum.copyToVault,
                  label: 'Copy to Vault',
                  icon: Icons.copy_rounded,
                ),
                VaultSegmentOption(
                  value: VaultSongIngestionModeEnum.moveToVault,
                  label: 'Move to Vault',
                  icon: Icons.drive_file_move_outlined,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 9.0,
              ),
              decoration: BoxDecoration(
                color: vaultTheme.background,
                borderRadius: VaultTheme.borderRadius8,
                border: Border.all(
                  color: vaultTheme.borderSubtle,
                  width: VaultTheme.borderWidth,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1.5),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 15.0,
                      color: vaultTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      _ingestionMode.description,
                      style: TextStyle(
                        fontFamily: VaultTheme.fontFamily,
                        fontSize: 12.0,
                        height: 1.35,
                        color: vaultTheme.textMediumSalience,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 10.0),
            child: Row(
              children: [
                Expanded(
                  child: VaultInlineSearchField(
                    controller: _searchController,
                    vaultTheme: vaultTheme,
                    hintText: 'Filter songs or artists',
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 8.0),
                ListenableBuilder(
                  listenable: Listenable.merge([
                    _filteredSnapshot,
                    _selectionVersion,
                  ]),
                  builder: (context, _) {
                    final selectablePaths =
                        _filteredSnapshot.value.selectablePaths;
                    final hasSelectable = selectablePaths.isNotEmpty;
                    final allSelectableChecked = hasSelectable &&
                        selectablePaths.every(_selectedTrackPaths.contains);

                    return SizedBox(
                      height: 44.0,
                      child: OutlinedButton(
                        onPressed: hasSelectable && !_isProcessing
                            ? () => _toggleSelectAllFiltered(selectablePaths)
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: vaultTheme.accent,
                          disabledForegroundColor: vaultTheme.textLowSalience,
                          side: BorderSide(
                            color: hasSelectable
                                ? vaultTheme.borderSubtle
                                : vaultTheme.borderSubtle
                                    .withValues(alpha: 0.4),
                            width: VaultTheme.borderWidth,
                          ),
                          shape: VaultTheme.shape8,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        ),
                        child: Text(
                          allSelectableChecked ? 'Clear' : 'Select All',
                          style: const TextStyle(
                            fontFamily: VaultTheme.fontFamily,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Divider(
            color: vaultTheme.borderSubtle,
            height: 1.0,
            thickness: VaultTheme.borderWidth,
          ),
          Expanded(
            child: _buildTracksBody(vaultTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildTracksBody(VaultThemeData vaultTheme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: vaultTheme.accent),
      );
    }

    if (_errorMessage case final err?) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: vaultTheme.background,
              borderRadius: VaultTheme.borderRadius8,
              border: Border.all(
                color: vaultTheme.borderSubtle,
                width: VaultTheme.borderWidth,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: vaultDangerInk(vaultTheme),
                  size: 36.0,
                ),
                const SizedBox(height: 12.0),
                Text(
                  err,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    color: vaultTheme.textMediumSalience,
                    fontSize: 13.0,
                  ),
                ),
                const SizedBox(height: 14.0),
                SizedBox(
                  height: 44.0,
                  child: OutlinedButton(
                    onPressed: _loadLocalTracks,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: vaultTheme.accent,
                      side: BorderSide(
                        color: vaultTheme.border,
                        width: VaultTheme.borderWidth,
                      ),
                      shape: VaultTheme.shape8,
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        fontFamily: VaultTheme.fontFamily,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ValueListenableBuilder<_FilteredTracksSnapshot>(
      valueListenable: _filteredSnapshot,
      builder: (context, snapshot, _) {
        final entries = snapshot.entries;
        if (entries.isEmpty) {
          final isFiltering = snapshot.isFiltering;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52.0,
                    height: 52.0,
                    decoration: BoxDecoration(
                      color: vaultTheme.surfaceSubtle,
                      borderRadius: VaultTheme.borderRadius8,
                      border: Border.all(
                        color: vaultTheme.borderSubtle,
                        width: VaultTheme.borderWidth,
                      ),
                    ),
                    child: Icon(
                      isFiltering
                          ? Icons.search_off_rounded
                          : Icons.music_off_outlined,
                      color: vaultTheme.textLowSalience,
                      size: 26.0,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    isFiltering ? 'No Songs Found' : 'No Local Songs',
                    style: TextStyle(
                      fontFamily: VaultTheme.fontFamily,
                      color: vaultTheme.textHighSalience,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    isFiltering
                        ? 'Try a different song or artist.'
                        : 'Add audio files to your device to import them here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: VaultTheme.fontFamily,
                      color: vaultTheme.textMediumSalience,
                      fontSize: 13.0,
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
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
            itemExtent: _pickerItemExtent,
            itemCount: entries.length,
            itemBuilder: (context, index) {
              return _buildTrackPickerTile(
                vaultTheme: vaultTheme,
                entry: entries[index],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTrackPickerTile({
    required VaultThemeData vaultTheme,
    required _PickerTrackEntry entry,
  }) {
    final track = entry.track;
    final isAlreadyAdded = entry.isAlreadyAdded;

    final Widget artworkAndMetadata = Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6.0),
          child: SizedBox(
            width: 44.0,
            height: 44.0,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PlayerArtworkImage(
                  imageUrl: entry.artworkUri,
                  artworkWidth: 44,
                  artworkHeight: 44,
                  placeholderIconSize: 20,
                  placeholderIcon: Icons.music_note_rounded,
                ),
                if (isAlreadyAdded)
                  ColoredBox(
                    color: vaultTheme.background.withValues(alpha: 0.50),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  color: isAlreadyAdded
                      ? vaultTheme.textLowSalience
                      : vaultTheme.textHighSalience,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                entry.displaySubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  color: isAlreadyAdded
                      ? vaultTheme.textLowSalience
                      : vaultTheme.textMediumSalience,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (isAlreadyAdded) {
      return Padding(
        padding: const EdgeInsets.only(bottom: _pickerRowSpacing),
        child: SizedBox(
          height: _pickerRowHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: vaultTheme.background.withValues(alpha: 0.65),
              borderRadius: VaultTheme.borderRadius8,
              border: Border.all(
                color: vaultTheme.borderSubtle.withValues(alpha: 0.50),
                width: VaultTheme.borderWidth,
              ),
            ),
            child: Padding(
              key: ValueKey('picker_track_${track.dataPath}'),
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(child: artworkAndMetadata),
                  const SizedBox(width: 8.0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: vaultTheme.surfaceSubtle.withValues(alpha: 0.60),
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(
                        color: vaultTheme.borderSubtle.withValues(alpha: 0.50),
                        width: VaultTheme.borderWidth,
                      ),
                    ),
                    child: Text(
                      'Added',
                      style: TextStyle(
                        fontFamily: VaultTheme.fontFamily,
                        color: vaultTheme.textLowSalience,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ValueListenableBuilder<int>(
      valueListenable: _selectionVersion,
      child: artworkAndMetadata,
      builder: (context, _, staticLeading) {
        final isSelected = _selectedTrackPaths.contains(track.dataPath);
        return Padding(
          padding: const EdgeInsets.only(bottom: _pickerRowSpacing),
          child: SizedBox(
            height: _pickerRowHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isSelected
                    ? vaultTheme.accent.withValues(alpha: 0.10)
                    : vaultTheme.background,
                borderRadius: VaultTheme.borderRadius8,
                border: Border.all(
                  color:
                      isSelected ? vaultTheme.accent : vaultTheme.borderSubtle,
                  width: VaultTheme.borderWidth,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('picker_track_${track.dataPath}'),
                  borderRadius: VaultTheme.borderRadius8,
                  onTap: _isProcessing
                      ? null
                      : () => _toggleTrackSelection(track, false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: staticLeading ?? artworkAndMetadata,
                        ),
                        const SizedBox(width: 8.0),
                        Checkbox(
                          value: isSelected,
                          activeColor: vaultTheme.accent,
                          checkColor: vaultTheme.scaffold,
                          side: BorderSide(
                            color: vaultTheme.border,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          onChanged: _isProcessing
                              ? null
                              : (_) => _toggleTrackSelection(track, false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActionBar(VaultThemeData vaultTheme) {
    final actionVerb = _ingestionMode == VaultSongIngestionModeEnum.copyToVault
        ? 'Add'
        : 'Move';

    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
      decoration: BoxDecoration(
        color: vaultTheme.surface,
        border: Border(
          top: BorderSide(
            color: vaultTheme.borderSubtle,
            width: VaultTheme.borderWidth,
          ),
        ),
      ),
      child: ValueListenableBuilder<int>(
        valueListenable: _selectionVersion,
        builder: (context, _, _) {
          final count = _selectedTrackPaths.length;
          final canCommit = count > 0 && !_isProcessing;
          final songWord = count == 1 ? 'Song' : 'Songs';

          return SizedBox(
            width: double.infinity,
            height: 48.0,
            child: ElevatedButton(
              key: const ValueKey('picker_commit_add_songs_button'),
              onPressed: canCommit ? _commitAddition : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: vaultTheme.accent,
                foregroundColor: vaultTheme.scaffold,
                disabledBackgroundColor: vaultTheme.surfaceSubtle,
                disabledForegroundColor: vaultTheme.textLowSalience,
                shape: VaultTheme.shape8,
                elevation: 0.0,
              ),
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18.0,
                          height: 18.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              vaultTheme.scaffold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          'Processing $_processingCurrent of $_processingTotal...',
                          style: TextStyle(
                            fontFamily: VaultTheme.fontFamily,
                            color: vaultTheme.scaffold,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      count == 0
                          ? 'Select Songs'
                          : '$actionVerb $count $songWord to Playlist',
                      style: TextStyle(
                        fontFamily: VaultTheme.fontFamily,
                        color: canCommit
                            ? vaultTheme.scaffold
                            : vaultTheme.textLowSalience,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.0,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _PickerTrackEntry {
  final LocalTrack track;
  final bool isAlreadyAdded;
  final String titleLower;
  final String artistLower;
  final String displayTitle;
  final String displaySubtitle;
  final String artworkUri;

  const _PickerTrackEntry({
    required this.track,
    required this.isAlreadyAdded,
    required this.titleLower,
    required this.artistLower,
    required this.displayTitle,
    required this.displaySubtitle,
    required this.artworkUri,
  });
}

class _FilteredTracksSnapshot {
  final List<_PickerTrackEntry> entries;
  final List<String> selectablePaths;
  final bool isFiltering;

  const _FilteredTracksSnapshot({
    required this.entries,
    required this.selectablePaths,
    required this.isFiltering,
  });
}
