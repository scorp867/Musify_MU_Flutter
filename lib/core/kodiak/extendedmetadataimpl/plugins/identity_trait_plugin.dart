import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/identity_trait.pb.dart'
    as it;
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 178 (IDENTITY_TRAIT).
/// Equivalent to Spotify Android's `l020` decoder plugin.
class IdentityTraitPlugin implements ExtendedMetadataPlugin<IdentityTrait> {
  const IdentityTraitPlugin();

  @override
  Type get traitType => IdentityTrait;

  @override
  int get extensionKindValue => 178;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.IDENTITY_TRAIT;

  @override
  IdentityTrait parse(Uint8List payload) {
    final trait = it.IdentityTrait.fromBuffer(payload);
    return IdentityTrait(
      name: trait.name,
      type: trait.type,
      description: trait.description,
      contributors: trait.contributors
          .map((c) => c.name)
          .where((n) => n.isNotEmpty)
          .toList(),
      parentUri: trait.hasContentHierarchyParent()
          ? trait.contentHierarchyParent.uri
          : null,
      parentName: trait.hasContentHierarchyParent()
          ? trait.contentHierarchyParent.name
          : null,
    );
  }
}
