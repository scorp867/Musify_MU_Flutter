import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 123 (CONCERT_LOCATION).
/// Equivalent to Spotify Android's `uzy` decoder plugin.
class ConcertLocationTraitPlugin
    implements ExtendedMetadataPlugin<ConcertLocationTrait> {
  const ConcertLocationTraitPlugin();

  @override
  Type get traitType => ConcertLocationTrait;

  @override
  int get extensionKindValue => 123;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.CONCERT_LOCATION;

  @override
  ConcertLocationTrait parse(Uint8List payload) {
    return const ConcertLocationTrait();
  }
}
