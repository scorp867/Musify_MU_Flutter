import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/home_feed/data/elements/podcast_preview_data_element.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/cards/episode_preview_card.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/cards/show_preview_card.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/video_carousel_section.dart';

/// Direct equivalent to Spotify Android's `p.tkn0` / `xab0` section renderer.
/// Handles Casita Tag 4 (`preview`):
/// - Video episodes / video sections: renders 16:9 [VideoPreviewCard].
/// - Audio episodes: renders 1:1 [EpisodePreviewCard].
/// - Shows: renders [ShowPreviewCard].
class PodcastPreviewSection extends StatefulWidget {
  final String title;
  final List<SpotifyEntity> items;

  const PodcastPreviewSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<PodcastPreviewSection> createState() => _PodcastPreviewSectionState();
}

class _PodcastPreviewSectionState extends State<PodcastPreviewSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSectionTraits();
  }

  @override
  void didUpdateWidget(covariant PodcastPreviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _loadSectionTraits();
    }
  }

  DataPool? _resolvePool() {
    try {
      return context.read<DataPool>();
    } catch (_) {
      return null;
    }
  }

  void _loadSectionTraits() {
    if (widget.items.isEmpty) return;
    final pool = _resolvePool();
    final uris = widget.items.map((e) => e.uri).toList();
    pool?.loadBatch(uris: uris, statement: PodcastPreviewDataElement.statement);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final pool = _resolvePool();
    if (pool == null) return const SizedBox.shrink();
    final isVideoSection = widget.title.toLowerCase().contains('video');

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
                    final currentTraits = <String, Trait>{
                      ...widget.items[i].traits,
                      ...?snapshot.data,
                    };
                    final item = SpotifyEntity(
                      uri: widget.items[i].uri,
                      type: widget.items[i].type,
                      traits: currentTraits,
                    );

                    final isVideo = item.hasVideo ||
                        (item.videoThumbnailUrl != null &&
                            item.videoThumbnailUrl!.isNotEmpty) ||
                        isVideoSection;

                    if (isVideo) {
                      return VideoPreviewCard(entity: item);
                    } else if (item.type == ContentType.episode ||
                        item.uri.contains(':episode:')) {
                      return EpisodePreviewCard(item: item);
                    } else {
                      return ShowPreviewCard(item: item);
                    }
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
