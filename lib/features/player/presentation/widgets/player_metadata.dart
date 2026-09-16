import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'player_header.dart';
import 'player_theme.dart';

class PlayerMetadata extends StatelessWidget {
  const PlayerMetadata({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onFavoriteChanged,
  });

  final MediaItem item;
  final bool isFavorite;
  final VoidCallback onFavoriteChanged;

  @override
  Widget build(BuildContext context) {
    final album = item.album;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title.isEmpty ? 'Unknown Track' : item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.artist?.isNotEmpty == true
                    ? item.artist!
                    : 'Unknown Artist',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PlayerColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (album != null && album.trim().isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  album,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlayerColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        PlayerCircleButton(
          icon: isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          iconColor: isFavorite ? Colors.redAccent : Colors.white,
          tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          onPressed: onFavoriteChanged,
        ),
      ],
    );
  }
}
