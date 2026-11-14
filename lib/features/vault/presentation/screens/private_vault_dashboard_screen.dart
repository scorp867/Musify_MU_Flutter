import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/vault/application/playlists/vault_playlists_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_auth_screen.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';
import 'package:musify_mu/features/vault/presentation/widgets/reauth_blur_overlay.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_artwork_image.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_portability_sheet.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_settings_components.dart';

/// Primary operational screen displaying encrypted private playlists.
///
/// Invariants:
/// - Full Scaffold adhering strictly to [VaultThemeData] (warmEspresso / forestNoir).
/// - Wrapped in [ReauthBlurOverlay] with exact sigma 12.0 blur over active list.
/// - Engages native Android FLAG_SECURE via [ScreenPrivacyCubit].
/// - Pure vertical list with 48px square thumbnails featuring frosted artwork peek.
/// - Inline instant search filter bar for real-time playlist name filtering.
/// - Top app bar quick-lock action for instant RAM zeroing.
/// - 8.0px geometric corner radius; strictly zero pill buttons, zero emojis, zero em dashes.
class PrivateVaultDashboardScreen extends StatelessWidget {
  /// Optional scoped [VaultPlaylistsCubit] instance for testing.
  final VaultPlaylistsCubit? playlistsCubit;

  /// Optional scoped [IVaultStorageRepository] instance.
  final IVaultStorageRepository? storageRepository;

  /// Optional scoped [VaultSessionBloc] instance.
  final VaultSessionBloc? sessionBloc;

  /// Optional scoped [ScreenPrivacyCubit] instance.
  final ScreenPrivacyCubit? screenPrivacyCubit;

  const PrivateVaultDashboardScreen({
    this.playlistsCubit,
    this.storageRepository,
    this.sessionBloc,
    this.screenPrivacyCubit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (playlistsCubit case final cubit?) {
      return BlocProvider<VaultPlaylistsCubit>.value(
        value: cubit,
        child: _PrivateVaultDashboardScreenView(
          storageRepositoryOverride: storageRepository,
          sessionBlocOverride: sessionBloc,
          screenPrivacyCubitOverride: screenPrivacyCubit,
        ),
      );
    }

    final repository = storageRepository ?? _safeResolve<IVaultStorageRepository>(context);
    if (repository == null) {
      return _PrivateVaultDashboardScreenView(
        storageRepositoryOverride: storageRepository,
        sessionBlocOverride: sessionBloc,
        screenPrivacyCubitOverride: screenPrivacyCubit,
      );
    }

    return BlocProvider<VaultPlaylistsCubit>(
      create: (ctx) => VaultPlaylistsCubit(storageRepository: repository)..loadPlaylists(),
      child: _PrivateVaultDashboardScreenView(
        storageRepositoryOverride: storageRepository,
        sessionBlocOverride: sessionBloc,
        screenPrivacyCubitOverride: screenPrivacyCubit,
      ),
    );
  }

  static T? _safeResolve<T>(BuildContext context) {
    try {
      return context.read<T>();
    } catch (_) {
      return null;
    }
  }
}

class _PrivateVaultDashboardScreenView extends StatefulWidget {
  final IVaultStorageRepository? storageRepositoryOverride;
  final VaultSessionBloc? sessionBlocOverride;
  final ScreenPrivacyCubit? screenPrivacyCubitOverride;

  const _PrivateVaultDashboardScreenView({
    this.storageRepositoryOverride,
    this.sessionBlocOverride,
    this.screenPrivacyCubitOverride,
  });

