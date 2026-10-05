import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Renders video episode sections matching Spotify's official layout.
///
/// Videos are displayed as full-width immersive cards with:
///   - Full-bleed 16:9 thumbnail
///   - Duration badge (top-left)
///   - Overlay controls (mute, add, play) on right side
///   - Episode info below: show artwork, title, show name, date
///
/// This matches sections like "Videos you might like", "Similar to your
/// recent listening" from the official Spotify podcasts tab.
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
        // Full-width video cards, one at a time, horizontally pageable
        SizedBox(
          height: 340,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.92),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _VideoPreviewCard(entity: items[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A single full-width immersive video card matching Spotify's layout.
class _VideoPreviewCard extends StatelessWidget {
  final SpotifyEntity entity;

  const _VideoPreviewCard({required this.entity});

  @override
  Widget build(BuildContext context) {
    final simpleTrait = entity.getTrait<SimpleCardTrait>();
    final previewTrait = entity.getTrait<PreviewCardTrait>();

    final title = simpleTrait?.title ?? previewTrait?.title ?? '';
    final subtitle = simpleTrait?.subtitle ?? previewTrait?.description ?? '';
    final imageUrl = simpleTrait?.imageUrl ?? previewTrait?.imageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full-width video thumbnail with overlays
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Thumbnail
              AspectRatio(
                aspectRatio: 16 / 9,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Container(
                          color: const Color(0xFF282828),
                          child: const Icon(Icons.videocam,
                              color: Colors.white24, size: 48),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF282828),
                        child: const Icon(Icons.videocam,
                            color: Colors.white24, size: 48),
                      ),
              ),
              // Bottom gradient for readability
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 80,
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
              // Right-side overlay controls
              Positioned(
                right: 12,
                bottom: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Play button
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
              // Add button (top-right)
              Positioned(
                right: 12,
                top: 56,
                child: _overlayIcon(Icons.add_circle_outline_rounded),
              ),
              // Mute button
              Positioned(
                right: 12,
                top: 104,
                child: _overlayIcon(Icons.volume_off_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Episode info row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show artwork (small)
              if (previewTrait?.imageUrl != null &&
                  simpleTrait?.imageUrl != null &&
                  previewTrait?.imageUrl != simpleTrait?.imageUrl)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: previewTrait!.imageUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          const SizedBox(width: 40, height: 40),
                    ),
                  ),
                ),
              // Title + subtitle
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
                          height: 1.3,
                        ),
                      ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
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
              // More options
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.more_horiz,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 20,
                ),
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
        color: Colors.black.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
