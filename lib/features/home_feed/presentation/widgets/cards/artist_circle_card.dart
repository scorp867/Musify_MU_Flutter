import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Reusable circle card for artists.
/// Shows: circle artwork + name + "Artist" label -- matches Spotify's layout.
class ArtistCircleCard extends StatelessWidget {
  final SpotifyEntity item;
  final double size;

  const ArtistCircleCard({
    super.key,
    required this.item,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    final title = item.fallbackTitle;
    final imageUrl = item.fallbackImageUrl;

    return SizedBox(
      width: size,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            child: Container(
              width: size - 10,
              height: size - 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF282828),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? Icon(Icons.person, color: Colors.grey.shade700, size: 40)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            'Artist',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
