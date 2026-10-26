library;

import 'package:flutter/material.dart';

import '../../../app/di/injection.dart';
import '../../../core/color/color_extraction_service.dart';
import '../../../core/color/eased_gradient.dart';
import '../../../features/player/data/esperanto/context_player_control_client.dart';
import '../../../features/player/data/esperanto/context_player_options_client.dart';
import '../../../features/player/data/esperanto/context_player_state_client.dart';
import '../../player/presentation/widgets/spotify_scroll_physics.dart';
import '../application/mobius/playlist_effect_handler.dart';
import '../application/mobius/playlist_mobius_loop.dart';
import '../domain/models/playlist_item.dart';
import '../domain/models/playlist_screen_state.dart';
import '../domain/models/sort_order.dart';
import '../domain/repositories/playlist_repository.dart';
import 'components/playlist_action_row.dart';
import 'components/playlist_app_bar.dart';
import 'components/playlist_empty_view.dart';
import 'components/playlist_header_content.dart';
import 'components/playlist_section_header.dart';
import 'components/playlist_sort_sheet.dart';
import 'components/playlist_track_tile.dart';

/// 1:1 replica of Spotify's Playlist screen coordinator (`playlist_all_songs_page.xml`, `b7r.java`, `ets0.java`).
/// Implements collapsing Encore header with 0.70 parallax fade, continuous 21-step matte EasedGradient,
/// SpotifyStretchOverscrollIndicator (for authentic upward and downward overscroll), fast scroller,
/// action row with 56x56 play FAB, and sectioned track tiles.
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
  late final SpotifyStretchController _stretchController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  double _scrollOffset = 0.0;
  bool _isSearchActive = false;
  Color _dominantHeaderColor = const Color(0xFF535353); // Default Spotify encore_header_background_default
  String? _lastExtractedCoverUrl;

  static const double _headerHeight = 320.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    if (_scrollOffset != offset) {
      setState(() {
        _scrollOffset = offset;
      });
      final alpha = (offset / _headerHeight).clamp(0.0, 1.0);
      _loop.onHeaderOffsetChanged(alpha);
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

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Color(0xFFB3B3B3),
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
                _loop.onSortChanged(ProvidedSortOrder.custom);
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
                // 1:1 Header Container with continuous 21-step matte EasedGradient (matching PlayerScreen and Spotify AppBarLayout)
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

                        // 1:1 Header Content (Centered Cover Art, Title, Description, Owner Row, Telemetry)
                        PlaylistHeaderContent(
                          metadata: state.playlist.metadata,
                          trackCount: state.playlist.items.length,
                        ),

                        // 1:1 Action Row: Follow, Download, Collaborators, More, Shuffle (dot), 56x56 Play FAB
                        PlaylistActionRow(
                          isFollowed: state.playlist.isFollowed,
                          isDownloaded: state.playlist.isDownloaded,
                          isShuffleEnabled: state.isShuffleEnabled,
                          isPlaying: state.isPlaying,
                          onFollowTapped: _loop.onFollowTapped,
                          onDownloadTapped: _loop.onDownloadTapped,
                          onAddCollaboratorTapped: () {},
                          onMoreOptionsTapped: () => _showPlaylistMoreMenu(state),
                          onShuffleTapped: _loop.onShuffleTapped,
                          onPlayTapped: () => _loop.onPlayTapped(),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // Search Input Bar (when active)
                if (_isSearchActive)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF282828),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            icon: const Icon(Icons.search, color: Color(0xFFB3B3B3), size: 20),
                            hintText: 'Find in playlist',
                            hintStyle: const TextStyle(color: Color(0xFF727272), fontSize: 14),
                            border: InputBorder.none,
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Color(0xFFB3B3B3), size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _loop.onSearchChanged('');
                                    },
                                  )
                                : null,
                          ),
                          onChanged: _loop.onSearchChanged,
                        ),
                      ),
                    ),
                  ),

                // Sort Selector Row (current sort order on left, song count on right)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            PlaylistSortSheet.show(
                              context,
                              currentOrder: state.sortOrder,
                              onOrderSelected: _loop.onSortChanged,
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.sort,
                                  color: Color(0xFFB3B3B3),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  state.sortOrder.displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Color(0xFFB3B3B3),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${state.displayItems.length} songs',
                          style: const TextStyle(
                            color: Color(0xFFB3B3B3),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Empty View or Sectioned Track Tiles
                if (state.isEmpty)
                  SliverToBoxAdapter(
                    child: PlaylistEmptyView(
                      onAddSongsTapped: () {
                        setState(() {
                          _isSearchActive = true;
                        });
                        _searchFocusNode.requestFocus();
                      },
                    ),
                  )
                else
                  ..._buildSectionedSlivers(state),

                // Bottom safe padding for NowPlaying / Navigation Bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ),
              ],
            ),
          ),
        ),

        // 2. Pinned Collapsing AppBar at Top with 0.70 Parallax Fade and Mini Green Play Button
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: PlaylistAppBar(
            title: state.playlist.name,
            scrollOffset: _scrollOffset,
            headerHeight: _headerHeight,
            dominantColor: _dominantHeaderColor,
            isPlaying: state.isPlaying,
            onBackTapped: () => Navigator.maybePop(context),
            onPlayTapped: () => _loop.onPlayTapped(),
            onSearchTapped: () {
              setState(() {
                _isSearchActive = !_isSearchActive;
              });
              if (_isSearchActive) {
                _searchFocusNode.requestFocus();
              } else {
                _searchController.clear();
                _loop.onSearchChanged('');
              }
            },
            onMoreTapped: () => _showPlaylistMoreMenu(state),
          ),
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
                key: ValueKey(item.uid),
                item: item,
                isActiveTrack: isCurrent,
                isPlaying: state.isPlaying,
                onTap: () => _loop.onPlayTapped(trackUri: item.uri),
                onMoreTapped: () => _showTrackOptionsMenu(item),
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
                key: ValueKey(item.uid),
                item: item,
                isActiveTrack: isCurrent,
                isPlaying: state.isPlaying,
                onTap: () => _loop.onPlayTapped(trackUri: item.uri),
                onMoreTapped: () => _showTrackOptionsMenu(item),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF535353),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF383838),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: state.playlist.pictureUrl.isNotEmpty
                          ? Image.network(state.playlist.pictureUrl, fit: BoxFit.cover)
                          : const Icon(Icons.music_note, color: Colors.white54),
                    ),
                    const SizedBox(width: 14),
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
                            state.playlist.ownerName.isNotEmpty
                                ? 'Playlist by ${state.playlist.ownerName}'
                                : 'Spotify Playlist',
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

              // Actions
              ListTile(
                leading: Icon(
                  state.playlist.isFollowed ? Icons.favorite : Icons.favorite_border,
                  color: state.playlist.isFollowed ? const Color(0xFF1DB954) : Colors.white,
                ),
                title: Text(
                  state.playlist.isFollowed ? 'Remove from library' : 'Save to library',
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _loop.onFollowTapped();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: Colors.white),
                title: const Text('Share', style: TextStyle(color: Colors.white, fontSize: 15)),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.white),
                title: const Text('Edit playlist', style: TextStyle(color: Colors.white, fontSize: 15)),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.white),
                title: const Text('Delete playlist', style: TextStyle(color: Colors.white, fontSize: 15)),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrackOptionsMenu(PlaylistItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF535353),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Track Preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF383838),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: item.coverUrl.isNotEmpty
                          ? Image.network(item.coverUrl, fit: BoxFit.cover)
                          : const Icon(Icons.music_note, color: Colors.white54),
                    ),
                    const SizedBox(width: 14),
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
                            item.subtitle,
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
                leading: const Icon(Icons.playlist_add, color: Colors.white),
                title: const Text('Add to another playlist', style: TextStyle(color: Colors.white, fontSize: 15)),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle_outline, color: Colors.white),
                title: const Text('Remove from this playlist', style: TextStyle(color: Colors.white, fontSize: 15)),
                onTap: () {
                  Navigator.pop(ctx);
                  _loop.onRemoveTrack(item.uri);
                },
              ),
              ListTile(
                leading: const Icon(Icons.album_outlined, color: Colors.white),
                title: const Text('View album', style: TextStyle(color: Colors.white, fontSize: 15)),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.white),
                title: const Text('View artist', style: TextStyle(color: Colors.white, fontSize: 15)),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: Colors.white),
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
