import 'dart:collection';
import 'package:flutter/foundation.dart';

import 'playback/audio_playback.dart';
import 'playback/video_playback.dart';
import 'trait.dart';

/// 1:1 replica of Spotify Android's `p199p/yjs0.java` (`PlaybackTrait`, ExtensionKind 212).
@immutable
final class PlaybackTrait extends Trait {
  final UnmodifiableListView<AudioPlayback> audio;
  final UnmodifiableListView<VideoPlayback> video;

  PlaybackTrait({
    List<AudioPlayback> audio = const [],
    List<VideoPlayback> video = const [],
  }) : audio = UnmodifiableListView<AudioPlayback>(
         List<AudioPlayback>.of(audio),
       ),
       video = UnmodifiableListView<VideoPlayback>(
         List<VideoPlayback>.of(video),
       );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaybackTrait &&
        listEquals(other.audio, audio) &&
        listEquals(other.video, video);
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(audio), Object.hashAll(video));
}
