library;

import 'package:flutter/material.dart';

/// 1:1 replica of Spotify's collapsing toolbar header (`image_header_content.xml` & `b7r.java`).
/// Replicates the 0.70 fade threshold (`image_header_toolbar_fade_range`), mini play button,
/// and Spotify Encore typography and icons.
class PlaylistAppBar extends StatelessWidget {
  final String title;
  final double scrollOffset;
  final double headerHeight;
  final Color dominantColor;
  final bool isPlaying;
  final VoidCallback onBackTapped;
  final VoidCallback onPlayTapped;
  final VoidCallback onSearchTapped;
  final VoidCallback onMoreTapped;

  const PlaylistAppBar({
    super.key,
    required this.title,
    required this.scrollOffset,
    required this.headerHeight,
    required this.dominantColor,
    required this.isPlaying,
    required this.onBackTapped,
    required this.onPlayTapped,
    required this.onSearchTapped,
    required this.onMoreTapped,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final totalBarHeight = kToolbarHeight + topPadding;

    // 1:1 Parallax calculation matching Spotify b7r.java and image_header_toolbar_fade_range = 0.70
    // Toolbar background alpha starts fading in smoothly from 0.0 to 1.0 as scroll progresses
    final collapseProgress = (scrollOffset / headerHeight).clamp(0.0, 1.0);
    
    // Title alpha remains strictly 0.0 until scrollOffset passes 70% of headerHeight
    final titleAlpha = scrollOffset <= (headerHeight * 0.70)
        ? 0.0
        : ((scrollOffset - (headerHeight * 0.70)) / (headerHeight * 0.30)).clamp(0.0, 1.0);

    // Mini Play button appears when the main play FAB scrolls out of view (~320dp)
    final showMiniPlay = scrollOffset > (headerHeight * 0.95);
    final miniPlayAlpha = scrollOffset <= (headerHeight * 0.85)
        ? 0.0
        : ((scrollOffset - (headerHeight * 0.85)) / (headerHeight * 0.15)).clamp(0.0, 1.0);

    // Spotify blends the dominant header color into dark gray #121212 when collapsed
    final effectiveBgColor = Color.alphaBlend(
      dominantColor.withValues(alpha: collapseProgress * 0.7),
      const Color(0xFF121212).withValues(alpha: collapseProgress),
    );

    return Container(
      height: totalBarHeight,
      padding: EdgeInsets.only(top: topPadding),
      decoration: BoxDecoration(
        color: effectiveBgColor,
        border: collapseProgress >= 0.98
            ? const Border(
                bottom: BorderSide(
                  color: Color(0xFF282828),
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: NavigationToolbar(
        leading: SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
            onPressed: onBackTapped,
            tooltip: 'Back',
            padding: EdgeInsets.zero,
          ),
        ),
        middle: Opacity(
          opacity: titleAlpha,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mini Circular Green Play Button (Encore 32dp play button from b7r.java)
            if (showMiniPlay)
              Opacity(
                opacity: miniPlayAlpha,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Material(
                    color: const Color(0xFF1DB954),
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onPlayTapped,
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: Center(
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Search Icon
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: onSearchTapped,
                tooltip: 'Find in playlist',
                padding: EdgeInsets.zero,
              ),
            ),

            // More Options Icon
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: onMoreTapped,
                tooltip: 'More options',
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
