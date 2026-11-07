import 'package:flutter/foundation.dart';

import 'playback_offsets.dart';
import 'video_hosted.dart';

/// 1:1 replica of Spotify Android's `p199p/csg1.java` (`VideoPlayback`).
@immutable
final class VideoPlayback {
  final int format;
  final VideoHosted hosted;
  final String reportingUri;
  final PlaybackOffsets? offsets;

  const VideoPlayback({
    required this.format,
    required this.hosted,
    required this.reportingUri,
    this.offsets,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoPlayback &&
        other.format == format &&
        other.hosted == hosted &&
        other.reportingUri == reportingUri &&
        other.offsets == offsets;
  }

  @override
  int get hashCode => Object.hash(format, hosted, reportingUri, offsets);
}
