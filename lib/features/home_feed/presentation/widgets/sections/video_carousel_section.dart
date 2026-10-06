import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Renders video episode sections matching Spotify's official layout.
///
/// Features:
///   - 16:9 video frame thumbnail with top-left duration badge (e.g. "09:22")
///   - Clean static display without clutter (playback controls only when actively playing)
///   - Square show artwork (40x40, 4px rounded corners) next to title and show info
///   - Horizontally pageable carousel matching Spotify's podcasts feed
class VideoCarouselSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const VideoCarouselSection({
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
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              title,
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
          height: 275,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.92),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: VideoPreviewCard(entity: items[index]),
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
        : (simpleTrait?.title ?? previewTrait?.title ?? '');
    final subtitle = videoTrait?.subtitle.isNotEmpty == true
        ? videoTrait!.subtitle
        : (simpleTrait?.subtitle ?? previewTrait?.description ?? '');

    // Video thumbnail (16:9 frame) vs Show artwork (square cover)
    final videoThumbnail = entity.videoThumbnailUrl ?? entity.cardImageUrl;
    final showArtwork = entity.showArtworkUrl ?? entity.cardImageUrl;
    final durationStr = entity.durationString;
    final isPlaying = videoTrait?.isPlaying ?? false;

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
                    ? CachedNetworkImage(
                        imageUrl: videoThumbnail,
                        fit: BoxFit.cover,
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

              // Overlay playback controls: ONLY displayed when actively playing
              if (isPlaying) ...[
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 60,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 50,
                  child: _overlayIcon(Icons.add_circle_outline_rounded),
                ),
                Positioned(
                  right: 12,
                  top: 96,
                  child: _overlayIcon(Icons.volume_off_rounded),
                ),
              ],
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
              // Square show artwork (40x40, 4px corners)
              if (showArtwork != null && showArtwork.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: showArtwork,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(
                        width: 40,
                        height: 40,
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
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
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
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
