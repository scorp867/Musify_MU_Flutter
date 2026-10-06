import 'trait.dart';

/// Content-agnostic preview playback (ExtensionKind 181).
/// Can hold either an audio or video preview.
class PreviewPlaybackTrait extends Trait {
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

  bool get hasAudio => audioUrl.isNotEmpty;
  bool get hasVideo => videoUrl.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
    'uri': uri,
    'reportingUri': reportingUri,
    'audioUrl': audioUrl,
    'videoUrl': videoUrl,
    'videoImageUrl': videoImageUrl,
    'durationMs': durationMs,
  };

  factory PreviewPlaybackTrait.fromJson(Map<String, dynamic> json) =>
      PreviewPlaybackTrait(
        uri: json['uri'] ?? '',
        reportingUri: json['reportingUri'] ?? '',
        audioUrl: json['audioUrl'] ?? '',
        videoUrl: json['videoUrl'] ?? '',
        videoImageUrl: json['videoImageUrl'] ?? '',
        durationMs: json['durationMs'] ?? 0,
      );
}
