import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';

import 'queue_event.dart';
import 'queue_state.dart';

class _QueueDataChanged extends QueueEvent {
  final List<MediaItem> queue;
  final MediaItem? currentItem;
  final int windowEnd;

  const _QueueDataChanged(this.queue, this.currentItem, this.windowEnd);

  @override
  List<Object?> get props => [queue.length, currentItem?.id, windowEnd];
}

class QueueBloc extends Bloc<QueueEvent, QueueState> {
  final PlaybackController _playbackController;
  StreamSubscription<List<MediaItem>>? _queueSub;
  StreamSubscription<MediaItem?>? _mediaItemSub;
  StreamSubscription<PlaybackState>? _playbackStateSub;

  List<MediaItem> _lastQueue = const [];
  MediaItem? _lastMediaItem;

  QueueBloc({required PlaybackController playbackController})
      : _playbackController = playbackController,
        super(const QueueState()) {
    on<QueueStarted>(_onStarted);
    on<QueueTrackTapped>(_onTrackTapped);
    on<QueueReordered>(_onReordered);
    on<_QueueDataChanged>(_onDataChanged);
  }

  Future<void> _onStarted(QueueStarted event, Emitter<QueueState> emit) async {
    await _queueSub?.cancel();
    await _mediaItemSub?.cancel();
    await _playbackStateSub?.cancel();

    _queueSub = _playbackController.queue.listen((queue) {
      _lastQueue = queue;
      _emitChange();
    });
    _mediaItemSub = _playbackController.mediaItem.listen((item) {
      _lastMediaItem = item;
      _emitChange();
    });
    // Subscribe to playbackState to reactively pick up window changes.
    // When onIndexChanged expands the window, it triggers a playback event
    // which fires this stream — ensuring we re-read windowEndIndex.
    _playbackStateSub = _playbackController.playbackState.listen((_) {
      _emitChange();
    });
  }

  void _emitChange() {
    add(_QueueDataChanged(
      _lastQueue,
      _lastMediaItem,
      _playbackController.audioWindowEndIndex,
    ));
  }

  void _onTrackTapped(QueueTrackTapped event, Emitter<QueueState> emit) {
    _playbackController.skipToQueueItem(event.absoluteIndex);
  }

  void _onReordered(QueueReordered event, Emitter<QueueState> emit) {
    _playbackController.reorderQueueItem(event.oldIndex, event.newIndex);
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
      emit(QueueState(nowPlaying: current, totalTracks: queue.length));
      return;
    }

    final windowEnd = event.windowEnd;
    final upcomingStart = currentIndex + 1;
    final upcomingCap = windowEnd > 0 ? windowEnd : queue.length;
    final upcomingEnd = upcomingCap.clamp(0, queue.length);
    final upcoming = upcomingStart < upcomingEnd
        ? queue.sublist(upcomingStart, upcomingEnd)
        : const <MediaItem>[];

    emit(QueueState(
      nowPlaying: current,
      upcomingTracks: upcoming,
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
