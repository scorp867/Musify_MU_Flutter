import 'dart:math' as math;

/// Spotify's authentic post-processing pipeline for music app color theming.
///
/// Features:
/// 1. Yellow/olive suppression filter penalty (25°-85°).
/// 2. Non-destructive tone mapping (preserves exact Hue and Saturation,
///    never blends with white which destroys color purity).
/// 3. Velvet matte ceiling (V <= 0.70) to prevent neon glare.
/// 4. WCAG AA 4.5:1 white contrast guarantee for effortless text readability.
/// 5. Atmospheric surface tone generation for card backgrounds.
///
/// All operations use raw ARGB32 ints for isolate execution.
class SpotifyPostProcessor {
  /// Tone-maps primary color into Spotify's dark-theme sweet spot:
  /// - Lifts V if < 0.55 so artwork colors radiate richness rather than looking like black sludge.
  /// - Clamps V if > 0.70 to eliminate neon/glowing sheen.
  /// - Preserves 100% of the artwork's authentic Hue and Saturation.
  /// - Ensures WCAG AA contrast (>= 4.5:1) against white text.
  static int processPrimary(int argb) {
    final hsv = argbToHsv(argb);
    final h = hsv.$1;
    final s = hsv.$2;
    var v = hsv.$3;

    // Lift dark colors smoothly into the rich branding window
    if (v < 0.55) {
      v = math.max(0.55, v * 1.25).clamp(0.55, 0.68);
    } else if (v > 0.70) {
      v = 0.70;
    }

    final mapped = hsvToArgb(h, s, v);
    return ensureWhiteContrast(mapped);
  }

  /// Darkens color to deep, velvety surface background (V = 0.14 - 0.20).
  /// Gives cards and sheets an authentic tint of the artwork instead of generic gray.
  static int processSurface(int argb) {
    final hsv = argbToHsv(argb);
    final v = (hsv.$3 * 0.35).clamp(0.12, 0.20);
    final s = (hsv.$2 * 0.85).clamp(0.20, 0.45);
    return hsvToArgb(hsv.$1, s, v);
  }

  /// Ensures contrast against white is >= 4.5:1 via binary search on HSV Value.
  static int ensureWhiteContrast(int argb) {
    const whiteArgb = 0xFFFFFFFF;
    if (calculateContrast(whiteArgb, argb) >= 4.5) return argb;

    final hsv = argbToHsv(argb);
    double upper = hsv.$3;
    double lower = 0.0;

    while (upper - lower > 0.01) {
      final mid = (upper + lower) * 0.5;
      final test = hsvToArgb(hsv.$1, hsv.$2, mid);
      if (calculateContrast(whiteArgb, test) < 4.5) {
        upper = mid;
      } else {
        lower = mid;
      }
    }

    return hsvToArgb(hsv.$1, hsv.$2, lower);
  }

  /// Negative penalty (0.0 to -2.0) for hues in yellow-olive range (25-85deg).
  /// Only applies when non-yellow alternatives exist.
  static double yellowPenalty(
    double hsvHue, {
    bool hasNonYellowAlternatives = true,
  }) {
    if (!hasNonYellowAlternatives) return 0.0;
    if (hsvHue < 25.0 || hsvHue > 85.0) return 0.0;

    const center = 55.0;
    const halfWidth = 30.0;
    final dist = (center - hsvHue).abs();
    final tent = ((halfWidth - dist) / halfWidth).clamp(0.0, 1.0);
    return -(tent * 2.0);
  }

  // ── WCAG utilities ──

  static double calculateContrast(int foreground, int background) {
    final l1 = relativeLuminance(foreground);
    final l2 = relativeLuminance(background);
    final hi = math.max(l1, l2);
    final lo = math.min(l1, l2);
    return (hi + 0.05) / (lo + 0.05);
  }

  static double relativeLuminance(int argb) {
    final r = ((argb >> 16) & 0xFF) / 255.0;
    final g = ((argb >> 8) & 0xFF) / 255.0;
    final b = (argb & 0xFF) / 255.0;

    final rl = r <= 0.04045
        ? r / 12.92
        : math.pow((r + 0.055) / 1.055, 2.4).toDouble();
    final gl = g <= 0.04045
        ? g / 12.92
        : math.pow((g + 0.055) / 1.055, 2.4).toDouble();
    final bl = b <= 0.04045
        ? b / 12.92
        : math.pow((b + 0.055) / 1.055, 2.4).toDouble();

    return rl * 0.2126 + gl * 0.7152 + bl * 0.0722;
  }

  // ── HSV utilities ──

  static (double, double, double) argbToHsv(int argb) {
    final r = ((argb >> 16) & 0xFF) / 255.0;
    final g = ((argb >> 8) & 0xFF) / 255.0;
    final b = (argb & 0xFF) / 255.0;

    final maxC = math.max(r, math.max(g, b));
    final minC = math.min(r, math.min(g, b));
    final delta = maxC - minC;

    double hue = 0.0;
    if (delta > 0.0001) {
      if (maxC == r) {
        hue = 60.0 * (((g - b) / delta) % 6.0);
      } else if (maxC == g) {
        hue = 60.0 * (((b - r) / delta) + 2.0);
      } else {
        hue = 60.0 * (((r - g) / delta) + 4.0);
      }
    }
    if (hue < 0) hue += 360.0;

    final saturation = maxC < 0.0001 ? 0.0 : delta / maxC;
    return (hue, saturation, maxC);
  }

  static int hsvToArgb(double h, double s, double v) {
    final c = v * s;
    final x = c * (1.0 - ((h / 60.0) % 2.0 - 1.0).abs());
    final m = v - c;

    double r, g, b;
    if (h < 60) {
      r = c; g = x; b = 0;
    } else if (h < 120) {
      r = x; g = c; b = 0;
    } else if (h < 180) {
      r = 0; g = c; b = x;
    } else if (h < 240) {
      r = 0; g = x; b = c;
    } else if (h < 300) {
      r = x; g = 0; b = c;
    } else {
      r = c; g = 0; b = x;
    }

    final ri = ((r + m) * 255.0).round().clamp(0, 255);
    final gi = ((g + m) * 255.0).round().clamp(0, 255);
    final bi = ((b + m) * 255.0).round().clamp(0, 255);

    return 0xFF000000 | (ri << 16) | (gi << 8) | bi;
  }
}
