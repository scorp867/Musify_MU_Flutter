library;

import 'package:flutter/material.dart';
import '../../domain/models/playlist_item.dart';

/// 1:1 replica of Spotify's Encore track row component (`zpq0.java`, `dg80.java`).
/// Implements 48x48 cover art, active track green typography (#1DB954), explicit "E" badge,
/// and Spotify 3-bar equalizer telemetry indicator.
class PlaylistTrackTile extends StatelessWidget {
  final PlaylistItem item;
  final bool isActiveTrack;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onMoreTapped;

  const PlaylistTrackTile({
    super.key,
    required this.item,
    required this.isActiveTrack,
    required this.isPlaying,
    required this.onTap,
    required this.onMoreTapped,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isActiveTrack ? const Color(0xFF1DB954) : Colors.white;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // 1. Track Artwork (48x48 rounded 4px)
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
                          _buildPlaceholderCover(),
                    )
                  : _buildPlaceholderCover(),
            ),
            const SizedBox(width: 12),

            // 2. Metadata Column (Title, Artists, Explicit Badge, Equalizer)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Active Playing Equalizer Indicator
                      if (isActiveTrack && isPlaying) ...[
                        const Icon(
                          Icons.equalizer,
                          color: Color(0xFF1DB954),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
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
                      // Explicit "E" Badge (Encore 9sp Bold, Gray background)
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

  Widget _buildPlaceholderCover() {
    return const Center(
      child: Icon(
        Icons.music_note,
        size: 24,
        color: Color(0xFF535353),
      ),
    );
  }
}
