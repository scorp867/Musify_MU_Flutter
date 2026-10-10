import 'dart:ui' as ui;

/// Immutable 5-color scheme extracted from artwork.
///
/// Provides all colors needed to theme any UI surface
/// (miniplayer, now-playing screen, playlist headers)
/// without nullable fallbacks.
///
/// The extraction pipeline guarantees all 5 colors are populated:
/// K-Means always converges to k centroids, so there is no
/// failure mode that requires a null/fallback color.
class ArtworkColorScheme {
  /// Dominant vibrant color from the artwork.
  /// Post-processed: WCAG contrast, luminance floor, matte ceiling.
  final ui.Color primary;

  /// Supporting color, perceptually distinct from [primary].
  /// Has OKLab distance > 0.15 from primary.
  final ui.Color secondary;

  /// Most vivid color in the artwork.
  /// NOT clamped by matte ceiling (allowed to be vivid).
  final ui.Color accent;

  /// Guaranteed-readable text color on [primary].
  /// Either white (0xFFFFFFFF) or near-black (0xFF121212).
  final ui.Color onPrimary;

  /// Deep dark variant of [primary] (HSV V <= 0.25).
  /// Used for cards, bottom sheets, surfaces.
  final ui.Color surface;

  /// Whether the source image had no colorful clusters.
  /// Used by mosaic extraction to decide whether to try
  /// the next tile.
  final bool isNeutral;

  const ArtworkColorScheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.onPrimary,
    required this.surface,
    this.isNeutral = false,
  });

  /// Neutral scheme for when no artwork is available.
  static const neutral = ArtworkColorScheme(
    primary: ui.Color(0xFF282828),
    secondary: ui.Color(0xFF333333),
    accent: ui.Color(0xFF535353),
    onPrimary: ui.Color(0xFFFFFFFF),
    surface: ui.Color(0xFF181818),
    isNeutral: true,
  );

  /// Serializes to a list of 6 ints for isolate transfer and cache storage.
  /// [primary, secondary, accent, onPrimary, surface, isNeutral(0|1)]
  List<int> toArgbList() => [
        primary.toARGB32(),
        secondary.toARGB32(),
        accent.toARGB32(),
        onPrimary.toARGB32(),
        surface.toARGB32(),
        isNeutral ? 1 : 0,
      ];

  /// Deserializes from a list of 6 ints.
  factory ArtworkColorScheme.fromArgbList(List<int> argb) {
    assert(argb.length >= 5);
    return ArtworkColorScheme(
      primary: ui.Color(argb[0]),
      secondary: ui.Color(argb[1]),
      accent: ui.Color(argb[2]),
      onPrimary: ui.Color(argb[3]),
      surface: ui.Color(argb[4]),
      isNeutral: argb.length > 5 && argb[5] == 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtworkColorScheme &&
          primary == other.primary &&
          secondary == other.secondary &&
          accent == other.accent &&
          onPrimary == other.onPrimary &&
          surface == other.surface &&
          isNeutral == other.isNeutral;

  @override
  int get hashCode =>
      Object.hash(primary, secondary, accent, onPrimary, surface, isNeutral);

  @override
  String toString() =>
      'ArtworkColorScheme(primary: ${_hex(primary)}, secondary: ${_hex(secondary)}, '
      'accent: ${_hex(accent)}, onPrimary: ${_hex(onPrimary)}, '
      'surface: ${_hex(surface)}, isNeutral: $isNeutral)';

  static String _hex(ui.Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
}
