import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/features/local_music/domain/local_context_resolver.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';
import 'package:musify_mu/features/player/domain/queue/queue_filter_helper.dart';
import 'package:musify_mu/features/player/domain/queue/queue_mutator.dart';

import 'queue_event.dart';
import 'queue_state.dart';

class _QueueDataChanged extends QueueEvent {
  final List<MediaItem> queue;
  final MediaItem? currentItem;

  const _QueueDataChanged(
    this.queue,
    this.currentItem,
  );

  @override
  List<Object?> get props => [queue, currentItem?.id];
}

class _PlaybackStatusChanged extends QueueEvent {
  final bool isPlaying;
  final AudioServiceShuffleMode shuffleMode;
  final AudioServiceRepeatMode repeatMode;

  const _PlaybackStatusChanged({
    required this.isPlaying,
    required this.shuffleMode,
    required this.repeatMode,
  });

  @override
  List<Object?> get props => [isPlaying, shuffleMode, repeatMode];
}

class QueueBloc extends Bloc<QueueEvent, QueueState> {
  final PlaybackController _playbackController;
  StreamSubscription<List<MediaItem>>? _queueSub;
  StreamSubscription<MediaItem?>? _mediaItemSub;
  StreamSubscription<PlaybackState>? _playbackStateSub;

  List<MediaItem> _lastQueue = const [];
  MediaItem? _lastMediaItem;
  int? _lastQueueIndex;
  int _pendingMutations = 0;
  int _latestTapGeneration = 0;
  DateTime? _animationEndTime;
  Future<void> _mutationChain = Future<void>.value();

  // Track explicit user-queued uids in memory (1:1 with Spotify is_queued flag tracking)
  final Set<String> _userQueuedUids = {};
  int _revisionCounter = 0;
  int _uidSeed = 0;

  void _enqueueMutation(Future<void> Function() action) {
    _pendingMutations++;
    _mutationChain = _mutationChain.then((_) async {
      final endTime = _animationEndTime;
      if (endTime != null) {
        final remaining = endTime.difference(DateTime.now());
        if (remaining > Duration.zero) {
          await Future<void>.delayed(remaining);
        }
      }
      if (!isClosed) {
        await action();
      }
    }).catchError((_) {}).whenComplete(() {
      _pendingMutations--;
      if (_pendingMutations == 0 && !isClosed) {
        _emitQueueChange();
      }
    });
  }

  QueueBloc({required PlaybackController playbackController})
      : _playbackController = playbackController,
        super(const QueueState()) {
    on<QueueStarted>(_onStarted);
    on<QueueTrackTapped>(_onTrackTapped);
    on<QueueReordered>(_onReordered);
    on<QueueTrackRemoved>(_onTrackRemoved);
    on<QueueTrackAdded>(_onTrackAdded);
    on<QueueCleared>(_onCleared);
    on<QueueShuffleToggled>(_onShuffleToggled);
    on<QueueRepeatToggled>(_onRepeatToggled);
    on<QueuePlayPauseToggled>(_onPlayPauseToggled);
    on<QueueNextPageRequested>(_onNextPageRequested);
    on<_QueueDataChanged>(_onDataChanged);
    on<_PlaybackStatusChanged>(_onPlaybackStatusChanged);
  }

  Future<void> _onStarted(QueueStarted event, Emitter<QueueState> emit) async {
    await _queueSub?.cancel();
    await _mediaItemSub?.cancel();
    await _playbackStateSub?.cancel();

    _queueSub = _playbackController.queue.listen((queue) {
      _lastQueue = queue;
      if (_pendingMutations == 0) {
        _emitQueueChange();
      }
    });
    _mediaItemSub = _playbackController.mediaItem.listen((item) {
      _lastMediaItem = item;
      if (_pendingMutations == 0) {
        _emitQueueChange();
      }
    });
    _playbackStateSub = _playbackController.playbackState.listen((pbState) {
      if (isClosed) return;
      if (_pendingMutations == 0) {
        _lastQueueIndex = pbState.queueIndex;
      }
      add(_PlaybackStatusChanged(
        isPlaying: pbState.playing,
        shuffleMode: pbState.shuffleMode,
        repeatMode: pbState.repeatMode,
      ));
    });
  }

  void _emitQueueChange() {
    if (isClosed || _pendingMutations > 0) return;
    add(_QueueDataChanged(
      _lastQueue,
      _lastMediaItem,
    ));
  }

