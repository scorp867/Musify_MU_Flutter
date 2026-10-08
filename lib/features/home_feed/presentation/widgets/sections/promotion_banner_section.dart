import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Promotion banner / "Picked for you" section matching Spotify's exact horizontal card layout:
///   ┌──────────────────────────────────────────────────┐
///   │  ┌─────────┐   Playlist                       ⋮  │
///   │  │ [Image] │   Deep Sleep                        │
///   │  │         │   Soothing, minimalist ambient...   │
///   │  └─────────┘   ⊕                              ▶  │
///   └──────────────────────────────────────────────────┘
class PromotionBannerSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const PromotionBannerSection({
    super.key,
    required this.title,
    required this.items,
  });

  String _contentTypeLabel(SpotifyEntity item) {
    final preview = item.getTrait<PreviewCardTrait>();
    if (preview != null && preview.contentTypeName.isNotEmpty) {
      return preview.contentTypeName;
    }
    return switch (item.type) {
      ContentType.playlist => 'Playlist',
      ContentType.album => 'Album',
      ContentType.podcast => 'Podcast',
      ContentType.episode => 'Episode',
      ContentType.artist => 'Artist',
      ContentType.track => 'Song',
      ContentType.unknown => 'Playlist',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final item = items.first;

    final displayTitle = item.cardTitle.isNotEmpty ? item.cardTitle : item.previewTitle;
    final subtitle = item.getTrait<SimpleCardTrait>()?.subtitle
        ?? item.getTrait<PreviewCardTrait>()?.description
        ?? '';
    final imageUrl = item.cardImageUrl;
    final typeLabel = _contentTypeLabel(item);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          Container(
            height: 132,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF242424),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left: Square cover image
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 240,
                            memCacheHeight: 240,
                            errorWidget: (_, _, _) => Container(
                              color: const Color(0xFF1E1E1E),
                              child: Icon(Icons.album_rounded,
                                  color: Colors.grey.shade600, size: 36),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF1E1E1E),
                            child: Icon(Icons.album_rounded,
                                color: Colors.grey.shade600, size: 36),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // Right column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top row: Content type + 3-dots more menu
                      Row(
                        children: [
                          Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.more_vert,
                            size: 20,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                      // Middle: Title + Subtitle
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (displayTitle.isNotEmpty)
                            Text(
                              displayTitle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                      // Bottom row: Add button + Play circle
                      Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 24,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          const Spacer(),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
