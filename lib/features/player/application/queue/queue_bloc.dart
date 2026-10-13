import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';

import 'queue_event.dart';
import 'queue_state.dart';

class _QueueDataChanged extends QueueEvent {
  final List<MediaItem> queue;
  final MediaItem? currentItem;
  final int windowEnd;

  const _QueueDataChanged(
    this.queue,
    this.currentItem,
    this.windowEnd,
  );

  @override
  List<Object?> get props => [queue, currentItem?.id, windowEnd];
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

  // Track explicit user-queued uids in memory
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
      _playbackController.audioWindowEndIndex,
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

    final userQueueCount = currentQueue.userQueue.length;
    final baseOffset = state.currentIndex + 1;
    final nextCurrentTrack =
        event.track.copyWith(isQueued: false, provider: 'context');

    _lastMediaItem = nextCurrentTrack.toMediaItem();
    _lastQueueIndex = baseOffset;
    final tapGen = ++_latestTapGeneration;

    // Reserve the 375ms window exclusively for the 120fps QueueSheet UI
    // transition (matching Spotify's p/pa3.java ItemAnimator completion guard)
    // so MediaCodec/AudioTrack teardown & creation never drops animation frames.
    _animationEndTime = DateTime.now().add(const Duration(milliseconds: 375));

    if (tapIdx < userQueueCount) {
      // Case 1: Tapped a track inside userQueue.
      // Remove queued tracks up to and including the tapped queued track,
      // and preserve the remaining queued tracks + all context tracks.
      for (var i = 0; i <= tapIdx; i++) {
        _userQueuedUids.remove(nextTracks[i].uid);
      }

      final newUserQueue = currentQueue.userQueue.sublist(tapIdx + 1);
      final newContextTracks = currentQueue.contextTracks;

      _revisionCounter++;
      emit(state.copyWith(
        queue: currentQueue.copyWith(
          currentTrack: nextCurrentTrack,
          userQueue: newUserQueue,
          contextTracks: newContextTracks,
          revision: '$_revisionCounter',
        ),
        currentIndex: baseOffset,
        isPlaying: true,
      ));

      _enqueueMutation(() async {
        if (tapIdx > 0) {
          await _playbackController.removeQueueRange(
            baseOffset,
            baseOffset + tapIdx,
          );
        }
        if (_latestTapGeneration == tapGen) {
          await _playbackController.skipToQueueItem(baseOffset);
          await _playbackController.play();
        }
      });
    } else {
      // Case 2: Tapped a context track below userQueue.
      // Preserve ALL userQueue tracks so they still play next after the tapped
      // track, and remove only the skipped context tracks up to tapIdx.
      final contextTapIdx = tapIdx - userQueueCount;
      final newUserQueue = currentQueue.userQueue;
      final newContextTracks =
          currentQueue.contextTracks.sublist(contextTapIdx + 1);

      _revisionCounter++;
      emit(state.copyWith(
        queue: currentQueue.copyWith(
          currentTrack: nextCurrentTrack,
          userQueue: newUserQueue,
          contextTracks: newContextTracks,
          revision: '$_revisionCounter',
        ),
        currentIndex: baseOffset,
        isPlaying: true,
      ));

      _enqueueMutation(() async {
        // Atomically remove skipped context tracks [userQueueCount .. tapIdx)
        if (tapIdx > userQueueCount) {
          await _playbackController.removeQueueRange(
            baseOffset + userQueueCount,
            baseOffset + tapIdx,
          );
        }
        // Move the tapped context track (now at baseOffset + userQueueCount)
        // right before userQueue (at baseOffset) so userQueue plays immediately after it.
        if (userQueueCount > 0) {
          await _playbackController.reorderQueueItem(
            baseOffset + userQueueCount,
            baseOffset,
          );
        }
        if (_latestTapGeneration == tapGen) {
          await _playbackController.skipToQueueItem(baseOffset);
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
    final nextTracks = List<ContextTrack>.from(currentQueue.nextTracks);

    if (oldIdx < 0 || oldIdx >= nextTracks.length) return;
    if (targetIdx < 0 || targetIdx >= nextTracks.length) return;

    final movedTrack = nextTracks.removeAt(oldIdx);
    nextTracks.insert(targetIdx, movedTrack);

    // Cross-section drag conversion:
    final userQueueCount = currentQueue.userQueue.length;
    final isDroppedIntoUserQueue = targetIdx < userQueueCount;

    final updatedTrack = movedTrack.copyWith(
      isQueued: isDroppedIntoUserQueue,
      provider: isDroppedIntoUserQueue ? 'queue' : 'context',
    );
    nextTracks[targetIdx] = updatedTrack;

    if (isDroppedIntoUserQueue) {
      _userQueuedUids.add(updatedTrack.uid);
    } else {
      _userQueuedUids.remove(updatedTrack.uid);
    }

    final newUserQueue = nextTracks.where((t) => t.isQueued).toList();
    final newContextTracks = nextTracks.where((t) => !t.isQueued).toList();

    _revisionCounter++;
    final newPlayerQueue = currentQueue.copyWith(
      userQueue: newUserQueue,
      contextTracks: newContextTracks,
      revision: '$_revisionCounter',
    );

    emit(state.copyWith(queue: newPlayerQueue));

    final baseOffset = state.currentIndex + 1;
    _enqueueMutation(() async {
      await _playbackController.reorderQueueItem(
        baseOffset + oldIdx,
        baseOffset + targetIdx,
      );
    });
  }

  Future<void> _onTrackRemoved(
    QueueTrackRemoved event,
    Emitter<QueueState> emit,
  ) async {
    final uid = event.uid;
    _userQueuedUids.remove(uid);

    final currentQueue = state.queue;
    final nextTracks = List<ContextTrack>.from(currentQueue.nextTracks);
    final removeIdx = nextTracks.indexWhere((t) => t.uid == uid);

    if (removeIdx != -1) {
      nextTracks.removeAt(removeIdx);
      final newUserQueue = nextTracks.where((t) => t.isQueued).toList();
      final newContextTracks = nextTracks.where((t) => !t.isQueued).toList();

      _revisionCounter++;
      emit(state.copyWith(
        queue: currentQueue.copyWith(
          userQueue: newUserQueue,
          contextTracks: newContextTracks,
          revision: '$_revisionCounter',
        ),
      ));

      final absoluteRemoveIndex = state.currentIndex + 1 + removeIdx;
      _enqueueMutation(() async {
        await _playbackController.removeQueueItemAt(absoluteRemoveIndex);
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
    final newUserQueue = [...currentQueue.userQueue, queuedTrack];

    _revisionCounter++;
    emit(state.copyWith(
      queue: currentQueue.copyWith(
        userQueue: newUserQueue,
        revision: '$_revisionCounter',
      ),
    ));

    final insertIndex = state.currentIndex + 1 + currentQueue.userQueue.length;
    _animationEndTime = DateTime.now().add(const Duration(milliseconds: 375));
    _enqueueMutation(() async {
      await _playbackController.insertQueueItem(
        insertIndex,
        queuedTrack.toMediaItem(),
      );
    });
  }

  Future<void> _onCleared(
    QueueCleared event,
    Emitter<QueueState> emit,
  ) async {
    _userQueuedUids.clear();
    final currentQueue = state.queue;
    final userCount = currentQueue.userQueue.length;
    if (userCount == 0) return;

    _revisionCounter++;
    emit(state.copyWith(
      queue: currentQueue.copyWith(
        userQueue: const [],
        revision: '$_revisionCounter',
      ),
    ));

    final baseOffset = state.currentIndex + 1;
    _enqueueMutation(() async {
      await _playbackController.removeQueueRange(
        baseOffset,
        baseOffset + userCount,
      );
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
          currentTrack: ContextTrack.fromMediaItem(
            current,
            uid: 'now_${current.id}',
          ),
          revision: '$_revisionCounter',
        ),
        totalTracks: queue.length,
      ));
      return;
    }

    final windowEnd = event.windowEnd;
    final upcomingStart = currentIndex + 1;
    final upcomingCap = windowEnd > 0 ? windowEnd : queue.length;
    final upcomingEnd = upcomingCap.clamp(0, queue.length);

    final upcomingItems = upcomingStart < upcomingEnd
        ? queue.sublist(upcomingStart, upcomingEnd)
        : const <MediaItem>[];

    final existingNext = state.queue.nextTracks;

    // Fast path: if the upcoming URI sequence already matches our optimistic
    // state.queue.nextTracks, preserve all existing UIDs and userQueue/contextTracks
    // division so ReorderableListView and row animations are never interrupted.
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
            queue: state.queue.copyWith(currentTrack: updatedCurrent),
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
        queue: state.queue.copyWith(currentTrack: updatedCurrent),
        currentIndex: currentIndex,
        totalTracks: queue.length,
      ));
      return;
    }

    // Reconcile upcoming items while preserving existing UIDs and isQueued status
    final availableExisting = List<ContextTrack>.from(existingNext);
    final userQueue = <ContextTrack>[];
    final contextTracks = <ContextTrack>[];
    final occurrenceCounts = <String, int>{};

    for (var i = 0; i < upcomingItems.length; i++) {
      final item = upcomingItems[i];
      final count = (occurrenceCounts[item.id] ?? 0) + 1;
      occurrenceCounts[item.id] = count;

      final matchIdx = availableExisting.indexWhere((t) => t.uri == item.id);
      ContextTrack track;
      if (matchIdx != -1) {
        final matched = availableExisting.removeAt(matchIdx);
        final isQueued = matched.isQueued ||
            _userQueuedUids.contains(matched.uid) ||
            item.extras?['is_queued'] == true ||
            item.extras?['is_queued'] == 'true';
        track = ContextTrack.fromMediaItem(
          item,
          uid: matched.uid,
          isQueued: isQueued,
        );
      } else {
        final explicitUid = item.extras?['uid']?.toString();
        final deterministicUid = explicitUid ??
            (count == 1 ? item.id : '${item.id}_#_$count');
        final isQueued = _userQueuedUids.contains(deterministicUid) ||
            item.extras?['is_queued'] == true ||
            item.extras?['is_queued'] == 'true';
        track = ContextTrack.fromMediaItem(
          item,
          uid: deterministicUid,
          isQueued: isQueued,
        );
      }

      if (track.isQueued) {
        userQueue.add(track);
      } else {
        contextTracks.add(track);
      }
    }

    _revisionCounter++;
    final playerQueue = PlayerQueue(
      currentTrack: ContextTrack.fromMediaItem(
        current,
        uid: 'now_${current.id}',
      ),
      userQueue: userQueue,
      contextTracks: contextTracks,
      revision: '$_revisionCounter',
    );

    emit(state.copyWith(
      queue: playerQueue,
      currentIndex: currentIndex,
      totalTracks: queue.length,
    ));
  }

  @override
  Future<void> close() {
    _queueSub?.cancel();
    _mediaItemSub?.cancel();
    _playbackStateSub?.cancel();
    return super.close();
  }
}
