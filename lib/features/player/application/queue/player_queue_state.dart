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

  /// Whether playback is currently paused
  bool get isPaused => playerState?.isPaused ?? false;

  /// Whether playback is currently buffering
  bool get isBuffering => playerState?.isBuffering ?? false;

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

  /// Drift-free current playback position in milliseconds.
  /// Computed using Spotify's position interpolation formula:
  /// `positionAsOfTimestamp + (playbackSpeed * (now - timestamp))`
  int get positionMs {
    final ps = playerState;
    if (ps == null) return 0;
    final calculated = ps.position(DateTime.now().millisecondsSinceEpoch);
    if (calculated != null && calculated >= 0) return calculated;
    return ps.positionAsOfTimestamp ?? 0;
  }

  /// Total duration of the current track in milliseconds
  int get durationMs {
    final ps = playerState;
    if (ps?.duration != null && ps!.duration! > 0) {
      return ps.duration!;
    }
    final rawDuration = nowPlaying?.metadata[ContextTrackMetadata.keyDuration];
    if (rawDuration != null && rawDuration.isNotEmpty) {
      final parsed = int.tryParse(rawDuration);
      if (parsed != null && parsed > 0) return parsed;
    }
    return 0;
  }

  /// Playback position as Duration
  Duration get currentPosition => Duration(milliseconds: positionMs);

  /// Track duration as Duration
  Duration get currentDuration => Duration(milliseconds: durationMs);

  /// Normalized playback progress clamped to [0.0, 1.0]
  double get playbackProgress {
    final total = durationMs;
    if (total <= 0) return 0.0;
    return (positionMs / total).clamp(0.0, 1.0);
  }

  /// Display title for the active track
  String get title {
    final t = nowPlaying?.metadata[ContextTrackMetadata.keyTitle];
    if (t != null && t.isNotEmpty) return t;
    return nowPlaying?.uri ?? '';
  }

  /// Display artist for the active track
  String get artist {
    return nowPlaying?.metadata[ContextTrackMetadata.keyArtistName] ?? '';
  }

  /// Display album for the active track
  String get album {
    return nowPlaying?.metadata[ContextTrackMetadata.keyAlbumTitle] ?? '';
  }

  /// Image URL for the active track
  String? get imageUrl {
    return nowPlaying?.metadata[ContextTrackMetadata.keyImageLargeUrl] ??
        nowPlaying?.metadata[ContextTrackMetadata.keyImageUrl];
  }

  /// Device song ID for offline/local music artwork
  int? get songId {
    final raw = nowPlaying?.metadata[ContextTrackMetadata.keySongId];
    if (raw != null && raw.isNotEmpty) {
      return int.tryParse(raw);
    }
    return null;
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
