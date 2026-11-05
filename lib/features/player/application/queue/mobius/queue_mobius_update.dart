import '../../../data/esperanto/context_player_options_client.dart';
import '../../../data/queue/queue_key_resolver.dart';
import '../../../domain/models/context_track.dart';
import 'mobius_types.dart';
import 'queue_effect.dart';
import 'queue_event.dart';
import 'queue_model.dart';

/// 1:1 pure functional Mobius Update function matching Spotify's `jcv0.java` (`m54765n`).
Next<QueueModel, QueueEffect> _dispatch(Set<QueueEffect> effects) =>
    Next.dispatch<QueueModel, QueueEffect>(effects);

Next<QueueModel, QueueEffect> _next(QueueModel model, [Set<QueueEffect> effects = const {}]) =>
    Next.next<QueueModel, QueueEffect>(model, effects);

/// 1:1 pure functional Mobius Update function matching Spotify's `jcv0.java` (`m54765n`).
///
/// Directs unidirectional data flow without arbitrary local mutations:
/// `(QueueModel, QueueEvent) -> Next<QueueModel, QueueEffect>`
Next<QueueModel, QueueEffect> queueMobiusUpdate(
  QueueModel model,
  QueueEvent event,
) {
  return switch (event) {
    QueueUpdatedEvent(:final queue) => () {
        final userQueue = <ContextTrack>[];
        final contextTracks = <ContextTrack>[];

        for (final track in queue.nextTracks) {
          if (QueueKeyResolver.isQueued(track)) {
            userQueue.add(track);
          } else {
            contextTracks.add(track);
          }
        }

        // Keep pendingRemovalKeys that are still in the queue (cleaning up evicted tracks)
        final activeKeys = <String>{};
        for (final t in queue.nextTracks) {
          activeKeys.add(QueueKeyResolver.resolveKey(t));
        }
        final updatedPending = <String>{};
        for (final k in model.pendingRemovalKeys) {
          if (activeKeys.contains(k)) {
            updatedPending.add(k);
          }
        }

        final nextTrack = queue.nextTracks.isNotEmpty ? queue.nextTracks.first : null;

        return _next(model.copyWith(
          currentTrack: queue.track,
          nextTrack: nextTrack,
          userQueue: List.unmodifiable(userQueue),
          contextTracks: List.unmodifiable(contextTracks),
          pendingRemovalKeys: updatedPending,
          totalQueuedCount: userQueue.length,
          playerQueue: queue,
          isLoading: false,
        ));
      }(),

    PlayerStateChangedEvent(:final playerState) => _next(model.copyWith(
        playerState: playerState,
        restrictions: playerState.restrictions,
        isLoading: false,
      )),

    RemoveTrackEvent(:final track) => () {
        final key = QueueKeyResolver.resolveKey(track);
        final updatedPending = Set<String>.from(model.pendingRemovalKeys)..add(key);
        return _next(
          model.copyWith(pendingRemovalKeys: updatedPending),
          {RemoveTracksEffect([track])},
        );
      }(),

    RemoveTracksEvent(:final tracks) => () {
        final keys = tracks.map(QueueKeyResolver.resolveKey);
        final updatedPending = Set<String>.from(model.pendingRemovalKeys)..addAll(keys);
        return _next(
          model.copyWith(pendingRemovalKeys: updatedPending),
          {RemoveTracksEffect(tracks)},
        );
      }(),

    ReorderTrackEvent(:final track, :final destinationVisibleIndex) =>
      _dispatch({
        ReorderTrackEffect(
          track: track,
          destinationIndex: destinationVisibleIndex,
        ),
      }),

    AddToQueueEvent(:final track, :final playNext, :final loggingParams) =>
      _dispatch({
        AddToQueueEffect(
          track: track,
          playNext: playNext,
          loggingParams: loggingParams,
        ),
      }),

    TrackTappedEvent(:final track) => _dispatch({
        SkipToTrackEffect(track),
      }),

    ClearQueueEvent() => _dispatch({
        const ClearQueueEffect(),
      }),

    ResetQueueEvent() => _next(model.copyWith(isLoading: true)),

    ToggleShuffleEvent(:final loggingParams) => () {
        final nextShuffle = !model.isShuffling;
        return _dispatch({
          ToggleShuffleEffect(
            enableShuffle: nextShuffle,
            loggingParams: loggingParams,
          ),
        });
      }(),

    ToggleRepeatEvent(:final loggingParams) => () {
        final currentMode = model.repeatMode;
        bool nextContext = false;
        bool nextTrack = false;
        if (currentMode == RepeatMode.none) {
          nextContext = true;
        } else if (currentMode == RepeatMode.context) {
          nextTrack = true;
        }
        return _dispatch({
          ToggleRepeatEffect(
            repeatingContext: nextContext,
            repeatingTrack: nextTrack,
            loggingParams: loggingParams,
          ),
        });
      }(),

    TogglePlayPauseEvent(:final loggingParams) => _dispatch({
        TogglePlayPauseEffect(loggingParams: loggingParams),
      }),

    SkipToNextTrackEvent(:final loggingParams) => _dispatch({
        SkipToNextTrackEffect(loggingParams: loggingParams),
      }),

    SkipToPrevTrackEvent(:final loggingParams) => _dispatch({
        SkipToPrevTrackEffect(loggingParams: loggingParams),
      }),

    SeekToPositionEvent(:final position, :final loggingParams) => _dispatch({
        SeekToPositionEffect(position, loggingParams: loggingParams),
      }),

    QueueErrorEvent(:final errorMessage) => _next(model.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      )),
  };
}
