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

  // Track explicit user-queued uids in memory
  final Set<String> _userQueuedUids = {};
  int _revisionCounter = 0;
  int _uidSeed = 0;

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
      _emitQueueChange();
    });
    _mediaItemSub = _playbackController.mediaItem.listen((item) {
      _lastMediaItem = item;
      _emitQueueChange();
    });
    _playbackStateSub = _playbackController.playbackState.listen((pbState) {
      if (isClosed) return;
      add(_PlaybackStatusChanged(
        isPlaying: pbState.playing,
        shuffleMode: pbState.shuffleMode,
        repeatMode: pbState.repeatMode,
      ));
    });
  }

  void _emitQueueChange() {
    if (isClosed) return;
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
    if (state.isPlaying == event.isPlaying &&
        state.shuffleMode == event.shuffleMode &&
        state.repeatMode == event.repeatMode) {
      return;
    }
    emit(state.copyWith(
      isPlaying: event.isPlaying,
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

  void _onTrackTapped(QueueTrackTapped event, Emitter<QueueState> emit) {
    _playbackController.skipToQueueItem(event.absoluteIndex);
  }

  void _onReordered(QueueReordered event, Emitter<QueueState> emit) {
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
    _playbackController.reorderQueueItem(
      baseOffset + oldIdx,
      baseOffset + targetIdx,
    );
  }

  void _onTrackRemoved(QueueTrackRemoved event, Emitter<QueueState> emit) {
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
      _playbackController.removeQueueItemAt(absoluteRemoveIndex);
    }
  }

  void _onTrackAdded(QueueTrackAdded event, Emitter<QueueState> emit) {
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
    _playbackController.insertQueueItem(insertIndex, queuedTrack.toMediaItem());
  }

  void _onCleared(QueueCleared event, Emitter<QueueState> emit) {
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
    for (var i = userCount - 1; i >= 0; i--) {
      _playbackController.removeQueueItemAt(baseOffset + i);
    }
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

  void _onDataChanged(_QueueDataChanged event, Emitter<QueueState> emit) {
    final queue = event.queue;
    final current = event.currentItem;

    if (queue.isEmpty || current == null) {
      emit(const QueueState());
      return;
    }

    final currentIndex = queue.indexWhere((item) => item.id == current.id);
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
    // division so ReorderableListView and Dismissible animations are never interrupted.
    if (existingNext.length == upcomingItems.length) {
      var allMatch = true;
      for (var i = 0; i < upcomingItems.length; i++) {
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
