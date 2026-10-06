import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/cards/preview_card.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/video_carousel_section.dart';

/// Preview feed section -- vertical stack of full-width preview cards.
/// Maps to Casita sections that contain Preview or ImmersivePreview.
/// Spotify shows these as full-width cards with 12px vertical spacing.
class PreviewFeedSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const PreviewFeedSection({
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
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                Builder(builder: (context) {
                  final item = items[i];

                  // 1. If entity has a video trait, render a video preview card
                  final videoTrait = item.getTrait<VideoCardTrait>();
                  if (videoTrait != null) {
                    return VideoPreviewCard(entity: item);
                  }

                  // 2. Otherwise render preview card with PreviewCardTrait (or synthesized fallback)
                  final fallbackTitle = item.previewTitle.isNotEmpty
                      ? item.previewTitle
                      : (item.cardTitle.isNotEmpty ? item.cardTitle : title);
                  final previewTrait = item.getTrait<PreviewCardTrait>() ??
                      PreviewCardTrait(
                        title: fallbackTitle,
                        description: item.getTrait<SimpleCardTrait>()?.subtitle ?? '',
                        imageUrl: item.cardImageUrl ?? item.previewImageUrl ?? '',
                        backgroundColor: item.backgroundColorHex,
                      );

                  return PreviewCard(item: item, trait: previewTrait);
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
