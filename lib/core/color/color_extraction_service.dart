import 'dart:developer' as dev;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:palette_generator/palette_generator.dart';

import 'package:musify_mu/core/color/color_cache.dart';

/// Extracts the dominant and vibrant branding color from artwork images,
/// matching Spotify's color extraction pipeline.
///
/// Handles:
/// 1. Single artwork covers (album / track / custom playlist cover)
/// 2. 2x2 Mosaic composite bitmaps (playlist covers composed of 4 track arts)
///
/// Uses [DefaultCacheManager] to reuse images already downloaded to disk
/// by [CachedNetworkImage], preventing redundant network requests.
class ColorExtractionService {
  final ColorCache _cache;
  final BaseCacheManager _cacheManager;

  ColorExtractionService({
    required ColorCache cache,
    BaseCacheManager? cacheManager,
  })  : _cache = cache,
        _cacheManager = cacheManager ?? DefaultCacheManager();

  /// Unified entrypoint for color extraction.
  /// If [mosaicUrls] has >= 4 items, builds a 2x2 composite and quantizes it.
  /// Otherwise, extracts from [imageUrl].
  Future<ui.Color?> extract({
    String? imageUrl,
    List<String>? mosaicUrls,
  }) async {
    if (mosaicUrls != null && mosaicUrls.length >= 4) {
      return extractFromMosaic(mosaicUrls.take(4).toList());
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return extractFromUrl(imageUrl);
    }
    return null;
  }

  /// Returns synchronously cached color if present.
  ui.Color? getCached(String imageUrl) => _cache.get(imageUrl);

  /// Extracts color from a single image URL.
  Future<ui.Color?> extractFromUrl(String imageUrl) async {
    final cached = _cache.get(imageUrl);
    if (cached != null) return cached;

    try {
      final file = await _cacheManager.getSingleFile(imageUrl);
      final bytes = await file.readAsBytes();

      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 112,
        targetHeight: 112,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      try {
        final palette = await PaletteGenerator.fromImage(
          image,
          maximumColorCount: 16,
        );

        final color = _pickBestColor(palette);
        if (color != null) {
          await _cache.put(imageUrl, color);
        }
        return color;
      } finally {
        image.dispose();
      }
    } catch (e) {
      dev.log('ColorExtraction: extractFromUrl failed: $e');
      return null;
    }
  }

  /// Extracts color from a playlist mosaic.
  /// Matches Spotify's decompiled playlist header pipeline:
  /// Spotify anchors playlist header theming on the primary track (Track 0 / Top-Left tile),
  /// causing the playlist header color to dynamically adapt when tracks are reordered.
  /// Falls back to remaining tiles and composite 2x2 grid if the primary track yields no color.
  Future<ui.Color?> extractFromMosaic(List<String> mosaicUrls) async {
    if (mosaicUrls.isEmpty) return null;
    final mosaicKey = 'mosaic:${mosaicUrls.take(4).join('|')}';

    final cached = _cache.get(mosaicKey);
    if (cached != null) return cached;

    // 1. Primary track extraction (Spotify Track 0 / Tile 0 header theming)
    final primaryColor = await extractFromUrl(mosaicUrls.first);
    if (primaryColor != null) {
      await _cache.put(mosaicKey, primaryColor);
      return primaryColor;
    }

    // 2. Fallback to subsequent tracks if primary yields no candidate
    for (int i = 1; i < math.min(mosaicUrls.length, 4); i++) {
      final tileColor = await extractFromUrl(mosaicUrls[i]);
      if (tileColor != null) {
        await _cache.put(mosaicKey, tileColor);
        return tileColor;
      }
    }

    if (mosaicUrls.length < 4) return null;

    try {
      // 3. Ultimate fallback: composite 2x2 grid quantization
      final files = await Future.wait(
        mosaicUrls.take(4).map((url) => _cacheManager.getSingleFile(url)),
      );

      // 2. Decode into 64x64 thumbnails
      final tileImages = <ui.Image>[];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: 64,
          targetHeight: 64,
        );
        final frame = await codec.getNextFrame();
        tileImages.add(frame.image);
      }

