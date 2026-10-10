import 'dart:developer' as dev;
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:material_color_utilities/quantize/quantizer_celebi.dart';

import 'package:musify_mu/core/color/artwork_color_scheme.dart';
import 'package:musify_mu/core/color/color_cache.dart';
import 'package:musify_mu/core/color/scheme_deriver.dart';

/// Industry-leading artwork color extraction engine.
///
/// Features:
/// 1. 200x200 high-fidelity thumbnail sampling (captures fine accents).
/// 2. Intelligent pixel pre-filtering: strips pure black borders/letterboxing,
///    blown-out white cards/margins, and sterile grays before quantization.
/// 3. QuantizerCelebi (Wu variance-minimization + WSMeans weighted K-Means).
/// 4. OKLab perceptual color space distance for accurate color relationships.
/// 5. Authentic Spotify tone-mapping preserving 100% of Hue & Saturation.
/// 6. Fully asynchronous off-thread execution via [Isolate.run].
/// 7. Zero fallback nulls: returns complete 5-color [ArtworkColorScheme].
class ColorExtractionService {
  final ColorCache _cache;
  final BaseCacheManager _cacheManager;
  final Future<Uint8List?> Function(int songId)? _artworkFetcher;

  ColorExtractionService({
    required ColorCache cache,
    BaseCacheManager? cacheManager,
    Future<Uint8List?> Function(int songId)? artworkFetcher,
  })  : _cache = cache,
        _cacheManager = cacheManager ?? DefaultCacheManager(),
        _artworkFetcher = artworkFetcher;

  /// Unified entrypoint for color extraction.
  Future<ArtworkColorScheme> extract({
    String? imageUrl,
    List<String>? mosaicUrls,
    Uint8List? imageBytes,
    int? songId,
    String? cacheKey,
  }) async {
    if (songId != null) {
      return extractFromSongId(songId, cacheKey: cacheKey);
    }
    if (imageBytes != null && imageBytes.isNotEmpty) {
      return extractFromBytes(imageBytes, cacheKey: cacheKey ?? imageUrl);
    }
    if (mosaicUrls != null && mosaicUrls.length >= 4) {
      return extractFromMosaic(mosaicUrls.take(4).toList());
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return extractFromUrl(imageUrl, cacheKey: cacheKey);
    }
    return ArtworkColorScheme.neutral;
  }

  /// Returns synchronously cached scheme if present.
  ArtworkColorScheme? getCached(String key) => _cache.get(key);

  /// Extracts from a local song's artwork.
  Future<ArtworkColorScheme> extractFromSongId(
    int songId, {
    String? cacheKey,
  }) async {
    final key = cacheKey ?? 'song_$songId';
    final cached = _cache.get(key);
    if (cached != null) return cached;

    if (_artworkFetcher == null) return ArtworkColorScheme.neutral;

    try {
      final bytes = await _artworkFetcher(songId);
      if (bytes != null && bytes.isNotEmpty) {
        return await extractFromBytes(bytes, cacheKey: key);
      }
    } catch (e) {
      dev.log('ColorExtraction: extractFromSongId failed: $e');
    }
    return ArtworkColorScheme.neutral;
  }

