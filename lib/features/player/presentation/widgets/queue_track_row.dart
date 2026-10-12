import 'package:flutter/material.dart';
import 'package:musify_mu/core/ui/icons/spotify_encore_icons.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';

import 'player_artwork.dart';
import 'player_theme.dart';

/// 1:1 with Spotify's layout_default_track_row.xml
///
/// Structure (from XML & screenshots):
///   ConstraintLayout (track_row_queue_root, height=64dp)
///     ArtworkView (48x48, 4dp radius, marginStart=16dp, marginEnd=12dp)
///     Title (BodyMedium, white)
///     Subtitle Row:
///       [QueuedBadgeView (13dp green queue badge, marginEnd=4dp) when track.isQueued]
///       ArtistName (BodySmall, #B3B3B3)
///     DragHandle (encore_icon_sort, marginEnd=8dp)
class QueueTrackRow extends StatelessWidget {
  const QueueTrackRow({
    super.key,
    required this.track,
    required this.index,
    required this.onTap,
    required this.onRemove,
    required this.onAddToQueue,
    this.showDragHandle = true,
  });

  final ContextTrack track;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onAddToQueue;
  final bool showDragHandle;

  static const Color _negativeRed = Color(0xFFE22134);
  static const Color _positiveGreen = Color(0xFF1ED760);

  @override
  Widget build(BuildContext context) {
    final mediaItem = track.toMediaItem();

    return Dismissible(
      key: ValueKey('dismiss_${track.uid}'),
      direction: DismissDirection.horizontal,
      movementDuration: const Duration(milliseconds: 220),
      resizeDuration: const Duration(milliseconds: 200),
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.30,
        DismissDirection.endToStart: 0.35,
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Let Dismissible finish its smooth slide-out & collapse animation
          // before removing from state in onDismissed.
          return true;
        } else {
          onAddToQueue();
          return false;
        }
      },
      onDismissed: (_) {
        onRemove();
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: _positiveGreen,
        child: SpotifyIcon.addToQueue(color: Colors.white, size: 24),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: _negativeRed,
        child: SpotifyIcon.delete(color: Colors.white, size: 24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.06),
          highlightColor: Colors.white.withValues(alpha: 0.03),
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        // 48x48 Artwork with 4dp corners
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: PlayerArtworkImage(
                              item: mediaItem,
                              artworkWidth: 48,
                              artworkHeight: 48,
                              placeholderIconSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title + Subtitle (with animated QueuedBadgeView)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title.isNotEmpty
                                      ? track.title
                                      : 'Unknown Track',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    // QueuedBadgeView (@+id/queued_badge in layout_default_track_row.xml)
                                    AnimatedSize(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      curve: Curves.easeOutCubic,
                                      child: track.isQueued
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                right: 5,
                                              ),
                                              child: SpotifyIcon.queueBadge(
                                                color: PlayerColors.accent,
                                                size: 13,
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    Expanded(
                                      child: Text(
                                        track.artist.isNotEmpty
                                            ? track.artist
                                            : 'Unknown Artist',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: PlayerColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Drag handle (encore_icon_sort, marginEnd=8dp)
                if (showDragHandle)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ReorderableDragStartListener(
                      index: index,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.transparent,
                        child: SpotifyIcon.sort(
                          color: Colors.white.withValues(alpha: 0.75),
                          size: 20,
                        ),
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
