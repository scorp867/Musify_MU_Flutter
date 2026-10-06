import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 31 (SHOW_ACCESS).
/// Equivalent to Spotify Android's `z6a0` decoder plugin.
class ShowAccessTraitPlugin implements ExtendedMetadataPlugin<ShowAccessTrait> {
  const ShowAccessTraitPlugin();

  @override
  Type get traitType => ShowAccessTrait;

  @override
  int get extensionKindValue => 31;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.SHOW_ACCESS;

  @override
  ShowAccessTrait parse(Uint8List payload) {
    return const ShowAccessTrait();
  }
}