  /// Extracts from raw image bytes.
  Future<ArtworkColorScheme> extractFromBytes(
    Uint8List bytes, {
    String? cacheKey,
  }) async {
    if (cacheKey != null) {
      final cached = _cache.get(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 200,
        targetHeight: 200,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      try {
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (byteData == null) return ArtworkColorScheme.neutral;

        final rawRgba = byteData.buffer.asUint8List();

        // Run pre-filtering, quantization, and scheme derivation in isolate
        final schemeArgbs = await Isolate.run(() async {
          final pixels = _filterAndConvertPixels(rawRgba);
          final quantizer = QuantizerCelebi();
          final result = await quantizer.quantize(pixels, 128);
          return SchemeDeriver.derive(result.colorToCount);
        });

        final scheme = ArtworkColorScheme.fromArgbList(schemeArgbs);

        if (cacheKey != null) {
          await _cache.put(cacheKey, scheme);
        }
        return scheme;
      } finally {
        image.dispose();
      }
    } catch (e) {
      dev.log('ColorExtraction: extractFromBytes failed: $e');
      return ArtworkColorScheme.neutral;
    }
  }

  /// Extracts from a single image URL.
  Future<ArtworkColorScheme> extractFromUrl(
    String imageUrl, {
    String? cacheKey,
  }) async {
    final key = cacheKey ?? imageUrl;
    final cached = _cache.get(key) ?? _cache.get(imageUrl);
    if (cached != null) return cached;

    try {
      final file = await _cacheManager.getSingleFile(imageUrl);
      final bytes = await file.readAsBytes();
      final scheme = await extractFromBytes(bytes);

      await _cache.put(imageUrl, scheme);
      if (cacheKey != null && cacheKey != imageUrl) {
        await _cache.put(cacheKey, scheme);
      }
      return scheme;
    } catch (e) {
      dev.log('ColorExtraction: extractFromUrl failed: $e');
      return ArtworkColorScheme.neutral;
    }
  }

  /// Extracts from a playlist mosaic.
  ///
  /// Matches Spotify: anchors header theming on Track 0 (top-left tile).
  /// Falls back to remaining tiles, then composite 2x2 grid.
  Future<ArtworkColorScheme> extractFromMosaic(List<String> mosaicUrls) async {
    if (mosaicUrls.isEmpty) return ArtworkColorScheme.neutral;
    final mosaicKey = 'mosaic:${mosaicUrls.take(4).join('|')}';

    final cached = _cache.get(mosaicKey);
    if (cached != null) return cached;

    // 1. Primary track extraction (Track 0)
    final primaryScheme = await extractFromUrl(mosaicUrls.first);
    if (!primaryScheme.isNeutral) {
      await _cache.put(mosaicKey, primaryScheme);
      return primaryScheme;
    }

    // 2. Fallback to subsequent tracks
    for (int i = 1; i < math.min(mosaicUrls.length, 4); i++) {
      final tileScheme = await extractFromUrl(mosaicUrls[i]);
      if (!tileScheme.isNeutral) {
        await _cache.put(mosaicKey, tileScheme);
        return tileScheme;
      }
    }

    if (mosaicUrls.length < 4) return ArtworkColorScheme.neutral;

    // 3. Composite 2x2 grid
    try {
      final files = await Future.wait(
        mosaicUrls.take(4).map((url) => _cacheManager.getSingleFile(url)),
      );

      final tileImages = <ui.Image>[];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: 100,
          targetHeight: 100,
        );
        final frame = await codec.getNextFrame();
        tileImages.add(frame.image);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      const half = 100.0;
      final paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;

      canvas.drawImage(tileImages[0], const ui.Offset(0, 0), paint);
      canvas.drawImage(tileImages[1], const ui.Offset(half, 0), paint);
      canvas.drawImage(tileImages[2], const ui.Offset(0, half), paint);
      canvas.drawImage(tileImages[3], const ui.Offset(half, half), paint);

      final picture = recorder.endRecording();
      final composite = await picture.toImage(200, 200);

      for (final img in tileImages) {
        img.dispose();
      }

      try {
        final byteData =
            await composite.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (byteData == null) return ArtworkColorScheme.neutral;

        final rawRgba = byteData.buffer.asUint8List();

        final schemeArgbs = await Isolate.run(() async {
          final pixels = _filterAndConvertPixels(rawRgba);
          final quantizer = QuantizerCelebi();
          final result = await quantizer.quantize(pixels, 128);
          return SchemeDeriver.derive(result.colorToCount);
        });

        final scheme = ArtworkColorScheme.fromArgbList(schemeArgbs);
        await _cache.put(mosaicKey, scheme);
        return scheme;
      } finally {
        composite.dispose();
      }
    } catch (e) {
      dev.log('ColorExtraction: extractFromMosaic composite failed: $e');
      return ArtworkColorScheme.neutral;
    }
  }

  /// Converts RGBA bytes to ARGB32 ints, stripping pure black borders,
  /// blown-out white cards, and sterile grays.
  static List<int> _filterAndConvertPixels(Uint8List rgba) {
    final pixelCount = rgba.length ~/ 4;
    final allPixels = List<int>.filled(pixelCount, 0);
    final filtered = <int>[];

    for (int i = 0; i < pixelCount; i++) {
      final off = i * 4;
      final r = rgba[off];
      final g = rgba[off + 1];
      final b = rgba[off + 2];
      final argb = 0xFF000000 | (r << 16) | (g << 8) | b;
      allPixels[i] = argb;

      final maxC = math.max(r, math.max(g, b));
      final minC = math.min(r, math.min(g, b));
      final delta = maxC - minC;

      // Filter extreme blacks (letterboxing, pure dark borders)
      if (maxC < 22) continue;
      // Filter extreme whites (margins, glare)
      if (minC > 238) continue;
      // Filter completely desaturated gray
      if (delta < 14) continue;

      filtered.add(argb);
    }

    // If at least 8% of pixels passed, use the clean filtered set.
    // Otherwise fallback to all pixels (handles monochrome/dark art).
    if (filtered.length >= pixelCount * 0.08) {
      return filtered;
    }
    return allPixels;
  }

  /// Initializes the cache. Call once at startup.
  Future<void> init() => _cache.load();

  @visibleForTesting
  static List<int> testDerive(Map<int, int> colorToPopulation) =>
      SchemeDeriver.derive(colorToPopulation);
}
