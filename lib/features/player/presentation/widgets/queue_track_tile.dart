import 'package:flutter/material.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';

import 'player_artwork.dart';
import 'player_theme.dart';

class QueueTrackTile extends StatelessWidget {
  const QueueTrackTile({
    super.key,
    required this.title,
    required this.artist,
    this.duration,
    this.imageUrl,
    this.songId,
    required this.index,
    required this.onTap,
  });

  final String title;
  final String artist;
  final Duration? duration;
  final String? imageUrl;
  final int? songId;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: PlayerColors.accent.withValues(alpha: 0.06),
          highlightColor: PlayerColors.accent.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: PlayerArtworkImage(
                      songId: songId,
                      imageUrl: imageUrl,
                      artworkWidth: 44,
                      artworkHeight: 44,
                      placeholderIconSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isNotEmpty ? title : 'Unknown Track',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PlayerColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        artist.isNotEmpty ? artist : 'Unknown Artist',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PlayerColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (duration != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    DurationFormatter.duration(duration!),
                    style: const TextStyle(
                      color: PlayerColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                ReorderableDragStartListener(
                  index: index - 1,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: PlayerColors.muted,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
