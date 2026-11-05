import 'package:equatable/equatable.dart';

import '../../../domain/commands/options/logging_params.dart';
import '../../../domain/models/context_track.dart';
import '../../../domain/models/player_queue.dart';

/// 1:1 sealed hierarchy of Spotify Mobius Queue Effects matching `cco0.java`.
sealed class QueueEffect extends Equatable {
  const QueueEffect();

  @override
  List<Object?> get props => [];
}

/// Removes tracks from nextTracks (1:1 with Spotify `lax0.java`).
final class RemoveTracksEffect extends QueueEffect {
  final List<ContextTrack> tracks;

  const RemoveTracksEffect(this.tracks);

  @override
  List<Object?> get props => [tracks];
}

/// Reorders a track within playerQueue.nextTracks (1:1 with Spotify `uax0.java`).
final class ReorderTrackEffect extends QueueEffect {
  final ContextTrack track;
  final int destinationIndex;

  const ReorderTrackEffect({
    required this.track,
    required this.destinationIndex,
  });

  @override
  List<Object?> get props => [track, destinationIndex];
}

/// Adds or moves a track to user queue (1:1 with Spotify `pax0.java`).
final class AddToQueueEffect extends QueueEffect {
  final ContextTrack track;
  final bool playNext;
  final LoggingParams? loggingParams;

  const AddToQueueEffect({
    required this.track,
    this.playNext = false,
    this.loggingParams,
  });

  @override
  List<Object?> get props => [track, playNext, loggingParams];
}

/// Skips playback directly to the specified track (1:1 with Spotify `kax0.java`).
final class SkipToTrackEffect extends QueueEffect {
  final ContextTrack track;

  const SkipToTrackEffect(this.track);

  @override
  List<Object?> get props => [track];
}

/// Clears user queue while preserving context lookahead (1:1 with Spotify `w9x0.java`).
final class ClearQueueEffect extends QueueEffect {
  const ClearQueueEffect();
}

/// Sets entire queue on native engine (1:1 with Spotify `nax0.java`).
final class SetQueueEffect extends QueueEffect {
  final PlayerQueue queue;

  const SetQueueEffect(this.queue);

  @override
  List<Object?> get props => [queue];
}

/// Toggles context shuffle on playback engine (1:1 with Spotify `jax0.java`).
final class ToggleShuffleEffect extends QueueEffect {
  final bool enableShuffle;
  final LoggingParams? loggingParams;

  const ToggleShuffleEffect({
    required this.enableShuffle,
    this.loggingParams,
  });

  @override
  List<Object?> get props => [enableShuffle, loggingParams];
}

/// Toggles repeat context / repeat track on playback engine.
final class ToggleRepeatEffect extends QueueEffect {
  final bool repeatingContext;
  final bool repeatingTrack;
  final LoggingParams? loggingParams;

  const ToggleRepeatEffect({
    required this.repeatingContext,
    required this.repeatingTrack,
    this.loggingParams,
  });

  @override
  List<Object?> get props => [repeatingContext, repeatingTrack, loggingParams];
}

/// Toggles play/pause on playback engine.
final class TogglePlayPauseEffect extends QueueEffect {
  final LoggingParams? loggingParams;

  const TogglePlayPauseEffect({this.loggingParams});

  @override
  List<Object?> get props => [loggingParams];
}

/// Skips to the next track on playback engine.
final class SkipToNextTrackEffect extends QueueEffect {
  final LoggingParams? loggingParams;

  const SkipToNextTrackEffect({this.loggingParams});

  @override
  List<Object?> get props => [loggingParams];
}

/// Skips to the previous track on playback engine.
final class SkipToPrevTrackEffect extends QueueEffect {
  final LoggingParams? loggingParams;

  const SkipToPrevTrackEffect({this.loggingParams});

  @override
  List<Object?> get props => [loggingParams];
}

/// Seeks to a specific duration on playback engine.
final class SeekToPositionEffect extends QueueEffect {
  final Duration position;
  final LoggingParams? loggingParams;

  const SeekToPositionEffect(this.position, {this.loggingParams});

  @override
  List<Object?> get props => [position, loggingParams];
}
