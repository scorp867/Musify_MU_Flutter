import 'dart:io';
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
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_auth_screen.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';
import 'package:musify_mu/features/vault/presentation/widgets/reauth_blur_overlay.dart';

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
      playlist: playlist ?? this.playlist,
      searchQuery: searchQuery ?? this.searchQuery,
      filteredTracks: filteredTracks ?? this.filteredTracks,
      artworkPeekState: artworkPeekState ?? this.artworkPeekState,
      activeTrackId: clearActiveTrack ? null : (activeTrackId ?? this.activeTrackId),
      playbackStatus: playbackStatus ?? this.playbackStatus,
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
    _loadPlaylist();
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
    final repo = _resolvedRepository;
    if (repo == null) {
      setState(() {
        _state = const PrivatePlaylistDetailErrorState(
          message: 'Storage repository unavailable.',
        );
      });
      return;
    }

    final result = await repo.getPlaylistById(widget.playlistId);
    if (!mounted) return;

    result.fold(
      onSuccess: (playlist) {
        setState(() {
          _state = PrivatePlaylistDetailLoadedState(
            playlist: playlist,
            searchQuery: _searchController.text,
            filteredTracks: _filterTracks(playlist.trackRefs, _searchController.text),
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

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final updated = List<PrivateTrackRef>.from(loaded.playlist.trackRefs);
    final movedItem = updated.removeAt(oldIndex);
    updated.insert(newIndex, movedItem);

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
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: vaultTheme.surface,
        shape: VaultTheme.shape8,
        title: Text(
          'Remove Track',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            color: vaultTheme.textHighSalience,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Remove "${track.title}" from this private playlist?',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            color: vaultTheme.textMediumSalience,
            fontSize: 13.0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                color: vaultTheme.textMediumSalience,
              ),
            ),
          ),
          Material(
            color: vaultTheme.danger,
            borderRadius: VaultTheme.borderRadius8,
            child: InkWell(
              borderRadius: VaultTheme.borderRadius8,
              onTap: () => Navigator.of(dialogContext).pop(true),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Remove',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Removed "${track.title}" from playlist',
            style: const TextStyle(fontFamily: VaultTheme.fontFamily),
          ),
          backgroundColor: VaultTheme.of(context).surfaceSubtle,
          behavior: SnackBarBehavior.floating,
          shape: VaultTheme.shape8,
        ),
      );
    }
  }

  Future<void> _confirmDeletePlaylist() async {
    if (_state is! PrivatePlaylistDetailLoadedState) return;
    final loaded = _state as PrivatePlaylistDetailLoadedState;
    final vaultTheme = VaultTheme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: vaultTheme.surface,
        shape: VaultTheme.shape8,
        title: Text(
          'Delete Private Playlist',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            color: vaultTheme.textHighSalience,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${loaded.playlist.name}"? This action will remove this playlist from your Secure Vault.',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            color: vaultTheme.textMediumSalience,
            fontSize: 13.0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                color: vaultTheme.textMediumSalience,
              ),
            ),
          ),
          Material(
            color: vaultTheme.danger,
            borderRadius: VaultTheme.borderRadius8,
            child: InkWell(
              borderRadius: VaultTheme.borderRadius8,
              onTap: () => Navigator.of(dialogContext).pop(true),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Delete',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
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
          titleOverride: 'Re-authenticate Session',
        ),
      ),
    );
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
        listenWhen: (previous, current) =>
            current is VaultLockedState || current is VaultUninitializedState,
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
    return AppBar(
      backgroundColor: vaultTheme.scaffold,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: vaultTheme.textHighSalience),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        switch (_state) {
          PrivatePlaylistDetailLoadedState(:final playlist) => playlist.name,
          PrivatePlaylistDetailLoadingState() => 'Loading...',
          PrivatePlaylistDetailErrorState() => 'Error',
          PrivatePlaylistDetailDeletedState() => 'Private Playlist',
        },
        style: TextStyle(
          fontFamily: VaultTheme.fontFamily,
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          color: vaultTheme.textHighSalience,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Quick Lock',
          icon: Icon(Icons.lock_outline_rounded, color: vaultTheme.accent),
          onPressed: () {
            if (_resolveSessionBloc() case final bloc?) {
              bloc.add(const VaultQuickLockRequested(reason: 'User manual quick-lock'));
            }
          },
        ),
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
    final isUnblurred = state.artworkPeekState == ArtworkPeekStateEnum.unblurredPeek;

    return Padding(
      key: const ValueKey('playlist_detail_header'),
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 140x140 Artwork with Frosted Peek / Unblur Toggle
          GestureDetector(
            onTap: _toggleArtworkPeek,
            child: Container(
              width: 140.0,
              height: 140.0,
              decoration: BoxDecoration(
                color: vaultTheme.surfaceSubtle,
                borderRadius: VaultTheme.borderRadius8,
                border: Border.all(
                  color: vaultTheme.border,
                  width: VaultTheme.borderWidth,
                ),
              ),
              child: ClipRRect(
                borderRadius: VaultTheme.borderRadius8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Underlying Image or Placeholder
                    if (playlist.coverUri case final uri? when uri.isNotEmpty)
                      Image.file(
                        File(uri),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderArt(vaultTheme),
                      )
                    else
                      _buildPlaceholderArt(vaultTheme),

                    // Frosted Privacy Overlay
                    if (!isUnblurred)
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                        child: Container(
                          color: vaultTheme.overlayTint.withValues(alpha: 0.55),
                          child: Center(
                            child: Icon(
                              Icons.visibility_off_outlined,
                              size: 28.0,
                              color: vaultTheme.textMediumSalience,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Playlist Title
          Text(
            playlist.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              fontSize: 22.0,
              fontWeight: FontWeight.w700,
              color: vaultTheme.textHighSalience,
              letterSpacing: 0.15,
            ),
          ),

          // Playlist Description (if non-empty)
          if (playlist.description.trim().isNotEmpty) ...[
            const SizedBox(height: 6.0),
            Text(
              playlist.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                fontSize: 13.0,
                fontWeight: FontWeight.w400,
                color: vaultTheme.textMediumSalience,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 8.0),

          // Metadata Telemetry Row (Track count \u2022 Total duration)
          Text(
            '${playlist.trackCount} ${playlist.trackCount == 1 ? 'track' : 'tracks'} \u2022 ${_formatDuration(playlist.totalDurationMs)}',
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              color: vaultTheme.textLowSalience,
            ),
          ),
          const SizedBox(height: 16.0),

          // Playback Controls Row: "Play All" and "Shuffle Play"
          Row(
            children: [
              Expanded(
                child: Material(
                  color: vaultTheme.accent,
                  borderRadius: VaultTheme.borderRadius8,
                  child: InkWell(
                    key: const ValueKey('playlist_detail_play_all_button'),
                    onTap: () => _playAll(shuffle: false),
                    borderRadius: VaultTheme.borderRadius8,
                    child: Container(
                      height: 44.0,
                      decoration: BoxDecoration(
                        borderRadius: VaultTheme.borderRadius8,
                        border: Border.all(
                          color: vaultTheme.border,
                          width: VaultTheme.borderWidth,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 20.0,
                            color: vaultTheme.scaffold,
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            'Play All',
                            style: TextStyle(
                              fontFamily: VaultTheme.fontFamily,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: vaultTheme.scaffold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Material(
                  color: vaultTheme.surfaceSubtle,
                  borderRadius: VaultTheme.borderRadius8,
                  child: InkWell(
                    key: const ValueKey('playlist_detail_shuffle_button'),
                    onTap: () => _playAll(shuffle: true),
                    borderRadius: VaultTheme.borderRadius8,
                    child: Container(
                      height: 44.0,
                      decoration: BoxDecoration(
                        borderRadius: VaultTheme.borderRadius8,
                        border: Border.all(
                          color: vaultTheme.border,
                          width: VaultTheme.borderWidth,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shuffle_rounded,
                            size: 18.0,
                            color: vaultTheme.textHighSalience,
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            'Shuffle',
                            style: TextStyle(
                              fontFamily: VaultTheme.fontFamily,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: vaultTheme.textHighSalience,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Secondary Actions Row (Delete)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _confirmDeletePlaylist,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 16.0,
                  color: vaultTheme.danger,
                ),
                label: Text(
                  'Delete Playlist',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                    color: vaultTheme.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // In-Playlist Instant Search & Filter Bar
          Container(
            height: 44.0,
            decoration: BoxDecoration(
              color: vaultTheme.surfaceSubtle,
              borderRadius: VaultTheme.borderRadius8,
              border: Border.all(
                color: vaultTheme.border,
                width: VaultTheme.borderWidth,
              ),
            ),
            child: TextField(
              key: const ValueKey('playlist_detail_search_input'),
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                fontSize: 13.0,
                color: vaultTheme.textHighSalience,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                isDense: true,
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18.0,
                  color: vaultTheme.textMediumSalience,
                ),
                hintText: 'Find in playlist...',
                hintStyle: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  fontSize: 13.0,
                  color: vaultTheme.textLowSalience,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 16.0,
                          color: vaultTheme.textMediumSalience,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderArt(VaultThemeData vaultTheme) {
    return Center(
      child: Icon(
        Icons.album_outlined,
        size: 56.0,
        color: vaultTheme.textLowSalience,
      ),
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
        key: ValueKey<String>('vault_track_${track.id}'),
        color: isActiveTrack ? vaultTheme.surfaceHighlight : Colors.transparent,
        child: InkWell(
          onTap: () => _playTrack(track),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: vaultTheme.borderSubtle,
                  width: VaultTheme.borderWidth,
                ),
              ),
            ),
            child: Row(
              children: [
                // Index or Active Playing Equalizer Indicator
                SizedBox(
                  width: 28.0,
                  child: isActiveTrack &&
                          state.playbackStatus == PlaylistPlaybackStatusEnum.playing
                      ? Icon(
                          Icons.volume_up_rounded,
                          size: 16.0,
                          color: vaultTheme.accent,
                        )
                      : Text(
                          '${index + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: VaultTheme.fontFamily,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w500,
                            color: vaultTheme.textMediumSalience,
                          ),
                        ),
                ),
                const SizedBox(width: 12.0),

                // Title & Artist \u2022 Album
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        '${track.artistName} \u2022 ${track.albumTitle}',
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

                // Source Badge (Local sandbox vs. Spotify stream)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: vaultTheme.surfaceSubtle,
                    borderRadius: VaultTheme.borderRadius8,
                    border: Border.all(
                      color: vaultTheme.border,
                      width: VaultTheme.borderWidth,
                    ),
                  ),
                  child: Text(
                    switch (track.sourceType) {
                      TrackSourceTypeEnum.localSandbox => 'Local',
                      TrackSourceTypeEnum.spotify => 'Spotify',
                    },
                    style: TextStyle(
                      fontFamily: VaultTheme.fontFamily,
                      fontSize: 10.0,
                      fontWeight: FontWeight.w500,
                      color: vaultTheme.textMediumSalience,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),

                // Duration (mm:ss)
                Text(
                  _formatTrackDuration(track.durationMs),
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w400,
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