  void _onPlaybackStatusChanged(
    _PlaybackStatusChanged event,
    Emitter<QueueState> emit,
  ) {
    final effectivePlaying =
        _pendingMutations > 0 ? state.isPlaying : event.isPlaying;
    if (state.isPlaying == effectivePlaying &&
        state.shuffleMode == event.shuffleMode &&
        state.repeatMode == event.repeatMode) {
      return;
    }
    emit(state.copyWith(
      isPlaying: effectivePlaying,
      shuffleMode: event.shuffleMode,
      repeatMode: event.repeatMode,
    ));
  }

  void _onPlayPauseToggled(
    QueuePlayPauseToggled event,
    Emitter<QueueState> emit,
  ) {
    final nextPlaying = !state.isPlaying;
    emit(state.copyWith(isPlaying: nextPlaying));
    if (nextPlaying) {
      _playbackController.play();
    } else {
      _playbackController.pause();
    }
  }

  Future<void> _onTrackTapped(
    QueueTrackTapped event,
    Emitter<QueueState> emit,
  ) async {
    final currentQueue = state.queue;
    final nextTracks = currentQueue.nextTracks;
    final tapIdx = nextTracks.indexWhere((t) => t.uid == event.track.uid);

    if (tapIdx == -1) {
      final tapGen = ++_latestTapGeneration;
      _animationEndTime =
          DateTime.now().add(const Duration(milliseconds: 375));
      _enqueueMutation(() async {
        if (_latestTapGeneration == tapGen) {
          await _playbackController.skipToQueueItem(event.absoluteIndex);
          await _playbackController.play();
        }
      });
      return;
    }

    final userQueueCount = QueueFilterHelper.getUserQueue(currentQueue).length;
    final baseOffset = state.currentIndex + 1;
    final nextCurrentTrack =
        event.track.copyWith(isQueued: false, provider: 'context');

    _lastMediaItem = nextCurrentTrack.toMediaItem();
    final tapGen = ++_latestTapGeneration;
    _animationEndTime = DateTime.now().add(const Duration(milliseconds: 375));

    if (tapIdx < userQueueCount || userQueueCount == 0) {
      // Case 1: Tapped a track inside userQueue (or no user queue exists).
      // Preceding user queue items are consumed into playback history.
      for (var i = 0; i <= tapIdx; i++) {
        _userQueuedUids.remove(nextTracks[i].uid);
      }

      final remainingUserQueue = userQueueCount > 0
          ? QueueFilterHelper.getUserQueue(currentQueue).sublist(tapIdx + 1)
          : const <ContextTrack>[];
      final contextTracks = QueueFilterHelper.getContextQueue(currentQueue);
      final targetAbsoluteIndex = baseOffset + tapIdx;

      _lastQueueIndex = targetAbsoluteIndex;
      _revisionCounter++;
      emit(state.copyWith(
        queue: currentQueue.copyWith(
          track: nextCurrentTrack,
          nextTracks: [...remainingUserQueue, ...contextTracks],
          revision: '$_revisionCounter',
        ),
        currentIndex: targetAbsoluteIndex,
        isPlaying: true,
      ));

      _enqueueMutation(() async {
        if (_latestTapGeneration == tapGen) {
          await _playbackController.skipToQueueItem(targetAbsoluteIndex);
          await _playbackController.play();
        }
      });
    } else {
      // Case 2: Tapped a context track below preserved userQueue.
      // 1:1 with Spotify: User queue remains preserved at head of upcoming tracks,
      // while tapped context track becomes active.
      final contextTapIdx = tapIdx - userQueueCount;
      final existingUserQueue = QueueFilterHelper.getUserQueue(currentQueue);
      final remainingContextTracks =
          QueueFilterHelper.getContextQueue(currentQueue).sublist(contextTapIdx + 1);
      final newUpcomingTracks = [...existingUserQueue, ...remainingContextTracks];

      final nextActiveMedia = nextCurrentTrack.toMediaItem();
      final upcomingMediaItems = newUpcomingTracks
          .map((t) => t.toMediaItem())
          .toList(growable: false);

      final targetAbsoluteIndex = baseOffset;
      _lastQueueIndex = targetAbsoluteIndex;
      _lastQueue = [
        nextActiveMedia,
        ...upcomingMediaItems,
      ];

      _revisionCounter++;
      emit(state.copyWith(
        queue: currentQueue.copyWith(
          track: nextCurrentTrack,
          nextTracks: newUpcomingTracks,
          revision: '$_revisionCounter',
        ),
        currentIndex: targetAbsoluteIndex,
        isPlaying: true,
      ));

      _enqueueMutation(() async {
        if (_latestTapGeneration == tapGen) {
          await _playbackController.setNextTracks([
            nextActiveMedia,
            ...upcomingMediaItems,
          ]);
          await _playbackController.skipToQueueItem(targetAbsoluteIndex);
          await _playbackController.play();
        }
      });
    }
  }

