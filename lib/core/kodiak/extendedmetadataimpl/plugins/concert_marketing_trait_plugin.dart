import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 124 (CONCERT_MARKETING).
/// Equivalent to Spotify Android's `ynu` decoder plugin.
class ConcertMarketingTraitPlugin
    implements ExtendedMetadataPlugin<ConcertMarketingTrait> {
  const ConcertMarketingTraitPlugin();

  @override
  Type get traitType => ConcertMarketingTrait;

  @override
  int get extensionKindValue => 124;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.CONCERT_MARKETING;

  @override
  ConcertMarketingTrait parse(Uint8List payload) {
    return const ConcertMarketingTrait();
  }
}
