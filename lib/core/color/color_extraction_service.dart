import 'dart:developer' as dev;
import 'dart:ui' as ui;

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

  /// Extracts color from a 4-tile mosaic by compositing them into a single 2x2 bitmap.
  Future<ui.Color?> extractFromMosaic(List<String> mosaicUrls) async {
    if (mosaicUrls.length < 4) return null;
    final mosaicKey = 'mosaic:${mosaicUrls.take(4).join('|')}';

    final cached = _cache.get(mosaicKey);
    if (cached != null) return cached;

    try {
      // 1. Concurrently fetch the 4 tile images (uses local disk cache if already shown)
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

        final color = _pickBestColor(palette);
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

  /// Picks the most vibrant, visually representative color from the palette,
  /// matching Spotify's scoring behavior.
  ///
  /// Weights saturation highest (0.45), targets medium luminance (0.40) to
  /// avoid murky blacks or washed-out whites, and considers population (0.15).
  ui.Color? _pickBestColor(PaletteGenerator palette) {
    if (palette.paletteColors.isEmpty) {
      return palette.dominantColor?.color;
    }

    final totalPop = palette.paletteColors.fold<int>(
      0,
      (sum, c) => sum + c.population,
    );
    final safeTotalPop = totalPop > 0 ? totalPop : 1;

    PaletteColor? bestSwatch;
    double bestScore = -1.0;

    for (final pc in palette.paletteColors) {
      final hsl = HSLColor.fromColor(pc.color);

      // Skip near-black and near-white
      if (hsl.lightness < 0.12 || hsl.lightness > 0.88) continue;

      // Prefer high saturation, optimal lightness around 0.42, with population weight
      final sScore = hsl.saturation * 0.45;
      final lScore = (1.0 - (hsl.lightness - 0.42).abs()) * 0.40;
      final pScore = (pc.population / safeTotalPop) * 0.15;
      final score = sScore + lScore + pScore;

      if (score > bestScore) {
        bestScore = score;
        bestSwatch = pc;
      }
    }

    return bestSwatch?.color ??
        palette.vibrantColor?.color ??
        palette.dominantColor?.color ??
        palette.darkVibrantColor?.color;
  }

  /// Initializes the cache. Call once at startup.
  Future<void> init() => _cache.load();
}
