import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/content_item.dart';

/// Reusable circle card for artists.
/// Shows: circle artwork → name → "Artist" label.
class ArtistCircleCard extends StatelessWidget {
  final ContentItem item;
  final double size;

  const ArtistCircleCard({
    super.key,
    required this.item,
    this.size = 170,
  });

  @override
  Widget build(BuildContext context) {
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
                color: const Color(0xFF1E293B),
                image: item.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(item.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item.imageUrl == null
                  ? Icon(Icons.person, color: Colors.grey.shade700, size: 40)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
