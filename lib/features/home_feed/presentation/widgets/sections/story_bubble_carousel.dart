import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Horizontal row of circular story-style bubbles.
/// Used for topStoryCarousel (tag 31).
class StoryBubbleCarousel extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const StoryBubbleCarousel({
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
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10, top: 8),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = items[index];
              final imageUrl = item.cardImageUrl;
              final label = item.cardTitle;

              return SizedBox(
                width: 68,
                child: Column(
                  children: [
                    // Ring + circle avatar
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1DB954),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: ClipOval(
                        child: imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 136,
                                memCacheHeight: 136,
                              )
                            : Container(
                                color: const Color(0xFF333333),
                                child: const Icon(Icons.person, color: Colors.white24, size: 28),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (label.isNotEmpty)
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
