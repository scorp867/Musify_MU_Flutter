import 'package:flutter/foundation.dart';

import 'trait.dart';
import 'visual_color_set.dart';

/// Visual identity metadata (ExtensionKind 179).
/// 1:1 replica of `com.spotify.contentagnostic.v2.VisualIdentityTrait` (`p/sw71.java`).
@immutable
final class VisualIdentityTrait extends Trait {
  final String? squareCoverUrl;
  final String? sixteenByNineCoverUrl;
  final String? wideFullBleedUrl;
  final String? squareFullBleedUrl;
  final String? videoNineBySixteenUrl;
  final bool hasVideo;

  final VisualColorSet? minContrast;
  final VisualColorSet? highContrast;
  final VisualColorSet? higherContrast;

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VisualIdentityTrait &&
        other.squareCoverUrl == squareCoverUrl &&
        other.sixteenByNineCoverUrl == sixteenByNineCoverUrl &&
        other.wideFullBleedUrl == wideFullBleedUrl &&
        other.squareFullBleedUrl == squareFullBleedUrl &&
        other.videoNineBySixteenUrl == videoNineBySixteenUrl &&
        other.hasVideo == hasVideo &&
        other.minContrast == minContrast &&
        other.highContrast == highContrast &&
        other.higherContrast == higherContrast &&
        other.backgroundColorHex == backgroundColorHex &&
        other.textColorHex == textColorHex &&
        other.textSubduedColorHex == textSubduedColorHex;
  }

  @override
  int get hashCode => Object.hash(
    squareCoverUrl,
    sixteenByNineCoverUrl,
    wideFullBleedUrl,
    squareFullBleedUrl,
    videoNineBySixteenUrl,
    hasVideo,
    minContrast,
    highContrast,
    higherContrast,
    backgroundColorHex,
    textColorHex,
    textSubduedColorHex,
  );
}
