import 'package:flutter/foundation.dart';

import 'trait.dart';

/// Content-agnostic preview playback (ExtensionKind 181).
@immutable
final class PreviewPlaybackTrait extends Trait {
  final String uri;
  final String reportingUri;
  final String audioUrl;
  final String videoUrl;
  final String videoImageUrl;
  final int durationMs;

  const PreviewPlaybackTrait({
    this.uri = '',
    this.reportingUri = '',
    this.audioUrl = '',
    this.videoUrl = '',
    this.videoImageUrl = '',
    this.durationMs = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PreviewPlaybackTrait &&
        other.uri == uri &&
        other.reportingUri == reportingUri &&
        other.audioUrl == audioUrl &&
        other.videoUrl == videoUrl &&
        other.videoImageUrl == videoImageUrl &&
        other.durationMs == durationMs;
  }

  @override
  int get hashCode => Object.hash(
    uri,
    reportingUri,
    audioUrl,
    videoUrl,
    videoImageUrl,
    durationMs,
  );
}
