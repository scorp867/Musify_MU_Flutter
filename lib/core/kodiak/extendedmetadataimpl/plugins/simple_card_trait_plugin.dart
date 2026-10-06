import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/protocol/generated/spotify/traits/simple_card_trait.pb.dart'
    as sct2;
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';
import 'plugin_utils.dart';

/// Plugin for ExtensionKind 97 (SIMPLE_TRAIT).
/// Equivalent to Spotify Android's `c6y0` decoder plugin.
class SimpleCardTraitPlugin implements ExtendedMetadataPlugin<SimpleCardTrait> {
  const SimpleCardTraitPlugin();

  @override
  Type get traitType => SimpleCardTrait;

  @override
  int get extensionKindValue => 97;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.SIMPLE_TRAIT;

  @override
  SimpleCardTrait parse(Uint8List payload) {
    final trait = sct2.SimpleCardTrait.fromBuffer(payload);
    return SimpleCardTrait(
      title: trait.title,
      subtitle: trait.subtitle,
      imageUrl: cleanImageUrl(trait.imageUri),
      navigationUri: trait.navigationUri,
      accessibility: trait.accessibility,
    );
  }
}
