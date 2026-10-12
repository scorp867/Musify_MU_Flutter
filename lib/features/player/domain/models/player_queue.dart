import 'package:equatable/equatable.dart';
import 'context_track.dart';

/// 1:1 with Spotify's com.spotify.player.model.PlayerQueue
///
/// Contains currently active track, user-enqueued tracks, upcoming context tracks,
/// history, and monotonic revision.
class PlayerQueue extends Equatable {
  final ContextTrack? currentTrack;
  final List<ContextTrack> userQueue; // Tracks explicitly queued by user (isQueued = true)
  final List<ContextTrack> contextTracks; // Upcoming tracks from album/playlist context (isQueued = false)
  final List<ContextTrack> prevTracks; // History of recently played tracks
  final String revision;

  const PlayerQueue({
    this.currentTrack,
    this.userQueue = const [],
    this.contextTracks = const [],
    this.prevTracks = const [],
    required this.revision,
  });

  /// 1:1 with Spotify's nextTracks() concatenation:
  /// [User Queued Tracks] + [Context Tracks]
  List<ContextTrack> get nextTracks => [...userQueue, ...contextTracks];

  bool get isEmpty => currentTrack == null && userQueue.isEmpty && contextTracks.isEmpty;

  bool get hasUserQueue => userQueue.isNotEmpty;

  bool get hasContextTracks => contextTracks.isNotEmpty;

  PlayerQueue copyWith({
    ContextTrack? currentTrack,
    List<ContextTrack>? userQueue,
    List<ContextTrack>? contextTracks,
    List<ContextTrack>? prevTracks,
    String? revision,
  }) {
    return PlayerQueue(
      currentTrack: currentTrack ?? this.currentTrack,
      userQueue: userQueue ?? this.userQueue,
      contextTracks: contextTracks ?? this.contextTracks,
      prevTracks: prevTracks ?? this.prevTracks,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [
        currentTrack?.uid,
        userQueue.map((t) => t.uid).join(','),
        contextTracks.map((t) => t.uid).join(','),
        prevTracks.map((t) => t.uid).join(','),
        revision,
      ];
}
