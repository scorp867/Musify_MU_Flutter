import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/protocol/generated/spotify/traits/shortcuts_card_trait.pb.dart'
    as sct;
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';
import 'plugin_utils.dart';

/// Plugin for ExtensionKind 119 (SHORTCUTS_CARD_TRAIT).
class ShortcutsCardTraitPlugin implements ExtendedMetadataPlugin<ShortcutsCardTrait> {
  const ShortcutsCardTraitPlugin();

  @override
  Type get traitType => ShortcutsCardTrait;

  @override
  int get extensionKindValue => 119;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.SHORTCUTS_CARD_TRAIT;

  @override
  ShortcutsCardTrait parse(Uint8List payload) {
    final trait = sct.ShortcutsCardTrait.fromBuffer(payload);
    return ShortcutsCardTrait(
      title: trait.title,
      imageUrl: cleanImageUrl(trait.imageUrl),
    );
  }
}
