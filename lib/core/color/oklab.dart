import 'dart:math' as math;

/// OKLab perceptual color space (Björn Ottosson, 2020).
///
/// Unlike CIELAB, OKLab has no blue-to-purple hue shift, making it
/// ideal for album art color extraction where blue covers are common.
///
/// All operations use raw ARGB32 ints to enable execution in
/// Dart isolates without dart:ui dependency.
class OkLabColor {
  /// Perceptual lightness (0.0 = black, 1.0 = white)
  final double L;

  /// Green-red opponent axis
  final double a;

  /// Blue-yellow opponent axis
  final double b;

  const OkLabColor(this.L, this.a, this.b);

  /// Converts sRGB ARGB32 int to OKLab.
  factory OkLabColor.fromArgb(int argb) {
    final r = _srgbToLinear(((argb >> 16) & 0xFF) / 255.0);
    final g = _srgbToLinear(((argb >> 8) & 0xFF) / 255.0);
    final b = _srgbToLinear((argb & 0xFF) / 255.0);

    final l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b;
    final m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b;
    final s = 0.0883024619 * r + 0.2024326033 * g + 0.6992649378 * b;

    final lc = _cbrt(l);
    final mc = _cbrt(m);
    final sc = _cbrt(s);

    return OkLabColor(
      0.2104542553 * lc + 0.7936177850 * mc - 0.0040720468 * sc,
      1.9779984951 * lc - 2.4285922050 * mc + 0.4505937099 * sc,
      0.0259040371 * lc + 0.7827717662 * mc - 0.8086757660 * sc,
    );
  }

  /// Converts back to sRGB ARGB32 int.
  int toArgb() {
    final l_ = L + 0.3963377774 * a + 0.2158037573 * b;
    final m_ = L - 0.1055613458 * a - 0.0638541728 * b;
    final s_ = L - 0.0894841775 * a - 1.2914855480 * b;

    final l = l_ * l_ * l_;
    final m = m_ * m_ * m_;
    final s = s_ * s_ * s_;

    final rLin = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s;
    final gLin = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s;
    final bLin = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s;

    final ri = (_linearToSrgb(rLin) * 255.0).round().clamp(0, 255);
    final gi = (_linearToSrgb(gLin) * 255.0).round().clamp(0, 255);
    final bi = (_linearToSrgb(bLin) * 255.0).round().clamp(0, 255);

    return 0xFF000000 | (ri << 16) | (gi << 8) | bi;
  }

  /// Chroma (colorfulness) = sqrt(a² + b²).
  double get chroma => math.sqrt(a * a + b * b);

  /// Hue angle in degrees [0, 360).
  double get hue {
    final h = math.atan2(b, a) * 180.0 / math.pi;
    return h < 0 ? h + 360.0 : h;
  }

  /// Squared Euclidean distance in OKLab (avoids sqrt for comparisons).
  double distanceSquaredTo(OkLabColor other) {
    final dL = L - other.L;
    final da = a - other.a;
    final db = b - other.b;
    return dL * dL + da * da + db * db;
  }

  /// Euclidean distance in OKLab (perceptual distance).
  double distanceTo(OkLabColor other) =>
      math.sqrt(distanceSquaredTo(other));

  static double _srgbToLinear(double x) {
    if (x <= 0.04045) return x / 12.92;
    return math.pow((x + 0.055) / 1.055, 2.4).toDouble();
  }

  static double _linearToSrgb(double x) {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;
    if (x <= 0.0031308) return x * 12.92;
    return 1.055 * math.pow(x, 1.0 / 2.4) - 0.055;
  }

  static double _cbrt(double x) {
    if (x >= 0) return math.pow(x, 1.0 / 3.0).toDouble();
    return -math.pow(-x, 1.0 / 3.0).toDouble();
  }
}
