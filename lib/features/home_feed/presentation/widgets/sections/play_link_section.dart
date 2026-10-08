import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Play link promo section — compact 1-tap playback bar.
/// Corresponds to Casita's playLinkPromo (tag 35).
class PlayLinkSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const PlayLinkSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final item = items.first;

    final displayTitle = item.cardTitle.isNotEmpty ? item.cardTitle : 'Jump back in';
    final subtitle = item.getTrait<SimpleCardTrait>()?.subtitle ?? '';
    final imageUrl = item.cardImageUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 104,
                    memCacheHeight: 104,
                    errorWidget: (_, _, _) => Container(
                      color: const Color(0xFF2C2C2C),
                      child: Icon(Icons.play_circle_fill_rounded,
                          color: Colors.grey.shade600, size: 28),
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title.isNotEmpty ? title : 'Jump back in',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.black,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
