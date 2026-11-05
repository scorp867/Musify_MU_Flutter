import '../../data/esperanto/context_player_options_client.dart';
import '../../data/queue/queue_helpers.dart';
import '../../data/queue/queue_track_filter.dart';
import '../../domain/models/audio_stream_metadata_keys.dart';
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
  ContextTrack? get nowPlaying {
    if (queue.track case final track?) {
      return track;
    }
    return playerState?.track;
  }

  /// Alias for nowPlaying for UI convenience
  ContextTrack? get currentTrack => nowPlaying;

  /// Whether playback is active
  bool get isPlaying {
    final ps = playerState;
    if (ps == null) return false;
    return ps.isPlaying;
  }

  /// Whether playback is currently paused
  bool get isPaused {
    final ps = playerState;
    if (ps == null) return false;
    return ps.isPaused;
  }

  /// Whether playback is currently buffering
  bool get isBuffering {
    final ps = playerState;
    if (ps == null) return false;
    return ps.isBuffering;
  }

  /// Whether shuffle is active
  bool get isShuffling {
    final ps = playerState;
    if (ps == null) return false;
    return ps.options.shufflingContext;
  }

  /// Whether repeating track is active
  bool get repeatTrack {
    final ps = playerState;
    if (ps == null) return false;
    return ps.options.repeatingTrack;
  }

  /// Whether repeating context is active
  bool get repeatContext {
    final ps = playerState;
    if (ps == null) return false;
    return ps.options.repeatingContext;
  }

  /// Repeat mode resolved from PlayerOptions
  RepeatMode get repeatMode {
    final ps = playerState;
    if (ps == null) return RepeatMode.none;
    final options = ps.options;
    if (options.repeatingTrack) return RepeatMode.track;
    if (options.repeatingContext) return RepeatMode.context;
    return RepeatMode.none;
  }

  /// Whether skipping to next track is allowed by active player restrictions
  bool get canSkipNext {
    final ps = playerState;
    if (ps == null) return true;
    return ps.restrictions.disallowSkippingNextReasons.isEmpty;
  }

  /// Whether skipping to previous track is allowed by active player restrictions
  bool get canSkipPrevious {
    final ps = playerState;
    if (ps == null) return true;
    return ps.restrictions.disallowSkippingPrevReasons.isEmpty;
  }

  /// Drift-free current playback position in milliseconds.
  /// Computed using Spotify's position interpolation formula:
  /// `positionAsOfTimestamp + (playbackSpeed * (now - timestamp))`
  int get positionMs {
    final ps = playerState;
    if (ps == null) return 0;
    final calculated = ps.position(DateTime.now().millisecondsSinceEpoch);
    if (calculated != null && calculated >= 0) return calculated;
    return switch (ps.positionAsOfTimestamp) {
      final pos? => pos,
      null => 0,
    };
  }

  /// Total duration of the current track in milliseconds
  int get durationMs {
    final track = nowPlaying;
    if (track != null) {
      if (track.metadata[ContextTrackMetadata.keyDuration] case final rawDuration? when rawDuration.isNotEmpty) {
        final parsed = int.tryParse(rawDuration);
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    final ps = playerState;
    if (ps != null) {
      if (ps.duration case final psDur? when psDur > 0) {
        final cdnAac = track?.metadata[AudioStreamMetadataKeys.keyCdnAacUrl];
        if ((cdnAac == null || cdnAac.isEmpty) && psDur <= 15000) {
          return 0;
        }
        return psDur;
      }
    }
    return 0;
  }

  /// Playback position as Duration
  Duration get currentPosition => Duration(milliseconds: positionMs);

  /// Track duration as Duration
  Duration get currentDuration => Duration(milliseconds: durationMs);

  /// Normalized playback progress bounded to [0.0, 1.0] without using clamp AST
  double get playbackProgress {
    final total = durationMs;
    if (total <= 0) return 0.0;
    final pos = positionMs;
    if (pos <= 0) return 0.0;
    if (pos >= total) return 1.0;
    return pos / total;
  }

  /// Display title for the active track
  String get title {
    final track = nowPlaying;
    if (track == null) return '';
    final t = track.metadata[ContextTrackMetadata.keyTitle];
    if (t != null && t.isNotEmpty) return t;
    return track.uri;
  }

  /// Display artist for the active track
  String get artist {
    final track = nowPlaying;
    if (track == null) return '';
    return switch (track.metadata[ContextTrackMetadata.keyArtistName]) {
      final a? => a,
      null => '',
    };
  }

  /// Display album for the active track
  String get album {
    final track = nowPlaying;
    if (track == null) return '';
    return switch (track.metadata[ContextTrackMetadata.keyAlbumTitle]) {
      final a? => a,
      null => '',
    };
  }

  /// Image URL for the active track
  String? get imageUrl {
    final track = nowPlaying;
    if (track == null) return null;
    if (track.metadata[ContextTrackMetadata.keyImageLargeUrl] case final large? when large.isNotEmpty) {
      return large;
    }
    if (track.metadata[ContextTrackMetadata.keyImageUrl] case final normal? when normal.isNotEmpty) {
      return normal;
    }
    return null;
  }

  /// Device song ID for offline/local music artwork
  int? get songId {
    final track = nowPlaying;
    if (track == null) return null;
    if (track.metadata[ContextTrackMetadata.keySongId] case final raw? when raw.isNotEmpty) {
      final parsed = int.tryParse(raw);
      if (parsed != null) return parsed;
    }
    final uid = track.uid;
    if (uid.isNotEmpty) {
      final parsed = int.tryParse(uid);
      if (parsed != null) return parsed;
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
      queue: switch (queue) {
        final q? => q,
        null => this.queue,
      },
      playerState: switch (playerState) {
        final ps? => ps,
        null => this.playerState,
      },
      isLoading: switch (isLoading) {
        final l? => l,
        null => this.isLoading,
      },
      errorMessage: switch (errorMessage) {
        final em? => em,
        null => this.errorMessage,
      },
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
