library;

import 'package:flutter/material.dart';
import '../../../../core/ui/icons/spotify_encore_icons.dart';
import '../../domain/models/playlist_metadata.dart';

/// 1:1 replica of Spotify's Editorial / Curated Playlist Header
/// (`image_header_content.xml`, `MetadataRow.java`, `R.layout.image_header_content`).
///
/// Layout hierarchy:
/// 1. Top full-width Find in playlist search bar (scrolls away first)
/// 2. Full-bleed artwork canvas with downward ambient gradient overlay fading into #121212
/// 3. Large bold TitleLarge typography (32sp, weight 900)
/// 4. Editorial description line (e.g. "The hottest 50. Cover: Tate McRae")
/// 5. Spotify creator row: Official circular Spotify icon (24x24) + bold "Spotify" label + verified badge
/// 6. Telemetry line: Formatted aggregate saves counter + total duration (e.g. "33,669,702 saves • 2h 48min")
class PlaylistEditorialHeader extends StatelessWidget {
  final PlaylistMetadata metadata;
  final int trackCount;
  final double scrollOffset;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  const PlaylistEditorialHeader({
    super.key,
    required this.metadata,
    required this.trackCount,
    required this.scrollOffset,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    // Parallax motion matching Spotify b7r.java
    final scrollProgress = (scrollOffset / 240.0).clamp(0.0, 1.0);
    final artworkOpacity = (1.0 - (scrollProgress * 0.75)).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // 1. Top Search Bar: "Find in playlist" (`find_in_context_edit_text_playlist_hint`)
          Container(
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Find in playlist',
                      hintStyle: TextStyle(
                        color: Color(0xFFB3B3B3),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchController,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return SizedBox(
                      width: 36,
                      height: 38,
                      child: IconButton(
                        icon: SpotifyIcon.clear(
                          color: const Color(0xFFB3B3B3),
                          size: 16,
                        ),
                        onPressed: () {
                          searchController.clear();
                          onClearSearch();
                        },
                        padding: EdgeInsets.zero,
                        tooltip: 'Clear search',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Full-Bleed Artwork Banner Container (image_header_content.xml)
          Opacity(
            opacity: artworkOpacity,
            child: Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x73000000),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: metadata.picture.isNotEmpty
                  ? Image.network(
                      metadata.picture,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderCover(),
                    )
                  : _buildPlaceholderCover(),
            ),
          ),
          const SizedBox(height: 18),

          // 3. Editorial Playlist Title (TitleLarge, 32sp, Extra Bold 900)
          Text(
            metadata.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              height: 1.12,
            ),
          ),

          // 4. Long-form Editorial Description Subtitle
          if (metadata.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              metadata.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFB3B3B3),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.35,
                letterSpacing: -0.1,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // 5. Official Spotify Creator Attribution Row (Circular Spotify Icon + Label + Verified Badge)
          Row(
            children: [
              SpotifyIcon.spotifyLogo(
                color: const Color(0xFF1DB954),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Spotify',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 4),
              SpotifyIcon.verifiedCheck(
                color: const Color(0xFF1DB954),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 6. Aggregate Social Telemetry Line (Encore MetadataRow: formatted saves count + duration)
          Text(
            _buildTelemetryString(),
            style: const TextStyle(
              color: Color(0xFFB3B3B3),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Center(
      child: SpotifyIcon.track(
        size: 72,
        color: const Color(0xFF535353),
      ),
    );
  }

  String _buildTelemetryString() {
    final parts = <String>[];

    if (metadata.followersCount > 0) {
      parts.add('${_formatCount(metadata.followersCount)} saves');
    }

    if (metadata.totalDurationMs > 0) {
      parts.add(_formatDuration(metadata.totalDurationMs));
    } else if (trackCount > 0) {
      parts.add('$trackCount ${trackCount == 1 ? 'song' : 'songs'}');
    }

    return parts.join(' • ');
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      final val = (count / 1000000).toStringAsFixed(1);
      return val.endsWith('.0') ? '${val.substring(0, val.length - 2)}M' : '${val}M';
    }
    if (count >= 1000) {
      final val = (count / 1000).toStringAsFixed(1);
      return val.endsWith('.0') ? '${val.substring(0, val.length - 2)}K' : '${val}K';
    }
    return count.toString();
  }

  String _formatDuration(int ms) {
    final totalSeconds = ms ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours hr $minutes min';
    }
    return '$minutes min';
  }
}
