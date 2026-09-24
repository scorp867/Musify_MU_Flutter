import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/cards/preview_card.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/cards/square_card.dart';

/// Preview carousel section -- horizontal scroll of preview cards.
/// Maps to Casita Section body field 37 (PreviewCarousel).
/// Spotify shows these as wide cards (~310px) in a horizontal list.
class PreviewCarouselSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const PreviewCarouselSection({
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
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final previewTrait = item.getTrait<PreviewCardTrait>();
              if (previewTrait != null) {
                return SizedBox(
                  width: 310,
                  child: PreviewCard(item: item, trait: previewTrait),
                );
              }
              return SquareCard(item: item, size: 150);
            },
          ),
        ),
      ],
    );
  }
}
