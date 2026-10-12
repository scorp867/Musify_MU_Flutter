import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/visual_identity_trait.pb.dart'
    as vit;
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/visual_types.pb.dart'
    as vt;
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';
import 'plugin_utils.dart';

int _rgbaToInt(vt.RgbaColor c) {
  final a = c.hasA() ? (c.a & 0xFF) : 0xFF;
  final r = c.r & 0xFF;
  final g = c.g & 0xFF;
  final b = c.b & 0xFF;
  return (a << 24) | (r << 16) | (g << 8) | b;
}

VisualColorSet _decodeColorSet(vt.ColorSet cs) {
  return VisualColorSet(
    backgroundBase:
        cs.hasBackgroundBase() ? _rgbaToInt(cs.backgroundBase) : 0xFF353535,
    backgroundTintedBase: cs.hasBackgroundTintedBase()
        ? _rgbaToInt(cs.backgroundTintedBase)
        : 0xFF565656,
    textBase: cs.hasTextBase() ? _rgbaToInt(cs.textBase) : 0xFFFFFFFF,
    textSubdued:
        cs.hasTextSubdued() ? _rgbaToInt(cs.textSubdued) : 0xFFCDCDCD,
    textBrightAccent: cs.hasTextBrightAccent()
        ? _rgbaToInt(cs.textBrightAccent)
        : 0xFF1ED760,
  );
}

/// Plugin for ExtensionKind 179 (VISUAL_IDENTITY_TRAIT).
/// Equivalent to Spotify Android's `e1y0` decoder plugin and `p/sw71.java`.
class VisualIdentityTraitPlugin
    implements ExtendedMetadataPlugin<VisualIdentityTrait> {
  const VisualIdentityTraitPlugin();

  @override
  Type get traitType => VisualIdentityTrait;

  @override
  int get extensionKindValue => 179;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.VISUAL_IDENTITY_TRAIT;

  @override
  VisualIdentityTrait parse(Uint8List payload) {
    final trait = vit.VisualIdentityTrait.fromBuffer(payload);

    String? squareUrl;
    String? wideUrl;
    String? fullBleedWideUrl;
    String? fullBleedSquareUrl;

    if (trait.hasSquareCoverImage()) {
      squareUrl = selectHighResImageUrl(trait.squareCoverImage);
    }
    if (trait.hasSixteenByNineCoverImage()) {
      wideUrl = selectHighResImageUrl(trait.sixteenByNineCoverImage);
    }
    if (trait.hasWideFullBleedImage()) {
      fullBleedWideUrl = selectHighResImageUrl(trait.wideFullBleedImage);
    }
    if (trait.hasSquareFullBleedImage()) {
      fullBleedSquareUrl = selectHighResImageUrl(trait.squareFullBleedImage);
    }

    // Resolves color options matching Spotify Android `p/rm2.java:121-138`:
    // Priority 1: squareCoverImage.extractedColorSet (track/album artwork)
    // Priority 2: sixteenByNineCoverImage.extractedColorSet
    // Priority 3: curatedColor (editorial palette)
    vt.ColorSetContrastOptions? options;
    if (trait.hasSquareCoverImage() &&
        trait.squareCoverImage.hasExtractedColorSet()) {
      options = trait.squareCoverImage.extractedColorSet;
    } else if (trait.hasSixteenByNineCoverImage() &&
        trait.sixteenByNineCoverImage.hasExtractedColorSet()) {
      options = trait.sixteenByNineCoverImage.extractedColorSet;
    } else if (trait.hasCuratedColor()) {
      options = trait.curatedColor;
    }

    VisualColorSet? minContrast;
    VisualColorSet? highContrast;
    VisualColorSet? higherContrast;

    if (options != null) {
      if (options.hasMinContrast()) {
        minContrast = _decodeColorSet(options.minContrast);
      }
      if (options.hasHighContrast()) {
        highContrast = _decodeColorSet(options.highContrast);
      }
      if (options.hasHigherContrast()) {
        higherContrast = _decodeColorSet(options.higherContrast);
      }
    }

    final primarySet = higherContrast ?? minContrast;
    final bgColor = primarySet != null
        ? '#${(primarySet.backgroundBase & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}'
        : null;
    final txtColor = primarySet != null
        ? '#${(primarySet.textBase & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}'
        : null;
    final subduedColor = primarySet != null
        ? '#${(primarySet.textSubdued & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}'
        : null;

    final hasVideo = trait.hasNineBySixteenCoverVideo() ||
        (wideUrl != null && wideUrl.isNotEmpty);

    return VisualIdentityTrait(
      squareCoverUrl: squareUrl,
      sixteenByNineCoverUrl: wideUrl,
      wideFullBleedUrl: fullBleedWideUrl,
      squareFullBleedUrl: fullBleedSquareUrl,
      hasVideo: hasVideo,
      minContrast: minContrast,
      highContrast: highContrast,
      higherContrast: higherContrast,
      backgroundColorHex: bgColor,
      textColorHex: txtColor,
      textSubduedColorHex: subduedColor,
    );
  }
}
