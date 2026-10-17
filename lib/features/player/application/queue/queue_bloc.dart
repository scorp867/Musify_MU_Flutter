import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/core/audio/queue_differ.dart';
import 'package:musify_mu/features/local_music/domain/local_context_resolver.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';
import 'package:musify_mu/features/player/domain/queue/queue_filter_helper.dart';
import 'package:musify_mu/features/player/domain/queue/queue_mutator.dart';
import 'package:musify_mu/features/player/domain/queue/queue_reconciler.dart';

import 'queue_event.dart';
import 'queue_state.dart';

/// Principal BLoC governing the player queue and active playback state.
///
/// Drives queue state unidirectionally from [SequenceState] and [PlayerState] streams.
/// Enforces event concurrency via [bloc_concurrency] transformers:
/// - [sequential] for queue mutations to guarantee atomic, in-order execution.
/// - [restartable] for rapid track switching and seeking.
class QueueBloc extends Bloc<QueueEvent, QueueState> {
  final PlaybackController _playbackController;

  StreamSubscription<SequenceState?>? _sequenceSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<List<MediaItem>>? _queueSub;
  StreamSubscription<MediaItem?>? _mediaItemSub;
  StreamSubscription<PlaybackState>? _playbackStateSub;

  List<MediaItem> _lastQueue = const [];
  MediaItem? _lastMediaItem;
  int? _lastQueueIndex;
  bool _lastIsPlaying = true;
  AudioServiceShuffleMode _lastShuffleMode = AudioServiceShuffleMode.none;
  AudioServiceRepeatMode _lastRepeatMode = AudioServiceRepeatMode.none;

  final Set<String> _userQueuedUids = {};
  final Set<String> _loadedPageUrls = <String>{};
  String? _loadingPageUrl;
  int _revisionCounter = 0;
  int _uidSeed = 0;

  QueueBloc({required PlaybackController playbackController})
      : _playbackController = playbackController,
        super(const QueueInitial()) {
    on<QueueStarted>(_onStarted);
    on<QueueTrackTapped>(_onTrackTapped, transformer: restartable());
    on<QueueReordered>(_onReordered, transformer: sequential());
    on<QueueTrackRemoved>(_onTrackRemoved, transformer: sequential());
    on<QueueTrackAdded>(_onTrackAdded, transformer: sequential());
    on<QueueCleared>(_onCleared, transformer: sequential());
    on<QueueShuffleToggled>(_onShuffleToggled, transformer: sequential());
    on<QueueRepeatToggled>(_onRepeatToggled, transformer: sequential());
    on<QueuePlayPauseToggled>(_onPlayPauseToggled, transformer: sequential());
    on<QueueNextPageRequested>(_onNextPageRequested, transformer: sequential());
    on<QueueDataChanged>(_onDataChanged, transformer: sequential());
    on<PlaybackStatusChanged>(_onPlaybackStatusChanged);
  }

  Future<void> _onStarted(QueueStarted event, Emitter<QueueState> emit) async {
    await _cancelSubscriptions();
    _loadedPageUrls.clear();
    _loadingPageUrl = null;

    // Primary unidirectional stream: SequenceState from native just_audio
    _sequenceSub = _playbackController.sequenceStateStream.listen((seqState) {
      if (isClosed) return;
      if (seqState != null) {
        add(QueueDataChanged(sequenceState: seqState));
      }
    });

    _playerStateSub = _playbackController.playerStateStream.listen((pState) {
      if (isClosed) return;
      _lastIsPlaying = pState.playing;
      final seq = _playbackController.sequenceState;
      final shuffle = seq?.shuffleModeEnabled == true
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none;
      final repeat = switch (seq?.loopMode) {
        LoopMode.one => AudioServiceRepeatMode.one,
        LoopMode.all => AudioServiceRepeatMode.all,
        _ => AudioServiceRepeatMode.none,
      };
      _lastShuffleMode = shuffle;
      _lastRepeatMode = repeat;

      add(PlaybackStatusChanged(
        isPlaying: pState.playing,
        shuffleMode: shuffle,
        repeatMode: repeat,
      ));
    });

    // Fallback streams for compatibility with standard AudioHandler or mock controllers
    _queueSub = _playbackController.queue.listen((q) {
      if (isClosed) return;
      _lastQueue = q;
      _dispatchFallbackQueueChange();
    });

    _mediaItemSub = _playbackController.mediaItem.listen((item) {
      if (isClosed) return;
      _lastMediaItem = item;
      _dispatchFallbackQueueChange();
    });

    _playbackStateSub = _playbackController.playbackState.listen((pbState) {
      if (isClosed) return;
      _lastQueueIndex = pbState.queueIndex;
      _lastIsPlaying = pbState.playing;
      _lastShuffleMode = pbState.shuffleMode;
      _lastRepeatMode = pbState.repeatMode;

      add(PlaybackStatusChanged(
        isPlaying: pbState.playing,
        shuffleMode: pbState.shuffleMode,
        repeatMode: pbState.repeatMode,
      ));
    });
  }

