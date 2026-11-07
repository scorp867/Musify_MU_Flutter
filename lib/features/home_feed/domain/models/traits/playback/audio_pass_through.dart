part of 'audio_playback_source.dart';

/// 1:1 replica of Spotify Android's `p199p/bp7.java` (`AudioPassThrough`).
@immutable
final class AudioPassThrough extends AudioPlaybackSource {
  final String url;

  const AudioPassThrough({
    required this.url,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioPassThrough && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}
