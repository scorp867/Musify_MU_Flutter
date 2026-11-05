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

/// 1:1 pure functional Mobius Update function for the Spotify Queue system (svd0.java / jcv0.java m54765n).
/// `(Model, Event) -> Next<Model, Effect>`
Next<PlayerQueueState, QueueEffect> queueMobiusUpdate(
  PlayerQueueState model,
  PlayerQueueEvent event,
) {
  return switch (event) {
    LoadQueue() => Next.next(model.copyWith(isLoading: true)),

    QueueUpdated(:final queue) => Next.next(model.copyWith(
        queue: queue,
        isLoading: false,
      )),

    PlayerStateChanged(:final playerState) => Next.next(model.copyWith(
        playerState: playerState,
        isLoading: false,
      )),

    QueueErrorOccurred(:final error) => Next.next(model.copyWith(
        isLoading: false,
        errorMessage: error,
      )),

    AddTracksToQueue(:final tracks, :final mode) => () {
        final updatedQueue = QueueAddHandler.addTracks(
          model.queue,
          tracks,
          mode: mode,
        );
        return Next.next(
          model.copyWith(queue: updatedQueue),
          {AddTracksEffect(tracks, mode)},
        );
      }(),

    SetQueueTracks(:final nextTracks, :final prevTracks) => () {
        final updatedQueue = model.queue.toBuilder()
            .nextTracks(nextTracks)
            .prevTracks(switch (prevTracks) {
              final prev? => prev,
              null => model.queue.prevTracks,
            })
            .build();
        return Next.next(
          model.copyWith(queue: updatedQueue),
          {
            SetQueueTracksEffect(
              nextTracks: nextTracks,
              prevTracks: prevTracks,
            ),
          },
        );
      }(),

    PlayContext(:final context, :final options, :final playOrigin) =>
      Next.dispatch({
        PlayContextEffect(
          context: context,
          options: options,
          playOrigin: playOrigin,
        ),
      }),

    RemoveTracksFromQueue(:final tracks) => () {
        final updatedQueue = QueueRemoveHandler.removeTracks(
          model.queue,
          tracks,
        );
        return Next.next(
          model.copyWith(queue: updatedQueue),
          {RemoveTracksEffect(tracks)},
        );
      }(),

    ReorderQueueTrack(:final track, :final destinationVisibleIndex) => () {
        final updatedQueue = QueueReorderHandler.reorderTrack(
          playerQueue: model.queue,
          trackToMove: track,
          destinationVisibleIndex: destinationVisibleIndex,
        );
        return Next.next(
          model.copyWith(queue: updatedQueue),
          {ReorderTrackEffect(track, destinationVisibleIndex)},
        );
      }(),

    ClearQueue() => () {
        final updatedQueue = QueueClearHandler.clearUserQueue(model.queue);
        return Next.next(
          model.copyWith(queue: updatedQueue),
          {const ClearQueueEffect()},
        );
      }(),

    ToggleShuffle(:final loggingParams) => () {
        final currentOpts = switch (model.playerState) {
          final ps? => ps.options,
          null => const PlayerOptions(),
        };
        final nextShuffle = !model.isShuffling;
        final updatedOptions = currentOpts
            .toBuilder()
            .shufflingContext(nextShuffle)
            .build();
        final basePs = switch (model.playerState) {
          final ps? => ps,
          null => const PlayerState(),
        };
        final updatedPs = basePs
            .toBuilder()
            .options(updatedOptions)
            .build();

        return Next.next(
          model.copyWith(playerState: updatedPs),
          {ToggleShuffleEffect(nextShuffle, loggingParams: loggingParams)},
        );
      }(),

    ToggleRepeat(:final loggingParams) => () {
        final currentOpts = switch (model.playerState) {
          final ps? => ps.options,
          null => const PlayerOptions(),
        };
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
        final basePs = switch (model.playerState) {
          final ps? => ps,
          null => const PlayerState(),
        };
        final updatedPs = basePs
            .toBuilder()
            .options(updatedOptions)
            .build();

        return Next.next(
          model.copyWith(playerState: updatedPs),
          {
            ToggleRepeatEffect(
              nextRepeatContext: nextRepeatContext,
              nextRepeatTrack: nextRepeatTrack,
              loggingParams: loggingParams,
            ),
          },
        );
      }(),

    TogglePlayPause(:final loggingParams) => () {
        final nextPlaying = !model.isPlaying;
        final basePs = switch (model.playerState) {
          final ps? => ps,
          null => const PlayerState(),
        };
        final updatedPs = basePs
            .toBuilder()
            .isPlaying(nextPlaying)
            .build();

        return Next.next(
          model.copyWith(playerState: updatedPs),
          {PlayPauseEffect(model.isPlaying, loggingParams: loggingParams)},
        );
      }(),

    SkipToNextTrack(:final loggingParams) => Next.dispatch({
        SkipNextEffect(loggingParams: loggingParams),
      }),

    SkipToPrevTrack(:final loggingParams) => Next.dispatch({
        SkipPrevEffect(loggingParams: loggingParams),
      }),

    PlayTrackFromQueue(:final track, :final playOrigin) => Next.dispatch({
        PlayTrackEffect(track, playOrigin: playOrigin),
      }),

    SeekToTrackPosition(:final positionMs, :final loggingParams) => () {
        final basePs = switch (model.playerState) {
          final ps? => ps,
          null => const PlayerState(),
        };
        final updatedPs = basePs
            .toBuilder()
            .positionAsOfTimestamp(positionMs)
            .build();

        return Next.next(
          model.copyWith(playerState: updatedPs),
          {SeekToEffect(positionMs, loggingParams: loggingParams)},
        );
      }(),

    StopPlayback() => () {
        final basePs = switch (model.playerState) {
          final ps? => ps,
          null => const PlayerState(),
        };
        final updatedPs = basePs
            .toBuilder()
            .isPlaying(false)
            .isPaused(false)
            .build();

        return Next.next(
          model.copyWith(playerState: updatedPs),
          {const StopEffect()},
        );
      }(),

    SendPlayerSignal(:final signal) => Next.dispatch({
        SignalEffect(signal),
      }),

    SetSleepTimer(:final command) => Next.dispatch({
        SetSleepTimerEffect(command),
      }),

    PlayAsNextInQueue(:final tracks) => () {
        final updatedQueue = QueueAddHandler.addTracks(
          model.queue,
          tracks,
          mode: QueueInsertMode.playNext,
        );
        return Next.next(
          model.copyWith(queue: updatedQueue),
          {PlayAsNextInQueueEffect(tracks)},
        );
      }(),

    UpdateContext(:final context) => Next.dispatch({
        UpdateContextEffect(context),
      }),

    UpdateTrack(:final track) => Next.dispatch({
        UpdateTrackEffect(track),
      }),

    TrackFinished() => model.queue.nextTracks.isNotEmpty
        ? Next.dispatch({const SkipNextEffect()})
        : Next.noChange(),
  };
}