  Future<void> _onReordered(
    QueueReordered event,
    Emitter<QueueState> emit,
  ) async {
    final oldIdx = event.oldIndex;
    final targetIdx = event.newIndex;
    if (oldIdx == targetIdx) return;

    final currentQueue = state.queue;
    final visibleTracks =
        QueueFilterHelper.getVisibleUpcomingTracks(currentQueue);

    if (oldIdx < 0 || oldIdx >= visibleTracks.length) return;
    final clampedTarget = targetIdx.clamp(0, visibleTracks.length - 1);

    final draggedTrack = visibleTracks[oldIdx];
    final userQueueCount =
        QueueFilterHelper.getUserQueue(currentQueue).length;
    final isDroppedIntoUserQueue =
        userQueueCount > 0 && clampedTarget < userQueueCount;

    _revisionCounter++;
    final newPlayerQueue = QueueMutator.reorderTrack(
      currentQueue,
      draggedTrack: draggedTrack,
      targetVisibleIndex: clampedTarget,
      isTargetInUserQueue: isDroppedIntoUserQueue,
    ).copyWith(revision: '$_revisionCounter');

    if (isDroppedIntoUserQueue) {
      _userQueuedUids.add(draggedTrack.uid);
    } else {
      _userQueuedUids.remove(draggedTrack.uid);
    }

    emit(state.copyWith(queue: newPlayerQueue));

    // 1:1 with hxl0.a / SetQueueCommand: Sync entire updated nextTracks to audio engine
    final upcomingMediaItems = newPlayerQueue.nextTracks
        .map((t) => t.toMediaItem())
        .toList(growable: false);

    _lastQueue = [
      if (state.nowPlaying != null) state.nowPlaying!.toMediaItem(),
      ...upcomingMediaItems,
    ];

    _enqueueMutation(() async {
      await _playbackController.setNextTracks(upcomingMediaItems);
    });
  }


  Future<void> _onTrackRemoved(
    QueueTrackRemoved event,
    Emitter<QueueState> emit,
  ) async {
    final uid = event.uid;
    _userQueuedUids.remove(uid);

    final currentQueue = state.queue;
    final removeIdx = currentQueue.nextTracks.indexWhere((t) => t.uid == uid);

    if (removeIdx != -1) {
      _revisionCounter++;
      final updatedQueue = QueueMutator.removeTrack(currentQueue, uid)
          .copyWith(revision: '$_revisionCounter');

      emit(state.copyWith(queue: updatedQueue));

      final upcomingMediaItems = updatedQueue.nextTracks
          .map((t) => t.toMediaItem())
          .toList(growable: false);
      _lastQueue = [
        if (state.nowPlaying != null) state.nowPlaying!.toMediaItem(),
        ...upcomingMediaItems,
      ];
      _enqueueMutation(() async {
        await _playbackController.setNextTracks(upcomingMediaItems);
      });
    }
  }

  Future<void> _onTrackAdded(
    QueueTrackAdded event,
    Emitter<QueueState> emit,
  ) async {
    _uidSeed++;
    final newUid = '${event.track.uri}_q_$_uidSeed';
    final queuedTrack = event.track.copyWith(
      uid: newUid,
      isQueued: true,
      provider: 'queue',
    );
    _userQueuedUids.add(newUid);

    final currentQueue = state.queue;
    _revisionCounter++;
    final updatedQueue = QueueMutator.addToQueue(currentQueue, [queuedTrack])
        .copyWith(revision: '$_revisionCounter');

    emit(state.copyWith(
      queue: updatedQueue,
      lastAddedUid: newUid,
    ));

    final upcomingMediaItems = updatedQueue.nextTracks
        .map((t) => t.toMediaItem())
        .toList(growable: false);
    _lastQueue = [
      if (state.nowPlaying != null) state.nowPlaying!.toMediaItem(),
      ...upcomingMediaItems,
    ];
    _enqueueMutation(() async {
      await _playbackController.setNextTracks(upcomingMediaItems);
    });
  }

