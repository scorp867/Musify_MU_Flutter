import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/cards/artist_circle_card.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/cards/square_card.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/cards/preview_card.dart';

/// Standard content carousel — large cards for albums, playlists, etc.
/// Matches Spotify's main feed sections (~170px cards).
class ContentCarouselSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const ContentCarouselSection({
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
        // Section title
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
        // Horizontal card list
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              
              final previewTrait = item.getTrait<PreviewCardTrait>();
              if (previewTrait != null) {
                return PreviewCard(item: item, trait: previewTrait);
              }
              
              if (item.type == ContentType.artist) {
                return ArtistCircleCard(item: item);
              }
              return SquareCard(item: item);
            },
          ),
        ),
      ],
    );
  }
}
