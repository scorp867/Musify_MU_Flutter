import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 64 (AUDIOBOOK_PRICE).
/// Equivalent to Spotify Android's `st6` decoder plugin.
class AudiobookPricePlugin
    implements ExtendedMetadataPlugin<AudiobookPriceTrait> {
  const AudiobookPricePlugin();

  @override
  Type get traitType => AudiobookPriceTrait;

  @override
  int get extensionKindValue => 64;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.AUDIOBOOK_PRICE;

  @override
  AudiobookPriceTrait parse(Uint8List payload) {
    return const AudiobookPriceTrait();
  }
}