  @override
  State<_PrivateVaultDashboardScreenView> createState() =>
      _PrivateVaultDashboardScreenViewState();
}

class _PrivateVaultDashboardScreenViewState
    extends State<_PrivateVaultDashboardScreenView> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    _searchController.addListener(_onSearchChanged);
    _engageScreenPrivacy();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() {});
    context.read<VaultPlaylistsCubit>().filterPlaylists(_searchController.text);
  }

  void _engageScreenPrivacy() {
    final cubit = _resolveScreenPrivacyCubit();
    cubit?.engageSecureFlag(reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive);
  }

  void _releaseScreenPrivacy() {
    final cubit = _resolveScreenPrivacyCubit();
    cubit?.releaseSecureFlag(reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive);
  }

  ScreenPrivacyCubit? _resolveScreenPrivacyCubit() {
    if (widget.screenPrivacyCubitOverride case final cubit?) {
      return cubit;
    }
    try {
      return context.read<ScreenPrivacyCubit>();
    } catch (_) {
      return null;
    }
  }

  VaultSessionBloc? _resolveSessionBloc() {
    if (widget.sessionBlocOverride case final bloc?) {
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
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _releaseScreenPrivacy();
    super.dispose();
  }

  void _handleQuickLock() {
    HapticFeedback.mediumImpact();
    final bloc = _resolveSessionBloc();
    bloc?.add(const VaultQuickLockRequested(reason: 'Dashboard manual quick-lock'));
  }

  void _handlePortabilityPressed() {
    HapticFeedback.lightImpact();
    VaultPortabilitySheet.show(context);
  }

  void _handleSettingsPressed() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushNamed('/vault/settings');
  }

  void _handlePlaylistTap(PrivatePlaylist playlist) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushNamed('/vault/playlist/${playlist.id}');
  }

  void _handleReauthRequested() {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => const VaultAuthScreen(
          mode: VaultAuthScreenMode.stepUp,
        ),
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final vaultTheme = VaultTheme.of(context);
    final submission = await showVaultCreatePlaylistSheet(
      context,
      vaultTheme,
    );

    if (submission == null) return;
    if (!context.mounted) return;

    final cubit = context.read<VaultPlaylistsCubit>();
    final result = await cubit.createPlaylist(
      name: submission.name,
      description: submission.description,
    );

    if (!context.mounted) return;
    if (result case VaultFailureResult(:final failure)) {
      showVaultSettingsSnackBar(
        context,
        vaultTheme,
        message: failure.message,
        isError: true,
        clearExisting: true,
      );
    }
  }

  Future<bool> _confirmDeletePlaylist(
    BuildContext context,
    PrivatePlaylist playlist,
  ) async {
    final vaultTheme = VaultTheme.of(context);
    return confirmVaultPlaylistDeletion(
      context,
      vaultTheme,
      playlistName: playlist.name,
    );
  }

  String _formatDuration(int durationMs) {
    if (durationMs <= 0) return '0m';
    final totalSeconds = durationMs ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    } else if (minutes > 0) {
      if (seconds > 0) {
        return '${minutes}m ${seconds}s';
      }
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultTheme = VaultTheme.of(context);
    final sessionBloc = _resolveSessionBloc();

    Widget viewContent = ReauthBlurOverlay(
      onReauthRequested: _handleReauthRequested,
      child: Scaffold(
        backgroundColor: vaultTheme.scaffold,
        appBar: buildVaultSettingsAppBar(
          vaultTheme: vaultTheme,
          title: 'Private Vault',
          onBackPressed: () => Navigator.of(context).pop(),
          actions: [
            IconButton(
              key: const ValueKey('vault_dashboard_portability_button'),
              icon: Icon(
                Icons.import_export_rounded,
                size: 21.0,
                color: vaultTheme.textHighSalience,
              ),
              tooltip: 'Import / Export',
              onPressed: _handlePortabilityPressed,
            ),
            IconButton(
              key: const ValueKey('vault_dashboard_quick_lock_button'),
              icon: Icon(
                Icons.lock_outline_rounded,
                size: 21.0,
                color: vaultTheme.textHighSalience,
              ),
              tooltip: 'Quick Lock',
              onPressed: _handleQuickLock,
            ),
            IconButton(
              key: const ValueKey('vault_dashboard_settings_button'),
              icon: Icon(
                Icons.settings_outlined,
                size: 21.0,
                color: vaultTheme.textHighSalience,
              ),
              tooltip: 'Vault Settings',
              onPressed: _handleSettingsPressed,
            ),
            const SizedBox(width: 4.0),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const ValueKey('create_private_playlist_fab'),
          onPressed: () => _showCreatePlaylistDialog(context),
          backgroundColor: vaultTheme.accent,
          foregroundColor: vaultTheme.scaffold,
          elevation: 0.0,
          highlightElevation: 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: VaultTheme.borderRadius8,
            side: BorderSide(
              color: vaultTheme.borderSubtle,
              width: VaultTheme.borderWidth,
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 20.0),
          label: const Text(
            'New Playlist',
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
        body: Column(
          children: [
            VaultInlineSearchField(
              controller: _searchController,
              vaultTheme: vaultTheme,
              hintText: 'Search playlists...',
              inputKey: const ValueKey('vault_dashboard_search_input'),
              padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 8.0),
            ),

            // Dense Playlists Content
            Expanded(
              child: BlocBuilder<VaultPlaylistsCubit, VaultPlaylistsState>(
                builder: (context, state) {
                  switch (state) {
                    case VaultPlaylistsInitialState():
                    case VaultPlaylistsLoadingState():
                      return Center(
                        child: CircularProgressIndicator(
                          color: vaultTheme.accent,
                          strokeWidth: 2.5,
                        ),
                      );

                    case VaultPlaylistsErrorState(:final message):
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 48.0,
                                height: 48.0,
                                decoration: BoxDecoration(
                                  color: vaultTheme.danger.withValues(alpha: 0.12),
                                  borderRadius: VaultTheme.borderRadius8,
                                  border: Border.all(
                                    color: vaultTheme.danger.withValues(alpha: 0.4),
                                    width: VaultTheme.borderWidth,
                                  ),
                                ),
                                child: Icon(
                                  Icons.error_outline_rounded,
                                  size: 24.0,
                                  color: vaultDangerInk(vaultTheme),
                                ),
                              ),
                              const SizedBox(height: 14.0),
                              Text(
                                'Unable to Load Playlists',
                                style: TextStyle(
                                  fontFamily: VaultTheme.fontFamily,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                  color: vaultTheme.textHighSalience,
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                message,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: VaultTheme.fontFamily,
                                  fontSize: 13.0,
                                  color: vaultTheme.textMediumSalience,
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: vaultTheme.textHighSalience,
                                  side: BorderSide(
                                    color: vaultTheme.border,
                                    width: VaultTheme.borderWidth,
                                  ),
                                  shape: VaultTheme.shape8,
                                ),
                                onPressed: () {
                                  context.read<VaultPlaylistsCubit>().loadPlaylists();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );

                    case VaultPlaylistsLoadedState(
                        :final allPlaylists,
                        :final filteredPlaylists,
                        :final searchQuery,
                      ):
                      if (allPlaylists.isEmpty) {
                        return _buildEmptyVaultState(vaultTheme);
                      }

                      if (filteredPlaylists.isEmpty) {
                        return _buildEmptySearchState(vaultTheme, searchQuery);
                      }

                      return RefreshIndicator(
                        color: vaultTheme.accent,
                        backgroundColor: vaultTheme.surface,
                        onRefresh: () =>
                            context.read<VaultPlaylistsCubit>().loadPlaylists(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            VaultSettingsSectionHeader(
                              title: 'Playlists',
                              vaultTheme: vaultTheme,
                              padding: const EdgeInsets.fromLTRB(
                                20.0,
                                8.0,
                                20.0,
                                8.0,
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  16.0,
                                  0.0,
                                  16.0,
                                  88.0,
                                ),
                                itemCount: filteredPlaylists.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8.0),
                                itemBuilder: (context, index) {
                                  final playlist = filteredPlaylists[index];
                                  return Dismissible(
                                    key: ValueKey(playlist.id),
                                    direction: DismissDirection.endToStart,
                                    confirmDismiss: (_) =>
                                        _confirmDeletePlaylist(context, playlist),
                                    onDismissed: (_) {
                                      context
                                          .read<VaultPlaylistsCubit>()
                                          .deletePlaylist(playlist.id);
                                    },
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding:
                                          const EdgeInsets.only(right: 20.0),
                                      decoration: BoxDecoration(
                                        color: vaultTheme.danger,
                                        borderRadius: VaultTheme.borderRadius8,
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.white,
                                        size: 22.0,
                                      ),
                                    ),
                                    child: _PrivatePlaylistTile(
                                      key: ValueKey(
                                        'vault_playlist_tile_${playlist.id}',
                                      ),
                                      playlist: playlist,
                                      vaultTheme: vaultTheme,
                                      formattedDuration: _formatDuration(
                                        playlist.totalDurationMs,
                                      ),
                                      onTap: () => _handlePlaylistTap(playlist),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (sessionBloc != null) {
      viewContent = BlocListener<VaultSessionBloc, VaultSessionState>(
        bloc: sessionBloc,
        listenWhen: (previous, current) => current is! VaultActiveSessionState,
        listener: (context, state) {
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        child: viewContent,
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _releaseScreenPrivacy();
        }
      },
      child: viewContent,
    );
  }

  Widget _buildEmptyVaultState(VaultThemeData vaultTheme) {
    return Center(
      key: const ValueKey('vault_dashboard_empty_view'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.0,
              height: 56.0,
              decoration: BoxDecoration(
                color: vaultTheme.surfaceSubtle,
                borderRadius: VaultTheme.borderRadius8,
                border: Border.all(
                  color: vaultTheme.borderSubtle,
                  width: VaultTheme.borderWidth,
                ),
              ),
              child: Icon(
                Icons.library_music_outlined,
                size: 26.0,
                color: vaultTheme.accent,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'No Playlists Yet',
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                fontSize: 17.0,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: vaultTheme.textHighSalience,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Create a playlist to keep tracks separate from your main library.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: vaultTheme.textMediumSalience,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20.0),
            SizedBox(
              height: 46.0,
              child: OutlinedButton.icon(
                key: const ValueKey('vault_dashboard_create_button'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: vaultTheme.accent,
                  side: BorderSide(
                    color: vaultTheme.border,
                    width: VaultTheme.borderWidth,
                  ),
                  shape: VaultTheme.shape8,
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                ),
                onPressed: () => _showCreatePlaylistDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18.0),
                label: const Text(
                  'Create Playlist',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState(VaultThemeData vaultTheme, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
                Icons.search_off_rounded,
                size: 22.0,
                color: vaultTheme.textLowSalience,
              ),
            ),
            const SizedBox(height: 14.0),
            Text(
              'No Results',
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: vaultTheme.textHighSalience,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              'Nothing matches "$query".',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                fontSize: 13.0,
                color: vaultTheme.textMediumSalience,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dense inset tile rendering an individual [PrivatePlaylist] record.
class _PrivatePlaylistTile extends StatelessWidget {
  final PrivatePlaylist playlist;
  final VaultThemeData vaultTheme;
  final String formattedDuration;
  final VoidCallback onTap;

  const _PrivatePlaylistTile({
    required this.playlist,
    required this.vaultTheme,
    required this.formattedDuration,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final trackCountCopy =
        playlist.trackCount == 1 ? '1 track' : '${playlist.trackCount} tracks';

    return Material(
      color: vaultTheme.surface,
      borderRadius: VaultTheme.borderRadius8,
      child: InkWell(
        onTap: onTap,
        borderRadius: VaultTheme.borderRadius8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 11.0),
          decoration: BoxDecoration(
            borderRadius: VaultTheme.borderRadius8,
            border: Border.all(
              color: vaultTheme.borderSubtle,
              width: VaultTheme.borderWidth,
            ),
          ),
          child: Row(
            children: [
              _FrostedArtworkPeekThumbnail(
                coverUri: playlist.coverUri,
                fallbackTracks: playlist.trackRefs,
                vaultTheme: vaultTheme,
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: VaultTheme.fontFamily,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: vaultTheme.textHighSalience,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      '$trackCountCopy \u2022 $formattedDuration',
                      style: TextStyle(
                        fontFamily: VaultTheme.fontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: vaultTheme.textMediumSalience,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 19.0,
                color: vaultTheme.textLowSalience,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 48px square thumbnail with frosted privacy peek mode.
class _FrostedArtworkPeekThumbnail extends StatelessWidget {
  final String? coverUri;
  final List<PrivateTrackRef> fallbackTracks;
  final VaultThemeData vaultTheme;

  const _FrostedArtworkPeekThumbnail({
    required this.coverUri,
    this.fallbackTracks = const <PrivateTrackRef>[],
    required this.vaultTheme,
  });

  @override
  Widget build(BuildContext context) {
    final hasExplicitCover = switch (coverUri) {
      final uri? when uri.trim().isNotEmpty => true,
      _ => false,
    };
    final hasArtworkCandidate = hasExplicitCover ||
        fallbackTracks.take(4).any((track) {
          final hasArtUri = switch (track.artworkUri) {
            final art? when art.trim().isNotEmpty => true,
            _ => false,
          };
          return hasArtUri || track.sourceType != TrackSourceTypeEnum.spotify;
        });

    if (hasArtworkCandidate) {
      return SizedBox(
        width: 48.0,
        height: 48.0,
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: VaultTheme.borderRadius8,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ImageFiltered(
                  enabled: vaultTheme.blurSigma > 0.0,
                  imageFilter: ImageFilter.blur(
                    sigmaX: vaultTheme.blurSigma,
                    sigmaY: vaultTheme.blurSigma,
                    tileMode: TileMode.clamp,
                  ),
                  child: VaultArtworkImage(
                    imageUrl: coverUri,
                    fallbackTracks: fallbackTracks,
                    width: 48.0,
                    height: 48.0,
                    placeholderIconSize: 20.0,
                    placeholderIcon: Icons.library_music_outlined,
                    vaultTheme: vaultTheme,
                  ),
                ),
                Container(
                  color: vaultTheme.overlayTint.withValues(alpha: 0.35),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.lock_outline,
                    size: 15.0,
                    color: vaultTheme.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildFallbackThumbnail();
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      width: 48.0,
      height: 48.0,
      decoration: BoxDecoration(
        color: vaultTheme.surfaceSubtle,
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: vaultTheme.border,
          width: VaultTheme.borderWidth,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.lock_outline,
        size: 18.0,
        color: vaultTheme.textMediumSalience,
      ),
    );
  }
}
