library;

import 'package:flutter/material.dart';
import '../../domain/models/playlist_item.dart';
import 'spotify_swipe_to_queue.dart';

/// 1:1 replica of Spotify's Playlist entity row components
/// (`layout_default_track_row.xml`, `preview_episode_row_playlist_all_songs.xml`, `show_complex_row_search_layout.xml`, `bqa1.java`).
///
/// Features:
/// 1. Authentic Swipe-to-Queue (`bqa1.java`) with 25% trigger threshold, 45% drag clamp,
///    fading green background with playlist_add icon, haptic pulse, and spring snap-back.
/// 2. Multi-Entity Rendering Support:
///    - Track: 48x48 art, 1-line title, 3-bar animated equalizer, download badge, explicit "E" badge, artists string, more button.
///    - Podcast Episode: 64x64 art with play overlay, 2-line title, show name, 2-line description excerpt,
///      publish date, progress bar if listened, and quick action bar (32dp play, add, download, more).
///    - Podcast Show: 64x64 art, 2-line show title, "Podcast • Publisher" subtitle, description, more button.
class PlaylistTrackTile extends StatelessWidget {
  final PlaylistItem item;
  final bool isActiveTrack;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onMoreTapped;
  final VoidCallback? onSwipeToQueue;

  const PlaylistTrackTile({
    super.key,
    required this.item,
    required this.isActiveTrack,
    required this.isPlaying,
    required this.onTap,
    required this.onMoreTapped,
    this.onSwipeToQueue,
  });

  @override
  Widget build(BuildContext context) {
    final Widget tileContent = switch (item.itemType) {
      PlaylistItemType.episode => _buildEpisodeTile(context),
      PlaylistItemType.show => _buildShowTile(context),
      PlaylistItemType.track => _buildTrackTile(context),
    };

    return SpotifySwipeToQueue(
      onSwipeToQueue: onSwipeToQueue,
      child: tileContent,
    );
  }

