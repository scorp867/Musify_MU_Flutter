import 'package:flutter/material.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/element/data_pool_entities_builder.dart';
import 'package:musify_mu/core/widgets/app_network_image.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/artist_v4.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/concert_location_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/concert_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/identity_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/image_size.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/visual_identity_trait.dart';

/// Spotify-identical On Tour / Live Events card
/// (`ScrollCardType.ON_TOUR` / `on_tour_event_card_layout.xml`).
///
/// Reactively observes both [concertUris] (`ConcertTrait`, `ConcertLocationTrait`)
/// and [artistUri] (`IdentityTrait`, `ArtistV4`, `VisualIdentityTrait`) in [DataPool].
class PlayerEventsSection extends StatelessWidget {
  const PlayerEventsSection({
    super.key,
    required this.artistName,
    this.bannerImageUrl,
    this.dataPool,
    this.artistUri,
    this.concertUris = const [],
    this.onFindTickets,
    this.onShowAll,
  });

  final String artistName;
  final String? bannerImageUrl;
  final DataPool? dataPool;
  final String? artistUri;
  final List<String> concertUris;
  final VoidCallback? onFindTickets;
  final VoidCallback? onShowAll;

  List<String> _watchedUris() {
    final uris = <String>[];
    if (artistUri case final uri? when uri.isNotEmpty) {
      uris.add(uri);
    }
    for (final uri in concertUris) {
      if (uri.isNotEmpty) {
        uris.add(uri);
      }
    }
    return uris;
  }

  @override
  Widget build(BuildContext context) {
    return DataPoolEntitiesBuilder(
      dataPool: dataPool,
      uris: _watchedUris(),
      builder: (context, pool) {
        ConcertTrait? concert;
        ConcertLocationTrait? location;
        String? resolvedBanner = bannerImageUrl;
        String resolvedArtist = artistName;

        if (pool case final activePool?) {
          for (final concertUri in concertUris) {
            if (concertUri.isEmpty) continue;
            final candidateConcert =
                activePool.getTrait<ConcertTrait>(concertUri);
            final candidateLocation =
                activePool.getTrait<ConcertLocationTrait>(concertUri);
            if (concert == null &&
                candidateConcert != null &&
                (candidateConcert.title.isNotEmpty ||
                    candidateConcert.artistName.isNotEmpty ||
                    candidateConcert.eventDateTimestamp > 0)) {
              concert = candidateConcert;
            }
            if (location == null &&
                candidateLocation != null &&
                (candidateLocation.venue.isNotEmpty ||
                    candidateLocation.city.isNotEmpty)) {
              location = candidateLocation;
            }
            if (concert != null && location != null) {
              break;
            }
          }

          if (artistUri case final aUri? when aUri.isNotEmpty) {
            final identity = activePool.getTrait<IdentityTrait>(aUri);
            final artistV4 = activePool.getTrait<ArtistV4>(aUri);
            final visual = activePool.getTrait<VisualIdentityTrait>(aUri);

            if (identity != null && identity.name.isNotEmpty) {
              resolvedArtist = identity.name;
            } else if (artistV4 != null && artistV4.name.isNotEmpty) {
              resolvedArtist = artistV4.name;
            }

            if (resolvedBanner == null || resolvedBanner.isEmpty) {
              if (visual?.wideFullBleedUrl case final url?
                  when url.isNotEmpty) {
                resolvedBanner = url;
              } else if (visual?.sixteenByNineCoverUrl case final url?
                  when url.isNotEmpty) {
                resolvedBanner = url;
              } else if (visual?.squareCoverUrl case final url?
                  when url.isNotEmpty) {
                resolvedBanner = url;
              } else if (artistV4?.portrait.urlForSize(ImageSize.large)
                  case final url? when url.isNotEmpty) {
                resolvedBanner = url;
              }
            }
          }
        }

        final title = switch (concert?.title) {
          final t? when t.isNotEmpty => t,
          _ => 'On Tour',
        };
        final displayArtist = switch (concert?.artistName) {
          final a? when a.isNotEmpty => a,
          _ => resolvedArtist,
        };
        final subtitle1 = switch (concert) {
          final c? when c.eventDateTimestamp > 0 =>
            _formatEventDate(c.eventDateTimestamp),
          _ => 'Upcoming Tour Dates',
        };
        final subtitle2 = _formatLocation(location);

        return _buildCard(
          title: title,
          artist: displayArtist,
          subtitle1: subtitle1,
          subtitle2: subtitle2,
          effectiveBannerUrl: resolvedBanner,
        );
      },
    );
  }

  static String _formatLocation(ConcertLocationTrait? location) {
    if (location == null) {
      return 'Find concert dates and venues near you';
    }
    final parts = <String>[
      if (location.venue.isNotEmpty) location.venue,
      if (location.city.isNotEmpty) location.city,
    ];
    if (parts.isEmpty) {
      return 'Find concert dates and venues near you';
    }
    return parts.join(' \u00B7 ');
  }

  Widget _buildCard({
    required String title,
    required String artist,
    required String subtitle1,
    required String subtitle2,
    required String? effectiveBannerUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Artwork / Banner with title overlay (on_tour_event_card_layout.xml)
          AspectRatio(
            aspectRatio: 3 / 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (effectiveBannerUrl case final url? when url.isNotEmpty)
                  AppNetworkImage(
                    imageUrl: url,
                    width: double.infinity,
                    height: double.infinity,
                    memCacheWidth: 720,
                    memCacheHeight: 480,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    placeholder: (_, _) => _buildBannerPlaceholder(),
                    errorWidget: (_, _, _) => _buildBannerPlaceholder(),
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
    return '${months[date.month - 1]} ${date.day} \u00B7 Live Tour';
  }
}
