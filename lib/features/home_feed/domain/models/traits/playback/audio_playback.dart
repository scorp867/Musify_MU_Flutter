import 'package:flutter/foundation.dart';

import 'audio_playback_source.dart';
import 'playback_offsets.dart';

/// 1:1 replica of Spotify Android's `p199p/xi7.java` (`AudioPlayback`).
@immutable
final class AudioPlayback {
  final AudioPlaybackSource source;
  final String reportingUri;
  final PlaybackOffsets? offsets;

  const AudioPlayback({
    required this.source,
    required this.reportingUri,
    this.offsets,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioPlayback &&
        other.source == source &&
        other.reportingUri == reportingUri &&
        other.offsets == offsets;
  }

  @override
  int get hashCode => Object.hash(source, reportingUri, offsets);
}
