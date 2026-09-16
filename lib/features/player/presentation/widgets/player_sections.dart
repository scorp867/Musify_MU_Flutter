import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';

import 'player_theme.dart';

class PlayerLyricsSection extends StatelessWidget {
  const PlayerLyricsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: playerPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PlayerSectionHeader(
            icon: Icons.lyrics_outlined,
            title: 'Lyrics',
          ),
          const SizedBox(height: 18),
          const Text(
            "Lyrics aren't available for this track yet.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enjoy the music and check back later for lyrics.',
            style: TextStyle(
              color: PlayerColors.muted.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerTrackDetailsSection extends StatelessWidget {
  const PlayerTrackDetailsSection({super.key, required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: playerPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PlayerSectionHeader(
            icon: Icons.info_outline_rounded,
            title: 'Track details',
          ),
          const SizedBox(height: 18),
          PlayerDetailRow(
            label: 'Artist',
            value: item.artist?.isNotEmpty == true
                ? item.artist!
                : 'Unknown Artist',
          ),
          if (item.album?.isNotEmpty == true)
            PlayerDetailRow(label: 'Album', value: item.album!),
          if (item.duration != null)
            PlayerDetailRow(
              label: 'Duration',
              value: _formatDuration(item.duration!),
            ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    return DurationFormatter.duration(duration);
  }
}

class PlayerSectionHeader extends StatelessWidget {
  const PlayerSectionHeader({
    super.key,
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: PlayerColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: PlayerColors.accent, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class PlayerDetailRow extends StatelessWidget {
  const PlayerDetailRow({super.key, required this.label, required this.value});

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
