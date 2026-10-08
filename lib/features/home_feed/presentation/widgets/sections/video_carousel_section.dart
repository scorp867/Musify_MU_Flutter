import 'package:musify_mu/core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/home_feed/data/elements/preview_card_data_element.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Renders video episode sections matching Spotify's official layout.
///
/// Features:
///   - 16:9 video frame thumbnail with top-left duration badge (e.g. "09:22" or "25:26")
///   - Right-edge overlay controls: (+) add, mute, play button
///   - Square show artwork (44x44, 4px rounded corners) next to title and show info
///   - Horizontally pageable carousel matching Spotify's podcasts feed
class VideoCarouselSection extends StatefulWidget {
  final String title;
  final List<SpotifyEntity> items;

  const VideoCarouselSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<VideoCarouselSection> createState() => _VideoCarouselSectionState();
}

class _VideoCarouselSectionState extends State<VideoCarouselSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSectionTraits();
  }

  @override
  void didUpdateWidget(covariant VideoCarouselSection oldWidget) {
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
        // Section title
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
        // Horizontal pageable video cards
        SizedBox(
          height: 285,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.92),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final rawItem = widget.items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: StreamBuilder<Map<String, Trait>>(
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
                    return VideoPreviewCard(entity: item);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A single video card matching Spotify's official layout.
class VideoPreviewCard extends StatelessWidget {
  final SpotifyEntity entity;

  const VideoPreviewCard({super.key, required this.entity});

  @override
  Widget build(BuildContext context) {
    final simpleTrait = entity.getTrait<SimpleCardTrait>();
    final previewTrait = entity.getTrait<PreviewCardTrait>();
    final videoTrait = entity.getTrait<VideoCardTrait>();

    final title = videoTrait?.title.isNotEmpty == true
        ? videoTrait!.title
        : (simpleTrait?.title.isNotEmpty == true
            ? simpleTrait!.title
            : (previewTrait?.title.isNotEmpty == true
                ? previewTrait!.title
                : (entity.cardTitle.isNotEmpty ? entity.cardTitle : entity.previewTitle)));

    final showName = previewTrait?.creatorName.isNotEmpty == true
        ? previewTrait!.creatorName
        : (simpleTrait?.subtitle.isNotEmpty == true
            ? simpleTrait!.subtitle
            : (videoTrait?.subtitle.isNotEmpty == true
                ? videoTrait!.subtitle
                : entity.cardSubtitle));

    // Video thumbnail (16:9 frame) vs Show artwork (square cover)
    final videoThumbnail = entity.videoThumbnailUrl ?? entity.cardImageUrl;
    final showArtwork = entity.showArtworkUrl ?? entity.cardImageUrl;
    final durationStr = entity.durationString;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 16:9 Video Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: videoThumbnail != null && videoThumbnail.isNotEmpty
                    ? AppNetworkImage(
                        imageUrl: videoThumbnail,
                        fit: BoxFit.cover,
                        memCacheWidth: 560,
                        memCacheHeight: 315,
                        errorWidget: (_, _, _) => Container(
                          color: const Color(0xFF242424),
                          child: const Icon(Icons.videocam,
                              color: Colors.white24, size: 48),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF242424),
                        child: const Icon(Icons.videocam,
                            color: Colors.white24, size: 48),
                      ),
              ),

              // Duration badge in top-left corner
              if (durationStr.isNotEmpty)
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      durationStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

              // Overlay playback controls (Spotify 1:1)
              Positioned(
                right: 12,
                top: 12,
                child: _overlayIcon(Icons.add_circle_outline_rounded),
              ),
              Positioned(
                right: 12,
                top: 54,
                child: _overlayIcon(Icons.volume_off_rounded),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Episode info row below the thumbnail
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Square show artwork (44x44, 4px corners)
              if (showArtwork != null && showArtwork.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: AppNetworkImage(
                      imageUrl: showArtwork,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      memCacheWidth: 88,
                      memCacheHeight: 88,
                      errorWidget: (_, _, _) => Container(
                        width: 44,
                        height: 44,
                        color: const Color(0xFF242424),
                        child: const Icon(Icons.podcasts,
                            color: Colors.white38, size: 20),
                      ),
                    ),
                  ),
                ),

              // Episode Title + Show name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    if (showName.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        showName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // More options
              Icon(
                Icons.more_vert,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _overlayIcon(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}
