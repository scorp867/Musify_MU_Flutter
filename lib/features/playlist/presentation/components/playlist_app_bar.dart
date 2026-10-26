library;

import 'package:flutter/material.dart';
import '../../../../core/ui/icons/spotify_encore_icons.dart';

/// 1:1 replica of Spotify's collapsing toolbar header
/// (`header_layout.xml`, `back_button_background.xml`, `b7r.java`, `yz40.java`).
///
/// Features:
/// 1. Back button pinned to the start edge and More options pinned to the end edge.
/// 2. Both buttons enclosed in circular translucent bubbles
///    (`back_button_background.xml`, `opacity_black_30` #4D000000).
/// 3. Bubbles fade out linearly to 0.0 (`((View) y52Var.f282532e).getBackground().setAlpha(...)`, `yz40.java` line 61).
/// 4. Back button slides outward towards the left edge by 8dp (from 14dp to 6dp, `yz40.m95659c`).
/// 5. More options button slides outward towards the right edge by 8dp (from 14dp to 6dp, `yz40.m95659c`).
/// 6. The button icons themselves DO NOT fade away; they remain fully opaque white throughout.
/// 7. Strict 0.70 fade threshold for toolbar title (`image_header_toolbar_fade_range`).
/// 8. In-toolbar FindInContextView mode when searching (`header_layout.xml` line 36).
/// 9. No play button in the top bar (in Spotify, the play FAB is floating and docked below the toolbar via PlayButtonBehavior).
class PlaylistAppBar extends StatelessWidget {
  final String title;
  final double scrollOffset;
  final double headerHeight;
  final Color dominantColor;
  final bool isSearchActive;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback onBackTapped;
  final VoidCallback onSearchTapped;
  final VoidCallback onSearchClosed;
  final VoidCallback onMoreTapped;

  const PlaylistAppBar({
    super.key,
    required this.title,
    required this.scrollOffset,
    required this.headerHeight,
    required this.dominantColor,
    this.isSearchActive = false,
    this.searchController,
    this.searchFocusNode,
    this.onSearchChanged,
    required this.onBackTapped,
    required this.onSearchTapped,
    required this.onSearchClosed,
    required this.onMoreTapped,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final totalBarHeight = kToolbarHeight + topPadding;

    // 1:1 Parallax calculation matching Spotify b7r.java and image_header_toolbar_fade_range = 0.70
    final collapseProgress = (scrollOffset / headerHeight).clamp(0.0, 1.0);

    // Bubble alpha: 1.0 when at top, fades to 0.0 as header collapses (yz40.java line 61)
    final bubbleAlpha = (1.0 - (collapseProgress * 2.0)).clamp(0.0, 1.0);

    // Outward slide translation (8dp matching header_back_button_unified_scroll_offset, yz40.java line 72)
    final slideOffset = collapseProgress * 8.0;

    // Title alpha remains strictly 0.0 until scrollOffset passes 70% of headerHeight
    final titleAlpha = scrollOffset <= (headerHeight * 0.70)
        ? 0.0
        : ((scrollOffset - (headerHeight * 0.70)) / (headerHeight * 0.30)).clamp(0.0, 1.0);

    // Spotify blends the dominant header color into dark gray #121212 when collapsed
    final effectiveBgColor = isSearchActive
        ? const Color(0xFF121212)
        : Color.alphaBlend(
            dominantColor.withValues(alpha: collapseProgress * 0.7),
            const Color(0xFF121212).withValues(alpha: collapseProgress),
          );

    return Container(
      height: totalBarHeight,
      padding: EdgeInsets.only(top: topPadding),
      decoration: BoxDecoration(
        color: effectiveBgColor,
        border: (collapseProgress >= 0.98 || isSearchActive)
            ? const Border(
                bottom: BorderSide(
                  color: Color(0xFF282828),
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: isSearchActive
          ? _buildSearchModeToolbar()
          : _buildStandardToolbar(titleAlpha, bubbleAlpha, slideOffset),
    );
  }

  /// Toolbar during in-context search (FindInContextView replaces middle title)
  Widget _buildSearchModeToolbar() {
    return SizedBox(
      height: kToolbarHeight,
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: SpotifyIcon.arrowLeft(
                color: Colors.white,
                size: 24,
              ),
              onPressed: onSearchClosed,
              tooltip: 'Close search',
              padding: EdgeInsets.zero,
            ),
          ),
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0, right: 8.0),
                    child: SpotifyIcon.search(
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      cursorColor: const Color(0xFF1DB954),
                      autofocus: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Find in playlist',
                        hintStyle: TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                      ),
                      onChanged: onSearchChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: SpotifyIcon.clear(
                color: const Color(0xFFB3B3B3),
                size: 20,
              ),
              onPressed: () {
                searchController?.clear();
                onSearchChanged?.call('');
                onSearchClosed();
              },
              tooltip: 'Clear',
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  /// Standard Collapsing Toolbar with dynamic fading bubbles and outward sliding buttons
  Widget _buildStandardToolbar(
    double titleAlpha,
    double bubbleAlpha,
    double slideOffset,
  ) {
    return SizedBox(
      height: kToolbarHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Centered Title (strictly faded in after 70% collapse threshold)
          Positioned(
            left: 56.0,
            right: 56.0,
            child: Opacity(
              opacity: titleAlpha,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),

          // 2. Back Button pinned to left edge, sliding from 14dp down to 6dp with bubble fade
          Positioned(
            left: (14.0 - slideOffset).clamp(2.0, 14.0),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF000000).withValues(alpha: 0.30 * bubbleAlpha), // back_button_background.xml
              ),
              child: IconButton(
                icon: SpotifyIcon.arrowLeft(
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: onBackTapped,
                tooltip: 'Back',
                padding: EdgeInsets.zero,
              ),
            ),
          ),

          // 3. More Options Button pinned to right edge, sliding from 14dp down to 6dp with bubble fade
          Positioned(
            right: (14.0 - slideOffset).clamp(2.0, 14.0),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF000000).withValues(alpha: 0.30 * bubbleAlpha),
              ),
              child: IconButton(
                icon: SpotifyIcon.more(
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: onMoreTapped,
                tooltip: 'More options',
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
