import 'package:flutter/widgets.dart';

/// Builds a Spotify-style atmospheric gradient between an extracted color
/// and the app's dark background color (#121212).
///
/// Matches Spotify's decompiled playlist header rendering (p.wma1.f and p.n6r.d):
/// - Continuous linear-diffuse interpolation across 21 stops without a harsh specular shelf
/// - Eliminates glossy highlight glare, giving the header an authentic velvety matte finish
class EasedGradient {
  static const _stopCount = 21;

  const EasedGradient._();

  /// Builds a vertical [Gradient] from [topColor] to [bottomColor]
  /// using Spotify's smooth matte interpolation.
  ///
  /// [topColor] is typically the extracted swatch color.
  /// [bottomColor] defaults to `#121212` (Spotify's dark background).
  static Gradient build({
    required Color topColor,
    Color bottomColor = const Color(0xFF121212),
    AlignmentGeometry begin = Alignment.topCenter,
    AlignmentGeometry end = Alignment.bottomCenter,
  }) {
    final colors = <Color>[];
    final stops = <double>[];

    // Ensure the top color respects Spotify's matte luminance ceiling
    final hsv = HSVColor.fromColor(topColor);
    final matteColor = hsv.value > 0.70 ? hsv.withValue(0.70).toColor() : topColor;

    for (int i = 0; i < _stopCount; i++) {
      final t = i / (_stopCount - 1);
      colors.add(Color.lerp(matteColor, bottomColor, t)!);
      stops.add(t);
    }

    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
      stops: stops,
    );
  }
}
