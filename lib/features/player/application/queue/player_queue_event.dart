import '../../data/queue/queue_add_handler.dart';
import '../../domain/commands/options/logging_params.dart';
import '../../domain/commands/options/prepare_play_options.dart';
import '../../domain/commands/set_sleep_timer_command.dart';
import '../../domain/commands/signal_command.dart';
import '../../domain/models/context.dart';
import '../../domain/models/context_track.dart';
import '../../domain/models/play_origin.dart';
import '../../domain/models/player_queue.dart';
import '../../domain/models/player_state.dart';

/// 1:1 sealed event hierarchy for Spotify Mobius Queue Loop (p199p/xdx0.java).
/// Every event is a final subclass of the sealed root event.
sealed class PlayerQueueEvent {
  const PlayerQueueEvent();
}

/// Initialize or reload the queue stream from ContextPlayer
final class LoadQueue extends PlayerQueueEvent {
  const LoadQueue();
}

/// Dispatched when a new PlayerQueue is emitted by the Esperanto client stream (1:1 with wcx0 / pvy).
final class QueueUpdated extends PlayerQueueEvent {
  final PlayerQueue queue;
  const QueueUpdated(this.queue);
}

/// Dispatched when a new PlayerState is emitted by the state client stream (1:1 with xcx0 / rvy).
final class PlayerStateChanged extends PlayerQueueEvent {
  final PlayerState playerState;
  const PlayerStateChanged(this.playerState);
}

/// Add tracks to user queue (1:1 with adx0 / dwp0).
final class AddTracksToQueue extends PlayerQueueEvent {
  final List<ContextTrack> tracks;
  final QueueInsertMode mode;

  const AddTracksToQueue(
    this.tracks, {
    this.mode = QueueInsertMode.addToEndOfQueue,
  });
}

/// Set tracks directly into nextTracks (1:1 with mcx0 / SetQueueCommand).
final class SetQueueTracks extends PlayerQueueEvent {
  final List<ContextTrack> nextTracks;
  final List<ContextTrack>? prevTracks;

  const SetQueueTracks({
    required this.nextTracks,
    this.prevTracks,
  });
}

/// Play a context (e.g. album, playlist, local files list) matching Spotify PlayCommand (1:1 with cdx0).
final class PlayContext extends PlayerQueueEvent {
  final Context context;
  final PreparePlayOptions? options;
  final PlayOrigin playOrigin;

  const PlayContext({
    required this.context,
    this.options,
    this.playOrigin = const PlayOrigin(),
  });
}

/// Remove one or more tracks from queue by compound queueKey (1:1 with ddx0).
final class RemoveTracksFromQueue extends PlayerQueueEvent {
  final List<ContextTrack> tracks;
  const RemoveTracksFromQueue(this.tracks);
}

/// Reorder a track by its destination index in the visible list (1:1 with kdx0).
final class ReorderQueueTrack extends PlayerQueueEvent {
  final ContextTrack track;
  final int destinationVisibleIndex;

  const ReorderQueueTrack({
    required this.track,
    required this.destinationVisibleIndex,
  });
}

/// Clear user-queued items, keeping context tracks intact (1:1 with scx0).
final class ClearQueue extends PlayerQueueEvent {
  const ClearQueue();
}

/// Toggle shuffling context (1:1 with qcx0).
final class ToggleShuffle extends PlayerQueueEvent {
  final LoggingParams? loggingParams;
  const ToggleShuffle({this.loggingParams});
}

/// Cycle through repeat modes: none -> context -> track -> none (1:1 with rcx0).
final class ToggleRepeat extends PlayerQueueEvent {
  final LoggingParams? loggingParams;
  const ToggleRepeat({this.loggingParams});
}

/// Play a specific track from the queue (1:1 with fcx0 / PlayTrack).
final class PlayTrackFromQueue extends PlayerQueueEvent {
  final ContextTrack track;
  final PlayOrigin playOrigin;
  const PlayTrackFromQueue(this.track, {this.playOrigin = const PlayOrigin()});
}

/// Toggle play/pause state (1:1 with tcx0).
final class TogglePlayPause extends PlayerQueueEvent {
  final LoggingParams? loggingParams;
  const TogglePlayPause({this.loggingParams});
}

/// Skip to next track (1:1 with hdx0).
final class SkipToNextTrack extends PlayerQueueEvent {
  final LoggingParams? loggingParams;
  const SkipToNextTrack({this.loggingParams});
}

/// Skip to previous track (1:1 with ldx0).
final class SkipToPrevTrack extends PlayerQueueEvent {
  final LoggingParams? loggingParams;
  const SkipToPrevTrack({this.loggingParams});
}

/// Seek playback to an exact position in milliseconds (1:1 with edx0).
final class SeekToTrackPosition extends PlayerQueueEvent {
  final int positionMs;
  final LoggingParams? loggingParams;
  const SeekToTrackPosition(this.positionMs, {this.loggingParams});
}

/// Stop playback immediately (1:1 with sdx0).
final class StopPlayback extends PlayerQueueEvent {
  const StopPlayback();
}

/// Send a signal command to ContextPlayer (1:1 with vdx0).
final class SendPlayerSignal extends PlayerQueueEvent {
  final SignalCommand signal;
  const SendPlayerSignal(this.signal);
}

/// Configure sleep timer (1:1 with pdx0).
final class SetSleepTimer extends PlayerQueueEvent {
  final SetSleepTimerCommand command;
  const SetSleepTimer(this.command);
}

/// Insert tracks to play immediately after the current playing track (1:1 with ndx0).
final class PlayAsNextInQueue extends PlayerQueueEvent {
  final List<ContextTrack> tracks;
  const PlayAsNextInQueue(this.tracks);
}

/// Update active context metadata (1:1 with jdx0).
final class UpdateContext extends PlayerQueueEvent {
  final Context context;
  const UpdateContext(this.context);
}

/// Update active track metadata (1:1 with icx0).
final class UpdateTrack extends PlayerQueueEvent {
  final ContextTrack track;
  const UpdateTrack(this.track);
}

/// Dispatched when the native engine finishes rendering a track (1:1 with ycx0 / EOS).
final class TrackFinished extends PlayerQueueEvent {
  final ContextTrack? finishedTrack;
  const TrackFinished([this.finishedTrack]);
}

/// Dispatched when an asynchronous stream error occurs (1:1 with gdx0).
final class QueueErrorOccurred extends PlayerQueueEvent {
  final String error;
  const QueueErrorOccurred(this.error);
}

// Convenient aliases for UI event dispatching
typedef PlayTrack = PlayTrackFromQueue;
typedef PlayerQueueTogglePlayPause = TogglePlayPause;
typedef PlayerQueueToggleShuffle = ToggleShuffle;
typedef PlayerQueueCycleRepeat = ToggleRepeat;
typedef PlayerQueueSkipNext = SkipToNextTrack;
typedef PlayerQueueSkipPrevious = SkipToPrevTrack;
typedef PlayerQueueSeekTo = SeekToTrackPosition;
typedef PlayerQueueStop = StopPlayback;
typedef PlayerQueueLoadQueue = LoadQueue;
typedef PlayerQueueClearQueue = ClearQueue;
typedef PlayerQueueSendSignal = SendPlayerSignal;
