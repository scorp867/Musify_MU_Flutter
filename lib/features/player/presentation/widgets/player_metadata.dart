import 'package:flutter/material.dart';

class PlayerMetadata extends StatelessWidget {
  const PlayerMetadata({
    super.key,
    this.title = 'Starboy',
    this.artist = 'The Weeknd, Daft Punk',
    required this.isFavorite,
    required this.onFavoriteChanged,
  });

  final String title;
  final String artist;
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
                title.isEmpty ? 'Unknown Track' : title,
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
                artist.isNotEmpty ? artist : 'Unknown Artist',
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
