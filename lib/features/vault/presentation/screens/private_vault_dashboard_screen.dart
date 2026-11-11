import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/vault/application/playlists/vault_playlists_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_auth_screen.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';
import 'package:musify_mu/features/vault/presentation/widgets/reauth_blur_overlay.dart';

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
      create: (_) => VaultPlaylistsCubit(storageRepository: repository)..loadPlaylists(),
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
    required this.storageRepositoryOverride,
    required this.sessionBlocOverride,
    required this.screenPrivacyCubitOverride,
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
    final submission = await showDialog<({String name, String description})>(
      context: context,
      builder: (dialogContext) => _CreatePlaylistDialog(vaultTheme: vaultTheme),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failure.message,
            style: const TextStyle(
              fontFamily: VaultTheme.fontFamily,
            ),
          ),
          backgroundColor: vaultTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: VaultTheme.shape8,
        ),
      );
    }
  }

  Future<bool> _confirmDeletePlaylist(
    BuildContext context,
    PrivatePlaylist playlist,
  ) async {
    final vaultTheme = VaultTheme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: vaultTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: VaultTheme.borderRadius8,
            side: BorderSide(
              color: vaultTheme.border,
              width: VaultTheme.borderWidth,
            ),
          ),
          title: Text(
            'Delete Playlist',
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              color: vaultTheme.textHighSalience,
            ),
          ),
          content: Text(
            'Delete "${playlist.name}" permanently from private vault?',
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              fontSize: 14.0,
              color: vaultTheme.textMediumSalience,
              height: 1.4,
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: vaultTheme.danger,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: VaultTheme.borderRadius8,
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
    return result == true;
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
        appBar: AppBar(
          backgroundColor: vaultTheme.scaffold,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: vaultTheme.textHighSalience,
            ),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Private Vault',
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.15,
              color: vaultTheme.textHighSalience,
            ),
          ),
          actions: [
            IconButton(
              key: const ValueKey('vault_dashboard_quick_lock_button'),
              icon: Icon(
                Icons.lock_outline,
                size: 22.0,
                color: vaultTheme.textHighSalience,
              ),
              tooltip: 'Quick Lock',
              onPressed: _handleQuickLock,
            ),
            IconButton(
              key: const ValueKey('vault_dashboard_settings_button'),
              icon: Icon(
                Icons.settings_outlined,
                size: 22.0,
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
          elevation: 3.0,
          shape: RoundedRectangleBorder(
            borderRadius: VaultTheme.borderRadius8,
            side: BorderSide(
              color: vaultTheme.border,
              width: VaultTheme.borderWidth,
            ),
          ),
          icon: const Icon(Icons.add, size: 20.0),
          label: const Text(
            'New Playlist',
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.15,
            ),
          ),
        ),
        body: Column(
          children: [
            // Quick Inline Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                height: 44.0,
                decoration: BoxDecoration(
                  color: vaultTheme.surfaceSubtle,
                  borderRadius: VaultTheme.borderRadius8,
                  border: Border.all(
                    color: vaultTheme.border,
                    width: VaultTheme.borderWidth,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 20.0,
                      color: vaultTheme.textMediumSalience,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('vault_dashboard_search_input'),
                        controller: _searchController,
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 14.0,
                          color: vaultTheme.textHighSalience,
                        ),
                        cursorColor: vaultTheme.accent,
                        decoration: InputDecoration(
                          hintText: 'Search private playlists...',
                          hintStyle: TextStyle(
                            fontFamily: VaultTheme.fontFamily,
                            fontSize: 14.0,
                            color: vaultTheme.textLowSalience,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                        },
                        child: Icon(
                          Icons.close,
                          size: 18.0,
                          color: vaultTheme.textMediumSalience,
                        ),
                      ),
                  ],
                ),
              ),
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
                              Icon(
                                Icons.error_outline,
                                size: 36.0,
                                color: vaultTheme.danger,
                              ),
                              const SizedBox(height: 12.0),
                              Text(
                                'Failed to load private playlists',
                                style: TextStyle(
                                  fontFamily: VaultTheme.fontFamily,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w600,
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
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: VaultTheme.borderRadius8,
                                  ),
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
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 88.0),
                          itemCount: filteredPlaylists.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8.0),
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
                                padding: const EdgeInsets.only(right: 20.0),
                                decoration: BoxDecoration(
                                  color: vaultTheme.danger,
                                  borderRadius: VaultTheme.borderRadius8,
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 22.0,
                                ),
                              ),
                              child: _PrivatePlaylistTile(
                                key: ValueKey('vault_playlist_tile_${playlist.id}'),
                                playlist: playlist,
                                vaultTheme: vaultTheme,
                                formattedDuration:
                                    _formatDuration(playlist.totalDurationMs),
                                onTap: () => _handlePlaylistTap(playlist),
                              ),
                            );
                          },
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
                  color: vaultTheme.border,
                  width: VaultTheme.borderWidth,
                ),
              ),
              child: Icon(
                Icons.lock_outline,
                size: 28.0,
                color: vaultTheme.textMediumSalience,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'No Private Playlists',
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                fontSize: 17.0,
                fontWeight: FontWeight.w600,
                color: vaultTheme.textHighSalience,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Playlists added to the vault are isolated and encrypted in local storage.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                fontSize: 13.0,
                fontWeight: FontWeight.w400,
                color: vaultTheme.textMediumSalience,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20.0),
            OutlinedButton.icon(
              key: const ValueKey('vault_dashboard_create_button'),
              style: OutlinedButton.styleFrom(
                foregroundColor: vaultTheme.accent,
                side: BorderSide(
                  color: vaultTheme.border,
                  width: VaultTheme.borderWidth,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: VaultTheme.borderRadius8,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
              ),
              onPressed: () => _showCreatePlaylistDialog(context),
              icon: const Icon(Icons.add, size: 18.0),
              label: const Text(
                'Create Playlist',
                style: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  fontWeight: FontWeight.w600,
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
            Icon(
              Icons.search_off_outlined,
              size: 36.0,
              color: vaultTheme.textLowSalience,
            ),
            const SizedBox(height: 12.0),
            Text(
              'No matching playlists',
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                fontSize: 15.0,
                fontWeight: FontWeight.w600,
                color: vaultTheme.textHighSalience,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              'No playlists match your search for "$query".',
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

/// Dense tile rendering an individual [PrivatePlaylist] record.
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
    final trackCountCopy = playlist.trackCount == 1 ? '1 track' : '${playlist.trackCount} tracks';

    return Material(
      color: vaultTheme.surface,
      borderRadius: VaultTheme.borderRadius8,
      child: InkWell(
        onTap: onTap,
        borderRadius: VaultTheme.borderRadius8,
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            borderRadius: VaultTheme.borderRadius8,
            border: Border.all(
              color: vaultTheme.border,
              width: VaultTheme.borderWidth,
            ),
          ),
          child: Row(
            children: [
              // 48px square thumbnail with frosted artwork peek
              _FrostedArtworkPeekThumbnail(
                coverUri: playlist.coverUri,
                vaultTheme: vaultTheme,
              ),
              const SizedBox(width: 12.0),

              // Title and metadata column
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
                        color: vaultTheme.textHighSalience,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 11.0,
                          color: vaultTheme.textMediumSalience,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          '$trackCountCopy \u2022 $formattedDuration',
                          style: TextStyle(
                            fontFamily: VaultTheme.fontFamily,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w400,
                            color: vaultTheme.textMediumSalience,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Trailing chevron indicator
              Icon(
                Icons.chevron_right,
                size: 18.0,
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
  final VaultThemeData vaultTheme;

  const _FrostedArtworkPeekThumbnail({
    required this.coverUri,
    required this.vaultTheme,
  });

  @override
  Widget build(BuildContext context) {
    if (coverUri case final uri? when uri.trim().isNotEmpty) {
      final ImageProvider imageProvider;
      if (uri.startsWith('http://') || uri.startsWith('https://')) {
        imageProvider = ResizeImage(
          NetworkImage(uri),
          width: 96,
          height: 96,
        );
      } else {
        imageProvider = ResizeImage(
          FileImage(File(uri)),
          width: 96,
          height: 96,
        );
      }

      return SizedBox(
        width: 48.0,
        height: 48.0,
        child: ClipRRect(
          borderRadius: VaultTheme.borderRadius8,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: imageProvider,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(),
              ),
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                  child: Container(
                    color: vaultTheme.overlayTint.withValues(alpha: 0.35),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.lock_outline,
                      size: 15.0,
                      color: vaultTheme.accent,
                    ),
                  ),
                ),
              ),
            ],
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

class _CreatePlaylistDialog extends StatefulWidget {
  final VaultThemeData vaultTheme;

  const _CreatePlaylistDialog({required this.vaultTheme});

  @override
  State<_CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<_CreatePlaylistDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vaultTheme = widget.vaultTheme;
    return AlertDialog(
      backgroundColor: vaultTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: VaultTheme.borderRadius8,
        side: BorderSide(
          color: vaultTheme.border,
          width: VaultTheme.borderWidth,
        ),
      ),
      title: Text(
        'New Private Playlist',
        style: TextStyle(
          fontFamily: VaultTheme.fontFamily,
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: vaultTheme.textHighSalience,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                fontSize: 14.0,
                color: vaultTheme.textHighSalience,
              ),
              decoration: InputDecoration(
                labelText: 'Playlist Name',
                labelStyle: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  color: vaultTheme.textMediumSalience,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: VaultTheme.borderRadius8,
                  borderSide: BorderSide(
                    color: vaultTheme.border,
                    width: VaultTheme.borderWidth,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: VaultTheme.borderRadius8,
                  borderSide: BorderSide(
                    color: vaultTheme.accent,
                    width: VaultTheme.borderWidth,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Playlist name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12.0),
            TextFormField(
              controller: _descriptionController,
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                fontSize: 14.0,
                color: vaultTheme.textHighSalience,
              ),
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  color: vaultTheme.textMediumSalience,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: VaultTheme.borderRadius8,
                  borderSide: BorderSide(
                    color: vaultTheme.border,
                    width: VaultTheme.borderWidth,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: VaultTheme.borderRadius8,
                  borderSide: BorderSide(
                    color: vaultTheme.accent,
                    width: VaultTheme.borderWidth,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              color: vaultTheme.textMediumSalience,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: vaultTheme.accent,
            foregroundColor: vaultTheme.scaffold,
            shape: const RoundedRectangleBorder(
              borderRadius: VaultTheme.borderRadius8,
            ),
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              final name = _nameController.text.trim();
              final description = _descriptionController.text.trim();
              Navigator.of(context).pop((name: name, description: description));
            }
          },
          child: Text(
            'Create',
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              fontWeight: FontWeight.w600,
              color: vaultTheme.scaffold,
            ),
          ),
        ),
      ],
    );
  }
}
