library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../app/di/injection.dart';
import '../../../core/color/color_extraction_service.dart';
import '../../../core/color/eased_gradient.dart';
import '../../../core/ui/icons/spotify_encore_icons.dart';
import '../../../core/ui/widgets/shell_bottom_spacer.dart';
import '../../../features/player/data/esperanto/context_player_control_client.dart';
import '../../../features/player/data/esperanto/context_player_options_client.dart';
import '../../../features/player/data/esperanto/context_player_state_client.dart';
import '../../../features/player/domain/commands/play_as_next_in_queue_command.dart';
import '../../../features/player/domain/models/context_track.dart';
import '../../player/presentation/widgets/spotify_scroll_physics.dart';
import '../application/mobius/playlist_effect_handler.dart';
import '../application/mobius/playlist_mobius_loop.dart';
import '../domain/models/playlist_item.dart';
import '../domain/models/playlist_screen_state.dart';
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

/// 1:1 replica of Spotify's Playlist screen coordinator
/// (`header_layout.xml`, `playlist_all_songs_page.xml`, `b7r.java`, `yz40.java`, `uwt.java`, `PlayButtonBehavior.java`).
///
/// Features:
/// 1. Top Search Bar: Find in playlist positioned at the top of header content
/// 2. Album Artwork Motion: Scales down (1.0 -> 0.75) and fades out smoothly with scroll
/// 3. Collapsing AppBar with dynamic fading dark translucent bubbles (`back_button_background.xml`)
///    and outward sliding buttons (8dp slide, zero button fade, zero play button in top bar)
/// 4. Action Row: Download, Share (Owner) / Heart (Viewer), Shuffle with active dot, and 56x56 layout slot
/// 5. Floating PlayButtonBehavior FAB: 56x56 green FAB with 20dp shuffle badge that moves smoothly
///    with the Action Row and pins at (topInset + kToolbarHeight - 28dp) directly overlapping the toolbar bottom
/// 6. Permission-Governed Curation Action Chips: `+ Add`, `Edit`, `Name & details`, `Sort` for owners; `Sort` for viewers
/// 7. Track Tiles: Wrapped with Dismissible swipe-to-queue (`ItemTouchHelper`), 48x48 art, 12dp download badge, explicit "E" badge, animated 3-bar green equalizer
/// 8. High-Performance Zero-Jank Rendering:
///    - Isolated scroll listeners using [ValueNotifier<double>] to eliminate full-tree setState rebuilds
///    - Memoized gradients and zero redundant Mobius loop dispatches during scroll ticks
class PlaylistScreen extends StatefulWidget {
  final String playlistUri;

  const PlaylistScreen({
    super.key,
    required this.playlistUri,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen>
    with TickerProviderStateMixin {
  late final PlaylistMobiusLoop _loop;
  late final ScrollController _scrollController;
  late final ValueNotifier<double> _scrollOffsetNotifier;
  late final SpotifyStretchController _stretchController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  final GlobalKey _actionRowKey = GlobalKey();
  double _initialActionRowTop = 0.0;

  bool _isSearchActive = false;
  Color _dominantHeaderColor = const Color(0xFF535353); // Default Spotify encore_header_background_default
  String? _lastExtractedCoverUrl;

  static const double _headerHeight = 360.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollOffsetNotifier = ValueNotifier<double>(0.0);
    _stretchController = SpotifyStretchController(vsync: this);
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    final repo = getIt<PlaylistRepository>();
    final optionsClient = getIt<ContextPlayerOptionsClient>();
    final controlClient = getIt<ContextPlayerControlClient>();
    final stateClient = getIt<ContextPlayerStateClient>();

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
      }).catchError((_) {});
    } catch (_) {}
  }

  void _handleSwipeToQueue(PlaylistItem item) {
    try {
      final controlClient = getIt<ContextPlayerControlClient>();
      final queuedTrack = ContextTrack.builder(item.uri)
          .uid(item.uid.isNotEmpty ? item.uid : item.uri)
          .metadata({
            ContextTrackMetadata.keyTitle: item.title,
            ContextTrackMetadata.keyArtistName: item.subtitle,
            ContextTrackMetadata.keyAlbumTitle: item.albumName,
            if (item.coverUrl.isNotEmpty) ContextTrackMetadata.keyImageUrl: item.coverUrl,
            if (item.coverUrl.isNotEmpty) ContextTrackMetadata.keyImageLargeUrl: item.coverUrl,
            if (item.coverUrl.isNotEmpty) ContextTrackMetadata.keyThumbnailImageUrl: item.coverUrl,
            if (item.durationMs > 0) ContextTrackMetadata.keyDuration: item.durationMs.toString(),
            ContextTrackMetadata.keyIsExplicit: item.isExplicit ? 'true' : 'false',
            ContextTrackMetadata.keyEntityUri: item.uri,
            ContextTrackMetadata.keyContextUri: widget.playlistUri,
            ContextTrackMetadata.keyIsQueued: 'true',
            if (item.trackMetadata case final meta? when meta.fileId.isNotEmpty)
              ContextTrackMetadata.keyFileId: meta.fileId,
            if (item.trackMetadata case final meta? when meta.headUrl.isNotEmpty)
              ContextTrackMetadata.keyHeadFileUrl: meta.headUrl,
            if (item.trackMetadata case final meta? when meta.cdnUrl.isNotEmpty)
              ContextTrackMetadata.keyCdnAacUrl: meta.cdnUrl,
          })
          .build();

      controlClient.playAsNextInQueue(
        PlayAsNextInQueueCommand.create([queuedTrack]),
      );
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
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollOffsetNotifier.dispose();
    _stretchController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _loop.dispose();
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
                onBackTapped: () => Navigator.maybePop(context),
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
                onPlayTapped: () => _loop.onPlayTapped(),
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
                onTap: () => _loop.onPlayTapped(trackUri: item.uri),
                onMoreTapped: () => _showTrackOptionsMenu(item),
                onSwipeToQueue: () => _handleSwipeToQueue(item),
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
                onTap: () => _loop.onPlayTapped(trackUri: item.uri),
                onMoreTapped: () => _showTrackOptionsMenu(item),
                onSwipeToQueue: () => _handleSwipeToQueue(item),
              );
            },
            childCount: sectionItems.length,
          ),
        ),
      );
    }

    return slivers;
  }

  void _showPlaylistMoreMenu(PlaylistLoadedState state) {
    final isOwner = state.playlist.metadata.canEdit;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
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

  void _showTrackOptionsMenu(PlaylistItem item) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
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
}
