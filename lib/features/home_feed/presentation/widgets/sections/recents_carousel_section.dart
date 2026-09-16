import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/content_item.dart';

/// Recents carousel — smaller cards (~100px) with title + type badge.
/// Matches Spotify's "Recents" / "Jump back in" section.
class RecentsCarouselSection extends StatelessWidget {
  final String title;
  final List<ContentItem> items;

  const RecentsCarouselSection({
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
        // Title row with "Show all"
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Show all',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
        // Smaller horizontal cards
        SizedBox(
          height: 175,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _RecentsCard(item: items[index]),
          ),
        ),
      ],
    );
  }
}

class _RecentsCard extends StatelessWidget {
  final ContentItem item;
  const _RecentsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasBadge = item.badge != null && item.badge!.isNotEmpty;

    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small artwork (circle for artists, square for rest)
          ClipRRect(
            borderRadius: item.type == ContentType.artist
                ? BorderRadius.circular(50)
                : BorderRadius.circular(6),
            child: Container(
              width: 100,
              height: 100,
              color: const Color(0xFF1E293B),
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(height: 6),
          // Badge (e.g. "2 songs added")
          if (hasBadge) ...[
            Text(
              item.badge!,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1DB954), // Spotify green
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
          ],
          // Title
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
            maxLines: hasBadge ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Subtitle
          if (item.subtitle.isNotEmpty)
            Text(
              item.subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(Icons.music_note, color: Colors.grey.shade700, size: 24),
    );
  }
}

