import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/color/color_cache.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Renders a podcast show preview card matching Spotify Android layout:
///   ┌────────────────────────────────────────────────────────┐
///   │ [88x88 Art]  Show Title (max 2 lines)                ⋮ │
///   │              Publisher / Host                          │
///   │                                                        │
///   │ Show description preview (optional)                    │
///   │                                                        │
///   │ [🔊 Preview show]                              ⊕   ▶   │
///   └────────────────────────────────────────────────────────┘
class ShowPreviewCard extends StatefulWidget {
  final SpotifyEntity item;

  const ShowPreviewCard({super.key, required this.item});

  @override
  State<ShowPreviewCard> createState() => _ShowPreviewCardState();
}

class _ShowPreviewCardState extends State<ShowPreviewCard> {
  Color? _extractedColor;

  @override
  void initState() {
    super.initState();
    _resolveColor();
  }

  @override
  void didUpdateWidget(ShowPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.cardImageUrl != widget.item.cardImageUrl ||
        oldWidget.item.backgroundColorHex != widget.item.backgroundColorHex) {
      _resolveColor();
    }
  }

  void _resolveColor() {
    final colorHex = widget.item.backgroundColorHex;
    if (colorHex != null && colorHex.isNotEmpty) return;

    final url = widget.item.cardImageUrl ?? widget.item.previewImageUrl;
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
    if (hsl.hue >= 260 && hsl.hue <= 325) {
      return hsl
          .withHue(230)
          .withSaturation((hsl.saturation * 0.7).clamp(0.0, 1.0))
          .toColor();
    }
    return color;
  }

  Color _cardBackgroundColor() {
    if (widget.item.backgroundColorHex != null &&
        widget.item.backgroundColorHex!.isNotEmpty) {
      try {
        final hex = widget.item.backgroundColorHex!.replaceFirst('#', '');
        final val = int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
        final base = Color(val);
        return Color.lerp(base, const Color(0xFF1E1E1E), 0.7) ?? const Color(0xFF282828);
      } catch (_) {}
    }
    if (_extractedColor != null) {
      return Color.lerp(_extractedColor!, const Color(0xFF1E1E1E), 0.7) ??
          const Color(0xFF282828);
    }
    return const Color(0xFF282828);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final previewTrait = item.getTrait<PreviewCardTrait>();
    final simpleTrait = item.getTrait<SimpleCardTrait>();

    final title = item.cardTitle.isNotEmpty
        ? item.cardTitle
        : (previewTrait?.title.isNotEmpty == true
            ? previewTrait!.title
            : 'Show');

    final publisher = previewTrait?.creatorName.isNotEmpty == true
        ? previewTrait!.creatorName
        : (item.cardSubtitle.isNotEmpty
            ? item.cardSubtitle
            : (simpleTrait?.subtitle ?? 'Podcast'));

    final description = previewTrait?.description.isNotEmpty == true
        ? previewTrait!.description
        : '';

    final artworkUrl = item.cardImageUrl ??
        item.previewImageUrl ??
        previewTrait?.imageUrl;

    final bgColor = _cardBackgroundColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: artworkUrl != null && artworkUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: artworkUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 176,
                          memCacheHeight: 176,
                          errorWidget: (_, _, _) => Container(
                            color: const Color(0xFF333333),
                            child: const Icon(
                              Icons.podcasts,
                              color: Colors.white24,
                              size: 36,
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF333333),
                          child: const Icon(
                            Icons.podcasts,
                            color: Colors.white24,
                            size: 36,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.more_vert,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      ],
                    ),
                    if (publisher.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        publisher,
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
            ],
          ),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],

          const SizedBox(height: 12),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
                      previewTrait?.previewLabel.isNotEmpty == true
                          ? previewTrait!.previewLabel
                          : 'Preview show',
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
              Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 26,
              ),
              const SizedBox(width: 14),
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
}
