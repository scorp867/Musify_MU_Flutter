library;

import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di/injection.dart';
import '../../../core/color/color_extraction_service.dart';
import '../../../core/color/eased_gradient.dart';
import '../../../core/ui/icons/spotify_encore_icons.dart';
import '../../../core/ui/widgets/shell_bottom_spacer.dart';
import '../../../core/navigation/spotify_navigator.dart';
import '../../../core/ubi/data/lifecycle/page_instance_id_holder.dart';
import '../../../core/ubi/domain/logging/ubi_logger.dart';
import '../../../core/ubi/domain/models/page_instance_id.dart';
import '../../../features/player/data/esperanto/context_player_control_client.dart';
import '../../../features/player/data/esperanto/context_player_options_client.dart';
import '../../../features/player/data/esperanto/context_player_state_client.dart';
import '../../player/presentation/widgets/spotify_scroll_physics.dart';
import '../../vault/application/session/vault_session_bloc.dart';
import '../../vault/domain/entities/private_playlist.dart';
import '../../vault/domain/entities/private_track_ref.dart';
import '../../vault/domain/entities/vault_result.dart';
import '../../vault/domain/interfaces/i_vault_storage_repository.dart';
import '../../vault/domain/states/vault_session_state.dart';
import '../application/mobius/playlist_effect_handler.dart';
import '../application/mobius/playlist_mobius_loop.dart';
import '../data/coordinator/playlist_play_coordinator.dart';
import '../domain/models/playlist_entity.dart';
import '../domain/models/playlist_item.dart';
import '../domain/models/playlist_screen_state.dart';
import '../domain/policies/playlist_curation_policy.dart';
import '../domain/repositories/playlist_repository.dart';
import 'components/playlist_action_row.dart';
import 'components/playlist_app_bar.dart';
import 'components/playlist_curation_chips_row.dart';
import 'components/playlist_empty_view.dart';
import 'components/playlist_header_content.dart';
import 'components/playlist_play_fab.dart';
import 'components/playlist_section_header.dart';
import 'components/playlist_sort_sheet.dart';
import 'components/playlist_track_tile.dart';
import 'extensions/track_item_metadata_presentation.dart';

/// 1:1 replica of Spotify's Playlist screen coordinator
/// (`header_layout.xml`, `playlist_all_songs_page.xml`, `b7r.java`, `yz40.java`, `uwt.java`, `PlayButtonBehavior.java`).
///
/// Features:
/// 1. Top Search Bar: Find in playlist positioned at the top of header content
/// 2. Header: Dynamic Matte EasedGradient color extracted from album cover
/// 3. Collapsing Pinned App Bar: with title opacity fading in as header scrolls out,
///    and outward sliding buttons (8dp slide, zero button fade, zero play button in top bar)
/// 4. 56x56 Round Play FAB with 1:1 PlayButtonBehavior docking physics: pins at (topInset + kToolbarHeight - 28dp)
/// 5. Sorting bottom sheet, curation action chips, sticky filter headers, swipe to queue
class PlaylistScreen extends StatefulWidget {
  final String playlistUri;
  final VaultSessionBloc? vaultSessionBlocOverride;
  final IVaultStorageRepository? vaultStorageRepositoryOverride;
  final PlaylistMobiusLoop? loopOverride;

  const PlaylistScreen({
    super.key,
    required this.playlistUri,
    this.vaultSessionBlocOverride,
    this.vaultStorageRepositoryOverride,
    this.loopOverride,
  });

  @override
  State<PlaylistScreen> createState() => PlaylistScreenWidgetState();
}

