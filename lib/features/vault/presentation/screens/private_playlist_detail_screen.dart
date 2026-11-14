import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/data/services/playback_privacy_proxy.dart';
import 'package:musify_mu/features/vault/data/services/vault_audio_playback_service.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/extensions/vault_storage_batch_ops.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_auth_screen.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';
import 'package:musify_mu/features/vault/presentation/widgets/reauth_blur_overlay.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_artwork_image.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_local_song_picker_sheet.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_settings_components.dart';

/// Artwork privacy peek state on the playlist detail header.
enum ArtworkPeekStateEnum {
  /// Cover artwork is shielded by frosted glass blur.
  frostedPeek,

  /// Cover artwork is fully unblurred and visible.
  unblurredPeek;

  ArtworkPeekStateEnum get toggle => switch (this) {
        ArtworkPeekStateEnum.frostedPeek => ArtworkPeekStateEnum.unblurredPeek,
        ArtworkPeekStateEnum.unblurredPeek => ArtworkPeekStateEnum.frostedPeek,
      };
}

/// Playback status of the active track within the private playlist.
enum PlaylistPlaybackStatusEnum {
  /// Track is currently actively playing.
  playing,

  /// Playback is paused on the active track.
  paused,

  /// Playback is stopped or idle.
  stopped;

  /// Helper getter to evaluate whether status is actively playing.
  bool get isPlaying => this == PlaylistPlaybackStatusEnum.playing;
}

/// Deeply immutable sealed state hierarchy for [PrivatePlaylistDetailScreen].
sealed class PrivatePlaylistDetailState extends Equatable {
  const PrivatePlaylistDetailState();

  @override
  List<Object?> get props => [];
}

/// Asynchronously loading playlist entity from encrypted vault storage.
final class PrivatePlaylistDetailLoadingState extends PrivatePlaylistDetailState {
  const PrivatePlaylistDetailLoadingState();
}

/// Successfully loaded playlist with active track filtering and playback status.
final class PrivatePlaylistDetailLoadedState extends PrivatePlaylistDetailState {
  final PrivatePlaylist playlist;
  final String searchQuery;
  final List<PrivateTrackRef> filteredTracks;
  final ArtworkPeekStateEnum artworkPeekState;
  final String? activeTrackId;
  final PlaylistPlaybackStatusEnum playbackStatus;

  const PrivatePlaylistDetailLoadedState({
    required this.playlist,
    required this.searchQuery,
    required this.filteredTracks,
    required this.artworkPeekState,
    this.activeTrackId,
    this.playbackStatus = PlaylistPlaybackStatusEnum.stopped,
  });

  PrivatePlaylistDetailLoadedState copyWith({
    PrivatePlaylist? playlist,
    String? searchQuery,
    List<PrivateTrackRef>? filteredTracks,
    ArtworkPeekStateEnum? artworkPeekState,
    String? activeTrackId,
    PlaylistPlaybackStatusEnum? playbackStatus,
    bool clearActiveTrack = false,
  }) {
    return PrivatePlaylistDetailLoadedState(
      playlist: switch (playlist) {
        final p? => p,
        null => this.playlist,
      },
      searchQuery: switch (searchQuery) {
        final q? => q,
        null => this.searchQuery,
      },
      filteredTracks: switch (filteredTracks) {
        final f? => f,
        null => this.filteredTracks,
      },
      artworkPeekState: switch (artworkPeekState) {
        final a? => a,
        null => this.artworkPeekState,
      },
      activeTrackId: clearActiveTrack
          ? null
          : switch (activeTrackId) {
              final id? => id,
              null => this.activeTrackId,
            },
      playbackStatus: switch (playbackStatus) {
        final s? => s,
        null => this.playbackStatus,
      },
    );
  }

  @override
  List<Object?> get props => [
        playlist,
        searchQuery,
        filteredTracks,
        artworkPeekState,
        activeTrackId,
        playbackStatus,
      ];
}

/// Error encountered while fetching or mutating playlist data.
final class PrivatePlaylistDetailErrorState extends PrivatePlaylistDetailState {
  final String message;

  const PrivatePlaylistDetailErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Playlist was deleted from vault storage; triggers route exit.
final class PrivatePlaylistDetailDeletedState extends PrivatePlaylistDetailState {
  const PrivatePlaylistDetailDeletedState();
}

/// Dedicated presentation screen for inspecting and managing a private playlist.
///
/// Features:
/// 1. Parameterized constructor with `final String playlistId`.
/// 2. 140x140 artwork container with frosted peek / unblur toggle.
/// 3. In-playlist instant search & filter bar.
/// 4. Reorderable track list via [ReorderableListView.builder] with deterministic [ValueKey].
/// 5. Swipe-to-remove [Dismissible] row actions with confirmation dialog.
/// 6. Playback controls ("Play All" & "Shuffle") via [VaultAudioPlaybackService].
/// 7. Wrapped with [ReauthBlurOverlay] to preserve scroll and query during pending reauth.
/// 8. Strict design system: 8px geometric radius, 1px border, Poppins font, zero purple gradients.
class PrivatePlaylistDetailScreen extends StatelessWidget {
  /// The unique identifier of the private playlist to display.
  final String playlistId;

  /// Optional injected storage repository for DI and test isolation.
  final IVaultStorageRepository? storageRepository;

  /// Optional injected audio playback service for DI and test isolation.
  final VaultAudioPlaybackService? audioPlaybackService;

  /// Optional injected playback privacy proxy for DI and test isolation.
  final PlaybackPrivacyProxy? playbackPrivacyProxy;

  /// Optional injected session bloc for DI and test isolation.
  final VaultSessionBloc? sessionBloc;

  /// Optional injected screen privacy cubit for DI and test isolation.
  final ScreenPrivacyCubit? screenPrivacyCubit;

  const PrivatePlaylistDetailScreen({
    required this.playlistId,
    this.storageRepository,
    this.audioPlaybackService,
    this.playbackPrivacyProxy,
    this.sessionBloc,
    this.screenPrivacyCubit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _PrivatePlaylistDetailScaffold(
      playlistId: playlistId,
      storageRepository: storageRepository,
      audioPlaybackService: audioPlaybackService,
      playbackPrivacyProxy: playbackPrivacyProxy,
      sessionBloc: sessionBloc,
      screenPrivacyCubit: screenPrivacyCubit,
    );
  }
}

class _PrivatePlaylistDetailScaffold extends StatefulWidget {
  final String playlistId;
  final IVaultStorageRepository? storageRepository;
  final VaultAudioPlaybackService? audioPlaybackService;
  final PlaybackPrivacyProxy? playbackPrivacyProxy;
  final VaultSessionBloc? sessionBloc;
  final ScreenPrivacyCubit? screenPrivacyCubit;

  const _PrivatePlaylistDetailScaffold({
    required this.playlistId,
    this.storageRepository,
    this.audioPlaybackService,
    this.playbackPrivacyProxy,
    this.sessionBloc,
    this.screenPrivacyCubit,
  });

  @override
  State<_PrivatePlaylistDetailScaffold> createState() =>
      _PrivatePlaylistDetailScaffoldState();
}

class _PrivatePlaylistDetailScaffoldState
    extends State<_PrivatePlaylistDetailScaffold> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final ScrollController _scrollController;

  PrivatePlaylistDetailState _state = const PrivatePlaylistDetailLoadingState();

  IVaultStorageRepository? _resolvedRepository;
  VaultAudioPlaybackService? _resolvedPlaybackService;
  ScreenPrivacyCubit? _screenPrivacyCubit;
  bool _hasRequestedInitialLoad = false;
  bool _isLoadingPlaylist = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _scrollController = ScrollController();
    _searchController.addListener(_onSearchQueryChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveDependencies();
    if (!_hasRequestedInitialLoad) {
      _hasRequestedInitialLoad = true;
      final cachedPlaylist =
          _resolvedRepository?.getCachedPlaylistSync(widget.playlistId);
      if (cachedPlaylist != null) {
        _state = PrivatePlaylistDetailLoadedState(
          playlist: cachedPlaylist,
          searchQuery: _searchController.text,
          filteredTracks:
              _filterTracks(cachedPlaylist.trackRefs, _searchController.text),
          artworkPeekState: ArtworkPeekStateEnum.frostedPeek,
          playbackStatus: PlaylistPlaybackStatusEnum.stopped,
        );
      } else {
        _loadPlaylist();
      }
    }
  }

