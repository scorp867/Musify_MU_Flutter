import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Single-item promotional video card section (matches Spotify Android's vbb0 / VideoPromo).
/// Renders a prominent 16:9 video promo banner with playback affordance.
class VideoPromoSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const VideoPromoSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final item = items.first;
    final videoTrait = item.getTrait<VideoCardTrait>();
    final simpleTrait = item.getTrait<SimpleCardTrait>();
    final previewTrait = item.getTrait<PreviewCardTrait>();

    final displayTitle = videoTrait?.title.isNotEmpty == true
        ? videoTrait!.title
        : (simpleTrait?.title ?? previewTrait?.title ?? '');
    final subtitle = videoTrait?.subtitle.isNotEmpty == true
        ? videoTrait!.subtitle
        : (simpleTrait?.subtitle ?? previewTrait?.description ?? '');
    final overline = videoTrait?.overline ?? '';

    final videoThumbnail = item.videoThumbnailUrl ??
        videoTrait?.videoThumbnailUrl ??
        item.cardImageUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: const Color(0xFF1E1E1E),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (videoThumbnail != null && videoThumbnail.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: videoThumbnail,
                            fit: BoxFit.cover,
                            memCacheWidth: 720,
                            memCacheHeight: 405,
                            errorWidget: (_, _, _) => Container(
                              color: const Color(0xFF282828),
                              child: const Icon(Icons.video_library, color: Colors.white24, size: 48),
                            ),
                          )
                        else
                          Container(
                            color: const Color(0xFF282828),
                            child: const Icon(Icons.video_library, color: Colors.white24, size: 48),
                          ),
                        // Dark overlay gradient for contrast
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.6),
                                ],
                                stops: const [0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                        // Play button
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1DB954),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.black,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (overline.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              overline.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF1DB954),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        if (displayTitle.isNotEmpty)
                          Text(
                            displayTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (subtitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              subtitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
