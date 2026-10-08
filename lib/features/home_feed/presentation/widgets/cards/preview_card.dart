import 'package:flutter/material.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/color/color_cache.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/core/widgets/app_network_image.dart';
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
class PreviewCard extends StatefulWidget {
  final SpotifyEntity item;
  final PreviewCardTrait trait;

  const PreviewCard({
    super.key,
    required this.item,
    required this.trait,
  });

  @override
  State<PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<PreviewCard> {
  Color? _extractedColor;

  @override
  void initState() {
    super.initState();
    _resolveColor();
  }

  @override
  void didUpdateWidget(PreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trait.imageUrl != widget.trait.imageUrl ||
        oldWidget.trait.backgroundColor != widget.trait.backgroundColor) {
      _resolveColor();
    }
  }

  void _resolveColor() {
    final colorHex = (widget.trait.backgroundColor != null &&
            widget.trait.backgroundColor!.isNotEmpty)
        ? widget.trait.backgroundColor
        : widget.item.backgroundColorHex;
    if (colorHex != null && colorHex.isNotEmpty) {
      return;
    }
    final url = widget.trait.imageUrl ?? widget.item.cardImageUrl;
    if (url == null || url.isEmpty) return;

    if (getIt.isRegistered<ColorCache>()) {
      final cached = getIt<ColorCache>().get(url);
      if (cached != null) {
        _extractedColor = _sanitizeColor(cached);
        return;
      }
    }

    if (getIt.isRegistered<ColorExtractionService>()) {
      getIt<ColorExtractionService>().extractFromUrl(url).then((color) {
        if (mounted && color != null) {
          setState(() {
            _extractedColor = _sanitizeColor(color);
          });
        }
      });
    }
  }

  static Color _sanitizeColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    // Strict compliance with Basic_Rules: Purple Ban (hue 260° - 325°)
    if (hsl.hue >= 260 && hsl.hue <= 325) {
      return hsl
          .withHue(230)
          .withSaturation((hsl.saturation * 0.7).clamp(0.0, 1.0))
          .toColor();
    }
    return color;
  }

  @override
  Widget build(BuildContext context) {
    final trait = widget.trait;
    final bgColor = _parseBackgroundColor();
    final darkerColor = Color.lerp(bgColor, Colors.black, 0.55) ?? Colors.black;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgColor, darkerColor],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
                  child: AppNetworkImage(
                    imageUrl: trait.imageUrl!,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    memCacheWidth: 176,
                    memCacheHeight: 176,
                    errorWidget: (_, _, _) => Container(
                      width: 88,
                      height: 88,
                      color: Colors.black26,
                      child: const Icon(Icons.music_note, color: Colors.white38),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
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
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trait.creatorName.isNotEmpty
                          ? trait.creatorName
                          : (widget.item.cardSubtitle.isNotEmpty
                              ? widget.item.cardSubtitle
                              : 'Spotify'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.6), size: 20),
            ],
          ),
          const SizedBox(height: 14),

          // Middle: track count + description
          if (trait.trackCount > 0 || trait.description.isNotEmpty)
            Text(
              _buildMiddleText(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 16),

          // Bottom row: Preview button + add + play
          Row(
            children: [
              // Preview button (rectangular container with 6px border radius, no pill shape)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(6),
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
                      trait.previewLabel.isNotEmpty
                          ? trait.previewLabel
                          : (widget.item.type == ContentType.episode
                              ? 'Preview episode'
                              : widget.item.type == ContentType.podcast
                                  ? 'Preview show'
                                  : 'Preview playlist'),
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
              Icon(Icons.add_circle_outline, color: Colors.white.withValues(alpha: 0.85), size: 26),
              const SizedBox(width: 14),
              // Play button
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.black,
                  size: 24,
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
    if (widget.trait.trackCount > 0) {
      parts.add('${widget.trait.trackCount} songs');
    }
    if (widget.trait.description.isNotEmpty) {
      parts.add(widget.trait.description);
    }
    return parts.join(' \u2022 ');
  }

  Color _parseBackgroundColor() {
    final colorHex = (widget.trait.backgroundColor != null &&
            widget.trait.backgroundColor!.isNotEmpty)
        ? widget.trait.backgroundColor
        : widget.item.backgroundColorHex;

    if (colorHex != null && colorHex.isNotEmpty) {
      try {
        final hex = colorHex.replaceAll('#', '');
        if (hex.length == 6) {
          return _sanitizeColor(Color(int.parse('FF$hex', radix: 16)));
        } else if (hex.length == 8) {
          return _sanitizeColor(Color(int.parse(hex, radix: 16)));
        }
      } catch (_) {}
    }
    if (_extractedColor != null) {
      return _extractedColor!;
    }
    return const Color(0xFF242424);
  }
}
