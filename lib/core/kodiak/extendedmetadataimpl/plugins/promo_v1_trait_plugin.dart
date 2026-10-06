import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 167 (PROMO_V1_TRAIT).
/// Equivalent to Spotify Android's `uou` decoder plugin.
class PromoV1TraitPlugin implements ExtendedMetadataPlugin<PromoV1Trait> {
  const PromoV1TraitPlugin();

  @override
  Type get traitType => PromoV1Trait;

  @override
  int get extensionKindValue => 167;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.PROMO_V1_TRAIT;

  @override
  PromoV1Trait parse(Uint8List payload) {
    return const PromoV1Trait(title: '');
  }
}
