import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/content_item.dart';

/// Reusable square card for albums, playlists, podcasts.
/// Shows: artwork → type label → title → subtitle.
/// Used in ContentCarouselSection.
class SquareCard extends StatelessWidget {
  final ContentItem item;
  final double size;
  final bool showTypeLabel;

  const SquareCard({
    super.key,
    required this.item,
    this.size = 170,
    this.showTypeLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: size,
              height: size,
              color: const Color(0xFF1E293B),
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(height: 8),
          // Type label (Album, Playlist, etc.)
          if (showTypeLabel)
            Text(
              _typeLabel,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          // Title
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Subtitle (artist/description)
          if (item.subtitle.isNotEmpty)
            Text(
              item.subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                height: 1.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  String get _typeLabel {
    return switch (item.type) {
      ContentType.album => 'Album',
      ContentType.playlist => 'Playlist',
      ContentType.podcast => 'Podcast',
      ContentType.episode => 'Episode',
      ContentType.artist => 'Artist',
      _ => '',
    };
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        Icons.music_note_rounded,
        color: Colors.grey.shade700,
        size: 32,
      ),
    );
  }
}