  void _dispatchFallbackQueueChange() {
    if (isClosed) return;
    add(QueueDataChanged(
      fallbackQueue: _lastQueue,
      fallbackCurrentItem: _lastMediaItem,
    ));
  }

  void _onPlaybackStatusChanged(
    PlaybackStatusChanged event,
    Emitter<QueueState> emit,
  ) {
    if (state is! QueueActive) return;

    final activeState = state as QueueActive;
    if (activeState.isPlaying == event.isPlaying &&
        activeState.shuffleMode == event.shuffleMode &&
        activeState.repeatMode == event.repeatMode) {
      return;
    }

    emit(activeState.copyWith(
      isPlaying: event.isPlaying,
      shuffleMode: event.shuffleMode,
      repeatMode: event.repeatMode,
    ));
  }

  void _onDataChanged(QueueDataChanged event, Emitter<QueueState> emit) {
    // 1. Resolve from native SequenceState if available
    final sequenceState = event.sequenceState;
    if (sequenceState != null) {
      _processSequenceState(sequenceState, emit);
      return;
    }

    // 2. Resolve from fallback queue and media item streams
    final queue = event.fallbackQueue ?? _lastQueue;
    final current = event.fallbackCurrentItem ?? _lastMediaItem;

    if (queue.isEmpty || current == null) {
      if (state is! QueueInitial) {
        emit(const QueueInitial());
      }
      return;
    }

    final currentIndex = _resolveCurrentIndex(queue, current);
    final activeMedia = current;
    final upcomingStart = currentIndex >= 0 ? currentIndex + 1 : 0;
    final upcomingItems = upcomingStart < queue.length
        ? queue.sublist(upcomingStart)
        : const <MediaItem>[];

    final currentTrack = ContextTrack.fromMediaItem(
      activeMedia,
      uid: activeMedia.extras?['uid']?.toString() ?? 'now_${activeMedia.id}',
    );

    _emitResolvedQueue(
      currentTrack: currentTrack,
      upcomingMediaItems: upcomingItems,
      currentIndex: currentIndex >= 0 ? currentIndex : 0,
      totalTracks: queue.length,
      shuffleMode: _lastShuffleMode,
      repeatMode: _lastRepeatMode,
      emit: emit,
    );
  }

  void _processSequenceState(SequenceState seqState, Emitter<QueueState> emit) {
    final effectiveSeq = seqState.effectiveSequence;
    final currentSource = seqState.currentSource;

    if (effectiveSeq.isEmpty || currentSource == null) {
      if (state is! QueueInitial) {
        emit(const QueueInitial());
      }
      return;
    }

    final activeMedia = currentSource.tag as MediaItem;
    final activeEffectiveIndex = effectiveSeq.indexOf(currentSource);
    final currentIndex = activeEffectiveIndex >= 0 ? activeEffectiveIndex : 0;

    final upcomingSources = currentIndex + 1 < effectiveSeq.length
        ? effectiveSeq.sublist(currentIndex + 1)
        : const <IndexedAudioSource>[];

    final upcomingMediaItems = upcomingSources
        .map((source) => source.tag as MediaItem)
        .toList(growable: false);

    final currentTrack = ContextTrack.fromMediaItem(
      activeMedia,
      uid: activeMedia.extras?['uid']?.toString() ?? 'now_${activeMedia.id}',
    );

    final shuffleMode = seqState.shuffleModeEnabled
        ? AudioServiceShuffleMode.all
        : AudioServiceShuffleMode.none;
    final repeatMode = switch (seqState.loopMode) {
      LoopMode.one => AudioServiceRepeatMode.one,
      LoopMode.all => AudioServiceRepeatMode.all,
      LoopMode.off => AudioServiceRepeatMode.none,
    };

    // Playback-driven Cosmos pagination:
    // If 3 or fewer context tracks remain ahead of currentIndex, auto-fetch and append next page.
    final remainingContextTracks = upcomingMediaItems.where((item) {
      final uid = item.extras?['uid']?.toString() ?? item.id;
      final isQueued = _userQueuedUids.contains(uid) ||
          item.extras?['is_queued'] == true ||
          item.extras?['is_queued'] == 'true';
      return !isQueued;
    }).length;

    if (remainingContextTracks <= 3) {
      _checkAndTriggerNextPage(upcomingMediaItems, activeMedia);
    }

    _emitResolvedQueue(
      currentTrack: currentTrack,
      upcomingMediaItems: upcomingMediaItems,
      currentIndex: currentIndex,
      totalTracks: effectiveSeq.length,
      shuffleMode: shuffleMode,
      repeatMode: repeatMode,
      emit: emit,
    );
  }

