import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/home_feed/data/elements/preview_card_data_element.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Renders episodes in a vertical list matching Spotify's "Episodes you might like".
///
/// Each episode card has:
///   - Square artwork on the left
///   - Title, show name, date, duration on the right
///   - "Preview episode" action bar at the bottom
///
/// This matches contentEvaluationList sections that contain episode URIs.
class EpisodeListSection extends StatefulWidget {
  final String title;
  final List<SpotifyEntity> items;

  const EpisodeListSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<EpisodeListSection> createState() => _EpisodeListSectionState();
}

class _EpisodeListSectionState extends State<EpisodeListSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSectionTraits();
  }

  @override
  void didUpdateWidget(covariant EpisodeListSection oldWidget) {
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
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ...widget.items.take(5).map((item) {
          return StreamBuilder<Map<String, Trait>>(
            stream: pool.watchEntity(item.uri),
            initialData: pool.getTraits(item.uri),
            builder: (context, snapshot) {
              final currentTraits = snapshot.data ?? item.traits;
              final entity = SpotifyEntity(
                uri: item.uri,
                type: item.type,
                traits: currentTraits,
              );
              return _EpisodeCard(entity: entity);
            },
          );
        }),
      ],
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  final SpotifyEntity entity;

  const _EpisodeCard({required this.entity});

  @override
  Widget build(BuildContext context) {
    final simpleTrait = entity.getTrait<SimpleCardTrait>();
    final previewTrait = entity.getTrait<PreviewCardTrait>();

    final title = simpleTrait?.title ?? previewTrait?.title ?? '';
    final subtitle = simpleTrait?.subtitle ?? previewTrait?.description ?? '';
    final imageUrl = simpleTrait?.imageUrl ?? previewTrait?.imageUrl;

    if (title.isEmpty && imageUrl == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Main content row
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Episode artwork
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => Container(
                                color: const Color(0xFF282828),
                                child: const Icon(Icons.podcasts,
                                    color: Colors.white24, size: 24),
                              ),
                            )
                          : Container(
                              color: const Color(0xFF282828),
                              child: const Icon(Icons.podcasts,
                                  color: Colors.white24, size: 24),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // More button
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            // Bottom action bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  // Preview episode button
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.volume_up_rounded,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Preview episode',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Add button
                  Icon(
                    Icons.add_circle_outline,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  // Play button
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
