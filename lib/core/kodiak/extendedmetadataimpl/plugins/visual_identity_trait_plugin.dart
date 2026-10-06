import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/visual_identity_trait.pb.dart'
    as vit;
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/visual_types.pb.dart'
    as vt;
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';
import 'plugin_utils.dart';

String _rgbaToHex(vt.RgbaColor c) {
  final r = c.r.toRadixString(16).padLeft(2, '0');
  final g = c.g.toRadixString(16).padLeft(2, '0');
  final b = c.b.toRadixString(16).padLeft(2, '0');
  return '#$r$g$b';
}

/// Plugin for ExtensionKind 179 (VISUAL_IDENTITY_TRAIT).
/// Equivalent to Spotify Android's `e1y0` decoder plugin.
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

    String? bgColor;
    String? txtColor;
    String? subduedColor;
    if (trait.hasCuratedColor() && trait.curatedColor.hasMinContrast()) {
      final palette = trait.curatedColor.minContrast;
      if (palette.hasBackgroundBase()) {
        bgColor = _rgbaToHex(palette.backgroundBase);
      }
      if (palette.hasTextBase()) {
        txtColor = _rgbaToHex(palette.textBase);
      }
      if (palette.hasTextSubdued()) {
        subduedColor = _rgbaToHex(palette.textSubdued);
      }
    }

    final hasVideo = trait.hasNineBySixteenCoverVideo() ||
        (wideUrl != null && wideUrl.isNotEmpty);

    return VisualIdentityTrait(
      squareCoverUrl: squareUrl,
      sixteenByNineCoverUrl: wideUrl,
      wideFullBleedUrl: fullBleedWideUrl,
      squareFullBleedUrl: fullBleedSquareUrl,
      hasVideo: hasVideo,
      backgroundColorHex: bgColor,
      textColorHex: txtColor,
      textSubduedColorHex: subduedColor,
    );
  }
}
