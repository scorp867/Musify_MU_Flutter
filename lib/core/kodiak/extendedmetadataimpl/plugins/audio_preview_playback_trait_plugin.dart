import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 116 (AUDIO_PREVIEW_PLAYBACK_TRAIT).
/// Equivalent to Spotify Android's `u17` decoder plugin.
class AudioPreviewPlaybackTraitPlugin
    implements ExtendedMetadataPlugin<AudioPreviewPlaybackTrait> {
  const AudioPreviewPlaybackTraitPlugin();

  @override
  Type get traitType => AudioPreviewPlaybackTrait;

  @override
  int get extensionKindValue => 116;

  @override
  ExtensionKind? get extensionKind =>
      ExtensionKind.AUDIO_PREVIEW_PLAYBACK_TRAIT;

  @override
  AudioPreviewPlaybackTrait parse(Uint8List payload) {
    return const AudioPreviewPlaybackTrait();
  }
}
