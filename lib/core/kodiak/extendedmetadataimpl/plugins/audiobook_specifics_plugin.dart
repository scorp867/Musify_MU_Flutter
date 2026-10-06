import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 52 (AUDIOBOOK_SPECIFICS).
/// Direct 1:1 equivalent to Spotify Android's `p.fu6`.
class AudiobookSpecificsPlugin
    implements ExtendedMetadataPlugin<AudiobookSpecificsTrait> {
  const AudiobookSpecificsPlugin();

  @override
  Type get traitType => AudiobookSpecificsTrait;

  @override
  int get extensionKindValue => 52;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.AUDIOBOOK_SPECIFICS;

  @override
  AudiobookSpecificsTrait parse(Uint8List payload) {
    return const AudiobookSpecificsTrait();
  }
}
