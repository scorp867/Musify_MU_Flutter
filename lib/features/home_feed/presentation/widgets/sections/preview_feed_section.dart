import 'package:flutter/material.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/home_feed/data/elements/preview_card_data_element.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/cards/preview_card.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/video_carousel_section.dart';

/// Preview feed section -- vertical stack of full-width preview cards.
/// Maps to Casita sections that contain Preview or ImmersivePreview.
/// Spotify shows these as full-width cards with 12px vertical spacing.
class PreviewFeedSection extends StatefulWidget {
  final String title;
  final List<SpotifyEntity> items;

  const PreviewFeedSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<PreviewFeedSection> createState() => _PreviewFeedSectionState();
}

class _PreviewFeedSectionState extends State<PreviewFeedSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSectionTraits();
  }

  @override
  void didUpdateWidget(covariant PreviewFeedSection oldWidget) {
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (int i = 0; i < widget.items.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                StreamBuilder<Map<String, Trait>>(
                  stream: pool.watchEntity(widget.items[i].uri),
                  initialData: pool.getTraits(widget.items[i].uri),
                  builder: (context, snapshot) {
                    final currentTraits = snapshot.data ?? widget.items[i].traits;
                    final item = SpotifyEntity(
                      uri: widget.items[i].uri,
                      type: widget.items[i].type,
                      traits: currentTraits,
                    );

                    // 1. If entity has a video trait, render a video preview card
                    final videoTrait = item.getTrait<VideoCardTrait>();
                    if (videoTrait != null) {
                      return VideoPreviewCard(entity: item);
                    }

                    // 2. Otherwise render preview card with PreviewCardTrait (or synthesized fallback)
                    final fallbackTitle = item.previewTitle.isNotEmpty
                        ? item.previewTitle
                        : (item.cardTitle.isNotEmpty ? item.cardTitle : widget.title);
                    final previewTrait = item.getTrait<PreviewCardTrait>() ??
                        PreviewCardTrait(
                          title: fallbackTitle,
                          description: item.getTrait<SimpleCardTrait>()?.subtitle ?? '',
                          imageUrl: item.cardImageUrl ?? item.previewImageUrl ?? '',
                          backgroundColor: item.backgroundColorHex,
                        );

                    return PreviewCard(item: item, trait: previewTrait);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
