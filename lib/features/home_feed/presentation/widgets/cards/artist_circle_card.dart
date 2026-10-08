import 'package:flutter/material.dart';
import 'package:musify_mu/core/widgets/app_network_image.dart';
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
    final title = item.cardTitle;
    final imageUrl = item.cardImageUrl;
    final pixelSize = (size * 2).toInt();

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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF282828),
              ),
              child: ClipOval(
                child: imageUrl != null
                    ? AppNetworkImage(
                        imageUrl: imageUrl,
                        width: size - 10,
                        height: size - 10,
                        fit: BoxFit.cover,
                        memCacheWidth: pixelSize,
                        memCacheHeight: pixelSize,
                        errorWidget: (_, _, _) => Icon(
                          Icons.person,
                          color: Colors.grey.shade700,
                          size: 40,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: Colors.grey.shade700,
                        size: 40,
                      ),
              ),
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
