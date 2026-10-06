import 'trait.dart';

/// Audio preview playback data (ExtensionKind 116).
/// Provides audio file URL, duration, and preview metadata for
/// sections like AudioSpotlight, AudioPromo, and ImmersivePreview.
class AudioPreviewPlaybackTrait extends Trait {
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

  @override
  Map<String, dynamic> toJson() => {
    'audioFileUrl': audioFileUrl,
    'transcriptUrl': transcriptUrl,
    'videoFileId': videoFileId,
    'videoPlaceholderImageUrl': videoPlaceholderImageUrl,
    'previewDurationMs': previewDurationMs,
    'durationFromOriginalMs': durationFromOriginalMs,
    'previewStreamReportingUri': previewStreamReportingUri,
    'previewRestriction': previewRestriction,
  };

  factory AudioPreviewPlaybackTrait.fromJson(Map<String, dynamic> json) =>
      AudioPreviewPlaybackTrait(
        audioFileUrl: json['audioFileUrl'] ?? '',
        transcriptUrl: json['transcriptUrl'] ?? '',
        videoFileId: json['videoFileId'] ?? '',
        videoPlaceholderImageUrl: json['videoPlaceholderImageUrl'] ?? '',
        previewDurationMs: json['previewDurationMs'] ?? 0,
        durationFromOriginalMs: json['durationFromOriginalMs'] ?? 0,
        previewStreamReportingUri: json['previewStreamReportingUri'] ?? '',
        previewRestriction: json['previewRestriction'] ?? 0,
      );
}
