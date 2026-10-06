import 'package:flutter/material.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/home_feed/data/elements/preview_card_data_element.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/cards/preview_card.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/cards/square_card.dart';

/// Preview carousel section -- horizontal scroll of preview cards.
/// Maps to Casita Section body field 37 (PreviewCarousel).
/// Spotify shows these as wide cards (~310px) in a horizontal list.
class PreviewCarouselSection extends StatefulWidget {
  final String title;
  final List<SpotifyEntity> items;

  const PreviewCarouselSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<PreviewCarouselSection> createState() => _PreviewCarouselSectionState();
}

class _PreviewCarouselSectionState extends State<PreviewCarouselSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSectionTraits();
  }

  @override
  void didUpdateWidget(covariant PreviewCarouselSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _loadSectionTraits();
    }
  }

  void _loadSectionTraits() {
    if (widget.items.isEmpty) return;
    final pool = getIt<DataPool>();
    final uris = widget.items.map((e) => e.uri).toList();
    pool.loadBatch(uris: uris, statement: PreviewCardDataElement.statement);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final pool = getIt<DataPool>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty)
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
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final rawItem = widget.items[index];
              return StreamBuilder<Map<String, Trait>>(
                stream: pool.watchEntity(rawItem.uri),
                initialData: pool.getTraits(rawItem.uri),
                builder: (context, snapshot) {
                  final currentTraits = <String, Trait>{
                    ...rawItem.traits,
                    ...?snapshot.data,
                  };
                  final item = SpotifyEntity(
                    uri: rawItem.uri,
                    type: rawItem.type,
                    traits: currentTraits,
                  );
                  final previewTrait = item.getTrait<PreviewCardTrait>();
                  if (previewTrait != null) {
                    return SizedBox(
                      width: 310,
                      child: PreviewCard(item: item, trait: previewTrait),
                    );
                  }
                  return SquareCard(item: item, size: 150);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
