import 'package:flutter/material.dart';
import 'package:musify_mu/core/widgets/app_network_image.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';

/// FullBleedBanner section matching Spotify's exact edge-to-edge promotional hero card
/// (e.g. "New Music Friday").
///
/// Layout based on Spotify Casita SDUI:
/// ┌──────────────────────────────────────────────────────────────┐
/// │                     [ NEW MUSIC FRIDAY ]                     │  <- colorCode background (#83E6BD)
/// └──────────────────────────────────────────────────────────────┘
///        New music from Drake, Mac Miller, Quavo and more!          <- description subtitle
///
/// The image provided by Spotify is a 2226x294 stencil mask where all RGB pixels
/// are jet black (0,0,0) and the typography/cutouts have alpha transparency.
/// Placing it edge-to-edge over a background filled with `colorCode` allows
/// the dynamic color to shine through the transparent stencil cutouts seamlessly.
class FullBleedBannerSection extends StatelessWidget {
  final HomeSection section;

  const FullBleedBannerSection({
    super.key,
    required this.section,
  });

  static Color _parseColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final clean = hexString.replaceFirst('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
    } catch (_) {}
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final bannerColor = _parseColor(section.colorCode, const Color(0xFF83E6BD));
    final imageUrl = section.imageUrl ?? '';
    final subtitle = section.subtitle;

    return RepaintBoundary(
      child: Semantics(
        label: section.title.isNotEmpty ? section.title : 'New Music Friday',
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Full-bleed edge-to-edge graphic banner (2226 x 294 aspect ratio)
            // The raw image is an alpha stencil mask where jet black pixels are tinted
            // with bannerColor via BlendMode.srcIn, while transparent cutouts remain
            // transparent to reveal the dark background beneath.
            AspectRatio(
              aspectRatio: 2226 / 294,
              child: imageUrl.isNotEmpty
                  ? AppNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.fill,
                      width: double.infinity,
                      color: bannerColor,
                      colorBlendMode: BlendMode.srcIn,
                      alignment: Alignment.center,
                      placeholder: (context, url) => const SizedBox.shrink(),
                      errorWidget: (context, url, error) => const SizedBox.shrink(),
                    )
                  : const SizedBox.shrink(),
            ),

            // Subtitle description under banner
            if (subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.1,
                    height: 1.25,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