  // =========================================================================
  // 1. Standard Music Track Row (layout_default_track_row.xml & e83.java)
  // =========================================================================
  Widget _buildTrackTile(BuildContext context) {
    final titleColor = isActiveTrack ? const Color(0xFF1DB954) : Colors.white;

    return InkWell(
      onTap: onTap,
      splashColor: const Color(0x33FFFFFF),
      highlightColor: const Color(0x1FFFFFFF),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // 1. Track Artwork (48x48 rounded 4px matching layout_default_track_row.xml)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(4),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.coverUrl.isNotEmpty
                  ? Image.network(
                      item.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderCover(Icons.music_note),
                    )
                  : _buildPlaceholderCover(Icons.music_note),
            ),
            const SizedBox(width: 12),

            // 2. Metadata Column (Title, Equalizer, Badges, Artists)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Active Playing 3-Bar Animated Equalizer Indicator
                      if (isActiveTrack) ...[
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: _AnimatedEqualizer(isPlaying: isPlaying),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          item.title.isNotEmpty ? item.title : 'Unknown Track',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 15,
                            fontWeight: isActiveTrack ? FontWeight.w700 : FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // Download Status Badge (p3u.Downloaded -> circular green arrow)
                      if (item.isDownloaded) ...[
                        const Padding(
                          padding: EdgeInsets.only(right: 5.0),
                          child: Icon(
                            Icons.arrow_circle_down,
                            color: Color(0xFF1DB954),
                            size: 13,
                          ),
                        ),
                      ],

                      // Explicit "E" Badge (s9l.Explicit -> Encore 9sp Bold, Gray background)
                      if (item.isExplicit) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB3B3B3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'E',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],

                      // Subtitle / Artists String
                      Expanded(
                        child: Text(
                          item.subtitle.isNotEmpty
                              ? item.subtitle
                              : (item.addedBy.isNotEmpty ? item.addedBy : 'Spotify'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFB3B3B3),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 3. More Options Icon Button (44dp touch area)
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFFB3B3B3),
                  size: 20,
                ),
                onPressed: onMoreTapped,
                padding: EdgeInsets.zero,
                tooltip: 'More options',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 2. Podcast Episode Row (preview_episode_row_playlist_all_songs.xml)
  // =========================================================================
  Widget _buildEpisodeTile(BuildContext context) {
    final titleColor = isActiveTrack ? const Color(0xFF1DB954) : Colors.white;
    final hasListenedProgress = item.playbackPositionMs > 0 && item.durationMs > 0;
    final progressFraction = hasListenedProgress
        ? (item.playbackPositionMs / item.durationMs).clamp(0.0, 1.0)
        : 0.0;

    return InkWell(
      onTap: onTap,
      splashColor: const Color(0x33FFFFFF),
      highlightColor: const Color(0x1FFFFFFF),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: 64x64 Artwork + Title & Show Subtitle
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 64x64 Episode Artwork with 4dp rounded corners
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: item.coverUrl.isNotEmpty
                            ? Image.network(
                                item.coverUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderCover(Icons.podcasts),
                              )
                            : _buildPlaceholderCover(Icons.podcasts),
                      ),
                      if (isActiveTrack)
                        Positioned.fill(
                          child: Container(
                            color: const Color(0x80000000),
                            child: Center(
                              child: _AnimatedEqualizer(isPlaying: isPlaying),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Episode Title (up to 2 lines) and Show Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.isNotEmpty ? item.title : 'Unknown Episode',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.showName.isNotEmpty
                            ? item.showName
                            : (item.subtitle.isNotEmpty ? item.subtitle : 'Podcast'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Description Excerpt (EpisodeRowDescriptionView)
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFA7A7A7),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],

            // Metadata: Date + Duration + Progress Bar + Quick Action Row
            const SizedBox(height: 8),
            Row(
              children: [
                // Explicit Badge
                if (item.isExplicit) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB3B3B3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      'E',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // Published Date & Duration telemetry
                Text(
                  _buildEpisodeTelemetryString(),
                  style: const TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(),

                // Episode Row Quick Actions Section (EpisodeRowQuickActionSectionView)
                // 1. Play circle button (32x32)
                InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActiveTrack && isPlaying
                          ? const Color(0xFF1DB954)
                          : const Color(0x1AFFFFFF),
                      border: Border.all(
                        color: isActiveTrack && isPlaying
                            ? const Color(0xFF1DB954)
                            : const Color(0x33FFFFFF),
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isActiveTrack && isPlaying ? Icons.pause : Icons.play_arrow,
                        color: isActiveTrack && isPlaying ? Colors.black : Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Add to Your Episodes (+) Button
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFFB3B3B3),
                      size: 22,
                    ),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    tooltip: 'Save episode',
                  ),
                ),
                const SizedBox(width: 4),

                // 3. Download Episode Button
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    icon: Icon(
                      item.isDownloaded
                          ? Icons.arrow_circle_down
                          : Icons.arrow_circle_down_outlined,
                      color: item.isDownloaded
                          ? const Color(0xFF1DB954)
                          : const Color(0xFFB3B3B3),
                      size: 22,
                    ),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    tooltip: 'Download episode',
                  ),
                ),
                const SizedBox(width: 4),

                // 4. More Options Button
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Color(0xFFB3B3B3),
                      size: 20,
                    ),
                    onPressed: onMoreTapped,
                    padding: EdgeInsets.zero,
                    tooltip: 'More options',
                  ),
                ),
              ],
            ),

            // Mini playback progress bar if episode was partially listened
            if (hasListenedProgress) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(1.5),
                child: SizedBox(
                  height: 3.0,
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    backgroundColor: const Color(0xFF383838),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 3. Podcast Show Row (show_complex_row_search_layout.xml)
  // =========================================================================
  Widget _buildShowTile(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0x33FFFFFF),
      highlightColor: const Color(0x1FFFFFFF),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // 64x64 Show Artwork
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(4),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.coverUrl.isNotEmpty
                  ? Image.network(
                      item.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderCover(Icons.podcasts),
                    )
                  : _buildPlaceholderCover(Icons.podcasts),
            ),
            const SizedBox(width: 12),

            // Show Title & Publisher Metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title.isNotEmpty ? item.title : 'Unknown Show',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Podcast • ${item.subtitle.isNotEmpty ? item.subtitle : 'Spotify'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFB3B3B3),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFA7A7A7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // More Options Button
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFFB3B3B3),
                  size: 20,
                ),
                onPressed: onMoreTapped,
                padding: EdgeInsets.zero,
                tooltip: 'More options',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Helpers
  // =========================================================================
  String _buildEpisodeTelemetryString() {
    final parts = <String>[];
    if (item.publishDate.isNotEmpty) {
      parts.add(item.publishDate);
    }
    if (item.durationMs > 0) {
      final totalMin = (item.durationMs / 60000).round();
      if (totalMin >= 60) {
        final hours = totalMin ~/ 60;
        final mins = totalMin % 60;
        parts.add('${hours}h ${mins}min');
      } else {
        parts.add('$totalMin min');
      }
    }
    return parts.isNotEmpty ? parts.join(' • ') : 'Episode';
  }

  Widget _buildPlaceholderCover(IconData icon) {
    return Container(
      color: const Color(0xFF282828),
      child: Center(
        child: Icon(
          icon,
          size: 24,
          color: const Color(0xFF535353),
        ),
      ),
    );
  }
}

