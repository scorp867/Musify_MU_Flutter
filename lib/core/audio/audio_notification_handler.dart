import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_playback_service.dart';
import 'playback_controller.dart';

class AudioNotificationHandler extends BaseAudioHandler
    with SeekHandler
    implements PlaybackController {
  final AudioPlaybackService _playbackService;
  final OnAudioQuery _audioQuery;
  final Map<String, MediaItem> _latestMediaItems = {};
  final Map<String, Future<MediaItem>> _artworkRequests = {};
  String? _pendingQueueItemId;

  AudioNotificationHandler(this._playbackService, this._audioQuery) {
    _playbackService.playbackEventStream.listen(_publishPlaybackState);
  }

  void _publishPlaybackState(PlaybackEvent event) {
    final player = _playbackService.player;
    final playing = player.playing;

    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[player.processingState]!,
        playing: playing,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
        queueIndex: event.currentIndex != null
            ? _playbackService.windowToAbsoluteIndex(event.currentIndex!)
            : null,
      ),
    );

    final currentIndex = event.currentIndex;
    if (currentIndex == null || currentIndex >= player.sequence.length) {
      return;
    }

    final taggedItem = player.sequence[currentIndex].tag as MediaItem?;
    if (taggedItem == null) return;

    final item = _latestMediaItems[taggedItem.id] ?? taggedItem;
    final pendingQueueItemId = _pendingQueueItemId;
    if (pendingQueueItemId != null) {
      if (item.id != pendingQueueItemId) return;
      _pendingQueueItemId = null;
    }

    _latestMediaItems[item.id] = item;

    if (item.id != mediaItem.value?.id) {
      mediaItem.add(item);
      _fetchAndCacheArtwork(item).then((updatedItem) {
        if (mediaItem.value?.id == updatedItem.id) {
          _latestMediaItems[updatedItem.id] = updatedItem;
          mediaItem.add(updatedItem);
        }
      });
    }
  }

  Future<void> playTrack(MediaItem item, String uri) async {
    _pendingQueueItemId = null;
    item = await _fetchAndCacheArtwork(item);
    _latestMediaItems[item.id] = item;
    mediaItem.add(item);

    await _playbackService.setAudioSource(uri);
    await _playbackService.play();
  }

  @override
  Future<void> playQueue(List<MediaItem> tracks, int initialIndex) async {
    if (tracks.isEmpty || initialIndex < 0 || initialIndex >= tracks.length) {
      return;
    }

    final queueItems = List<MediaItem>.of(tracks);
    final requestedItemId = queueItems[initialIndex].id;
    _pendingQueueItemId = requestedItemId;

    try {
      var currentItem = await _fetchAndCacheArtwork(queueItems[initialIndex]);
      queueItems[initialIndex] = currentItem;

      for (final item in queueItems) {
        _latestMediaItems[item.id] = item;
      }

      mediaItem.add(currentItem);
      queue.add(queueItems);

      await _playbackService.setQueue(queueItems, initialIndex);
      await _playbackService.play();
    } finally {
      if (_pendingQueueItemId == requestedItemId) {
        _pendingQueueItemId = null;
      }
    }
  }

  @override
  Future<void> updateCurrentMediaItem(MediaItem item) async {
    final currentItem = currentMediaItem;
    if (currentItem == null || currentItem.id != item.id) return;

    final updatedItem = await _fetchAndCacheArtwork(item);
    _latestMediaItems[updatedItem.id] = updatedItem;
    mediaItem.add(updatedItem);

    final currentQueue = queue.value;
    final queueIndex = currentQueue.indexWhere(
      (queued) => queued.id == item.id,
    );
    if (queueIndex == -1) return;

    final updatedQueue = List<MediaItem>.of(currentQueue);
    updatedQueue[queueIndex] = updatedItem;
    queue.add(updatedQueue);
  }

  @override
  Future<void> refreshArtwork() async {
    final currentItem = currentMediaItem;
    if (currentItem == null) return;
    await updateCurrentMediaItem(currentItem);
  }

  Future<MediaItem> _fetchAndCacheArtwork(MediaItem item) {
    final requestKey =
        '${item.id}:${item.extras?[MediaItemMapper.dateModifiedKey]}';
    final inFlightRequest = _artworkRequests[requestKey];
    if (inFlightRequest != null) return inFlightRequest;

    final request = _loadAndCacheArtwork(item);
    _artworkRequests[requestKey] = request;
    request.whenComplete(() {
      if (identical(_artworkRequests[requestKey], request)) {
        _artworkRequests.remove(requestKey);
      }
    });
    return request;
  }

  Future<MediaItem> _loadAndCacheArtwork(MediaItem item) async {
    try {
      final songId = MediaItemMapper.songId(item);
      if (songId == null) return item;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final bytes = await _audioQuery.queryArtwork(
        songId,
        ArtworkType.AUDIO,
        size: 400,
      );
      final extras = <String, dynamic>{
        ...?item.extras,
        MediaItemMapper.artworkVersionKey: timestamp,
      };

      if (bytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/art_${item.id}_$timestamp.jpg');
        await file.writeAsBytes(bytes);
        return item.copyWith(artUri: Uri.file(file.path), extras: extras);
      }

      return item.copyWith(extras: extras);
    } catch (_) {
      // Metadata updates must not interrupt playback when artwork is unavailable.
    }
    return item;
  }

  @override
  MediaItem? get currentMediaItem => mediaItem.valueOrNull;

  @override
  int get audioWindowEndIndex => _playbackService.windowEndIndex;

  @override
  Future<void> reorderQueueItem(int fromIndex, int toIndex) async {
    await _playbackService.reorderTrack(fromIndex, toIndex);
    queue.add(_playbackService.fullTracks);
  }

  @override
  Future<void> play() => _playbackService.play();

  @override
  Future<void> pause() => _playbackService.pause();

  @override
  Future<void> seek(Duration position) => _playbackService.seek(position);

  @override
  Future<void> skipToNext() => _playbackService.seekToNext();

  @override
  Future<void> skipToPrevious() => _playbackService.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) =>
      _playbackService.seekToAbsoluteIndex(index);

  @override
  Future<void> stop() async {
    await _playbackService.stop();
    return super.stop();
  }
}
