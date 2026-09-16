import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';

import 'player_artwork.dart';
import 'player_header.dart';
import 'player_theme.dart';

class PlayerQueueSheet extends StatelessWidget {
  const PlayerQueueSheet({
    super.key,
    required this.playbackController,
    required this.currentItem,
  });

  final PlaybackController playbackController;
  final MediaItem currentItem;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: StreamBuilder<List<MediaItem>>(
          stream: playbackController.queue,
          builder: (context, snapshot) {
            final queue = snapshot.data ?? const <MediaItem>[];

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PlayerSheetHeader(title: 'Queue'),
                if (queue.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 38, 12, 28),
                    child: Text(
                      'Your playback queue is empty.',
                      style: TextStyle(color: PlayerColors.muted, fontSize: 15),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.55,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: queue.length,
                      separatorBuilder: (_, _) => Divider(
                        color: Colors.white.withValues(alpha: 0.06),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final track = queue[index];
                        final isCurrent = track.id == currentItem.id;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: SizedBox(
                            width: 48,
                            height: 48,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: PlayerArtworkImage(
                                item: track,
                                artworkWidth: 48,
                                artworkHeight: 48,
                                placeholderIconSize: 20,
                              ),
                            ),
                          ),
                          title: Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrent
                                  ? PlayerColors.accent
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            track.artist ?? 'Unknown Artist',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PlayerColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          trailing: isCurrent
                              ? const Icon(
                                  Icons.equalizer_rounded,
                                  color: PlayerColors.accent,
                                )
                              : null,
                          onTap: () {
                            Navigator.pop(context);
                            playbackController.skipToQueueItem(index);
                          },
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PlayerOptionsSheet extends StatelessWidget {
  const PlayerOptionsSheet({
    super.key,
    required this.onShowDetails,
    required this.onShowQueue,
  });

  final VoidCallback onShowDetails;
  final VoidCallback onShowQueue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: const PlayerSheetHeader(title: 'Track options'),
          ),
          ListTile(
            leading: const Icon(
              Icons.info_outline_rounded,
              color: PlayerColors.accent,
            ),
            title: const Text(
              'Track details',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              onShowDetails();
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.queue_music_rounded,
              color: PlayerColors.accent,
            ),
            title: const Text(
              'Open queue',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              onShowQueue();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class PlayerTrackDetailsSheet extends StatelessWidget {
  const PlayerTrackDetailsSheet({super.key, required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PlayerSheetHeader(title: 'Track details'),
            const SizedBox(height: 18),
            PlayerSheetDetailRow(label: 'Title', value: item.title),
            PlayerSheetDetailRow(
              label: 'Artist',
              value: item.artist ?? 'Unknown Artist',
            ),
            PlayerSheetDetailRow(
              label: 'Album',
              value: item.album ?? 'Unknown Album',
            ),
            if (item.duration != null)
              PlayerSheetDetailRow(
                label: 'Duration',
                value: DurationFormatter.duration(item.duration!),
              ),
          ],
        ),
      ),
    );
  }
}

class PlayerSheetHeader extends StatelessWidget {
  const PlayerSheetHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            PlayerCircleButton(
              icon: Icons.close_rounded,
              tooltip: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ],
    );
  }
}

class PlayerSheetDetailRow extends StatelessWidget {
  const PlayerSheetDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                color: PlayerColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
