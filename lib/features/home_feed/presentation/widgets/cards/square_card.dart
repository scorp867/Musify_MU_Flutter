import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Reusable square card for albums, playlists, podcasts.
/// Renders: artwork + title + subtitle (no type labels -- Spotify doesn't show those).
/// Used in ContentCarouselSection.
class SquareCard extends StatelessWidget {
  final SpotifyEntity item;
  final double size;

  const SquareCard({
    super.key,
    required this.item,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    final title = item.cardTitle;
    final subtitle = item.getTrait<SimpleCardTrait>()?.subtitle ?? '';
    final imageUrl = item.cardImageUrl;

    return SizedBox(
      width: size,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: size,
              height: size,
              color: const Color(0xFF282828),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Subtitle (artist/description)
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
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