class PlaylistScreenWidgetState extends State<PlaylistScreen>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final ValueNotifier<double> _scrollOffsetNotifier;
  late final SpotifyStretchController _stretchController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  late final PlaylistMobiusLoop _loop;
  late final PageInstanceId _pageInstanceId;

  final GlobalKey _actionRowKey = GlobalKey();
  double _initialActionRowTop = 0.0;

  static const double _headerHeight = 360.0;
  Color _dominantHeaderColor = const Color(0xFF535353);
  String _lastExtractedCoverUrl = '';
  bool _isSearchActive = false;

  @visibleForTesting
  void showPlaylistMoreMenu(PlaylistLoadedState state) => _showPlaylistMoreMenu(state);

  @visibleForTesting
  void showTrackOptionsMenu(PlaylistItem item) => _showTrackOptionsMenu(item);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollOffsetNotifier = ValueNotifier<double>(0.0);
    _stretchController = SpotifyStretchController(vsync: this);
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    if (widget.loopOverride case final loop?) {
      _loop = loop;
      _pageInstanceId = PageInstanceIdHolder.generateNew();
    } else {
      final repo = getIt<PlaylistRepository>();
      final optionsClient = getIt<ContextPlayerOptionsClient>();
      final controlClient = getIt<ContextPlayerControlClient>();
      final stateClient = getIt<ContextPlayerStateClient>();
      final pageInstanceHolder = getIt<PageInstanceIdHolder>();

      _pageInstanceId = PageInstanceIdHolder.generateNew();
      pageInstanceHolder.update(_pageInstanceId);

      try {
        if (getIt.isRegistered<UbiLogger>()) {
          final ubiLogger = getIt<UbiLogger>();
          ubiLogger.logImpression(
            UbiImpressionElement(
              elementPath: 'playlist_screen',
              uri: widget.playlistUri,
            ),
          );
        }
      } catch (e, stack) {
        dev.log('Failed to log screen impression: $e', name: 'PlaylistScreen', error: e, stackTrace: stack);
      }

      final effectHandler = PlaylistMobiusEffectHandler(
        repository: repo,
        optionsClient: optionsClient,
        controlClient: controlClient,
      );

      _loop = PlaylistMobiusLoop(
        playlistUri: widget.playlistUri,
        repository: repo,
        effectHandler: effectHandler,
        playerStateClient: stateClient,
      );
    }

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      _scrollOffsetNotifier.value = _scrollController.offset;
    }
  }

  void _updateDerivedColor(String coverUrl) {
    if (coverUrl.isEmpty || _lastExtractedCoverUrl == coverUrl) return;
    _lastExtractedCoverUrl = coverUrl;

    try {
      final colorService = getIt<ColorExtractionService>();
      colorService.extract(imageUrl: coverUrl).then((scheme) {
        if (!mounted) return;
        final extracted = scheme.primary;
        final hsl = HSLColor.fromColor(extracted);
        // Strict guardrail: reject any purple/violet tones to guarantee neutral Spotify dark palette
        if (hsl.hue >= 250 && hsl.hue <= 315) {
          setState(() {
            _dominantHeaderColor = const Color(0xFF535353);
          });
        } else {
          setState(() {
            _dominantHeaderColor = extracted;
          });
        }
      }).catchError((e, stack) {
        dev.log('Failed to extract dominant color: $e', name: 'PlaylistScreen', error: e, stackTrace: stack);
      });
    } catch (e, stack) {
      dev.log('Failed to get ColorExtractionService: $e', name: 'PlaylistScreen', error: e, stackTrace: stack);
    }
  }

  void _handlePlayFabTapped() {
    final ubiLogger = getIt<UbiLogger>();
    final coordinator = getIt<PlaylistPlayCoordinator>();
    final result = ubiLogger.logInteraction(
      const UbiInteractionElement(
        elementPath: 'play_button',
        actionName: 'hit',
      ),
    );
    final loggingParams = coordinator.buildLoggingParams(result);
    _loop.onPlayTapped(loggingParams: loggingParams);
  }

  void _handleTrackTapped(PlaylistItem item, int position) {
    final ubiLogger = getIt<UbiLogger>();
    final coordinator = getIt<PlaylistPlayCoordinator>();
    final result = ubiLogger.logInteraction(
      UbiInteractionElement(
        elementPath: 'track_row',
        uri: item.uri,
        position: position,
        actionName: 'hit',
      ),
    );
    final loggingParams = coordinator.buildLoggingParams(result);
    _loop.onPlayTapped(trackUri: item.uri, loggingParams: loggingParams);
  }

  void _handleSwipeToQueue(PlaylistItem item, [int position = 0]) {
    try {
      final ubiLogger = getIt<UbiLogger>();
      final coordinator = getIt<PlaylistPlayCoordinator>();
      final result = ubiLogger.logInteraction(
        UbiInteractionElement(
          elementPath: 'swipe_to_queue',
          uri: item.uri,
          position: position,
          actionName: 'swipe',
        ),
      );
      final loggingParams = coordinator.buildLoggingParams(result);
      _loop.onSwipeToQueue(item, loggingParams: loggingParams);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${item.title}" to queue'),
            duration: const Duration(milliseconds: 1500),
            backgroundColor: const Color(0xFF282828),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      dev.log('Swipe to queue failed: $e', name: 'PlaylistScreen', error: e, stackTrace: stack);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollOffsetNotifier.dispose();
    _stretchController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    if (widget.loopOverride == null) {
      _loop.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: StreamBuilder<PlaylistScreenState>(
        stream: _loop.stateStream,
        initialData: _loop.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data ?? _loop.currentState;

          return switch (state) {
            PlaylistLoadingState() => _buildLoading(),
            PlaylistErrorState(:final message) => _buildError(message),
            PlaylistLoadedState() => _buildLoaded(state),
          };
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpotifyIcon.error(
              size: 48,
              color: const Color(0xFFB3B3B3),
            ),
            const SizedBox(height: 16),
            const Text(
              'Couldn\'t load playlist',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB3B3B3),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _loop.onRetryTapped();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaded(PlaylistLoadedState state) {
    // Derive dominant background color once cover is available
    if (state.playlist.pictureUrl.isNotEmpty) {
      _updateDerivedColor(state.playlist.pictureUrl);
    }

    final topInset = MediaQuery.of(context).padding.top;
    final isOwner = state.playlist.metadata.canEdit;
    final toolbarHeight = kToolbarHeight;
    final pinnedFabTop = (topInset + toolbarHeight) - 28.0;

    // Dynamically measure initial Action Row position once for 1:1 PlayButtonBehavior docking
    if (_initialActionRowTop == 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final box = _actionRowKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final pos = box.localToGlobal(Offset.zero);
          final top = pos.dy + (_scrollController.hasClients ? _scrollController.offset : 0.0);
          if (top > 0) {
            _initialActionRowTop = top;
          }
        }
      });
    }

    final effectiveHeaderHeight = state.playlist.metadata.isEditorial ? 440.0 : _headerHeight;
    final baselineTop = _initialActionRowTop > 0
        ? _initialActionRowTop
        : (topInset + toolbarHeight + effectiveHeaderHeight);

    return Stack(
      children: [
        // 1. Spotify Stretch Overscroll Indicator + Fast Scroller + CustomScrollView
        SpotifyStretchOverscrollIndicator(
          controller: _stretchController,
          axisDirection: AxisDirection.down,
          child: RawScrollbar(
            controller: _scrollController,
            thumbColor: Colors.white38,
            thickness: 4.0,
            radius: const Radius.circular(2.0),
            minThumbLength: 48.0,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              slivers: [
                // 1:1 Header Container with continuous 21-step matte EasedGradient
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: EasedGradient.build(
                        topColor: _dominantHeaderColor,
                        bottomColor: const Color(0xFF121212),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Safe area spacing for top toolbar
                        SizedBox(height: topInset + kToolbarHeight),

                        // 1. Top Search Bar, Artwork (Scaling), Title, Creator, Duration
                        // Wrapped in ValueListenableBuilder so only header content rebuilds with scroll
                        ValueListenableBuilder<double>(
                          valueListenable: _scrollOffsetNotifier,
                          builder: (context, offset, _) {
                            return PlaylistHeaderContent(
                              metadata: state.playlist.metadata,
                              trackCount: state.playlist.items.length,
                              scrollOffset: offset,
                              searchController: _searchController,
                              searchFocusNode: _searchFocusNode,
                              onSearchChanged: _loop.onSearchChanged,
                              onClearSearch: () => _loop.onSearchChanged(''),
                              onAddCollaboratorTapped: () {},
                            );
                          },
                        ),

                        // 2. Action Row: Download, Share/Heart, Shuffle, and 56x56 Play FAB layout slot
                        PlaylistActionRow(
                          key: _actionRowKey,
                          isOwner: isOwner,
                          isFollowed: state.playlist.isFollowed,
                          isDownloaded: state.playlist.isDownloaded,
                          isShuffleEnabled: state.isShuffleEnabled,
                          isPlaying: state.isPlaying,
                          onFollowTapped: _loop.onFollowTapped,
                          onDownloadTapped: _loop.onDownloadTapped,
                          onShareTapped: () => _showPlaylistMoreMenu(state),
                          onShuffleTapped: _loop.onShuffleTapped,
                          onPlayTapped: () => _loop.onPlayTapped(),
                        ),

                        // 3. Permission-Governed Curation Actions Chips (`uwt.java`, `curation_actions_*`)
                        PlaylistCurationChipsRow(
                          isEditorial: state.playlist.metadata.isEditorial,
                          canEdit: isOwner,
                          onAddTapped: () {
                            _searchFocusNode.requestFocus();
                          },
                          onEditTapped: () {
                            _showPlaylistMoreMenu(state);
                          },
                          onDetailsTapped: () {
                            _showPlaylistMoreMenu(state);
                          },
                          onSortTapped: () {
                            PlaylistSortSheet.show(
                              context,
                              currentOrder: state.sortOrder,
                              onOrderSelected: _loop.onSortChanged,
                            );
                          },
                          currentSortName: state.sortOrder.displayName,
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),

                // 4. Empty View or Sectioned Track Tiles
                if (state.isEmpty)
                  SliverToBoxAdapter(
                    child: PlaylistEmptyView(
                      onAddSongsTapped: () {
                        _searchFocusNode.requestFocus();
                      },
                    ),
                  )
                else
                  ..._buildSectionedSlivers(state),

                // Bottom safe padding for NowPlaying / Navigation Bar via Reusable Shell Spacer
                const SliverShellBottomSpacer(),
              ],
            ),
          ),
        ),

        // 5. Pinned Collapsing AppBar at Top with Dynamic Bubble Fade and Sliding Action Buttons
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<double>(
            valueListenable: _scrollOffsetNotifier,
            builder: (context, offset, _) {
              return PlaylistAppBar(
                title: state.playlist.name,
                scrollOffset: offset,
                headerHeight: effectiveHeaderHeight,
                dominantColor: _dominantHeaderColor,
                isSearchActive: _isSearchActive,
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                onSearchChanged: _loop.onSearchChanged,
                onBackTapped: () {
                  if (getIt.isRegistered<SpotifyNavigator>()) {
                    getIt<SpotifyNavigator>().goBack(context);
                  } else {
                    Navigator.maybePop(context);
                  }
                },
                onSearchTapped: () {
                  setState(() {
                    _isSearchActive = true;
                  });
                  _searchFocusNode.requestFocus();
                },
                onSearchClosed: () {
                  setState(() {
                    _isSearchActive = false;
                  });
                  _searchController.clear();
                  _loop.onSearchChanged('');
                },
                onMoreTapped: () => _showPlaylistMoreMenu(state),
              );
            },
          ),
        ),

        // 6. Floating 56x56 Play FAB with PlayButtonBehavior docking physics
        // Matches ComposePlayButtonBehavior.java: pins at (topInset + kToolbarHeight) - 28dp
        ValueListenableBuilder<double>(
          valueListenable: _scrollOffsetNotifier,
          builder: (context, offset, _) {
            final currentActionRowY = baselineTop - offset;
            final fabTop = math.max(pinnedFabTop, currentActionRowY + 6.0);
            return Positioned(
              top: fabTop,
              right: 16.0,
              child: PlaylistPlayFab(
                isPlaying: state.isPlaying,
                isShuffleEnabled: state.isShuffleEnabled,
                onPlayTapped: _handlePlayFabTapped,
              ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildSectionedSlivers(PlaylistLoadedState state) {
    final hasSections = state.displayItems.any((i) => i.sectionType != PlaylistSectionType.standard);

    if (!hasSections) {
      return [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = state.displayItems[index];
              final isCurrent = item.uri == state.activeTrackUri;

              return PlaylistTrackTile(
                key: ValueKey<String>('track_${item.uid.isNotEmpty ? item.uid : item.uri}'),
                item: item,
                isActiveTrack: isCurrent,
                isPlaying: state.isPlaying,
                onTap: () => _handleTrackTapped(item, index),
                onMoreTapped: () => _showTrackOptionsMenu(item),
                onSwipeToQueue: () => _handleSwipeToQueue(item, index),
              );
            },
            childCount: state.displayItems.length,
          ),
        ),
      ];
    }

    // Group items into sections matching Spotify dg80.java
    final slivers = <Widget>[];
    final sections = [
      PlaylistSectionType.youAdded,
      PlaylistSectionType.includes,
      PlaylistSectionType.weAdded,
      PlaylistSectionType.standard,
    ];

    for (final section in sections) {
      final sectionItems = state.displayItems.where((i) => i.sectionType == section).toList();
      if (sectionItems.isEmpty) continue;

      slivers.add(
        SliverToBoxAdapter(
          child: PlaylistSectionHeader(
            sectionType: section,
            count: sectionItems.length,
          ),
        ),
      );

      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = sectionItems[index];
              final isCurrent = item.uri == state.activeTrackUri;

              return PlaylistTrackTile(
                key: ValueKey<String>('track_${item.uid.isNotEmpty ? item.uid : item.uri}'),
                item: item,
                isActiveTrack: isCurrent,
                isPlaying: state.isPlaying,
                onTap: () => _handleTrackTapped(item, index),
                onMoreTapped: () => _showTrackOptionsMenu(item),
                onSwipeToQueue: () => _handleSwipeToQueue(item, index),
              );
            },
            childCount: sectionItems.length,
          ),
        ),
      );
    }

    return slivers;
  }

  VaultSessionBloc? _resolveVaultSessionBloc() {
    if (widget.vaultSessionBlocOverride case final bloc?) {
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

  IVaultStorageRepository? _resolveVaultStorageRepository() {
    if (widget.vaultStorageRepositoryOverride case final repo?) {
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

  void _showPlaylistMoreMenu(PlaylistLoadedState state) {
    final isOwner = state.playlist.metadata.canEdit;
    final sessionBloc = _resolveVaultSessionBloc();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        Widget buildContent(bool isVaultActive) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Header preview in sheet
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            width: 48,
                            height: 48,
                            color: const Color(0xFF383838),
                            child: state.playlist.pictureUrl.isNotEmpty
                                ? Image.network(
                                    state.playlist.pictureUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => SpotifyIcon.track(
                                      size: 24,
                                      color: const Color(0xFFB3B3B3),
                                    ),
                                  )
                                : SpotifyIcon.track(
                                    size: 24,
                                    color: const Color(0xFFB3B3B3),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.playlist.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'By ${state.playlist.metadata.ownerName.isNotEmpty ? state.playlist.metadata.ownerName : 'Spotify'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFB3B3B3),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFF383838), height: 1),

                  // Owner-only or shared options
                  if (isOwner) ...[
                    ListTile(
                      leading: SpotifyIcon.edit(size: 24, color: Colors.white),
                      title: const Text('Edit playlist', style: TextStyle(color: Colors.white, fontSize: 15)),
                      onTap: () => Navigator.pop(ctx),
                    ),
                    ListTile(
                      leading: SpotifyIcon.plusCircle(size: 24, color: Colors.white),
                      title: const Text('Invite collaborators', style: TextStyle(color: Colors.white, fontSize: 15)),
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ],
                  ListTile(
                    leading: SpotifyIcon.download(size: 24, color: Colors.white),
                    title: const Text('Download', style: TextStyle(color: Colors.white, fontSize: 15)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _loop.onDownloadTapped();
                    },
                  ),
                  ListTile(
                    leading: SpotifyIcon.share(size: 24, color: Colors.white),
                    title: const Text('Share', style: TextStyle(color: Colors.white, fontSize: 15)),
                    onTap: () => Navigator.pop(ctx),
                  ),

                  // STRICT STEALTH GATE: Rendered ONLY when VaultSession is active (unlocked or background grace)
                  if (isVaultActive)
                    ListTile(
                      key: const ValueKey('menu_clone_to_private_vault'),
                      leading: const Icon(Icons.shield_outlined, size: 24, color: Colors.white),
                      title: const Text(
                        'Clone to Private Vault',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _handleClonePlaylistToVault(state.playlist);
                      },
                    ),

                  if (isOwner)
                    ListTile(
                      leading: SpotifyIcon.delete(size: 24, color: const Color(0xFFE91429)),
                      title: const Text('Delete playlist', style: TextStyle(color: Color(0xFFE91429), fontSize: 15)),
                      onTap: () => Navigator.pop(ctx),
                    ),
                ],
              ),
            ),
          ),
        );
        }

        if (sessionBloc case final bloc?) {
          return BlocBuilder<VaultSessionBloc, VaultSessionState>(
            bloc: bloc,
            buildWhen: (prev, curr) {
              final prevActive = prev is VaultUnlockedState || prev is VaultBackgroundGraceState;
              final currActive = curr is VaultUnlockedState || curr is VaultBackgroundGraceState;
              return prevActive != currActive;
            },
            builder: (sheetContext, sessionState) {
              final isVaultActive = sessionState is VaultUnlockedState ||
                  sessionState is VaultBackgroundGraceState;
              return buildContent(isVaultActive);
            },
          );
        }

        return buildContent(false);
      },
    );
  }

  void _showTrackOptionsMenu(PlaylistItem item) {
    final sessionBloc = _resolveVaultSessionBloc();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        Widget buildContent(bool isVaultActive) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Track preview header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            width: 48,
                            height: 48,
                            color: const Color(0xFF383838),
                            child: item.coverUrl.isNotEmpty
                                ? Image.network(
                                    item.coverUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => SpotifyIcon.track(
                                      size: 24,
                                      color: const Color(0xFFB3B3B3),
                                    ),
                                  )
                                : SpotifyIcon.track(
                                    size: 24,
                                    color: const Color(0xFFB3B3B3),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle.isNotEmpty ? item.subtitle : 'Unknown Artist',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFB3B3B3),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF383838), height: 1),

                  // Track Actions
                  ListTile(
                    leading: SpotifyIcon.addToPlaylist(size: 24, color: Colors.white),
                    title: const Text('Add to another playlist', style: TextStyle(color: Colors.white, fontSize: 15)),
                    onTap: () => Navigator.pop(ctx),
                  ),

                  // STRICT STEALTH GATE: Rendered ONLY when VaultSession is active (unlocked or background grace)
                  if (isVaultActive)
                    ListTile(
                      key: const ValueKey('menu_add_to_private_playlists'),
                      leading: const Icon(Icons.shield_outlined, size: 24, color: Colors.white),
                      title: const Text(
                        'Add to Private Playlists',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _handleAddToPrivatePlaylists(item);
                      },
                    ),

                  ListTile(
                    leading: SpotifyIcon.addToQueue(size: 24, color: Colors.white),
                    title: const Text('Add to queue', style: TextStyle(color: Colors.white, fontSize: 15)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleSwipeToQueue(item);
                    },
                  ),
                  ListTile(
                    leading: SpotifyIcon.minusCircle(size: 24, color: Colors.white),
                    title: const Text('Remove from this playlist', style: TextStyle(color: Colors.white, fontSize: 15)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _loop.onRemoveTrack(item.uri);
                    },
                  ),
                  ListTile(
                    leading: SpotifyIcon.album(size: 24, color: Colors.white),
                    title: const Text('View album', style: TextStyle(color: Colors.white, fontSize: 15)),
                    onTap: () => Navigator.pop(ctx),
                  ),
                  ListTile(
                    leading: SpotifyIcon.user(size: 24, color: Colors.white),
                    title: const Text('View artist', style: TextStyle(color: Colors.white, fontSize: 15)),
                    onTap: () => Navigator.pop(ctx),
                  ),
                  ListTile(
                    leading: SpotifyIcon.share(size: 24, color: Colors.white),
                    title: const Text('Share', style: TextStyle(color: Colors.white, fontSize: 15)),
                    onTap: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ),
        );
        }

        if (sessionBloc case final bloc?) {
          return BlocBuilder<VaultSessionBloc, VaultSessionState>(
            bloc: bloc,
            buildWhen: (prev, curr) {
              final prevActive = prev is VaultUnlockedState || prev is VaultBackgroundGraceState;
              final currActive = curr is VaultUnlockedState || curr is VaultBackgroundGraceState;
              return prevActive != currActive;
            },
            builder: (sheetContext, sessionState) {
              final isVaultActive = sessionState is VaultUnlockedState ||
                  sessionState is VaultBackgroundGraceState;
              return buildContent(isVaultActive);
            },
          );
        }

        return buildContent(false);
      },
    );
  }

  Future<void> _handleClonePlaylistToVault(PlaylistEntity playlist) async {
    final storageRepo = _resolveVaultStorageRepository();
    if (storageRepo == null) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final createResult = await storageRepo.createPlaylist(
      name: playlist.name,
      description: playlist.description.isNotEmpty
          ? playlist.description
          : 'Cloned from public playlist',
      coverUri: playlist.pictureUrl.isNotEmpty ? playlist.pictureUrl : null,
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
          );
          await storageRepo.addTrackToPlaylist(
            playlistId: createdPlaylist.id,
            trackRef: trackRef,
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cloned "${playlist.name}" to Private Vault',
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      case VaultFailureResult<PrivatePlaylist>():
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
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
  }

  Future<void> _handleAddToPrivatePlaylists(PlaylistItem item) async {
    final storageRepo = _resolveVaultStorageRepository();
    if (storageRepo == null) return;

    final playlistsResult = await storageRepo.getPlaylists();
    if (!mounted) return;

    switch (playlistsResult) {
      case VaultSuccess<List<PrivatePlaylist>>(:final data):
        final playlists = data;
        if (playlists.isEmpty) {
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final createResult = await storageRepo.createPlaylist(
            name: 'Private Playlist',
            description: 'Created from public track ingestion',
          );
          if (createResult case VaultSuccess<PrivatePlaylist>(:final data)) {
            final newPlaylist = data;
            final trackRef = PrivateTrackRef(
              id: 'track_${newPlaylist.id}_0',
              playlistId: newPlaylist.id,
              trackUri: item.uri.isNotEmpty ? item.uri : 'spotify:track:single',
              title: item.title.isNotEmpty ? item.title : 'Unknown Track',
              artistName: item.subtitle.isNotEmpty ? item.subtitle : 'Unknown Artist',
              albumTitle: item.albumName.isNotEmpty ? item.albumName : 'Unknown Album',
              durationMs: item.durationMs,
              sourceType: TrackSourceTypeEnum.spotify,
              localRelativePath: null,
              sortOrder: 0,
              addedAtEpochMs: nowMs,
            );
            await storageRepo.addTrackToPlaylist(
              playlistId: newPlaylist.id,
              trackRef: trackRef,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Added "${item.title}" to "${newPlaylist.name}"',
                    style: const TextStyle(fontFamily: 'Poppins'),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
          return;
        }

        _showPrivatePlaylistPicker(playlists, item, storageRepo);

      case VaultFailureResult<List<PrivatePlaylist>>():
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to load private playlists',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
    }
  }

  void _showPrivatePlaylistPicker(
    List<PrivatePlaylist> playlists,
    PlaylistItem item,
    IVaultStorageRepository storageRepo,
  ) {
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (pickerCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Text(
                'Select Private Playlist',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const Divider(color: Color(0xFF383838), height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return ListTile(
                    key: ValueKey('picker_playlist_${playlist.id}'),
                    leading: const Icon(Icons.lock_outline, color: Colors.white, size: 20),
                    title: Text(
                      playlist.name,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins'),
                    ),
                    subtitle: Text(
                      '${playlist.trackCount} tracks',
                      style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12, fontFamily: 'Poppins'),
                    ),
                    onTap: () async {
                      Navigator.pop(pickerCtx);
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
                      );
                      await storageRepo.addTrackToPlaylist(
                        playlistId: playlist.id,
                        trackRef: trackRef,
                      );
                      if (mounted) {
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
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
