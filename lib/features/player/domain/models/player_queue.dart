import 'package:equatable/equatable.dart';
import 'context_track.dart';

/// 1:1 with Spotify's com.spotify.player.model.PlayerQueue
///
/// Contains currently active track, single linear nextTracks list,
/// history, and monotonic revision.
class PlayerQueue extends Equatable {
  final String revision;
  final ContextTrack? track;
  final List<ContextTrack> nextTracks; // SINGLE linear list (Spotify core source of truth)
  final List<ContextTrack> prevTracks; // History of recently played tracks

  const PlayerQueue({
    required this.revision,
    this.track,
    this.nextTracks = const [],
    this.prevTracks = const [],
  }) : super();

  /// Factory supporting legacy partitioned construction
  factory PlayerQueue.partitioned({
    required String revision,
    ContextTrack? currentTrack,
    List<ContextTrack> userQueue = const [],
    List<ContextTrack> contextTracks = const [],
    List<ContextTrack> prevTracks = const [],
  }) {
    // Stamp userQueue with is_queued = true
    final stampedUserQueue = userQueue.map((t) => t.copyWith(isQueued: true)).toList();
    // Stamp contextTracks with is_queued = false
    final stampedContextTracks = contextTracks.map((t) => t.copyWith(isQueued: false)).toList();

    return PlayerQueue(
      revision: revision,
      track: currentTrack,
      nextTracks: [...stampedUserQueue, ...stampedContextTracks],
      prevTracks: prevTracks,
    );
  }

  /// 1:1 with Spotify track()
  ContextTrack? get currentTrack => track;

  /// 1:1 with Spotify hxl0.d(playerQueue): user-queued items
  List<ContextTrack> get userQueue =>
      nextTracks.where((t) => t.isQueued).toList();

  /// 1:1 with Spotify hxl0.b(playerQueue): upcoming context items
  List<ContextTrack> get contextTracks =>
      nextTracks.where((t) => !t.isQueued).toList();

  bool get isEmpty => track == null && nextTracks.isEmpty;
  bool get hasUserQueue => userQueue.isNotEmpty;
  bool get hasContextTracks => contextTracks.isNotEmpty;

  PlayerQueue copyWith({
    String? revision,
    ContextTrack? track,
    ContextTrack? currentTrack,
    List<ContextTrack>? nextTracks,
    List<ContextTrack>? prevTracks,
    List<ContextTrack>? userQueue,
    List<ContextTrack>? contextTracks,
  }) {
    if (userQueue != null || contextTracks != null) {
      final uq = userQueue ?? this.userQueue;
      final cq = contextTracks ?? this.contextTracks;
      final stampedUserQueue = uq.map((t) => t.copyWith(isQueued: true)).toList();
      final stampedContextTracks = cq.map((t) => t.copyWith(isQueued: false)).toList();
      return PlayerQueue(
        revision: revision ?? this.revision,
        track: track ?? currentTrack ?? this.track,
        nextTracks: [...stampedUserQueue, ...stampedContextTracks],
        prevTracks: prevTracks ?? this.prevTracks,
      );
    }

    return PlayerQueue(
      revision: revision ?? this.revision,
      track: track ?? currentTrack ?? this.track,
      nextTracks: nextTracks ?? this.nextTracks,
      prevTracks: prevTracks ?? this.prevTracks,
    );
  }

  @override
  List<Object?> get props => [
        revision,
        track?.uid,
        nextTracks.map((t) => '${t.uid}:${t.isQueued}').join(','),
        prevTracks.map((t) => t.uid).join(','),
      ];
}
