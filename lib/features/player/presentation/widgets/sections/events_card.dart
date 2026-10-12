import 'package:flutter/material.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/concert_trait.dart';

/// Spotify-identical On Tour / Live Events card
/// (`ScrollCardType.ON_TOUR` / `on_tour_event_card_layout.xml`).
///
/// Features:
/// - 16dp rounded corners (`widgets_corner_radius`)
/// - Elevated base background (#242424)
/// - Top 3:2 banner with gradient scrim (`on_tour_event_card_gradient`)
/// - "On Tour" header + "Show all" tertiary button
/// - Artist name, concert date/venue, and location details
/// - Outline "Find tickets" secondary button (`Encore.Button.Secondary.Small`)
/// - Dual-mode: Binds to [DataPool] [ConcertTrait] when available (online).
class PlayerEventsSection extends StatelessWidget {
  const PlayerEventsSection({
    super.key,
    required this.artistName,
    this.bannerImageUrl,
    this.dataPool,
    this.artistUri,
    this.onFindTickets,
    this.onShowAll,
  });

  final String artistName;
  final String? bannerImageUrl;
  final DataPool? dataPool;
  final String? artistUri;
  final VoidCallback? onFindTickets;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    if (dataPool != null && artistUri != null && artistUri!.isNotEmpty) {
      return StreamBuilder<Map<String, dynamic>>(
        stream: dataPool!.watchEntity(artistUri!),
        initialData: dataPool!.getTraits(artistUri!),
        builder: (context, snapshot) {
          final concert = dataPool!.getTrait<ConcertTrait>(artistUri!);
          return _buildCard(
            title: concert?.title.isNotEmpty == true
                ? concert!.title
                : 'Live Tour',
            artist: concert?.artistName.isNotEmpty == true
                ? concert!.artistName
                : artistName,
            subtitle1: concert != null && concert.eventDateTimestamp > 0
                ? _formatEventDate(concert.eventDateTimestamp)
                : 'Upcoming Tour Dates',
            subtitle2: 'Find concert dates and venues near you',
          );
        },
      );
    }

    return _buildCard(
      title: 'On Tour',
      artist: artistName,
      subtitle1: 'Upcoming Tour Dates',
      subtitle2: 'Find concert dates and venues near you',
    );
  }

  Widget _buildCard({
    required String title,
    required String artist,
    required String subtitle1,
    required String subtitle2,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Artwork / Banner with title overlay (on_tour_event_card_layout.xml)
          AspectRatio(
            aspectRatio: 3 / 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (bannerImageUrl != null && bannerImageUrl!.isNotEmpty)
                  Image.network(
                    bannerImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildBannerPlaceholder(),
                  )
                else
                  _buildBannerPlaceholder(),
                // Gradient scrim
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.70),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (onShowAll != null)
                        InkWell(
                          onTap: onShowAll,
                          borderRadius: BorderRadius.circular(4),
                          child: Text(
                            'Show all',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.70),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 2. Event info and action row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFFB3B3B3).withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: onFindTickets,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white60, width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Find tickets',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerPlaceholder() {
    return Container(
      color: const Color(0xFF2A2A2A),
      child: const Center(
        child: Icon(
          Icons.stadium_rounded,
          color: Colors.white24,
          size: 48,
        ),
      ),
    );
  }

  static String _formatEventDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day} · Live Tour';
  }
}
