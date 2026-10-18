// 1:1 replica of com.spotify.player.model.PlayerQueue

import 'context_track.dart';

class PlayerQueue {
  static const PlayerQueue empty = PlayerQueue();

  final String revision;
  final ContextTrack? track;
  final List<ContextTrack> nextTracks;
  final List<ContextTrack> prevTracks;

  const PlayerQueue({
    this.revision = '',
    this.track,
    this.nextTracks = const <ContextTrack>[],
    this.prevTracks = const <ContextTrack>[],
  });

  static PlayerQueueBuilder builder() => PlayerQueueBuilder();

  PlayerQueueBuilder toBuilder() => PlayerQueueBuilder(
        revision: revision,
        track: track,
        nextTracks: nextTracks,
        prevTracks: prevTracks,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerQueue &&
          other.revision == revision &&
          other.track == track &&
          _listEquals(other.nextTracks, nextTracks) &&
          _listEquals(other.prevTracks, prevTracks));

  @override
  int get hashCode => Object.hash(
        revision,
        track,
        Object.hashAll(nextTracks),
        Object.hashAll(prevTracks),
      );

  @override
  String toString() =>
      'PlayerQueue{revision=$revision, track=$track, nextTracks=$nextTracks, prevTracks=$prevTracks}';

  static bool _listEquals(List<ContextTrack> a, List<ContextTrack> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class PlayerQueueBuilder {
  String _revision;
  ContextTrack? _track;
  List<ContextTrack> _nextTracks;
  List<ContextTrack> _prevTracks;

  PlayerQueueBuilder({
    String revision = '',
    ContextTrack? track,
    List<ContextTrack> nextTracks = const <ContextTrack>[],
    List<ContextTrack> prevTracks = const <ContextTrack>[],
  })  : _revision = revision,
        _track = track,
        _nextTracks = List<ContextTrack>.from(nextTracks),
        _prevTracks = List<ContextTrack>.from(prevTracks);

  PlayerQueueBuilder revision(String val) {
    _revision = val;
    return this;
  }

  PlayerQueueBuilder track(ContextTrack? val) {
    _track = val;
    return this;
  }

  PlayerQueueBuilder nextTracks(List<ContextTrack> val) {
    _nextTracks = List<ContextTrack>.from(val);
    return this;
  }

  PlayerQueueBuilder prevTracks(List<ContextTrack> val) {
    _prevTracks = List<ContextTrack>.from(val);
    return this;
  }

  PlayerQueue build() => PlayerQueue(
        revision: _revision,
        track: _track,
        nextTracks: List<ContextTrack>.unmodifiable(_nextTracks),
        prevTracks: List<ContextTrack>.unmodifiable(_prevTracks),
      );
}