  void _resolveDependencies() {
    _resolvedRepository ??= widget.storageRepository ??
        _safeResolve<IVaultStorageRepository>(context);
    _resolvedPlaybackService ??= widget.audioPlaybackService ??
        _safeResolve<VaultAudioPlaybackService>(context);

    if (_screenPrivacyCubit == null) {
      final privacyCubit = widget.screenPrivacyCubit ??
          _safeResolve<ScreenPrivacyCubit>(context);
      if (privacyCubit != null) {
        _screenPrivacyCubit = privacyCubit;
        privacyCubit.engageSecureFlag(
          reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
        );
      }
    }
  }

  static T? _safeResolve<T>(BuildContext context) {
    try {
      return context.read<T>();
    } catch (_) {
      return null;
    }
  }

  VaultSessionBloc? _resolveSessionBloc() {
    if (widget.sessionBloc case final bloc?) {
      return bloc;
    }
    try {
      return context.read<VaultSessionBloc>();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _screenPrivacyCubit?.releaseSecureFlag(
      reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
    );
    _searchController.removeListener(_onSearchQueryChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylist() async {
    if (_isLoadingPlaylist) return;
    final repo = _resolvedRepository;
    if (repo == null) {
      setState(() {
        _state = const PrivatePlaylistDetailErrorState(
          message: 'Storage repository unavailable.',
        );
      });
      return;
    }

    _isLoadingPlaylist = true;
    try {
      final result = await repo.getPlaylistById(widget.playlistId);
      if (!mounted) return;

      result.fold(
        onSuccess: (playlist) {
          setState(() {
            _state = PrivatePlaylistDetailLoadedState(
              playlist: playlist,
              searchQuery: _searchController.text,
              filteredTracks:
                  _filterTracks(playlist.trackRefs, _searchController.text),
              artworkPeekState: ArtworkPeekStateEnum.frostedPeek,
              playbackStatus: PlaylistPlaybackStatusEnum.stopped,
            );
          });
        },
        onFailure: (failure) {
          setState(() {
            _state = PrivatePlaylistDetailErrorState(message: failure.message);
          });
        },
      );
    } finally {
      _isLoadingPlaylist = false;
    }
  }

  List<PrivateTrackRef> _filterTracks(
    List<PrivateTrackRef> tracks,
    String query,
  ) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return tracks;
    return tracks.where((track) {
      final titleMatch = track.title.toLowerCase().contains(trimmed);
      final artistMatch = track.artistName.toLowerCase().contains(trimmed);
      final albumMatch = track.albumTitle.toLowerCase().contains(trimmed);
      return titleMatch || artistMatch || albumMatch;
    }).toList();
  }

  void _onSearchQueryChanged() {
    if (_state is PrivatePlaylistDetailLoadedState) {
      final current = _state as PrivatePlaylistDetailLoadedState;
      final query = _searchController.text;
      setState(() {
        _state = current.copyWith(
          searchQuery: query,
          filteredTracks: _filterTracks(current.playlist.trackRefs, query),
        );
      });
    }
  }

  void _toggleArtworkPeek() {
    if (_state is PrivatePlaylistDetailLoadedState) {
      final current = _state as PrivatePlaylistDetailLoadedState;
      setState(() {
        _state = current.copyWith(
          artworkPeekState: current.artworkPeekState.toggle,
        );
      });
    }
  }

  Future<void> _playAll({required bool shuffle}) async {
    if (_state is! PrivatePlaylistDetailLoadedState) return;
    final loaded = _state as PrivatePlaylistDetailLoadedState;
    if (loaded.playlist.trackRefs.isEmpty) return;

    final service = _resolvedPlaybackService;
    if (service == null) return;

    final startIndex = shuffle && loaded.playlist.trackRefs.length > 1
        ? (DateTime.now().millisecondsSinceEpoch % loaded.playlist.trackRefs.length)
        : 0;

    await service.playPrivatePlaylist(
      playlist: loaded.playlist,
      startIndex: startIndex,
    );
  }

  Future<void> _playTrack(PrivateTrackRef track) async {
    if (_state is! PrivatePlaylistDetailLoadedState) return;
    final loaded = _state as PrivatePlaylistDetailLoadedState;

    final index = loaded.playlist.trackRefs.indexWhere((t) => t.id == track.id);
    if (index < 0) return;

    final service = _resolvedPlaybackService;
    if (service == null) return;

    await service.playPrivatePlaylist(
      playlist: loaded.playlist,
      startIndex: index,
    );
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (_state is! PrivatePlaylistDetailLoadedState) return;
    final loaded = _state as PrivatePlaylistDetailLoadedState;

    // Suppress reordering during active search filter
    if (loaded.searchQuery.trim().isNotEmpty) return;

    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }

    final updated = List<PrivateTrackRef>.from(loaded.playlist.trackRefs);
    final movedItem = updated.removeAt(oldIndex);
    updated.insert(targetIndex, movedItem);

    final updatedPlaylist = loaded.playlist.copyWith(trackRefs: updated);
    setState(() {
      _state = loaded.copyWith(
        playlist: updatedPlaylist,
        filteredTracks: updated,
      );
    });

    final repo = _resolvedRepository;
    if (repo != null) {
      final trackIds = updated.map((t) => t.id).toList();
      await repo.reorderTracksInPlaylist(
        playlistId: widget.playlistId,
        trackIdsInOrder: trackIds,
      );
    }
  }

  Future<bool> _confirmRemoveTrack(PrivateTrackRef track) async {
    final vaultTheme = VaultTheme.of(context);
    return showVaultConfirmationSheet(
      context,
      vaultTheme,
      sheetKey: const ValueKey('remove_track_confirmation_sheet'),
      title: 'Remove from Playlist',
      message: 'Remove "${track.title}" from this playlist?',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
  }

  Future<void> _handleRemoveTrack(PrivateTrackRef track) async {
    if (_state is! PrivatePlaylistDetailLoadedState) return;
    final loaded = _state as PrivatePlaylistDetailLoadedState;

    final repo = _resolvedRepository;
    if (repo != null) {
      await repo.removeTrackFromPlaylist(
        playlistId: widget.playlistId,
        trackId: track.id,
      );
    }

    final updatedTrackRefs =
        loaded.playlist.trackRefs.where((t) => t.id != track.id).toList();
    final updatedPlaylist = loaded.playlist.copyWith(trackRefs: updatedTrackRefs);

    setState(() {
      _state = loaded.copyWith(
        playlist: updatedPlaylist,
        filteredTracks: _filterTracks(updatedTrackRefs, loaded.searchQuery),
      );
    });

    if (mounted) {
      showVaultSettingsSnackBar(
        context,
        VaultTheme.of(context),
        message: 'Removed "${track.title}" from playlist',
        clearExisting: true,
      );
    }
  }

  Future<void> _confirmDeletePlaylist() async {
    if (_state is! PrivatePlaylistDetailLoadedState) return;
    final loaded = _state as PrivatePlaylistDetailLoadedState;
    final vaultTheme = VaultTheme.of(context);

    final confirmed = await confirmVaultPlaylistDeletion(
      context,
      vaultTheme,
      playlistName: loaded.playlist.name,
    );

    if (confirmed && mounted) {
      final repo = _resolvedRepository;
      if (repo != null) {
        await repo.deletePlaylist(widget.playlistId);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleStepUpReauth() {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => const VaultAuthScreen(
          mode: VaultAuthScreenMode.stepUp,
          titleOverride: "Confirm It's You",
        ),
      ),
    );
  }

  Future<void> _openAddLocalSongsPicker(PrivatePlaylist playlist) async {
    final result = await VaultLocalSongPickerSheet.show(
      context,
      playlist: playlist,
      storageRepository: _resolvedRepository,
    );
    if (result == true && mounted) {
      _loadPlaylist();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultTheme = VaultTheme.of(context);
    final sessionBloc = _resolveSessionBloc();

    Widget content = ReauthBlurOverlay(
      onReauthRequested: _handleStepUpReauth,
      child: Scaffold(
        backgroundColor: vaultTheme.scaffold,
        appBar: _buildAppBar(vaultTheme),
        body: _buildBody(vaultTheme),
      ),
    );

    if (sessionBloc != null) {
      content = BlocListener<VaultSessionBloc, VaultSessionState>(
        bloc: sessionBloc,
        listenWhen: (previous, current) => current is! VaultActiveSessionState,
        listener: (context, sessionState) {
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        child: content,
      );
    }

    return content;
  }

  PreferredSizeWidget _buildAppBar(VaultThemeData vaultTheme) {
    final title = switch (_state) {
      PrivatePlaylistDetailLoadedState(:final playlist) => playlist.name,
      PrivatePlaylistDetailLoadingState() => 'Loading...',
      PrivatePlaylistDetailErrorState() => 'Error',
      PrivatePlaylistDetailDeletedState() => 'Playlist',
    };

    return buildVaultSettingsAppBar(
      vaultTheme: vaultTheme,
      title: title,
      onBackPressed: () => Navigator.of(context).pop(),
      actions: [
        if (_state case PrivatePlaylistDetailLoadedState loaded)
          IconButton(
            key: const ValueKey('playlist_detail_add_songs_button'),
            tooltip: 'Add Local Songs',
            icon: Icon(
              Icons.add_rounded,
              size: 22.0,
              color: vaultTheme.textHighSalience,
            ),
            onPressed: () => _openAddLocalSongsPicker(loaded.playlist),
          ),
        IconButton(
          tooltip: 'Quick Lock',
          icon: Icon(
            Icons.lock_outline_rounded,
            size: 21.0,
            color: vaultTheme.textHighSalience,
          ),
          onPressed: () {
            if (_resolveSessionBloc() case final bloc?) {
              bloc.add(
                const VaultQuickLockRequested(reason: 'User manual quick-lock'),
              );
            }
          },
        ),
        const SizedBox(width: 4.0),
      ],
    );
  }

  Widget _buildBody(VaultThemeData vaultTheme) {
    return switch (_state) {
      PrivatePlaylistDetailLoadingState() => Center(
          child: CircularProgressIndicator(color: vaultTheme.accent),
        ),
      PrivatePlaylistDetailErrorState(:final message) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, color: vaultTheme.danger, size: 48),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    color: vaultTheme.textHighSalience,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _loadPlaylist,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: vaultTheme.accent,
                    side: BorderSide(color: vaultTheme.border),
                    shape: VaultTheme.shape8,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      PrivatePlaylistDetailDeletedState() => const SizedBox.shrink(),
      final PrivatePlaylistDetailLoadedState loadedState => _buildLoadedContent(
          loadedState,
          vaultTheme,
        ),
    };
  }

  Widget _buildLoadedContent(
    PrivatePlaylistDetailLoadedState state,
    VaultThemeData vaultTheme,
  ) {
    return ReorderableListView.builder(
      scrollController: _scrollController,
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.only(bottom: 80.0),
      itemExtent: 62.0,
      header: _buildHeader(state, vaultTheme),
      itemCount: state.filteredTracks.length,
      // ignore: deprecated_member_use
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final track = state.filteredTracks[index];
        return _buildTrackRow(track, index, state, vaultTheme);
      },
    );
  }

  Widget _buildHeader(
    PrivatePlaylistDetailLoadedState state,
    VaultThemeData vaultTheme,
  ) {
    final playlist = state.playlist;
    final isUnblurred =
        state.artworkPeekState == ArtworkPeekStateEnum.unblurredPeek;
    final trackLabel = playlist.trackCount == 1 ? 'track' : 'tracks';
    final dangerInk = vaultDangerInk(vaultTheme);

    return Column(
      key: const ValueKey('playlist_detail_header'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Editorial Hero Card (220px+ hero block with 148x148 cover & split typography)
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 10.0),
          child: Container(
            constraints: const BoxConstraints(minHeight: 224.0),
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: vaultTheme.surface,
              borderRadius: VaultTheme.borderRadius8,
              border: Border.all(
                color: vaultTheme.borderSubtle,
                width: VaultTheme.borderWidth,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      key: const ValueKey('playlist_detail_artwork_peek'),
                      onTap: _toggleArtworkPeek,
                      child: Container(
                        width: 144.0,
                        height: 144.0,
                        decoration: BoxDecoration(
                          color: vaultTheme.surfaceSubtle,
                          borderRadius: VaultTheme.borderRadius8,
                          border: Border.all(
                            color: vaultTheme.border,
                            width: VaultTheme.borderWidth,
                          ),
                        ),
                        child: RepaintBoundary(
                          child: ClipRRect(
                            borderRadius: VaultTheme.borderRadius8,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ImageFiltered(
                                  enabled:
                                      !isUnblurred && vaultTheme.blurSigma > 0.0,
                                  imageFilter: ImageFilter.blur(
                                    sigmaX: vaultTheme.blurSigma,
                                    sigmaY: vaultTheme.blurSigma,
                                    tileMode: TileMode.clamp,
                                  ),
                                  child: VaultArtworkImage.forPlaylist(
                                    playlist,
                                    size: 144.0,
                                    placeholderIconSize: 52.0,
                                    vaultTheme: vaultTheme,
                                  ),
                                ),
                                if (!isUnblurred)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.28),
                                    alignment: Alignment.center,
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: vaultTheme.surface
                                            .withValues(alpha: 0.72),
                                        borderRadius: VaultTheme.borderRadius8,
                                        border: Border.all(
                                          color: vaultTheme.borderSubtle,
                                          width: VaultTheme.borderWidth,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.visibility_off_outlined,
                                        size: 22.0,
                                        color: vaultTheme.textHighSalience,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            playlist.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: VaultTheme.fontFamily,
                              fontSize: 20.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1.2,
                              color: vaultTheme.textHighSalience,
                            ),
                          ),
                          if (playlist.description.trim().isNotEmpty) ...[
                            const SizedBox(height: 6.0),
                            Text(
                              playlist.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: VaultTheme.fontFamily,
                                fontSize: 13.0,
                                fontWeight: FontWeight.w400,
                                color: vaultTheme.textMediumSalience,
                                height: 1.35,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8.0),
                          Text(
                            '${playlist.trackCount} $trackLabel \u2022 ${_formatDuration(playlist.totalDurationMs)}',
                            style: TextStyle(
                              fontFamily: VaultTheme.fontFamily,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: vaultTheme.textLowSalience,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14.0),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44.0,
                        child: ElevatedButton.icon(
                          key: const ValueKey('playlist_detail_play_all_button'),
                          onPressed: () => _playAll(shuffle: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: vaultTheme.accent,
                            foregroundColor: vaultTheme.scaffold,
                            elevation: 0.0,
                            shape: VaultTheme.shape8,
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20.0),
                          label: const Text(
                            'Play All',
                            style: TextStyle(
                              fontFamily: VaultTheme.fontFamily,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: SizedBox(
                        height: 44.0,
                        child: OutlinedButton.icon(
                          key: const ValueKey('playlist_detail_shuffle_button'),
                          onPressed: () => _playAll(shuffle: true),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: vaultTheme.surfaceSubtle,
                            foregroundColor: vaultTheme.textHighSalience,
                            side: BorderSide(
                              color: vaultTheme.border,
                              width: VaultTheme.borderWidth,
                            ),
                            shape: VaultTheme.shape8,
                          ),
                          icon: const Icon(Icons.shuffle_rounded, size: 18.0),
                          label: const Text(
                            'Shuffle',
                            style: TextStyle(
                              fontFamily: VaultTheme.fontFamily,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Tracks Section Bar & Destructive Playlist Action
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 2.0, 12.0, 0.0),
          child: Row(
            children: [
              Expanded(
                child: VaultSettingsSectionHeader(
                  title: 'Tracks',
                  vaultTheme: vaultTheme,
                  padding: EdgeInsets.zero,
                ),
              ),
              TextButton.icon(
                onPressed: _confirmDeletePlaylist,
                style: TextButton.styleFrom(
                  foregroundColor: dangerInk,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ),
                ),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 16.0,
                  color: dangerInk,
                ),
                label: Text(
                  'Delete Playlist',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: dangerInk,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Instant Track Search Field
        VaultInlineSearchField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          vaultTheme: vaultTheme,
          hintText: 'Search tracks...',
          inputKey: const ValueKey('playlist_detail_search_input'),
          padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 10.0),
        ),

        // Empty Tracklist Placeholder
        if (playlist.trackRefs.isEmpty) ...[
          const SizedBox(height: 28.0),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: BoxDecoration(
                      color: vaultTheme.surfaceSubtle,
                      borderRadius: VaultTheme.borderRadius8,
                      border: Border.all(
                        color: vaultTheme.borderSubtle,
                        width: VaultTheme.borderWidth,
                      ),
                    ),
                    child: Icon(
                      Icons.music_note_outlined,
                      size: 24.0,
                      color: vaultTheme.textLowSalience,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'No Tracks Yet',
                    style: TextStyle(
                      fontFamily: VaultTheme.fontFamily,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: vaultTheme.textHighSalience,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Add songs from your device to build this playlist.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: VaultTheme.fontFamily,
                      fontSize: 13.0,
                      color: vaultTheme.textMediumSalience,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    height: 46.0,
                    child: OutlinedButton.icon(
                      key: const ValueKey(
                        'playlist_detail_empty_add_songs_button',
                      ),
                      onPressed: () => _openAddLocalSongsPicker(playlist),
                      icon: Icon(
                        Icons.add_rounded,
                        color: vaultTheme.accent,
                        size: 18.0,
                      ),
                      label: Text(
                        'Add Songs',
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 14.0,
                          color: vaultTheme.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: vaultTheme.border,
                          width: VaultTheme.borderWidth,
                        ),
                        shape: VaultTheme.shape8,
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrackRow(
    PrivateTrackRef track,
    int index,
    PrivatePlaylistDetailLoadedState state,
    VaultThemeData vaultTheme,
  ) {
    final isActiveTrack = track.id == state.activeTrackId;

    return Dismissible(
      key: ValueKey<String>('dismiss_${track.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmRemoveTrack(track),
      onDismissed: (_) => _handleRemoveTrack(track),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          color: vaultTheme.danger,
          borderRadius: VaultTheme.borderRadius8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              'Remove',
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.0,
              ),
            ),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey<String>('vault_track_${track.id}'),
          onTap: () => _playTrack(track),
          child: Container(
            height: 62.0,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isActiveTrack
                  ? vaultTheme.surfaceSubtle.withValues(alpha: 0.65)
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: vaultTheme.borderSubtle,
                  width: VaultTheme.borderWidth,
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28.0,
                  child: isActiveTrack && state.playbackStatus.isPlaying
                      ? Icon(
                          Icons.volume_up_rounded,
                          size: 18.0,
                          color: vaultTheme.accent,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontFamily: VaultTheme.fontFamily,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: isActiveTrack
                                ? vaultTheme.accent
                                : vaultTheme.textLowSalience,
                          ),
                        ),
                ),
                const SizedBox(width: 8.0),
                Container(
                  width: 40.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: vaultTheme.surfaceSubtle,
                    borderRadius: VaultTheme.borderRadius8,
                    border: Border.all(
                      color: vaultTheme.borderSubtle,
                      width: VaultTheme.borderWidth,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: VaultTheme.borderRadius8,
                    child: VaultArtworkImage.forTrack(
                      track,
                      size: 40.0,
                      placeholderIconSize: 18.0,
                      vaultTheme: vaultTheme,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 14.0,
                          fontWeight:
                              isActiveTrack ? FontWeight.w700 : FontWeight.w500,
                          color: isActiveTrack
                              ? vaultTheme.accent
                              : vaultTheme.textHighSalience,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        track.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w400,
                          color: vaultTheme.textMediumSalience,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: vaultTheme.surfaceSubtle,
                    borderRadius: VaultTheme.borderRadius8,
                    border: Border.all(
                      color: vaultTheme.borderSubtle,
                      width: VaultTheme.borderWidth,
                    ),
                  ),
                  child: Text(
                    switch (track.sourceType) {
                      TrackSourceTypeEnum.localSandbox => 'Local',
                      TrackSourceTypeEnum.localReference => 'Device',
                      TrackSourceTypeEnum.spotify => 'Spotify',
                    },
                    style: TextStyle(
                      fontFamily: VaultTheme.fontFamily,
                      fontSize: 10.0,
                      fontWeight: FontWeight.w500,
                      color: vaultTheme.textLowSalience,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  _formatTrackDuration(track.durationMs),
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w400,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: vaultTheme.textMediumSalience,
                  ),
                ),

                // Reorder Drag Handle (hidden when search is active)
                if (state.searchQuery.trim().isEmpty) ...[
                  const SizedBox(width: 8.0),
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_handle_rounded,
                      size: 20.0,
                      color: vaultTheme.textMediumSalience,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDuration(int totalMs) {
    if (totalMs <= 0) return '0 min';
    final totalSeconds = totalMs ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours hr $minutes min';
    }
    if (minutes > 0) {
      return '$minutes min';
    }
    return '$seconds sec';
  }

  static String _formatTrackDuration(int durationMs) {
    if (durationMs <= 0) return '0:00';
    final totalSeconds = durationMs ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final secondsPadded = seconds.toString().padLeft(2, '0');
    return '$minutes:$secondsPadded';
  }
}