/// 1:1 replica of Spotify's animated 3-bar playing equalizer indicator
/// (`PlayIndicatorView.java` & `a4d1.java`).
class _AnimatedEqualizer extends StatefulWidget {
  final bool isPlaying;

  const _AnimatedEqualizer({required this.isPlaying});

  @override
  State<_AnimatedEqualizer> createState() => _AnimatedEqualizerState();
}

class _AnimatedEqualizerState extends State<_AnimatedEqualizer>
    with TickerProviderStateMixin {
  late final AnimationController _controller1;
  late final AnimationController _controller2;
  late final AnimationController _controller3;

  late final Animation<double> _anim1;
  late final Animation<double> _anim2;
  late final Animation<double> _anim3;

  @override
  void initState() {
    super.initState();

    // Bar 1: 480ms cycle, height range 3-12dp
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _anim1 = Tween<double>(begin: 3.0, end: 12.0).animate(
      CurvedAnimation(parent: _controller1, curve: Curves.easeInOutSine),
    );

    // Bar 2: 620ms cycle, height range 5-15dp
    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _anim2 = Tween<double>(begin: 5.0, end: 15.0).animate(
      CurvedAnimation(parent: _controller2, curve: Curves.easeInOutCubic),
    );

    // Bar 3: 530ms cycle, height range 4-13dp
    _controller3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    );
    _anim3 = Tween<double>(begin: 4.0, end: 13.0).animate(
      CurvedAnimation(parent: _controller3, curve: Curves.easeInOutQuad),
    );

    if (widget.isPlaying) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    _controller1.repeat(reverse: true);
    _controller2.repeat(reverse: true);
    _controller3.repeat(reverse: true);
  }

  void _stopAnimations() {
    _controller1.stop();
    _controller2.stop();
    _controller3.stop();
  }

  @override
  void didUpdateWidget(covariant _AnimatedEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 15,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedBuilder(
            animation: _anim1,
            builder: (context, _) => _buildBar(_anim1.value),
          ),
          AnimatedBuilder(
            animation: _anim2,
            builder: (context, _) => _buildBar(_anim2.value),
          ),
          AnimatedBuilder(
            animation: _anim3,
            builder: (context, _) => _buildBar(_anim3.value),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 3.0,
      height: widget.isPlaying ? height : 8.0,
      decoration: BoxDecoration(
        color: const Color(0xFF1DB954),
        borderRadius: BorderRadius.circular(1.0),
      ),
    );
  }
}
