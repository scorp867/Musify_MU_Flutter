import '../../../data/queue/queue_add_handler.dart';
import '../../../data/queue/queue_clear_handler.dart';
import '../../../data/queue/queue_helpers.dart';
import '../../../data/queue/queue_remove_handler.dart';
import '../../../data/queue/queue_reorder_handler.dart';
import '../../../domain/models/context_track.dart';
import '../../../domain/models/player_options.dart';
import '../../../domain/models/player_queue.dart';
import '../../../domain/models/player_state.dart';
import '../player_queue_event.dart';
import '../player_queue_state.dart';
import 'mobius_types.dart';
import 'queue_effects.dart';

/// 1:1 pure functional Mobius Update function for the Spotify Queue system.
/// `(Model, Event) -> Next<Model, Effect>`
Next<PlayerQueueState, QueueEffect> queueMobiusUpdate(
  PlayerQueueState model,
  PlayerQueueEvent event,
) {
  if (event is LoadQueue) {
    return Next.next(model.copyWith(isLoading: true));
  }

  if (event is QueueUpdated) {
    return Next.next(model.copyWith(
      queue: event.queue,
      isLoading: false,
    ));
  }

  if (event is PlayerStateChanged) {
    return Next.next(model.copyWith(
      playerState: event.playerState,
      isLoading: false,
    ));
  }

  if (event is QueueErrorOccurred) {
    return Next.next(model.copyWith(
      isLoading: false,
      errorMessage: event.error,
    ));
  }

  if (event is AddTracksToQueue) {
    final updatedQueue = QueueAddHandler.addTracks(
      model.queue,
      event.tracks,
      mode: event.mode,
    );
    return Next.next(
      model.copyWith(queue: updatedQueue),
      {AddTracksEffect(event.tracks, event.mode)},
    );
  }

  if (event is SetQueueTracks) {
    final updatedQueue = model.queue.toBuilder()
        .nextTracks(event.nextTracks)
        .prevTracks(event.prevTracks ?? model.queue.prevTracks)
        .build();
    return Next.next(
      model.copyWith(queue: updatedQueue),
      {
        SetQueueTracksEffect(
          nextTracks: event.nextTracks,
          prevTracks: event.prevTracks,
        ),
      },
    );
  }

  if (event is PlayContext) {
    return Next.dispatch({
      PlayContextEffect(
        context: event.context,
        options: event.options,
        playOrigin: event.playOrigin,
      ),
    });
  }

  if (event is RemoveTracksFromQueue) {
    final updatedQueue = QueueRemoveHandler.removeTracks(
      model.queue,
      event.tracks,
    );
    return Next.next(
      model.copyWith(queue: updatedQueue),
      {RemoveTracksEffect(event.tracks)},
    );
  }

  if (event is ReorderQueueTrack) {
    final updatedQueue = QueueReorderHandler.reorderTrack(
      playerQueue: model.queue,
      trackToMove: event.track,
      destinationVisibleIndex: event.destinationVisibleIndex,
    );
    return Next.next(
      model.copyWith(queue: updatedQueue),
      {ReorderTrackEffect(event.track, event.destinationVisibleIndex)},
    );
  }

  if (event is ClearQueue) {
    final updatedQueue = QueueClearHandler.clearUserQueue(model.queue);
    return Next.next(
      model.copyWith(queue: updatedQueue),
      {const ClearQueueEffect()},
    );
  }

  if (event is ToggleShuffle) {
    final currentOpts = model.playerState?.options ?? const PlayerOptions();
    final nextShuffle = !model.isShuffling;
    final updatedOptions = currentOpts
        .toBuilder()
        .shufflingContext(nextShuffle)
        .build();
    final updatedPs = (model.playerState ?? const PlayerState())
        .toBuilder()
        .options(updatedOptions)
        .build();

    PlayerQueue updatedQueue = model.queue;
    if (nextShuffle && model.queue.nextTracks.isNotEmpty) {
      final userQueue = QueueHelpers.getUserQueuedTracks(model.queue);
      final contextTracks = List<ContextTrack>.from(QueueHelpers.getContextTracks(model.queue));
      contextTracks.shuffle();
      updatedQueue = model.queue.toBuilder()
          .nextTracks([...userQueue, ...contextTracks])
          .build();
    }

    return Next.next(
      model.copyWith(
        playerState: updatedPs,
        queue: updatedQueue,
      ),
      {
        ToggleShuffleEffect(nextShuffle),
        if (nextShuffle)
          SetQueueTracksEffect(nextTracks: updatedQueue.nextTracks),
      },
    );
  }

  if (event is ToggleRepeat) {
    final currentOpts = model.playerState?.options ?? const PlayerOptions();
    final isRepeatingContext = currentOpts.repeatingContext;
    final isRepeatingTrack = currentOpts.repeatingTrack;

    bool nextRepeatContext = false;
    bool nextRepeatTrack = false;

    if (!isRepeatingContext && !isRepeatingTrack) {
      nextRepeatContext = true;
      nextRepeatTrack = false;
    } else if (isRepeatingContext && !isRepeatingTrack) {
      nextRepeatContext = false;
      nextRepeatTrack = true;
    } else {
      nextRepeatContext = false;
      nextRepeatTrack = false;
    }

    final updatedOptions = currentOpts
        .toBuilder()
        .repeatingContext(nextRepeatContext)
        .repeatingTrack(nextRepeatTrack)
        .build();
    final updatedPs = (model.playerState ?? const PlayerState())
        .toBuilder()
        .options(updatedOptions)
        .build();

    return Next.next(
      model.copyWith(playerState: updatedPs),
      {
        ToggleRepeatEffect(
          nextRepeatContext: nextRepeatContext,
          nextRepeatTrack: nextRepeatTrack,
        )
      },
    );
  }

  if (event is TogglePlayPause) {
    final nextPlaying = !model.isPlaying;
    final updatedPs = (model.playerState ?? const PlayerState())
        .toBuilder()
        .isPlaying(nextPlaying)
        .build();

    return Next.next(
      model.copyWith(playerState: updatedPs),
      {PlayPauseEffect(model.isPlaying)},
    );
  }

  if (event is SkipToNextTrack) {
    return Next.dispatch({const SkipNextEffect()});
  }

  if (event is SkipToPrevTrack) {
    return Next.dispatch({const SkipPrevEffect()});
  }

  if (event is PlayTrackFromQueue) {
    return Next.dispatch({PlayTrackEffect(event.track)});
  }

  if (event is SeekToTrackPosition) {
    final updatedPs = (model.playerState ?? const PlayerState())
        .toBuilder()
        .positionAsOfTimestamp(event.positionMs)
        .build();

    return Next.next(
      model.copyWith(playerState: updatedPs),
      {SeekToEffect(event.positionMs)},
    );
  }

  if (event is StopPlayback) {
    final updatedPs = (model.playerState ?? const PlayerState())
        .toBuilder()
        .isPlaying(false)
        .isPaused(false)
        .build();

    return Next.next(
      model.copyWith(playerState: updatedPs),
      {const StopEffect()},
    );
  }

  if (event is SendPlayerSignal) {
    return Next.dispatch({SignalEffect(event.signal)});
  }

  if (event is SetSleepTimer) {
    return Next.dispatch({SetSleepTimerEffect(event.command)});
  }

  if (event is PlayAsNextInQueue) {
    final updatedQueue = QueueAddHandler.addTracks(
      model.queue,
      event.tracks,
      mode: QueueInsertMode.playNext,
    );
    return Next.next(
      model.copyWith(queue: updatedQueue),
      {PlayAsNextInQueueEffect(event.tracks)},
    );
  }

  if (event is UpdateContext) {
    return Next.dispatch({UpdateContextEffect(event.context)});
  }

  if (event is UpdateTrack) {
    return Next.dispatch({UpdateTrackEffect(event.track)});
  }

  if (event is TrackFinished) {
    if (model.queue.nextTracks.isNotEmpty) {
      return Next.dispatch({const SkipNextEffect()});
    }
  }

  return Next.noChange();
}
