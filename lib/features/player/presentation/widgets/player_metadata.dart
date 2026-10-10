import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.title.isEmpty ? 'Unknown Track' : item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.artist?.isNotEmpty == true
                    ? item.artist!
                    : 'Unknown Artist',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFB3B3B3),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? const Color(0xFF1ED760) : Colors.white70,
            size: 26,
          ),
          tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          onPressed: onFavoriteChanged,
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      ],
    );
  }
}
