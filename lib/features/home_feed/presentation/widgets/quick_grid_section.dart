import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/content_item.dart';

/// 2-column compact grid — used for shortcuts (recently played quick access).
/// Mimics Spotify's top quick-access grid with small rectangular cards.
class QuickGridSection extends StatelessWidget {
  final String title;
  final List<ContentItem> items;

  const QuickGridSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final gridItems = items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              title,
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
          child: ExcludeSemantics(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: gridItems.map((item) => _QuickGridTile(item: item)).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickGridTile extends StatelessWidget {
  final ContentItem item;
  const _QuickGridTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 40) / 2;

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: width,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Thumbnail
            SizedBox(
              width: 56,
              height: 56,
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 10),
            // Title
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF383838),
      child: Icon(Icons.music_note, color: Colors.grey.shade600, size: 20),
    );
  }
}