  void _checkAndTriggerNextPage(List<MediaItem> upcomingMediaItems, MediaItem activeMedia) {
    if (isClosed) return;

    final lastContextItem = upcomingMediaItems.lastWhere(
      (item) {
        final uid = item.extras?['uid']?.toString() ?? item.id;
        return !_userQueuedUids.contains(uid) &&
            item.extras?['is_queued'] != true &&
            item.extras?['is_queued'] != 'true';
      },
      orElse: () => activeMedia,
    );

    final nextPageUrl = lastContextItem.extras?['next_page_url']?.toString();
    if (nextPageUrl == null || nextPageUrl.isEmpty) return;
    if (_loadedPageUrls.contains(nextPageUrl) || _loadingPageUrl == nextPageUrl) return;

    add(const QueueNextPageRequested());
  }

  void _emitResolvedQueue({
    required ContextTrack currentTrack,
    required List<MediaItem> upcomingMediaItems,
    required int currentIndex,
    required int totalTracks,
    required AudioServiceShuffleMode shuffleMode,
    required AudioServiceRepeatMode repeatMode,
    required Emitter<QueueState> emit,
  }) {
    if (state is QueueActive) {
      final active = state as QueueActive;
      final existingContextUrl = active.currentTrack.metadata['context_url'];
      final incomingContextUrl = currentTrack.metadata['context_url'];
      if (existingContextUrl != null &&
          incomingContextUrl != null &&
          existingContextUrl != incomingContextUrl) {
        _loadedPageUrls.clear();
        _loadingPageUrl = null;
      }
    }

    final existingTracks = (state is QueueActive)
        ? (state as QueueActive).queue.nextTracks
        : const <ContextTrack>[];

    // 1. Reconcile local slots with incoming engine slots using QueueReconciler
    final localSlots = existingTracks.map((t) => LocalSlot(
      uri: t.uri,
      clusterUid: t.uid,
      clusterGoverned: !t.isQueued,
      awaitingEcho: t.isQueued && _userQueuedUids.contains(t.uid),
    )).toList(growable: false);

    final clusterSlots = upcomingMediaItems.map((item) {
      final uid = item.extras?['uid']?.toString() ?? item.id;
      final isQueued = _userQueuedUids.contains(uid) ||
          item.extras?['is_queued'] == true ||
          item.extras?['is_queued'] == 'true';
      return ClusterSlot(
        uri: item.id,
        uid: uid,
        isQueued: isQueued,
      );
    }).toList(growable: false);

    final reconcileResult = QueueReconciler.reconcile(
      local: localSlots,
      cluster: clusterSlots,
    );

    // Build candidate target tracks from the reconcile result
    final candidateTargetTracks = <ContextTrack>[];
    for (final slot in reconcileResult.target) {
      switch (slot) {
        case TargetSlotKeep(:final localIndex, :final adoptUid):
          final existing = existingTracks[localIndex];
          candidateTargetTracks.add(
            adoptUid != null ? existing.copyWith(uid: adoptUid) : existing,
          );
        case TargetSlotNew(:final clusterIndex):
          final item = upcomingMediaItems[clusterIndex];
          final itemUid = item.extras?['uid']?.toString() ?? item.id;
          final isQueued = _userQueuedUids.contains(itemUid) ||
              item.extras?['is_queued'] == true ||
              item.extras?['is_queued'] == 'true';
          candidateTargetTracks.add(ContextTrack.fromMediaItem(
            item,
            uid: itemUid,
            isQueued: isQueued,
          ));
      }
    }

    // 2. Compute minimal edits between existingTracks and candidateTargetTracks via QueueDiffer
    final currentKeys = QueueDiffer.computeKeys(
      existingTracks.map((t) => KeySource(uri: t.uri, uid: t.uid)).toList(growable: false),
    );

    final targetKeys = QueueDiffer.computeKeys(
      candidateTargetTracks.map((t) => KeySource(uri: t.uri, uid: t.uid)).toList(growable: false),
    );

    final edits = QueueDiffer.diff(currentKeys, targetKeys);

    // Fast path: if incoming items exactly match existing nextTracks,
    // preserve existing state and revision to prevent ReorderableListView churn.
    if (state is QueueActive) {
      final active = state as QueueActive;
      if (active.currentTrack.uri == currentTrack.uri && edits.isEmpty) {
        final preservedQueue = active.queue.copyWith(
          track: currentTrack.copyWith(uid: active.currentTrack.uid),
        );
        emit(active.copyWith(
          queue: preservedQueue,
          currentTrack: preservedQueue.track ?? currentTrack,
          currentIndex: currentIndex,
          totalTracks: totalTracks,
          isPlaying: _lastIsPlaying,
          shuffleMode: shuffleMode,
          repeatMode: repeatMode,
          edits: const [],
        ));
        return;
      }
    }

    // Determine newly inserted UIDs from edits for animations
    String? newlyAddedUid;
    for (final edit in edits) {
      if (edit is QueueEditInsert) {
        if (edit.targetIndex < candidateTargetTracks.length) {
          newlyAddedUid ??= candidateTargetTracks[edit.targetIndex].uid;
        }
      }
    }

    _revisionCounter++;
    final playerQueue = PlayerQueue(
      revision: '$_revisionCounter',
      track: currentTrack,
      nextTracks: candidateTargetTracks,
    );

    emit(QueueActive(
      queue: playerQueue,
      currentTrack: currentTrack,
      currentIndex: currentIndex,
      totalTracks: totalTracks,
      isPlaying: _lastIsPlaying,
      shuffleMode: shuffleMode,
      repeatMode: repeatMode,
      lastAddedUid: newlyAddedUid,
      edits: edits,
    ));
  }

