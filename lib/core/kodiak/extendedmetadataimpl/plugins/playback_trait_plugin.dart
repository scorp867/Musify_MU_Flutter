import 'dart:typed_data';

import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/playback_trait.pb.dart'
    as pb;
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

import 'plugin_utils.dart';

/// Plugin for ExtensionKind 212 (`PLAYBACK_TRAIT`).
/// 1:1 replica of Spotify Android's `p199p/aks0.java` returning [PlaybackTrait].
class PlaybackTraitPlugin implements ExtendedMetadataPlugin<PlaybackTrait> {
  const PlaybackTraitPlugin();

  @override
  Type get traitType => PlaybackTrait;

  @override
  int get extensionKindValue => 212;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.PLAYBACK_TRAIT;

  static Duration _mapProtoDuration(pb.Duration duration) {
    final millis =
        (duration.seconds.toInt() * 1000) + (duration.nanos ~/ 1000000);
    return Duration(milliseconds: millis);
  }

  static PlaybackOffsets? _mapOffsets(pb.PlaybackOffsets offsets) {
    return PlaybackOffsets(
      start: offsets.hasStart()
          ? _mapProtoDuration(offsets.start)
          : Duration.zero,
      end: offsets.hasEnd() ? _mapProtoDuration(offsets.end) : Duration.zero,
    );
  }

  @override
  PlaybackTrait parse(Uint8List payload) {
    final trait = pb.PlaybackTrait.fromBuffer(payload);
    final audios = <AudioPlayback>[];
    final videos = <VideoPlayback>[];

    for (final entry in trait.audio) {
      if (!entry.hasValue()) continue;
      final ap = entry.value;
      final offsets = ap.hasOffsets() ? _mapOffsets(ap.offsets) : null;

      AudioPlaybackSource? source;
      if (ap.hasHosted() && ap.hosted.audioId.isNotEmpty) {
        final audioId = bytesToLowerHex(ap.hosted.audioId);
        if (audioId.isNotEmpty) {
          source = AudioHosted(audioId: audioId);
        }
      } else if (ap.hasPassThrough() &&
          ap.passThrough.hasFlatFile() &&
          ap.passThrough.flatFile.cdnUrl.isNotEmpty) {
        source = AudioPassThrough(url: ap.passThrough.flatFile.cdnUrl);
      }

      if (source != null) {
        audios.add(
          AudioPlayback(
            source: source,
            reportingUri: ap.reportingUri,
            offsets: offsets,
          ),
        );
      }
    }

    for (final entry in trait.video) {
      if (!entry.hasValue()) continue;
      final vp = entry.value;
      if (!vp.hasHosted() || vp.hosted.videoId.isEmpty) continue;

      final manifestId = bytesToLowerHex(vp.hosted.videoId);
      if (manifestId.isEmpty) continue;

      final offsets = vp.hasOffsets() ? _mapOffsets(vp.offsets) : null;

      videos.add(
        VideoPlayback(
          format: entry.key,
          hosted: VideoHosted(manifestId: manifestId),
          reportingUri: vp.reportingUri,
          offsets: offsets,
        ),
      );
    }

    return PlaybackTrait(audio: audios, video: videos);
  }
}
