import 'package:equatable/equatable.dart';

import '../../../domain/commands/options/logging_params.dart';
import '../../../domain/models/context_track.dart';
import '../../../domain/models/player_queue.dart';
import '../../../domain/models/player_state.dart';

/// 1:1 sealed hierarchy of Spotify Mobius Queue Events matching `xdx0.java`.
sealed class QueueEvent extends Equatable {
  const QueueEvent();

  @override
  List<Object?> get props => [];
}

/// Native engine queue updated event (1:1 with Spotify `wcx0.java`).
final class QueueUpdatedEvent extends QueueEvent {
  final PlayerQueue queue;

  const QueueUpdatedEvent(this.queue);

  @override
  List<Object?> get props => [queue];
}

/// Native engine player state changed event (1:1 with Spotify `xcx0.java`).
final class PlayerStateChangedEvent extends QueueEvent {
  final PlayerState playerState;

  const PlayerStateChangedEvent(this.playerState);

  @override
  List<Object?> get props => [playerState];
}

/// Single track tapped in the queue to skip/play (1:1 with Spotify `kdx0.java`).
final class TrackTappedEvent extends QueueEvent {
  final ContextTrack track;

  const TrackTappedEvent(this.track);

  @override
  List<Object?> get props => [track];
}

/// Swipe to remove a single track from the queue (1:1 with Spotify `edx0.java`).
final class RemoveTrackEvent extends QueueEvent {
  final ContextTrack track;

  const RemoveTrackEvent(this.track);

  @override
  List<Object?> get props => [track];
}

/// Bulk remove multiple tracks from the queue (1:1 with Spotify `ddx0.java`).
final class RemoveTracksEvent extends QueueEvent {
  final List<ContextTrack> tracks;

  const RemoveTracksEvent(this.tracks);

  @override
  List<Object?> get props => [tracks];
}

/// Drag and drop reorder event with visible destination index (1:1 with Spotify `ldx0.java`).
final class ReorderTrackEvent extends QueueEvent {
  final ContextTrack track;
  final int destinationVisibleIndex;

  const ReorderTrackEvent({
    required this.track,
    required this.destinationVisibleIndex,
  });

  @override
  List<Object?> get props => [track, destinationVisibleIndex];
}

/// Swipe or tap to add track to queue (1:1 with Spotify `hdx0.java`).
final class AddToQueueEvent extends QueueEvent {
  final ContextTrack track;
  final bool playNext;
  final LoggingParams? loggingParams;

  const AddToQueueEvent({
    required this.track,
    this.playNext = false,
    this.loggingParams,
  });

  @override
  List<Object?> get props => [track, playNext, loggingParams];
}

/// Clear user queue (1:1 with Spotify `qcx0.java`).
final class ClearQueueEvent extends QueueEvent {
  const ClearQueueEvent();
}

/// Reset/reload queue (1:1 with Spotify `scx0.java`).
final class ResetQueueEvent extends QueueEvent {
  const ResetQueueEvent();
}

/// Toggle shuffle mode (1:1 with Spotify `tcx0.java`).
final class ToggleShuffleEvent extends QueueEvent {
  final LoggingParams? loggingParams;

  const ToggleShuffleEvent({this.loggingParams});

  @override
  List<Object?> get props => [loggingParams];
}

/// Cycle repeat mode (1:1 with Spotify `ucx0.java`).
final class ToggleRepeatEvent extends QueueEvent {
  final LoggingParams? loggingParams;

  const ToggleRepeatEvent({this.loggingParams});

  @override
  List<Object?> get props => [loggingParams];
}

/// Toggle play/pause state.
final class TogglePlayPauseEvent extends QueueEvent {
  final LoggingParams? loggingParams;

  const TogglePlayPauseEvent({this.loggingParams});

  @override
  List<Object?> get props => [loggingParams];
}

/// Skip to next track event.
final class SkipToNextTrackEvent extends QueueEvent {
  final LoggingParams? loggingParams;

  const SkipToNextTrackEvent({this.loggingParams});

  @override
  List<Object?> get props => [loggingParams];
}

/// Skip to previous track event.
final class SkipToPrevTrackEvent extends QueueEvent {
  final LoggingParams? loggingParams;

  const SkipToPrevTrackEvent({this.loggingParams});

  @override
  List<Object?> get props => [loggingParams];
}

/// Seek to position in track.
final class SeekToPositionEvent extends QueueEvent {
  final Duration position;
  final LoggingParams? loggingParams;

  const SeekToPositionEvent(this.position, {this.loggingParams});

  @override
  List<Object?> get props => [position, loggingParams];
}

/// Error received from audio engine.
final class QueueErrorEvent extends QueueEvent {
  final String errorMessage;

  const QueueErrorEvent(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
