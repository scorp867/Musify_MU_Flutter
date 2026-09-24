import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/cards/preview_card.dart';

/// Preview feed section -- vertical stack of full-width preview cards.
/// Maps to Casita sections that contain PreviewCardTrait items.
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
                  final previewTrait = item.getTrait<PreviewCardTrait>();
                  if (previewTrait != null) {
                    return PreviewCard(item: item, trait: previewTrait);
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
