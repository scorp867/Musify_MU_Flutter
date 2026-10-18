import '../../data/esperanto/context_player_options_client.dart';
import '../../data/queue/queue_helpers.dart';
import '../../data/queue/queue_track_filter.dart';
import '../../domain/models/context_track.dart';
import '../../domain/models/player_queue.dart';
import '../../domain/models/player_state.dart';

class PlayerQueueState {
  final PlayerQueue queue;
  final PlayerState? playerState;
  final bool isLoading;
  final String? errorMessage;

  const PlayerQueueState({
    this.queue = PlayerQueue.empty,
    this.playerState,
    this.isLoading = false,
    this.errorMessage,
  });

  /// The currently active/playing track
  ContextTrack? get nowPlaying => queue.track ?? playerState?.track;

  /// Alias for nowPlaying for UI convenience
  ContextTrack? get currentTrack => nowPlaying;

  /// Whether playback is active
  bool get isPlaying => playerState?.isPlaying ?? false;

  /// Whether shuffle is active
  bool get isShuffling =>
      playerState?.options.shufflingContext ?? false;

  /// Whether repeating track is active
  bool get repeatTrack =>
      playerState?.options.repeatingTrack ?? false;

  /// Whether repeating context is active
  bool get repeatContext =>
      playerState?.options.repeatingContext ?? false;

  /// Repeat mode resolved from PlayerOptions
  RepeatMode get repeatMode {
    final options = playerState?.options;
    if (options == null) return RepeatMode.none;
    if (options.repeatingTrack) return RepeatMode.track;
    if (options.repeatingContext) return RepeatMode.context;
    return RepeatMode.none;
  }

  /// User-queued tracks only (where is_queued = true)
  List<ContextTrack> get userQueuedTracks =>
      QueueHelpers.getUserQueuedTracks(queue);

  /// Context-origin tracks only (where is_queued != true)
  List<ContextTrack> get contextTracks =>
      QueueHelpers.getContextTracks(queue);

  /// Filtered visible tracks matching Spotify UI behavior (delimiter slicing, ban/hidden filtering)
  List<ContextTrack> get visibleTracks =>
      QueueTrackFilter.filterTracks(queue.nextTracks);

  /// Whether there are user-queued tracks present
  bool get hasUserQueue => userQueuedTracks.isNotEmpty;

  /// Total count of next tracks
  int get queueCount => queue.nextTracks.length;

  PlayerQueueState copyWith({
    PlayerQueue? queue,
    PlayerState? playerState,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PlayerQueueState(
      queue: queue ?? this.queue,
      playerState: playerState ?? this.playerState,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerQueueState &&
          other.queue == queue &&
          other.playerState == playerState &&
          other.isLoading == isLoading &&
          other.errorMessage == errorMessage);

  @override
  int get hashCode => Object.hash(queue, playerState, isLoading, errorMessage);
}
