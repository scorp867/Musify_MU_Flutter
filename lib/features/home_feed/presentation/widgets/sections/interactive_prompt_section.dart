import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Interactive search/prompt field section.
/// Used for interactiveEntrypoint (tag 30).
/// Renders as a tappable search-style input, NOT a card.
class InteractivePromptSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const InteractivePromptSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    // Try to extract prompt text from the section's first item
    String promptText = '';
    if (items.isNotEmpty) {
      final simple = items.first.getTrait<SimpleCardTrait>();
      promptText = simple?.title ?? '';
    }
    if (promptText.isEmpty) {
      promptText = title.isNotEmpty ? title : 'Search for songs, artists, podcasts...';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty && title != promptText)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          GestureDetector(
            onTap: () {
              // TODO: Navigate to search or AI prompt
            },
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      promptText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