      // 3. Composite into a 128x128 2x2 grid
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      const half = 64.0;
      final paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;

      canvas.drawImage(tileImages[0], const ui.Offset(0, 0), paint);
      canvas.drawImage(tileImages[1], const ui.Offset(half, 0), paint);
      canvas.drawImage(tileImages[2], const ui.Offset(0, half), paint);
      canvas.drawImage(tileImages[3], const ui.Offset(half, half), paint);

      final picture = recorder.endRecording();
      final composite = await picture.toImage(128, 128);

      // Clean up tile images
      for (final img in tileImages) {
        img.dispose();
      }

      try {
        // 4. Quantize the full composite with 32 clusters
        final palette = await PaletteGenerator.fromImage(
          composite,
          maximumColorCount: 32,
        );

        final color = _pickBestColor(palette, isMosaic: true);
        if (color != null) {
          await _cache.put(mosaicKey, color);
        }
        return color;
      } finally {
        composite.dispose();
      }
    } catch (e) {
      dev.log('ColorExtraction: extractFromMosaic failed: $e');
      return null;
    }
  }

  /// Picks the optimal branding color from the palette, matching Spotify's exact
  /// decompiled extraction pipeline (p.m351.y, p.laa1.o, p.xj41.p, and p.epp0.d).
  ///
  /// Steps:
  /// 1. Candidate scoring with yellow/olive tent filter penalty (p.laa1.o / p.laa1.g).
  /// 2. If no candidate qualifies, fall back to Muted (zf21.h) -> Vibrant (zf21.e) (p.m351.y).
  /// 3. Darken via binary search on Lightness to guarantee WCAG AA 4.5:1 contrast against White (p.xj41.p).
  /// 4. Apply 12% relative luminance floor, blending with 20% white if too dark (p.epp0.d).
  ui.Color? _pickBestColor(PaletteGenerator palette, {bool isMosaic = false}) {
    ui.Color? rawColor;

    if (palette.paletteColors.isNotEmpty) {
      final totalPop = palette.paletteColors.fold<int>(
        0,
        (sum, c) => sum + c.population,
      );
      final safeTotalPop = totalPop > 0 ? totalPop : 1;

      // Filter candidates: S >= 0.2, V >= 0.2, PopRatio >= 0.0016 (p.laa1.java)
      final candidates = <PaletteColor>[];
      for (final pc in palette.paletteColors) {
        final hsv = HSVColor.fromColor(pc.color);
        final popRatio = pc.population / safeTotalPop;
        if (hsv.saturation >= 0.2 && hsv.value >= 0.2 && popRatio >= 0.0016) {
          candidates.add(pc);
        }
      }

      if (candidates.isNotEmpty) {
        // Check if there is at least one non-yellow candidate (hue < 30 or hue > 80)
        final hasNonYellow = candidates.any((pc) {
          final h = HSVColor.fromColor(pc.color).hue;
          return h < 30.0 || h > 80.0;
        });

        PaletteColor? bestCandidate;
        double bestScore = -double.infinity;

        for (final pc in candidates) {
          final hsv = HSVColor.fromColor(pc.color);
          final popRatio = pc.population / safeTotalPop;

          // Tent filter penalty centered at pure yellow (Hue = 55°)
          double yellowPenalty = 0.0;
          if (hasNonYellow && hsv.hue >= 30.0 && hsv.hue <= 80.0) {
            final distFromCenter = (25.0 - (hsv.hue - 30.0)).abs();
            final tent = ((25.0 - distFromCenter) / 25.0).clamp(0.0, 1.0);
            yellowPenalty = -(tent * 2.0);
          }

          final score = (hsv.saturation * hsv.value) + popRatio + yellowPenalty;
          if (score > bestScore) {
            bestScore = score;
            bestCandidate = pc;
          }
        }

        rawColor = bestCandidate?.color;
      }
    }

    // Fallback: Spotify's standard hierarchy (p.m351.y) -> Muted first, then Vibrant
    rawColor ??= palette.mutedColor?.color ??
        palette.vibrantColor?.color ??
        palette.darkMutedColor?.color ??
        palette.darkVibrantColor?.color ??
        palette.dominantColor?.color;

    if (rawColor == null) return null;

    // Step 3: Apply Spotify's WCAG AA 4.5:1 White Contrast Binary Search (p.xj41.p)
    final darkened = _ensureWhiteContrast(rawColor);

    // Step 4: Apply Spotify's Relative Luminance Floor (p.epp0.d)
    final floored = _applyLuminanceFloor(darkened);

    // Step 5: Apply Spotify's Matte Finish Ceiling (V <= 0.70)
    return _applyMatteFinish(floored);
  }

  /// Ensures extracted color does not exceed Spotify's matte luminance ceiling (V <= 0.70).
  /// Eliminates glowing neon sheen, producing Spotify's signature velvety matte appearance.
  ui.Color _applyMatteFinish(ui.Color color) {
    final hsv = HSVColor.fromColor(color);
    if (hsv.value > 0.70) {
      return hsv.withValue(0.70).toColor();
    }
    return color;
  }

  /// Binary search on HSV Value channel down to 0.0 until contrast against
  /// pure white (0xFFFFFFFF) is >= 4.5:1 (WCAG AA compliant).
  ///
  /// Matches decompiled logic in p.vkb1.d and p.vde.e.
  ui.Color _ensureWhiteContrast(ui.Color color) {
    const white = ui.Color(0xFFFFFFFF);
    if (_calculateContrast(white, color) >= 4.5) {
      return color;
    }

    final hsv = HSVColor.fromColor(color);
    double upperV = hsv.value;
    double lowerV = 0.0;

    while (upperV - lowerV > 0.01) {
      final midV = (upperV + lowerV) * 0.5;
      final testColor = hsv.withValue(midV).toColor();
      if (_calculateContrast(white, testColor) < 4.5) {
        upperV = midV; // Too bright, reduce value
      } else {
        lowerV = midV; // Dark enough, keep as high as possible for vibrancy
      }
    }

    return hsv.withValue(lowerV).toColor();
  }


  /// If relative luminance < 0.12 (too dark / pitch black), blends with 20% white.
  /// Matches decompiled logic in p.epp0.d and p.epp0.l.
  ui.Color _applyLuminanceFloor(ui.Color color) {
    final lum = _relativeLuminance(color);
    if (lum >= 0.12) {
      return color;
    }
    final argb = color.toARGB32();
    final rInt = (argb >> 16) & 0xFF;
    final gInt = (argb >> 8) & 0xFF;
    final bInt = argb & 0xFF;

    final r = (((255 - rInt) * 0.2) + rInt).round();
    final g = (((255 - gInt) * 0.2) + gInt).round();
    final b = (((255 - bInt) * 0.2) + bInt).round();
    return ui.Color.fromARGB(255, r, g, b);
  }

  /// Calculates WCAG contrast ratio between two colors (p.vde.e).
  double _calculateContrast(ui.Color foreground, ui.Color background) {
    final l1 = _relativeLuminance(foreground);
    final l2 = _relativeLuminance(background);
    final maxL = math.max(l1, l2);
    final minL = math.min(l1, l2);
    return (maxL + 0.05) / (minL + 0.05);
  }

  /// Calculates WCAG relative luminance Y using sRGB gamma decompression (p.epp0.l).
  double _relativeLuminance(ui.Color c) {
    double decompress(int channel) {
      final f = channel / 255.0;
      if (f <= 0.04045) {
        return f / 12.92;
      }
      return math.pow((f + 0.055) / 1.055, 2.4).toDouble();
    }

    final argb = c.toARGB32();
    final rInt = (argb >> 16) & 0xFF;
    final gInt = (argb >> 8) & 0xFF;
    final bInt = argb & 0xFF;

    return (decompress(rInt) * 0.2126) +
        (decompress(gInt) * 0.7152) +
        (decompress(bInt) * 0.0722);
  }

  /// Initializes the cache. Call once at startup.
  Future<void> init() => _cache.load();

  @visibleForTesting
  ui.Color? testPickBestColor(PaletteGenerator palette, {bool isMosaic = false}) =>
      _pickBestColor(palette, isMosaic: isMosaic);
}

