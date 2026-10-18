import '../../data/queue/queue_add_handler.dart';
import '../../domain/models/context_track.dart';
import '../../domain/models/player_queue.dart';
import '../../domain/models/player_state.dart';

abstract class PlayerQueueEvent {
  const PlayerQueueEvent();
}

/// Initialize or reload the queue stream from ContextPlayer
class LoadQueue extends PlayerQueueEvent {
  const LoadQueue();
}

/// Dispatched when a new PlayerQueue is emitted by the Esperanto client stream
class QueueUpdated extends PlayerQueueEvent {
  final PlayerQueue queue;
  const QueueUpdated(this.queue);
}

/// Dispatched when a new PlayerState is emitted by the state client stream
class PlayerStateChanged extends PlayerQueueEvent {
  final PlayerState playerState;
  const PlayerStateChanged(this.playerState);
}

/// Add tracks to queue (supports standard append or playNext mode)
class AddTracksToQueue extends PlayerQueueEvent {
  final List<ContextTrack> tracks;
  final QueueInsertMode mode;

  const AddTracksToQueue(
    this.tracks, {
    this.mode = QueueInsertMode.addToEndOfQueue,
  });
}

/// Remove one or more tracks from queue by compound queueKey
class RemoveTracksFromQueue extends PlayerQueueEvent {
  final List<ContextTrack> tracks;
  const RemoveTracksFromQueue(this.tracks);
}

/// Reorder a track by its destination index in the visible list
class ReorderQueueTrack extends PlayerQueueEvent {
  final ContextTrack track;
  final int destinationVisibleIndex;

  const ReorderQueueTrack({
    required this.track,
    required this.destinationVisibleIndex,
  });
}

/// Clear user-queued items, keeping context tracks intact
class ClearQueue extends PlayerQueueEvent {
  const ClearQueue();
}

/// Toggle shuffling context
class ToggleShuffle extends PlayerQueueEvent {
  const ToggleShuffle();
}

/// Cycle through repeat modes: none -> context -> track -> none
class ToggleRepeat extends PlayerQueueEvent {
  const ToggleRepeat();
}

/// Play a specific track from the queue
class PlayTrackFromQueue extends PlayerQueueEvent {
  final ContextTrack track;
  const PlayTrackFromQueue(this.track);
}

/// Toggle play/pause state
class TogglePlayPause extends PlayerQueueEvent {
  const TogglePlayPause();
}

/// Skip to next track
class SkipToNextTrack extends PlayerQueueEvent {
  const SkipToNextTrack();
}

/// Skip to previous track
class SkipToPrevTrack extends PlayerQueueEvent {
  const SkipToPrevTrack();
}

/// Dispatched when an asynchronous stream error occurs
class QueueErrorOccurred extends PlayerQueueEvent {
  final String error;
  const QueueErrorOccurred(this.error);
}

// Convenient aliases for UI event dispatching
typedef PlayerQueueTogglePlayPause = TogglePlayPause;
typedef PlayerQueueToggleShuffle = ToggleShuffle;
typedef PlayerQueueCycleRepeat = ToggleRepeat;
typedef PlayerQueueSkipNext = SkipToNextTrack;
typedef PlayerQueueSkipPrevious = SkipToPrevTrack;
typedef PlayerQueueLoadQueue = LoadQueue;
typedef PlayerQueueClearQueue = ClearQueue;

