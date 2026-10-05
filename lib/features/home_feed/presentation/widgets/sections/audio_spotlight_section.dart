import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Audio spotlight card with artwork and preview info.
/// Used for audioSpotlight (tag 36) and audioPromo (tag 33).
class AudioSpotlightSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const AudioSpotlightSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final item = items.first;
    final previewTrait = item.getTrait<PreviewCardTrait>();
    final simpleTrait = item.getTrait<SimpleCardTrait>();

    final displayTitle = previewTrait?.title ?? simpleTrait?.title ?? '';
    final subtitle = previewTrait?.description ?? simpleTrait?.subtitle ?? '';
    final imageUrl = previewTrait?.imageUrl ?? simpleTrait?.imageUrl;
    final contentType = previewTrait?.contentTypeName ?? '';
    final creator = previewTrait?.creatorName ?? '';

    final bgHex = previewTrait?.backgroundColor;
    Color bgColor = const Color(0xFF2A2A2A);
    if (bgHex != null && bgHex.length >= 6) {
      try {
        bgColor = Color(int.parse('FF${bgHex.substring(0, 6)}', radix: 16));
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: bgColor,
              child: Row(
                children: [
                  // Artwork
                  if (imageUrl != null)
                    SizedBox(
                      width: 128,
                      height: 128,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 128,
                      height: 128,
                      color: bgColor.withValues(alpha: 0.5),
                      child: const Icon(Icons.music_note, color: Colors.white38, size: 40),
                    ),
                  // Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (contentType.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                contentType.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          if (displayTitle.isNotEmpty)
                            Text(
                              displayTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (creator.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              creator,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
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
