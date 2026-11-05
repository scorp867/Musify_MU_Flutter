import 'package:equatable/equatable.dart';

import '../../../data/esperanto/context_player_options_client.dart' show RepeatMode;
import '../../../data/queue/context_track_extensions.dart';
import '../../../data/queue/queue_key_resolver.dart';
import '../../../domain/models/context_track.dart';
import '../../../domain/models/player_queue.dart';
import '../../../domain/models/player_state.dart';
import '../../../domain/models/restrictions.dart';

/// 1:1 replica of Spotify Mobius Queue Model (`ehx0.java`).
///
/// Immutable representation of the queue system state:
/// - [currentTrack] (`f61923a`): Currently active playing track.
/// - [nextTrack] (`f61924b`): Peek/lookahead upcoming track.
/// - [userQueue] (`f61925c`): List of tracks enqueued explicitly by the user.
/// - [contextTracks] (`f61926d`): Lookahead tracks from active album/playlist context.
/// - [pendingRemovalKeys] (`f61919F`): Tracks pending dismissal animation in UI.
/// - [totalQueuedCount] (`f61922I`): Total count of user-enqueued tracks.
/// - [playerQueue]: Authoritative raw queue engine state from Esperanto ContextPlayer.
/// - [playerState]: Active playback engine state.
/// - [restrictions] (`f61932j`): Restriction flags for queue and playback actions.
/// - [isLoading]: Queue loading or bootstrap indicator.
/// - [errorMessage]: Error message from failed engine operations.
class QueueModel extends Equatable {
  final ContextTrack? currentTrack;
  final ContextTrack? nextTrack;
  final List<ContextTrack> userQueue;
  final List<ContextTrack> contextTracks;
  final Set<String> pendingRemovalKeys;
  final int totalQueuedCount;
  final PlayerQueue playerQueue;
  final PlayerState? playerState;
  final Restrictions? restrictions;
  final bool isLoading;
  final String? errorMessage;

