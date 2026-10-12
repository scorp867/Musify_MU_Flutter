import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/credits_trait.pb.dart'
    as ct;
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 186 (CREDITS_V2_TRAIT).
/// Equivalent to Spotify Android's `bmk` decoder plugin.
class CreditsTraitPlugin implements ExtendedMetadataPlugin<CreditsTrait> {
  const CreditsTraitPlugin();

  @override
  Type get traitType => CreditsTrait;

  @override
  int get extensionKindValue => 186;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.CREDITS_V2_TRAIT;

  @override
  CreditsTrait parse(Uint8List payload) {
    final trait = ct.CreditsTrait.fromBuffer(payload);
    return CreditsTrait(
      contributors: trait.contributors.map((c) {
        return CreditContributor(
          name: c.name,
          role: c.role,
          uri: c.uri,
          url: c.url,
          roleGroupName: c.hasRoleGroup() ? c.roleGroup.name : '',
        );
      }).toList(),
      sourceNames: trait.sources.map((s) => s.name).toList(),
    );
  }
}
