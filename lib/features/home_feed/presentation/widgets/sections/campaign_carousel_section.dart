import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Campaign link carousel — 16:9 editorial banners with typography.
/// Corresponds to Casita's campaignLinkCarousel (tag 23).
class CampaignCarouselSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const CampaignCarouselSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
        SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return _CampaignCardTile(item: items[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _CampaignCardTile extends StatelessWidget {
  final SpotifyEntity item;

  const _CampaignCardTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item.cardTitle;
    final subtitle = item.getTrait<SimpleCardTrait>()?.subtitle ?? '';
    final imageUrl = item.cardImageUrl;

    return SizedBox(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: const Color(0xFF282828),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 500,
                        memCacheHeight: 280,
                        errorWidget: (_, _, _) => Center(
                          child: Icon(Icons.campaign_rounded,
                              color: Colors.grey.shade600, size: 32),
                        ),
                      )
                    : Center(
                        child: Icon(Icons.campaign_rounded,
                            color: Colors.grey.shade600, size: 32),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (title.isNotEmpty)
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
