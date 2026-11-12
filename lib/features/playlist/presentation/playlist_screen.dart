library;

import 'dart:async';
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
import '../../player/presentation/models/more_options_entity.dart';
import '../../player/presentation/widgets/more_options_bottom_sheet.dart';
import '../../player/presentation/widgets/spotify_scroll_physics.dart';
import '../../vault/application/session/vault_session_bloc.dart';
import '../../vault/domain/interfaces/i_vault_storage_repository.dart';
import '../application/mobius/playlist_effect_handler.dart';
import '../application/mobius/playlist_mobius_loop.dart';
import '../data/coordinator/playlist_play_coordinator.dart';
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
  StreamSubscription<PlaylistScreenState>? _loopColorSub;

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
    _syncColorForState(_loop.currentState, allowSetState: false);
    _loopColorSub = _loop.stateStream.listen(
      (state) => _syncColorForState(state, allowSetState: true),
    );
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      _scrollOffsetNotifier.value = _scrollController.offset;
    }
  }

  void _syncColorForState(
    PlaylistScreenState state, {
    required bool allowSetState,
  }) {
    if (state is PlaylistLoadedState && state.playlist.pictureUrl.isNotEmpty) {
      _updateDerivedColor(
        state.playlist.pictureUrl,
        allowSetState: allowSetState,
      );
    }
  }

  void _updateDerivedColor(String coverUrl, {required bool allowSetState}) {
    if (coverUrl.isEmpty || _lastExtractedCoverUrl == coverUrl) return;
    _lastExtractedCoverUrl = coverUrl;

    try {
      if (!getIt.isRegistered<ColorExtractionService>()) return;
      final colorService = getIt<ColorExtractionService>();
      final cached = colorService.getCached(coverUrl);
      if (cached != null) {
        final target = _sanitizeHeaderColor(cached.primary);
        if (_dominantHeaderColor != target) {
          if (allowSetState && mounted) {
            setState(() {
              _dominantHeaderColor = target;
            });
          } else {
            _dominantHeaderColor = target;
          }
        }
        return;
      }

      colorService.extract(imageUrl: coverUrl).then((scheme) {
        if (!mounted || _lastExtractedCoverUrl != coverUrl) return;
        final target = _sanitizeHeaderColor(scheme.primary);
        if (_dominantHeaderColor != target) {
          setState(() {
            _dominantHeaderColor = target;
          });
        }
      }).catchError((e, stack) {
        dev.log('Failed to extract dominant color: $e', name: 'PlaylistScreen', error: e, stackTrace: stack);
      });
    } catch (e, stack) {
      dev.log('Failed to get ColorExtractionService: $e', name: 'PlaylistScreen', error: e, stackTrace: stack);
    }
  }

  static Color _sanitizeHeaderColor(Color extracted) {
    final hsl = HSLColor.fromColor(extracted);
    // Strict guardrail: reject any purple/violet tones to guarantee neutral Spotify dark palette
    if (hsl.hue >= 250 && hsl.hue <= 315) {
      return const Color(0xFF535353);
    }
    return extracted;
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
    _loopColorSub?.cancel();
    _loopColorSub = null;
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
    MoreOptionsBottomSheet.show(
      context,
      entity: SpotifyPlaylistOptionsEntity(state.playlist),
      sessionBlocOverride: _resolveVaultSessionBloc(),
      storageRepositoryOverride: _resolveVaultStorageRepository(),
    );
  }

  void _showTrackOptionsMenu(PlaylistItem item) {
    MoreOptionsBottomSheet.show(
      context,
      entity: SpotifyTrackOptionsEntity(item),
      onRemoveFromPlaylist: () => _loop.onRemoveTrack(item.uri),
      sessionBlocOverride: _resolveVaultSessionBloc(),
      storageRepositoryOverride: _resolveVaultStorageRepository(),
    );
  }
}
