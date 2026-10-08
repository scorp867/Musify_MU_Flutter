import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Live event card with date badge overlay.
/// Used for liveEvent (tag 16).
class LiveEventSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const LiveEventSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final item = items.first;
    final simpleTrait = item.getTrait<SimpleCardTrait>();
    final previewTrait = item.getTrait<PreviewCardTrait>();

    final displayTitle = simpleTrait?.title ?? previewTrait?.title ?? '';
    final subtitle = simpleTrait?.subtitle ?? previewTrait?.description ?? '';
    final imageUrl = simpleTrait?.imageUrl ?? previewTrait?.imageUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: const Color(0xFF2A2A2A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Artwork with event badge
                  AspectRatio(
                    aspectRatio: 2 / 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageUrl != null)
                          CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 720,
                            memCacheHeight: 360,
                          )
                        else
                          Container(
                            color: const Color(0xFF333333),
                            child: const Icon(Icons.event, color: Colors.white24, size: 48),
                          ),
                        // Event badge
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, color: Color(0xFF1DB954), size: 8),
                                SizedBox(width: 6),
                                Text(
                                  'LIVE EVENT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Info
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (displayTitle.isNotEmpty)
                          Text(
                            displayTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
