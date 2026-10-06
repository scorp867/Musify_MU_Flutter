import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 122 (CONCERT).
/// Equivalent to Spotify Android's `kwe` decoder plugin.
class ConcertTraitPlugin implements ExtendedMetadataPlugin<ConcertTrait> {
  const ConcertTraitPlugin();

  @override
  Type get traitType => ConcertTrait;

  @override
  int get extensionKindValue => 122;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.CONCERT;

  @override
  ConcertTrait parse(Uint8List payload) {
    return const ConcertTrait(title: '');
  }
}
