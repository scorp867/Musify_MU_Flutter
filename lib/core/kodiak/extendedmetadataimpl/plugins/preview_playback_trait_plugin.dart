import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 181 (PREVIEW_PLAYBACK_TRAIT).
/// Equivalent to Spotify Android's `vpt` decoder plugin.
class PreviewPlaybackTraitPlugin
    implements ExtendedMetadataPlugin<PreviewPlaybackTrait> {
  const PreviewPlaybackTraitPlugin();

  @override
  Type get traitType => PreviewPlaybackTrait;

  @override
  int get extensionKindValue => 181;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.PREVIEW_PLAYBACK_TRAIT;

  @override
  PreviewPlaybackTrait parse(Uint8List payload) {
    return const PreviewPlaybackTrait();
  }
}
