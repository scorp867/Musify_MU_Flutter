import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 171 (PROMO_V3_TRAIT).
/// Equivalent to Spotify Android's `kqu` decoder plugin.
class PromoV3TraitPlugin implements ExtendedMetadataPlugin<PromoV3Trait> {
  const PromoV3TraitPlugin();

  @override
  Type get traitType => PromoV3Trait;

  @override
  int get extensionKindValue => 171;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.PROMO_V3_TRAIT;

  @override
  PromoV3Trait parse(Uint8List payload) {
    return const PromoV3Trait(title: '');
  }
}
