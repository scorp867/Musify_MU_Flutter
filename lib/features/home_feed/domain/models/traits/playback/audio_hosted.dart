part of 'audio_playback_source.dart';

/// 1:1 replica of Spotify Android's `p199p/ap7.java` (`AudioHosted`).
@immutable
final class AudioHosted extends AudioPlaybackSource {
  final String audioId;

  const AudioHosted({
    required this.audioId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioHosted && other.audioId == audioId;
  }

  @override
  int get hashCode => audioId.hashCode;
}
