import 'package:flutter/material.dart';
import 'trait.dart';

/// Complete Spotify Encore palette color set.
/// 1:1 replica of `spotify.contentagnostic.v2.ColorSet` and `p/sxs.java`.
class VisualColorSet {
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

  Map<String, dynamic> toJson() => {
    'backgroundBase': backgroundBase,
    'backgroundTintedBase': backgroundTintedBase,
    'textBase': textBase,
    'textSubdued': textSubdued,
    'textBrightAccent': textBrightAccent,
  };

  factory VisualColorSet.fromJson(Map<String, dynamic> json) => VisualColorSet(
    backgroundBase: json['backgroundBase'] as int? ?? 0xFF353535,
    backgroundTintedBase: json['backgroundTintedBase'] as int? ?? 0xFF565656,
    textBase: json['textBase'] as int? ?? 0xFFFFFFFF,
    textSubdued: json['textSubdued'] as int? ?? 0xFFCDCDCD,
    textBrightAccent: json['textBrightAccent'] as int? ?? 0xFF1ED760,
  );
}

/// Visual identity metadata (ExtensionKind 179).
/// Carries square cover art, 16:9 video cover art, full-bleed images,
/// and Spotify curated + extracted color palettes across contrast tiers.
/// 1:1 replica of `com.spotify.contentagnostic.v2.VisualIdentityTrait` (`p/sw71.java`).
class VisualIdentityTrait extends Trait {
  final String? squareCoverUrl;
  final String? sixteenByNineCoverUrl;
  final String? wideFullBleedUrl;
  final String? squareFullBleedUrl;
  final String? videoNineBySixteenUrl;
  final bool hasVideo;

  /// Contrast options (low, medium, high).
  /// Spotify's Now Playing lyrics card specifically selects [higherContrast] (`p/rm2.java:126`).
  final VisualColorSet? minContrast;
  final VisualColorSet? highContrast;
  final VisualColorSet? higherContrast;

  /// Legacy hex properties for backward compatibility.
  final String? backgroundColorHex;
  final String? textColorHex;
  final String? textSubduedColorHex;

  const VisualIdentityTrait({
    this.squareCoverUrl,
    this.sixteenByNineCoverUrl,
    this.wideFullBleedUrl,
    this.squareFullBleedUrl,
    this.videoNineBySixteenUrl,
    this.hasVideo = false,
    this.minContrast,
    this.highContrast,
    this.higherContrast,
    this.backgroundColorHex,
    this.textColorHex,
    this.textSubduedColorHex,
  });

  /// The active color set for high-contrast cards (e.g. lyrics preview).
  VisualColorSet? get preferredCardPalette =>
      higherContrast ?? highContrast ?? minContrast;

  @override
  Map<String, dynamic> toJson() => {
    'squareCoverUrl': squareCoverUrl,
    'sixteenByNineCoverUrl': sixteenByNineCoverUrl,
    'wideFullBleedUrl': wideFullBleedUrl,
    'squareFullBleedUrl': squareFullBleedUrl,
    'videoNineBySixteenUrl': videoNineBySixteenUrl,
    'hasVideo': hasVideo,
    if (minContrast != null) 'minContrast': minContrast!.toJson(),
    if (highContrast != null) 'highContrast': highContrast!.toJson(),
    if (higherContrast != null) 'higherContrast': higherContrast!.toJson(),
    'backgroundColorHex': backgroundColorHex,
    'textColorHex': textColorHex,
    'textSubduedColorHex': textSubduedColorHex,
  };

  factory VisualIdentityTrait.fromJson(Map<String, dynamic> json) =>
      VisualIdentityTrait(
        squareCoverUrl: json['squareCoverUrl'],
        sixteenByNineCoverUrl: json['sixteenByNineCoverUrl'],
        wideFullBleedUrl: json['wideFullBleedUrl'],
        squareFullBleedUrl: json['squareFullBleedUrl'],
        videoNineBySixteenUrl: json['videoNineBySixteenUrl'],
        hasVideo: json['hasVideo'] ?? false,
        minContrast: json['minContrast'] != null
            ? VisualColorSet.fromJson(
                json['minContrast'] as Map<String, dynamic>)
            : null,
        highContrast: json['highContrast'] != null
            ? VisualColorSet.fromJson(
                json['highContrast'] as Map<String, dynamic>)
            : null,
        higherContrast: json['higherContrast'] != null
            ? VisualColorSet.fromJson(
                json['higherContrast'] as Map<String, dynamic>)
            : null,
        backgroundColorHex: json['backgroundColorHex'],
        textColorHex: json['textColorHex'],
        textSubduedColorHex: json['textSubduedColorHex'],
      );
}
