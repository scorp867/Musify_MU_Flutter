import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/element/kodiak_reactive_card.dart';
import 'package:musify_mu/features/home_feed/data/elements/image_link_card_data_element.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/cards/artist_circle_card.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/cards/square_card.dart';

/// Standard content carousel - large cards for albums, playlists, etc.
/// Matches Spotify's main feed sections (~170px cards).
/// Fetches all items in the section as a single batched request via Kodiak DataPool.
class ContentCarouselSection extends StatefulWidget {
  final String title;
  final List<SpotifyEntity> items;
  final DataPool? dataPool;

  const ContentCarouselSection({
    super.key,
    required this.title,
    required this.items,
    this.dataPool,
  });

  @override
  State<ContentCarouselSection> createState() => _ContentCarouselSectionState();
}

class _ContentCarouselSectionState extends State<ContentCarouselSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchSectionTraits();
  }

  @override
  void didUpdateWidget(covariant ContentCarouselSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _fetchSectionTraits();
    }
  }

  DataPool? _resolvePool() {
    if (widget.dataPool != null) return widget.dataPool;
    try {
      return context.read<DataPool>();
    } catch (_) {
      return null;
    }
  }

  void _fetchSectionTraits() {
    final pool = _resolvePool();
    if (pool == null || widget.items.isEmpty) return;

    final uris = widget.items
        .map((e) => e.uri)
        .where((u) => !u.startsWith('spotify:collection:'))
        .toList();

    if (uris.isNotEmpty) {
      pool.loadBatch(
        uris: uris,
        statement: ImageLinkCardDataElement.statement,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final pool = _resolvePool();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            widget.title,
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
            itemCount: widget.items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = widget.items[index];

              return KodiakReactiveCard(
                item: item,
                dataPool: pool,
                builder: (context, entity) {
                  if (entity.type == ContentType.artist) {
                    return ArtistCircleCard(item: entity);
                  }
                  return SquareCard(item: entity);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