  int _resolveCurrentIndex(List<MediaItem> queue, MediaItem current) {
    final knownIdx = _lastQueueIndex;
    if (knownIdx != null &&
        knownIdx >= 0 &&
        knownIdx < queue.length &&
        queue[knownIdx].id == current.id) {
      return knownIdx;
    }
    if (state is QueueActive) {
      final stateIdx = (state as QueueActive).currentIndex;
      if (stateIdx >= 0 &&
          stateIdx < queue.length &&
          queue[stateIdx].id == current.id) {
        return stateIdx;
      }
    }
    final index = queue.indexWhere((item) => item.id == current.id);
    return index >= 0 ? index : 0;
  }

  Future<void> _onTrackTapped(
    QueueTrackTapped event,
    Emitter<QueueState> emit,
  ) async {
    try {
      final currentQueue = state.queue;
      final nextTracks = currentQueue.nextTracks;
      final tapIdx = nextTracks.indexWhere((t) => t.uid == event.track.uid);

      if (tapIdx == -1) {
        final liveIndex = _lastQueue.indexWhere((m) => m.id == event.track.uri);
        final resolvedIndex = liveIndex != -1 ? liveIndex : event.absoluteIndex;
        await _playbackController.skipToQueueItem(resolvedIndex);
        await _playbackController.play();
        return;
      }

      final userQueueCount = QueueFilterHelper.getUserQueue(currentQueue).length;
      final safeCurrentIndex =
          state is QueueActive ? (state as QueueActive).currentIndex : (_lastQueueIndex ?? 0);
      final baseOffset = safeCurrentIndex + 1;
      final nextCurrentTrack =
          event.track.copyWith(isQueued: false, provider: 'context');

      _lastMediaItem = nextCurrentTrack.toMediaItem();

      if (tapIdx < userQueueCount || userQueueCount == 0) {
        // Tapped a track inside userQueue (or no user queue exists)
        if (userQueueCount > 0) {
          final removeCount = tapIdx < userQueueCount ? tapIdx + 1 : userQueueCount;
          for (var i = 0; i < removeCount; i++) {
            _userQueuedUids.remove(nextTracks[i].uid);
          }
        }

        final remainingUserQueue = userQueueCount > 0
            ? QueueFilterHelper.getUserQueue(currentQueue).sublist(tapIdx + 1)
            : const <ContextTrack>[];
        final contextTracks = QueueFilterHelper.getContextQueue(currentQueue);
        final remainingContextTracks = userQueueCount == 0
            ? (tapIdx + 1 < contextTracks.length
                ? contextTracks.sublist(tapIdx + 1)
                : const <ContextTrack>[])
            : contextTracks;
        final targetAbsoluteIndex = baseOffset + tapIdx;

        _lastQueueIndex = targetAbsoluteIndex;
        _revisionCounter++;
        final updatedQueue = currentQueue.copyWith(
          track: nextCurrentTrack,
          nextTracks: [...remainingUserQueue, ...remainingContextTracks],
          revision: '$_revisionCounter',
        );

        emit(QueueActive(
          queue: updatedQueue,
          currentTrack: nextCurrentTrack,
          currentIndex: targetAbsoluteIndex,
          totalTracks: state.totalTracks,
          isPlaying: true,
          shuffleMode: state.shuffleMode,
          repeatMode: state.repeatMode,
        ));

        await _playbackController.skipToQueueItem(targetAbsoluteIndex);
        await _playbackController.play();
      } else {
        // Tapped a context track below preserved userQueue
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
        final updatedQueue = currentQueue.copyWith(
          track: nextCurrentTrack,
          nextTracks: newUpcomingTracks,
          revision: '$_revisionCounter',
        );

        emit(QueueActive(
          queue: updatedQueue,
          currentTrack: nextCurrentTrack,
          currentIndex: targetAbsoluteIndex,
          totalTracks: 1 + upcomingMediaItems.length,
          isPlaying: true,
          shuffleMode: state.shuffleMode,
          repeatMode: state.repeatMode,
        ));

        await _playbackController.setNextTracks([
          nextActiveMedia,
          ...upcomingMediaItems,
        ]);
        await _playbackController.skipToQueueItem(targetAbsoluteIndex);
        await _playbackController.play();
      }
    } catch (error, stackTrace) {
      emit(QueueError(
        message: 'Failed to switch track: $error',
        error: error,
        stackTrace: stackTrace,
      ));
    }
  }

