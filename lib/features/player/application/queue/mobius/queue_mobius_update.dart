import '../../../data/queue/queue_add_handler.dart';
import '../../../data/queue/queue_clear_handler.dart';
import '../../../data/queue/queue_remove_handler.dart';
import '../../../data/queue/queue_reorder_handler.dart';
import '../../../domain/models/player_options.dart';
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

    return Next.next(
      model.copyWith(playerState: updatedPs),
      {ToggleShuffleEffect(nextShuffle)},
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

  return Next.noChange();
}
