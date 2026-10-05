import 'package:flutter/widgets.dart';

/// Builds a Spotify-style eased gradient between an extracted color
/// and the app's background color.
///
/// Replicates the gradient from Spotify's `MainLayoutGradientView.java`:
/// - 21 color stops
/// - Cubic bezier easing: (0.51, 0.0, 0.26, 1.0)
/// - Interpolates from [topColor] at the top to [bottomColor] at the bottom
///
/// The easing curve causes the extracted color to dominate the upper portion
/// and fade smoothly into the background, creating a natural, non-linear
/// transition that looks significantly better than a 2-stop linear gradient.
class EasedGradient {
  static const _stopCount = 21;

  /// The cubic bezier curve Spotify uses for gradient easing.
  /// Control points: (0.51, 0.0) and (0.26, 1.0)
  static const _easing = Cubic(0.51, 0.0, 0.26, 1.0);

  const EasedGradient._();

  /// Builds a vertical [Gradient] from [topColor] to [bottomColor]
  /// using Spotify's 21-stop eased interpolation.
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

    for (int i = 0; i < _stopCount; i++) {
      final t = i / (_stopCount - 1);
      // Apply cubic bezier easing to the interpolation parameter.
      // This makes the top color persist longer before fading.
      final easedT = _easing.transform(t);
      colors.add(Color.lerp(topColor, bottomColor, easedT)!);
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
