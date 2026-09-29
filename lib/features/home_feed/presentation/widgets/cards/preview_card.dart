import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Renders a full-width PreviewCardTrait exactly matching Spotify's layout:
///   ┌─────────────────────────────────────┐
///   │  [image]  Title                  ⋮  │
///   │           Subtitle                  │
///   │                                     │
///   │  75 songs · Artist1, Artist2, ...   │
///   │                                     │
///   │  [🔊 Preview playlist]    ⊕   ▶    │
///   └─────────────────────────────────────┘
class PreviewCard extends StatelessWidget {
  final SpotifyEntity item;
  final PreviewCardTrait trait;

  const PreviewCard({
    super.key,
    required this.item,
    required this.trait,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseBackgroundColor();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: image + title/subtitle + menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (trait.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    trait.imageUrl!,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 88,
                      height: 88,
                      color: Colors.black26,
                      child: const Icon(Icons.music_note, color: Colors.white38),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trait.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (trait.creatorName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        trait.creatorName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.6), size: 20),
            ],
          ),
          const SizedBox(height: 16),

          // Middle: track count + description
          if (trait.trackCount > 0 || trait.description.isNotEmpty)
            Text(
              _buildMiddleText(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 16),

          // Bottom row: Preview button + add + play
          Row(
            children: [
              // Preview button (outlined capsule)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up_outlined,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      trait.previewLabel.isNotEmpty ? trait.previewLabel : 'Preview',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Add button
              Icon(Icons.add_circle_outline, color: Colors.white.withValues(alpha: 0.8), size: 28),
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
                  Icons.play_arrow,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildMiddleText() {
    final parts = <String>[];
    if (trait.trackCount > 0) {
      parts.add('${trait.trackCount} songs');
    }
    if (trait.description.isNotEmpty) {
      parts.add(trait.description);
    }
    return parts.join(' \u2022 ');
  }

  Color _parseBackgroundColor() {
    if (trait.backgroundColor == null || trait.backgroundColor!.isEmpty) {
      return const Color(0xFF2A2A2A);
    }
    try {
      final hex = trait.backgroundColor!.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF2A2A2A);
  }
}
