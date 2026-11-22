// ============================================================================
// 1:1 Replica of Spotify Mobius Queue Update Function (`p199p/jcv0.java`)
// Sources:
// - Decompiled Java:
//   - `p199p/jcv0.java` (`m54765n`: pure functional Mobius update)
//   - `p199p/bh10.java:339-361` (partitions `playerQueue.nextTracks()` via `ock1.m68146V`
//     and applies `erl.m42237b` to both userQueue and contextTracks)
//   - `p199p/erl.java:16,40-69` (`m42237b`: stops at `isDelimiter()` and drops
//     `spotify:meta*`, banned, hidden, and optionally 19+ tracks)
//   - `p199p/fi31.java:42-88` (resolves `nextTrack` skipping/stopping at delimiters)
//   - `com/spotify/player/model/ContextTrack.java:16,206-208` (`isDelimiter()`)
// - Native binary (`liborbit-jni-spotify.so` arm64):
//   - `parseClusterProto` @ `0xdc7e84..0xdc7ed0` (preserves delimiters on wire; UI filters)
//   - `ListPlayer` @ `0xe61078..0xe610cc`, `0xe61124..0xe61158`
// ============================================================================

import '../../../data/esperanto/context_player_options_client.dart';
import '../../../data/queue/queue_key_resolver.dart';
import '../../../data/queue/queue_track_filter.dart';
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
        // 1:1 with `p199p/bh10.java:344-361` -> `p199p/erl.java:40-69`:
        // Partition raw `queue.nextTracks` by `isQueued` and stop each partition
        // at the first `spotify:delimiter` / `spotify:meta:delimiter` (excluding
        // the delimiter and all post-delimiter tracks, plus blacklisted/banned/hidden).
        // The raw `queue` is retained untouched in `model.playerQueue` for `SetQueue`.
        final filtered = QueueTrackFilter.partitionAndFilter(queue.nextTracks);
        final userQueue = filtered.userQueue;
        final contextTracks = filtered.contextTracks;

        // Keep pendingRemovalKeys that are still visible in the filtered queue.
        final activeKeys = <String>{};
        for (final t in userQueue) {
          activeKeys.add(QueueKeyResolver.resolveKey(t));
        }
        for (final t in contextTracks) {
          activeKeys.add(QueueKeyResolver.resolveKey(t));
        }
        final updatedPending = <String>{};
        for (final k in model.pendingRemovalKeys) {
          if (activeKeys.contains(k)) {
            updatedPending.add(k);
          }
        }

        // 1:1 with `p199p/fi31.java:42-88`: next track comes from filtered lists,
        // never a delimiter or post-delimiter track.
        final ContextTrack? nextTrack;
        if (userQueue.isNotEmpty) {
          nextTrack = userQueue.first;
        } else if (contextTracks.isNotEmpty) {
          nextTrack = contextTracks.first;
        } else {
          nextTrack = null;
        }

        return _next(model.copyWith(
          currentTrack: queue.track,
          clearCurrentTrack: queue.track == null,
          nextTrack: nextTrack,
          clearNextTrack: nextTrack == null,
          userQueue: List.unmodifiable(userQueue),
          contextTracks: List.unmodifiable(contextTracks),
          pendingRemovalKeys: updatedPending,
          totalQueuedCount: userQueue.length,
          playerQueue: queue,
          isLoading: false,
        ));
      }(),

    PlayerStateChangedEvent(:final playerState) => () {
        final incomingTrack = playerState.track;
        final existingTrack = model.currentTrack;
        ContextTrack? updatedCurrentTrack;
        if (incomingTrack != null && !incomingTrack.isDelimiter()) {
          final isExistingVaultMasked =
              existingTrack != null &&
              existingTrack.metadata['musify_vault_masked'] == 'true' &&
              incomingTrack.metadata['musify_vault_masked'] != 'true' &&
              existingTrack.uri == incomingTrack.uri &&
              existingTrack.uid == incomingTrack.uid;
          if (!isExistingVaultMasked) {
            final isDifferentTrack =
                existingTrack == null ||
                existingTrack.uri != incomingTrack.uri ||
                existingTrack.uid != incomingTrack.uid;
            final hasEnrichedMetadata =
                existingTrack != null &&
                incomingTrack.metadata.length >= existingTrack.metadata.length;
            if (isDifferentTrack || hasEnrichedMetadata) {
              updatedCurrentTrack = incomingTrack;
            }
          }
        }
        final shouldClearCurrentTrack = incomingTrack == null &&
            !playerState.isPlaying &&
            !playerState.isPaused &&
            !playerState.isBuffering;

        return _next(model.copyWith(
          currentTrack: updatedCurrentTrack,
          clearCurrentTrack: shouldClearCurrentTrack,
          playerState: playerState,
          restrictions: playerState.restrictions,
          isLoading: false,
        ));
      }(),

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

    ResetQueueEvent() => _next(
        const QueueModel(isLoading: false),
        {const ResetQueueEffect()},
      ),

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
