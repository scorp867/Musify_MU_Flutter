import 'package:flutter/foundation.dart';

import 'trait.dart';

/// Audio preview playback data (ExtensionKind 116).
@immutable
final class AudioPreviewPlaybackTrait extends Trait {
  final String audioFileUrl;
  final String transcriptUrl;
  final String videoFileId;
  final String videoPlaceholderImageUrl;
  final int previewDurationMs;
  final int durationFromOriginalMs;
  final String previewStreamReportingUri;
  final int previewRestriction;

  const AudioPreviewPlaybackTrait({
    this.audioFileUrl = '',
    this.transcriptUrl = '',
    this.videoFileId = '',
    this.videoPlaceholderImageUrl = '',
    this.previewDurationMs = 0,
    this.durationFromOriginalMs = 0,
    this.previewStreamReportingUri = '',
    this.previewRestriction = 0,
  });
}
