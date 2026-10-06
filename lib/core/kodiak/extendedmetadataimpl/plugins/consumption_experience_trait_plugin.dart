import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 182 (CONSUMPTION_EXPERIENCE_TRAIT).
/// Equivalent to Spotify Android's `ce40` decoder plugin.
class ConsumptionExperienceTraitPlugin
    implements ExtendedMetadataPlugin<ConsumptionExperienceTrait> {
  const ConsumptionExperienceTraitPlugin();

  @override
  Type get traitType => ConsumptionExperienceTrait;

  @override
  int get extensionKindValue => 182;

  @override
  ExtensionKind? get extensionKind =>
      ExtensionKind.CONSUMPTION_EXPERIENCE_TRAIT;

  @override
  ConsumptionExperienceTrait parse(Uint8List payload) {
    return const ConsumptionExperienceTrait();
  }
}