  Future<void> _onCleared(
    QueueCleared event,
    Emitter<QueueState> emit,
  ) async {
    _userQueuedUids.clear();
    final currentQueue = state.queue;
    final userCount = QueueFilterHelper.getUserQueue(currentQueue).length;
    if (userCount == 0) return;

    _revisionCounter++;
    final updatedQueue = QueueMutator.clearUserQueue(currentQueue)
        .copyWith(revision: '$_revisionCounter');

    emit(state.copyWith(queue: updatedQueue));

    final upcomingMediaItems = updatedQueue.nextTracks
        .map((t) => t.toMediaItem())
        .toList(growable: false);
    _lastQueue = [
      if (state.nowPlaying != null) state.nowPlaying!.toMediaItem(),
      ...upcomingMediaItems,
    ];
    _enqueueMutation(() async {
      await _playbackController.setNextTracks(upcomingMediaItems);
    });
  }

  void _onShuffleToggled(QueueShuffleToggled event, Emitter<QueueState> emit) {
    final current = state.shuffleMode;
    final next = current == AudioServiceShuffleMode.none
        ? AudioServiceShuffleMode.all
        : AudioServiceShuffleMode.none;
    emit(state.copyWith(shuffleMode: next));
    _playbackController.setShuffleMode(next);
  }

  void _onRepeatToggled(QueueRepeatToggled event, Emitter<QueueState> emit) {
    final current = state.repeatMode;
    AudioServiceRepeatMode next;
    switch (current) {
      case AudioServiceRepeatMode.none:
        next = AudioServiceRepeatMode.all;
        break;
      case AudioServiceRepeatMode.all:
        next = AudioServiceRepeatMode.one;
        break;
      case AudioServiceRepeatMode.one:
      default:
        next = AudioServiceRepeatMode.none;
        break;
    }
    emit(state.copyWith(repeatMode: next));
    _playbackController.setRepeatMode(next);
  }

  int _resolveCurrentIndex(List<MediaItem> queue, MediaItem current) {
    final knownIdx = _lastQueueIndex;
    if (knownIdx != null &&
        knownIdx >= 0 &&
        knownIdx < queue.length &&
        queue[knownIdx].id == current.id) {
      return knownIdx;
    }
    final stateIdx = state.currentIndex;
    if (stateIdx >= 0 &&
        stateIdx < queue.length &&
        queue[stateIdx].id == current.id) {
      return stateIdx;
    }
    return queue.indexWhere((item) => item.id == current.id);
  }

