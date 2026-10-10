import 'dart:math' as math;

import 'package:musify_mu/core/color/oklab.dart';
import 'package:musify_mu/core/color/spotify_post_processor.dart';

/// Derives a full 5-color [ArtworkColorScheme] from quantized clusters.
///
/// Features:
/// 1. Strict filtering of extreme dark sludge (V < 0.12) and blown-out whites (V > 0.94, S < 0.12).
/// 2. Saturation-forward candidate scoring with bell-curve luminance targeting.
/// 3. Yellow/olive suppression penalty when other vibrant colors exist.
/// 4. Non-destructive tone mapping that preserves authentic album hue and saturation.
/// 5. Secondary selection guaranteed free of dark sludge (V >= 0.35, S >= 0.20).
/// 6. Electric accent selection allowing full unconstrained vibrancy for highlights.
/// 7. Deep, tinted surface generation for cards/sheets.
/// 8. Graceful dark slate handling for monochrome/black-and-white artwork.
class SchemeDeriver {
  static const _secondaryMinDistance = 0.12;
  static const _minColorfulSat = 0.18;

  /// Derives scheme from Quantizer result.
  ///
  /// [colorToPopulation]: map of ARGB32 int -> pixel count.
  /// Returns list of 6 ints: [primary, secondary, accent, onPrimary, surface, isNeutral].
  static List<int> derive(Map<int, int> colorToPopulation) {
    const neutralResult = [
      0xFF282828, 0xFF333333, 0xFF535353, 0xFFFFFFFF, 0xFF181818, 1,
    ];

    if (colorToPopulation.isEmpty) return neutralResult;

    final totalPop =
        colorToPopulation.values.fold<int>(0, (sum, p) => sum + p);
    final safeTotalPop = totalPop > 0 ? totalPop : 1;

    // Build candidates, rejecting extreme dark sludge and blown-out whites
    final candidates = <_Candidate>[];
    for (final entry in colorToPopulation.entries) {
      final argb = entry.key;
      final pop = entry.value;
      final hsv = SpotifyPostProcessor.argbToHsv(argb);
      final lab = OkLabColor.fromArgb(argb);
      final popRatio = pop / safeTotalPop;

      // Filter extreme blacks/dark sludge (V < 0.12)
      if (hsv.$3 < 0.12) continue;
      // Filter extreme whites / washed-out highlights (V > 0.94 and S < 0.12)
      if (hsv.$3 > 0.94 && hsv.$2 < 0.12) continue;

      candidates.add(_Candidate(
        argb: argb,
        pop: pop,
        popRatio: popRatio,
        h: hsv.$1,
        s: hsv.$2,
        v: hsv.$3,
        lab: lab,
      ));
    }

    // Fallback if all clusters were filtered out
    if (candidates.isEmpty) {
      for (final entry in colorToPopulation.entries) {
        final argb = entry.key;
        final pop = entry.value;
        final hsv = SpotifyPostProcessor.argbToHsv(argb);
        final lab = OkLabColor.fromArgb(argb);
        candidates.add(_Candidate(
          argb: argb,
          pop: pop,
          popRatio: pop / safeTotalPop,
          h: hsv.$1,
          s: hsv.$2,
          v: hsv.$3,
          lab: lab,
        ));
      }
    }

    if (candidates.isEmpty) return neutralResult;

    // Check if there are non-yellow colorful candidates
    final hasNonYellow = candidates.any(
      (c) => (c.h < 25.0 || c.h > 85.0) && c.s >= _minColorfulSat,
    );

    // Score candidates
    for (final c in candidates) {
      // Saturation is highest priority for music branding
      final sScore = math.pow(c.s, 1.4);
      // Bell curve preference centered at sweet-spot brightness (V = 0.58)
      final vScore = 1.0 - (c.v - 0.58).abs() * 0.65;
      // Population bonus with diminishing returns
      final pScore = math.log(1.0 + c.popRatio * 15.0) * 0.40;
      // Yellow/olive penalty
      final yPenalty = SpotifyPostProcessor.yellowPenalty(
        c.h,
        hasNonYellowAlternatives: hasNonYellow,
      );

      c.score = (sScore * vScore) + pScore + yPenalty;
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    final best = candidates.first;

    final isNeutral = best.s < _minColorfulSat;

    // ── Primary ──
    final int primaryArgb;
    if (isNeutral) {
      // Elegant dark slate for monochrome artwork
      primaryArgb = SpotifyPostProcessor.hsvToArgb(best.h, 0.08, 0.32);
    } else {
      // Process through authentic Spotify tone mapping
      primaryArgb = SpotifyPostProcessor.processPrimary(best.argb);
    }

    final primaryLab = OkLabColor.fromArgb(primaryArgb);

    // ── Secondary ──
    // Distinct colorful candidate, strictly rejecting dark sludge and grays
    int secondaryArgb = 0;
    if (!isNeutral) {
      for (final c in candidates) {
        if (c.argb == best.argb) continue;
        if (c.s < 0.20 || c.v < 0.28) continue; // no dark sludge, no gray
        if (c.lab.distanceTo(primaryLab) > _secondaryMinDistance) {
          final secV = c.v.clamp(0.40, 0.65);
          secondaryArgb = SpotifyPostProcessor.hsvToArgb(c.h, c.s, secV);
          break;
        }
      }
    }

    if (secondaryArgb == 0) {
      // Harmonious analogue shift by 28 degrees
      final hsv = SpotifyPostProcessor.argbToHsv(primaryArgb);
      secondaryArgb = SpotifyPostProcessor.hsvToArgb(
        (hsv.$1 + 28.0) % 360.0,
        (hsv.$2 * 0.80).clamp(0.0, 1.0),
        (hsv.$3 * 0.85).clamp(0.28, 0.60),
      );
    }

    // ── Accent ──
    // Most vibrant/electric color in the artwork, unconstrained by matte ceilings
    final bySat = List<_Candidate>.from(candidates)
      ..sort((a, b) => b.s.compareTo(a.s));

    int accentArgb;
    if (!isNeutral && bySat.first.s >= 0.25) {
      final acc = bySat.first;
      accentArgb = SpotifyPostProcessor.hsvToArgb(
        acc.h,
        acc.s,
        acc.v.clamp(0.60, 0.95),
      );
    } else {
      // Brightened primary for subtle accent
      final hsv = SpotifyPostProcessor.argbToHsv(primaryArgb);
      accentArgb = SpotifyPostProcessor.hsvToArgb(
        hsv.$1,
        (hsv.$2 * 1.1).clamp(0.0, 1.0),
        (hsv.$3 * 1.3).clamp(0.50, 0.85),
      );
    }

    // ── Surface ──
    final surfaceArgb = SpotifyPostProcessor.processSurface(primaryArgb);

    // ── OnPrimary ──
    final onPrimaryArgb =
        SpotifyPostProcessor.calculateContrast(0xFFFFFFFF, primaryArgb) >= 4.5
            ? 0xFFFFFFFF
            : 0xFF121212;

    return [
      primaryArgb,
      secondaryArgb,
      accentArgb,
      onPrimaryArgb,
      surfaceArgb,
      isNeutral ? 1 : 0,
    ];
  }
}

class _Candidate {
  final int argb;
  final int pop;
  final double popRatio;
  final double h;
  final double s;
  final double v;
  final OkLabColor lab;
  double score = 0.0;

  _Candidate({
    required this.argb,
    required this.pop,
    required this.popRatio,
    required this.h,
    required this.s,
    required this.v,
    required this.lab,
  });
}
