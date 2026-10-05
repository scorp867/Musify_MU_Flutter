import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Compact inline card, type-driven content.
/// Used for inlineCard (tag 34).
class InlineCardSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const InlineCardSection({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: Colors.white.withValues(alpha: 0.06),
          height: 72,
          child: Row(
            children: [
              if (imageUrl != null)
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 72,
                  height: 72,
                  color: Colors.white.withValues(alpha: 0.04),
                  child: const Icon(Icons.library_music, color: Colors.white24, size: 28),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (displayTitle.isNotEmpty)
                        Text(
                          displayTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
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
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