  Future<void> _onReordered(
    QueueReordered event,
    Emitter<QueueState> emit,
  ) async {
    try {
      final oldIdx = event.oldIndex;
      final targetIdx = event.newIndex;
      if (oldIdx == targetIdx) return;

      final currentQueue = state.queue;
      final visibleTracks =
          QueueFilterHelper.getVisibleUpcomingTracks(currentQueue);

      if (oldIdx < 0 || oldIdx >= visibleTracks.length) {
        throw RangeError.range(oldIdx, 0, visibleTracks.length - 1, 'oldIndex');
      }
      if (targetIdx < 0 || targetIdx >= visibleTracks.length) {
        throw RangeError.range(targetIdx, 0, visibleTracks.length - 1, 'newIndex');
      }

      final draggedTrack = visibleTracks[oldIdx];
      final userQueueCount =
          QueueFilterHelper.getUserQueue(currentQueue).length;
      final isDroppedIntoUserQueue =
          userQueueCount > 0 && targetIdx < userQueueCount;

      _revisionCounter++;
      final newPlayerQueue = QueueMutator.reorderTrack(
        currentQueue,
        draggedTrack: draggedTrack,
        targetVisibleIndex: targetIdx,
        isTargetInUserQueue: isDroppedIntoUserQueue,
      ).copyWith(revision: '$_revisionCounter');

      if (isDroppedIntoUserQueue) {
        _userQueuedUids.add(draggedTrack.uid);
      } else {
        _userQueuedUids.remove(draggedTrack.uid);
      }

      emit(state.copyWith(queue: newPlayerQueue));

      final upcomingMediaItems = newPlayerQueue.nextTracks
          .map((t) => t.toMediaItem())
          .toList(growable: false);

      _lastQueue = [
        if (state.nowPlaying != null) state.nowPlaying!.toMediaItem(),
        ...upcomingMediaItems,
      ];

      await _playbackController.setNextTracks(upcomingMediaItems);
    } catch (error, stackTrace) {
      emit(QueueError(
        message: 'Failed to reorder track: $error',
        error: error,
        stackTrace: stackTrace,
      ));
    }
  }

