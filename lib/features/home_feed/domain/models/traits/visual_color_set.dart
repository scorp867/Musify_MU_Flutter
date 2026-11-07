import 'package:flutter/material.dart';

/// Complete Spotify Encore palette color set.
/// 1:1 replica of `spotify.contentagnostic.v2.ColorSet` and `p/sxs.java`.
@immutable
final class VisualColorSet {
  final int backgroundBase;
  final int backgroundTintedBase;
  final int textBase;
  final int textSubdued;
  final int textBrightAccent;

  const VisualColorSet({
    required this.backgroundBase,
    required this.backgroundTintedBase,
    required this.textBase,
    required this.textSubdued,
    required this.textBrightAccent,
  });

  Color get backgroundBaseColor => Color(backgroundBase);
  Color get backgroundTintedBaseColor => Color(backgroundTintedBase);
  Color get textBaseColor => Color(textBase);
  Color get textSubduedColor => Color(textSubdued);
  Color get textBrightAccentColor => Color(textBrightAccent);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VisualColorSet &&
        other.backgroundBase == backgroundBase &&
        other.backgroundTintedBase == backgroundTintedBase &&
        other.textBase == textBase &&
        other.textSubdued == textSubdued &&
        other.textBrightAccent == textBrightAccent;
  }

  @override
  int get hashCode => Object.hash(
    backgroundBase,
    backgroundTintedBase,
    textBase,
    textSubdued,
    textBrightAccent,
  );
}
