import 'package:flutter/foundation.dart';

/// 1:1 replica of Spotify Android's `p199p/gfs0.java` (`PlaybackOffsets`).
@immutable
final class PlaybackOffsets {
  final Duration start;
  final Duration end;

  const PlaybackOffsets({
    required this.start,
    required this.end,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaybackOffsets && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}