  Future<void> _onTrackRemoved(
    QueueTrackRemoved event,
    Emitter<QueueState> emit,
  ) async {
    try {
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

        await _playbackController.setNextTracks(upcomingMediaItems);
      }
    } catch (error, stackTrace) {
      emit(QueueError(
        message: 'Failed to remove track: $error',
        error: error,
        stackTrace: stackTrace,
      ));
    }
  }

  Future<void> _onTrackAdded(
    QueueTrackAdded event,
    Emitter<QueueState> emit,
  ) async {
    try {
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

      await _playbackController.setNextTracks(upcomingMediaItems);
    } catch (error, stackTrace) {
      emit(QueueError(
        message: 'Failed to add track to queue: $error',
        error: error,
        stackTrace: stackTrace,
      ));
    }
  }

  Future<void> _onCleared(
    QueueCleared event,
    Emitter<QueueState> emit,
  ) async {
    try {
      _userQueuedUids.clear();
      final currentQueue = state.queue;
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

      await _playbackController.setNextTracks(upcomingMediaItems);
    } catch (error, stackTrace) {
      emit(QueueError(
        message: 'Failed to clear queue: $error',
        error: error,
        stackTrace: stackTrace,
      ));
    }
  }

  Future<void> _onShuffleToggled(
    QueueShuffleToggled event,
    Emitter<QueueState> emit,
  ) async {
    try {
      final currentMode = state.shuffleMode;
      final nextMode = currentMode == AudioServiceShuffleMode.all
          ? AudioServiceShuffleMode.none
          : AudioServiceShuffleMode.all;

      await _playbackController.setShuffleMode(nextMode);
    } catch (error, stackTrace) {
      emit(QueueError(
        message: 'Failed to toggle shuffle: $error',
        error: error,
        stackTrace: stackTrace,
      ));
    }
  }

  Future<void> _onRepeatToggled(
    QueueRepeatToggled event,
    Emitter<QueueState> emit,
  ) async {
    try {
      final currentMode = state.repeatMode;
      final nextMode = switch (currentMode) {
        AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
        AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
        AudioServiceRepeatMode.one => AudioServiceRepeatMode.none,
        _ => AudioServiceRepeatMode.none,
      };

      await _playbackController.setRepeatMode(nextMode);
    } catch (error, stackTrace) {
      emit(QueueError(
        message: 'Failed to toggle repeat: $error',
        error: error,
        stackTrace: stackTrace,
      ));
    }
  }

  Future<void> _onPlayPauseToggled(
    QueuePlayPauseToggled event,
    Emitter<QueueState> emit,
  ) async {
    try {
      if (state.isPlaying) {
        await _playbackController.pause();
      } else {
        await _playbackController.play();
      }
    } catch (error, stackTrace) {
      emit(QueueError(
        message: 'Failed to toggle playback: $error',
        error: error,
        stackTrace: stackTrace,
      ));
    }
  }

  Future<void> _onNextPageRequested(
    QueueNextPageRequested event,
    Emitter<QueueState> emit,
  ) async {
    try {
      final lastContextTrack = state.queue.contextTracks.lastOrNull;
      final nextPageUrl = lastContextTrack?.metadata['next_page_url'];
      if (nextPageUrl == null || nextPageUrl.isEmpty) return;
      if (_loadedPageUrls.contains(nextPageUrl)) return;

      _loadingPageUrl = nextPageUrl;
      final page = LocalContextResolver.resolvePage(nextPageUrl);
      if (page == null) {
        _loadingPageUrl = null;
        return;
      }

      _loadedPageUrls.add(nextPageUrl);
      _loadingPageUrl = null;

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

      await _playbackController.setNextTracks(upcomingMediaItems);
    } catch (error, stackTrace) {
      _loadingPageUrl = null;
      emit(QueueError(
        message: 'Failed to load next page: $error',
        error: error,
        stackTrace: stackTrace,
      ));
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _sequenceSub?.cancel();
    _sequenceSub = null;
    await _playerStateSub?.cancel();
    _playerStateSub = null;
    await _queueSub?.cancel();
    _queueSub = null;
    await _mediaItemSub?.cancel();
    _mediaItemSub = null;
    await _playbackStateSub?.cancel();
    _playbackStateSub = null;
  }

  @override
  Future<void> close() async {
    await _cancelSubscriptions();
    return super.close();
  }
}