  const QueueModel({
    this.currentTrack,
    this.nextTrack,
    this.userQueue = const [],
    this.contextTracks = const [],
    this.pendingRemovalKeys = const {},
    this.totalQueuedCount = 0,
    this.playerQueue = PlayerQueue.empty,
    this.playerState,
    this.restrictions,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Factory creating an initial empty QueueModel.
  factory QueueModel.empty() => const QueueModel();

  /// Visible tracks exposed to the UI, excluding tracks undergoing removal animations (`f61919F`).
  List<ContextTrack> get visibleTracks {
    final result = <ContextTrack>[];
    for (final track in userQueue) {
      final key = QueueKeyResolver.resolveKey(track);
      if (!pendingRemovalKeys.contains(key)) {
        result.add(track);
      }
    }
    for (final track in contextTracks) {
      final key = QueueKeyResolver.resolveKey(track);
      if (!pendingRemovalKeys.contains(key)) {
        result.add(track);
      }
    }
    return List.unmodifiable(result);
  }

  /// The active playing track.
  ContextTrack? get nowPlaying {
    if (currentTrack case final ct?) {
      return ct;
    }
    if (playerState?.track case final pst?) {
      return pst;
    }
    return playerQueue.track;
  }

  /// Title of active playing track.
  String get title {
    if (nowPlaying case final track?) {
      return track.title;
    }
    return '';
  }

  /// Artist of active playing track.
  String get artist {
    if (nowPlaying case final track?) {
      return track.artist;
    }
    return '';
  }

  /// Album of active playing track.
  String get album {
    if (nowPlaying case final track?) {
      return track.album;
    }
    return '';
  }

  /// High-resolution artwork URL of active playing track.
  String? get imageUrl {
    if (nowPlaying case final track?) {
      return track.imageUrl;
    }
    return null;
  }

  /// Thumbnail artwork URL of active playing track.
  String? get thumbnailImageUrl {
    if (nowPlaying case final track?) {
      return track.thumbnailImageUrl;
    }
    return null;
  }

  /// MediaStore song ID of active playing track.
  int? get songId {
    if (nowPlaying case final track?) {
      return track.songId;
    }
    return null;
  }

  /// Playback progress alias for durationProgress.
  double get playbackProgress => durationProgress;

  /// Whether audio is actively playing.
  bool get isPlaying {
    if (playerState case final ps?) {
      return ps.isPlaying && !ps.isPaused;
    }
    return false;
  }

  /// Whether playback is explicitly paused.
  bool get isPaused {
    if (playerState case final ps?) {
      return ps.isPaused;
    }
    return false;
  }

  /// Whether playback is currently buffering.
  bool get isBuffering {
    if (playerState case final ps?) {
      return ps.isBuffering;
    }
    return false;
  }

  /// Whether context shuffle mode is enabled.
  bool get isShuffling {
    if (playerState case final ps?) {
      return ps.options.shufflingContext;
    }
    return false;
  }

  /// Repeat mode matching Spotify options.
  RepeatMode get repeatMode {
    if (playerState case final ps?) {
      if (ps.options.repeatingTrack) return RepeatMode.track;
      if (ps.options.repeatingContext) return RepeatMode.context;
    }
    return RepeatMode.none;
  }

  /// Integer repeat mode: 0 = none, 1 = context, 2 = track.
  int get repeatModeIndex => repeatMode.index;

  /// Whether repeat mode is track.
  bool get repeatTrack => repeatMode == RepeatMode.track;

  /// Whether repeat mode is context.
  bool get repeatContext => repeatMode == RepeatMode.context;

  /// Current playback position in milliseconds.
  int get trackPositionMs {
    if (playerState case final ps?) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (ps.position(now) case final pos?) {
        return pos;
      }
    }
    return 0;
  }

  /// Duration of the currently playing track in milliseconds.
  int get trackDurationMs {
    if (playerState case final ps?) {
      if (ps.duration case final d? when d > 0) {
        return d;
      }
    }
    if (nowPlaying case final track?) {
      final raw = track.metadata[ContextTrackMetadata.keyDuration];
      if (raw != null && raw.isNotEmpty) {
        final parsed = int.tryParse(raw);
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return 0;
  }

  /// Duration in milliseconds alias for trackDurationMs.
  int get durationMs => trackDurationMs;

  /// Current playback position as Duration.
  Duration get currentPosition => Duration(milliseconds: trackPositionMs);

  /// Current duration as Duration.
  Duration get currentDuration => Duration(milliseconds: trackDurationMs);

  /// Whether skipping to next track is permitted by restrictions.
  bool get canSkipNext {
    if (restrictions case final r?) {
      return r.disallowSkippingNextReasons.isEmpty;
    }
    return true;
  }

  /// Whether skipping to previous track is permitted by restrictions.
  bool get canSkipPrevious {
    if (restrictions case final r?) {
      return r.disallowSkippingPrevReasons.isEmpty;
    }
    return true;
  }

  /// Progress fraction in range [0.0, 1.0].
  double get durationProgress {
    final total = trackDurationMs;
    if (total <= 0) return 0.0;
    final pos = trackPositionMs;
    if (pos <= 0) return 0.0;
    if (pos >= total) return 1.0;
    return pos / total;
  }

  /// Returns a copy of this QueueModel with updated fields.
  QueueModel copyWith({
    ContextTrack? currentTrack,
    ContextTrack? nextTrack,
    List<ContextTrack>? userQueue,
    List<ContextTrack>? contextTracks,
    Set<String>? pendingRemovalKeys,
    int? totalQueuedCount,
    PlayerQueue? playerQueue,
    PlayerState? playerState,
    Restrictions? restrictions,
    bool? isLoading,
    String? errorMessage,
  }) {
    return QueueModel(
      currentTrack: switch (currentTrack) {
        final val? => val,
        null => this.currentTrack,
      },
      nextTrack: switch (nextTrack) {
        final val? => val,
        null => this.nextTrack,
      },
      userQueue: switch (userQueue) {
        final val? => val,
        null => this.userQueue,
      },
      contextTracks: switch (contextTracks) {
        final val? => val,
        null => this.contextTracks,
      },
      pendingRemovalKeys: switch (pendingRemovalKeys) {
        final val? => val,
        null => this.pendingRemovalKeys,
      },
      totalQueuedCount: switch (totalQueuedCount) {
        final val? => val,
        null => this.totalQueuedCount,
      },
      playerQueue: switch (playerQueue) {
        final val? => val,
        null => this.playerQueue,
      },
      playerState: switch (playerState) {
        final val? => val,
        null => this.playerState,
      },
      restrictions: switch (restrictions) {
        final val? => val,
        null => this.restrictions,
      },
      isLoading: switch (isLoading) {
        final val? => val,
        null => this.isLoading,
      },
      errorMessage: switch (errorMessage) {
        final val? => val,
        null => this.errorMessage,
      },
    );
  }

  @override
  List<Object?> get props => [
        currentTrack,
        nextTrack,
        userQueue,
        contextTracks,
        pendingRemovalKeys,
        totalQueuedCount,
        playerQueue,
        playerState,
        restrictions,
        isLoading,
        errorMessage,
      ];
}
