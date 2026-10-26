library;

import 'package:flutter/material.dart';
import '../../domain/models/playlist_metadata.dart';

/// 1:1 replica of Spotify's playlist header content
/// (`zh31.java` line 1314, `header_layout.xml`, `image_header_content.xml`).
///
/// Layout hierarchy:
/// 1. Top full-width Find in playlist search bar (scrolls away first)
/// 2. Centered album artwork with scroll scale-down and fade motion
/// 3. Playlist title (left-aligned, 24sp, extra bold)
/// 4. Owner avatar and name row with add collaborator (+) button
/// 5. Metadata telemetry line (duration / song count)
class PlaylistHeaderContent extends StatelessWidget {
  final PlaylistMetadata metadata;
  final int trackCount;
  final double scrollOffset;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onAddCollaboratorTapped;

  const PlaylistHeaderContent({
    super.key,
    required this.metadata,
    required this.trackCount,
    required this.scrollOffset,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onAddCollaboratorTapped,
  });

  @override
  Widget build(BuildContext context) {
    // Parallax & scale progress: from 0.0 (top) to 1.0 (scrolled 200dp)
    final scrollProgress = (scrollOffset / 200.0).clamp(0.0, 1.0);
    final artworkScale = (1.0 - (scrollProgress * 0.25)).clamp(0.75, 1.0);
    final artworkOpacity = (1.0 - (scrollProgress * 0.85)).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // 1. Top Search Bar: "Find in playlist" (`find_in_context_edit_text_playlist_hint`)
          // Positioned at the very top of header content, scrolling offscreen first
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF), // dark_base_background_tinted_base (10% white)
              borderRadius: BorderRadius.circular(4), // find_in_context_background
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 10.0, right: 8.0),
                  child: Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    cursorColor: const Color(0xFF1DB954), // text_cursor_green
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
                        icon: const Icon(
                          Icons.clear,
                          color: Color(0xFFB3B3B3),
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
          const SizedBox(height: 20),

          // 2. Centered Album Artwork with Scroll Scale-Down and Fade Motion
          Center(
            child: Transform.scale(
              scale: artworkScale,
              child: Opacity(
                opacity: artworkOpacity,
                child: Container(
                  width: 216,
                  height: 216,
                  decoration: BoxDecoration(
                    color: const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x73000000),
                        blurRadius: 28,
                        spreadRadius: 2,
                        offset: Offset(0, 14),
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
            ),
          ),
          const SizedBox(height: 16),

          // 3. Playlist Title (Left-aligned, 24sp, Extra Bold)
          Text(
            metadata.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),

          // 4. Description (Subdued)
          if (metadata.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              metadata.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFB3B3B3),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.35,
                letterSpacing: -0.1,
              ),
            ),
          ],
          const SizedBox(height: 10),

          // 5. Owner Avatar, Collaborator (+) Icon, and Owner Name
          Row(
            children: [
              // Add collaborator button (+)
              InkWell(
                onTap: onAddCollaboratorTapped,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x33FFFFFF),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Owner Avatar
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF333333),
                ),
                clipBehavior: Clip.antiAlias,
                child: metadata.ownerAvatarUrl.isNotEmpty
                    ? Image.network(
                        metadata.ownerAvatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.person,
                          size: 15,
                          color: Colors.white70,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 15,
                        color: Colors.white70,
                      ),
              ),
              const SizedBox(width: 8),

              // Owner Name
              Text(
                metadata.ownerName.isNotEmpty
                    ? metadata.ownerName
                    : (metadata.ownerUsername.isNotEmpty
                        ? metadata.ownerUsername
                        : 'Spotify'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 6. Metadata Telemetry Line (Globe icon + duration / saves)
          Row(
            children: [
              const Icon(
                Icons.language,
                color: Color(0xFFB3B3B3),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                _buildTelemetryString(),
                style: const TextStyle(
                  color: Color(0xFFB3B3B3),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return const Center(
      child: Icon(
        Icons.music_note,
        size: 72,
        color: Color(0xFF535353),
      ),
    );
  }

  String _buildTelemetryString() {
    final parts = <String>[];

    if (metadata.totalDurationMs > 0) {
      parts.add(_formatDuration(metadata.totalDurationMs));
    }

    if (trackCount > 0) {
      parts.add('$trackCount ${trackCount == 1 ? 'song' : 'songs'}');
    }

    if (metadata.followersCount > 0) {
      parts.add('${_formatCount(metadata.followersCount)} saves');
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