  void _onDataChanged(_QueueDataChanged event, Emitter<QueueState> emit) {
    if (_pendingMutations > 0) return;

    final queue = event.queue;
    final current = event.currentItem;

    if (queue.isEmpty || current == null) {
      emit(const QueueState());
      return;
    }

    final currentIndex = _resolveCurrentIndex(queue, current);
    if (currentIndex == -1) {
      emit(state.copyWith(
        queue: PlayerQueue(
          track: ContextTrack.fromMediaItem(
            current,
            uid: 'now_${current.id}',
          ),
          revision: '$_revisionCounter',
        ),
        totalTracks: queue.length,
      ));
      return;
    }

    final upcomingStart = currentIndex + 1;
    final upcomingItems = upcomingStart < queue.length
        ? queue.sublist(upcomingStart)
        : const <MediaItem>[];

    final existingNext = state.queue.nextTracks;

    // Fast path: if the upcoming URI sequence matches optimistic nextTracks,
    // preserve existing UIDs and isQueued division so ReorderableListView is smooth.
    if (existingNext.isNotEmpty &&
        upcomingItems.isNotEmpty &&
        state.nowPlaying?.uri == current.id) {
      final checkLen = existingNext.length < upcomingItems.length
          ? existingNext.length
          : upcomingItems.length;
      final lengthDiff = (existingNext.length - upcomingItems.length).abs();
      if (lengthDiff <= 2 && checkLen > 0) {
        var allMatch = true;
        for (var i = 0; i < checkLen; i++) {
          if (existingNext[i].uri != upcomingItems[i].id) {
            allMatch = false;
            break;
          }
        }
        if (allMatch) {
          final updatedCurrent = ContextTrack.fromMediaItem(
            current,
            uid: state.nowPlaying?.uri == current.id
                ? state.nowPlaying!.uid
                : 'now_${current.id}',
          );
          emit(state.copyWith(
            queue: state.queue.copyWith(track: updatedCurrent),
            currentIndex: currentIndex,
            totalTracks: queue.length,
          ));
          return;
        }
      }
    } else if (existingNext.isEmpty &&
        upcomingItems.isEmpty &&
        state.nowPlaying?.uri == current.id) {
      final updatedCurrent = ContextTrack.fromMediaItem(
        current,
        uid: state.nowPlaying!.uid,
      );
      emit(state.copyWith(
        queue: state.queue.copyWith(track: updatedCurrent),
        currentIndex: currentIndex,
        totalTracks: queue.length,
      ));
      return;
    }

    // Reconcile upcoming items while preserving existing UIDs and isQueued status
    final availableExisting = List<ContextTrack>.from(existingNext);
    final upcomingTracks = <ContextTrack>[];
    final occurrenceCounts = <String, int>{};

    for (var i = 0; i < upcomingItems.length; i++) {
      final item = upcomingItems[i];
      final count = (occurrenceCounts[item.id] ?? 0) + 1;
      occurrenceCounts[item.id] = count;

      final itemUid = item.extras?['uid']?.toString();
      var matchIdx = -1;
      if (itemUid != null && itemUid.isNotEmpty) {
        matchIdx = availableExisting.indexWhere((t) => t.uid == itemUid);
      }
      if (matchIdx == -1) {
        matchIdx = availableExisting.indexWhere((t) => t.uri == item.id);
      }

      ContextTrack track;
      if (matchIdx != -1) {
        final matched = availableExisting.removeAt(matchIdx);
        final explicitUid = matched.uid;
        final isQueued = _userQueuedUids.contains(explicitUid) ||
            item.extras?['is_queued'] == true ||
            item.extras?['is_queued'] == 'true';
        track = ContextTrack.fromMediaItem(
          item,
          uid: explicitUid,
          isQueued: isQueued,
        );
      } else {
        final explicitUid = itemUid ??
            (count == 1 ? item.id : '${item.id}_#_$count');
        final isQueued = _userQueuedUids.contains(explicitUid) ||
            item.extras?['is_queued'] == true ||
            item.extras?['is_queued'] == 'true';
        track = ContextTrack.fromMediaItem(
          item,
          uid: explicitUid,
          isQueued: isQueued,
        );
      }

      upcomingTracks.add(track);
    }

    // Pre-emptively fetch next page if upcoming context tracks are nearly exhausted
    final contextUpcomingCount =
        upcomingTracks.where((t) => !t.isQueued).length;
    if (contextUpcomingCount <= 8) {
      final lastContextTrack =
          upcomingTracks.where((t) => !t.isQueued).lastOrNull;
      final nextPageUrl = lastContextTrack?.metadata['next_page_url'] ??
          current.extras?['next_page_url']?.toString();
      if (nextPageUrl != null && nextPageUrl.isNotEmpty) {
        final page = LocalContextResolver.resolvePage(nextPageUrl);
        if (page != null) {
          final tempQueue = PlayerQueue(
            revision: '$_revisionCounter',
            track: ContextTrack.fromMediaItem(current, uid: 'now_${current.id}'),
            nextTracks: upcomingTracks,
          );
          final pagedQueue = QueueMutator.updatePage(tempQueue, page);
          upcomingTracks
            ..clear()
            ..addAll(pagedQueue.nextTracks);

          final upcomingMedia = upcomingTracks
              .map((t) => t.toMediaItem())
              .toList(growable: false);
          _lastQueue = [
            current,
            ...upcomingMedia,
          ];
          _playbackController.setNextTracks(upcomingMedia);
        }
      }
    }

    _revisionCounter++;
    final playerQueue = PlayerQueue(
      track: ContextTrack.fromMediaItem(
        current,
        uid: 'now_${current.id}',
      ),
      nextTracks: upcomingTracks,
      revision: '$_revisionCounter',
    );

    emit(state.copyWith(
      queue: playerQueue,
      currentIndex: currentIndex,
      totalTracks: queue.length,
    ));
  }

  Future<void> _onNextPageRequested(
    QueueNextPageRequested event,
    Emitter<QueueState> emit,
  ) async {
    final lastContextTrack = state.queue.contextTracks.lastOrNull;
    final nextPageUrl = lastContextTrack?.metadata['next_page_url'];
    if (nextPageUrl == null || nextPageUrl.isEmpty) return;

    final page = LocalContextResolver.resolvePage(nextPageUrl);
    if (page == null) return;

    _revisionCounter++;
    final updatedQueue = QueueMutator.updatePage(state.queue, page)
        .copyWith(revision: '$_revisionCounter');

    emit(state.copyWith(queue: updatedQueue));

    final upcomingMediaItems = updatedQueue.nextTracks
        .map((t) => t.toMediaItem())
        .toList(growable: false);

    _lastQueue = [
      if (state.nowPlaying != null) state.nowPlaying!.toMediaItem(),
      ...upcomingMediaItems,
    ];

    _enqueueMutation(() async {
      await _playbackController.setNextTracks(upcomingMediaItems);
    });
  }

  @override
  Future<void> close() {
    _queueSub?.cancel();
    _mediaItemSub?.cancel();
    _playbackStateSub?.cancel();
    return super.close();
  }
}
