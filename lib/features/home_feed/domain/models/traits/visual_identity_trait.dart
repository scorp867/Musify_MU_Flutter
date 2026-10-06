import 'trait.dart';

/// Visual identity metadata (ExtensionKind 179).
/// Carries square cover art, 16:9 video cover art, full-bleed images,
/// and Spotify curated color palette (background and text colors).
class VisualIdentityTrait extends Trait {
  final String? squareCoverUrl;
  final String? sixteenByNineCoverUrl;
  final String? wideFullBleedUrl;
  final String? squareFullBleedUrl;
  final String? videoNineBySixteenUrl;
  final bool hasVideo;
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
    this.backgroundColorHex,
    this.textColorHex,
    this.textSubduedColorHex,
  });

  @override
  Map<String, dynamic> toJson() => {
    'squareCoverUrl': squareCoverUrl,
    'sixteenByNineCoverUrl': sixteenByNineCoverUrl,
    'wideFullBleedUrl': wideFullBleedUrl,
    'squareFullBleedUrl': squareFullBleedUrl,
    'videoNineBySixteenUrl': videoNineBySixteenUrl,
    'hasVideo': hasVideo,
    'backgroundColorHex': backgroundColorHex,
    'textColorHex': textColorHex,
    'textSubduedColorHex': textSubduedColorHex,
  };

  factory VisualIdentityTrait.fromJson(Map<String, dynamic> json) => VisualIdentityTrait(
    squareCoverUrl: json['squareCoverUrl'],
    sixteenByNineCoverUrl: json['sixteenByNineCoverUrl'],
    wideFullBleedUrl: json['wideFullBleedUrl'],
    squareFullBleedUrl: json['squareFullBleedUrl'],
    videoNineBySixteenUrl: json['videoNineBySixteenUrl'],
    hasVideo: json['hasVideo'] ?? false,
    backgroundColorHex: json['backgroundColorHex'],
    textColorHex: json['textColorHex'],
    textSubduedColorHex: json['textSubduedColorHex'],
  );
}
