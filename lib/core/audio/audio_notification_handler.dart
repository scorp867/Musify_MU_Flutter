import 'dart:async';
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
  final Map<String, Uri> _cachedArtUris = {};
  String? _pendingQueueItemId;
  late final StreamSubscription _playbackSub;

  AudioNotificationHandler(this._playbackService, this._audioQuery) {
    _playbackSub = _playbackService.playbackEventStream.listen(_publishPlaybackState);
    _playbackService.onQueueChanged = (tracks) {
      for (final item in tracks) {
        _addLatestMediaItem(item);
      }
      queue.add(tracks);
    };
  }

  void _addLatestMediaItem(MediaItem item) {
    if (_latestMediaItems.length > 500) {
      final keysToRemove = _latestMediaItems.keys.take(_latestMediaItems.length - 400).toList();
      keysToRemove.forEach(_latestMediaItems.remove);
    }
    _latestMediaItems[item.id] = item;
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

    _addLatestMediaItem(item);

    if (item.id != mediaItem.value?.id) {
      final cachedArtUri = _cachedArtUris[item.id];
      final initialItem = cachedArtUri != null && item.artUri != cachedArtUri
          ? item.copyWith(artUri: cachedArtUri)
          : item;
      _addLatestMediaItem(initialItem);
      mediaItem.add(initialItem);

      if (cachedArtUri == null) {
        _fetchAndCacheArtwork(initialItem).then((updatedItem) {
          if (mediaItem.value?.id == updatedItem.id &&
              mediaItem.value?.artUri != updatedItem.artUri) {
            _addLatestMediaItem(updatedItem);
            mediaItem.add(updatedItem);
          }
        });
      }
    }
  }

  Future<void> playTrack(MediaItem item, String uri) async {
    _pendingQueueItemId = null;
    item = await _fetchAndCacheArtwork(item);
    _addLatestMediaItem(item);
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
        _addLatestMediaItem(item);
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

    _cachedArtUris.remove(item.id);
    final updatedItem =
        await _fetchAndCacheArtwork(item, bumpArtworkVersion: true);
    _addLatestMediaItem(updatedItem);
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

  Future<MediaItem> _fetchAndCacheArtwork(
    MediaItem item, {
    bool bumpArtworkVersion = false,
  }) {
    final requestKey =
        '${item.id}:${item.extras?[MediaItemMapper.dateModifiedKey]}:$bumpArtworkVersion';
    final inFlightRequest = _artworkRequests[requestKey];
    if (inFlightRequest != null) return inFlightRequest;

    final request =
        _loadAndCacheArtwork(item, bumpArtworkVersion: bumpArtworkVersion);
    _artworkRequests[requestKey] = request;
    request.whenComplete(() {
      if (identical(_artworkRequests[requestKey], request)) {
        _artworkRequests.remove(requestKey);
      }
    });
    return request;
  }

  Future<MediaItem> _loadAndCacheArtwork(
    MediaItem item, {
    required bool bumpArtworkVersion,
  }) async {
    try {
      if (!bumpArtworkVersion) {
        final existingUri = _cachedArtUris[item.id];
        if (existingUri != null) {
          return item.artUri == existingUri
              ? item
              : item.copyWith(artUri: existingUri);
        }
      }

      final songId = MediaItemMapper.songId(item);
      if (songId == null) return item;

      final bytes = await _audioQuery.queryArtwork(
        songId,
        ArtworkType.AUDIO,
        size: 400,
      );

      final Map<String, dynamic>? extras = bumpArtworkVersion
          ? <String, dynamic>{
              ...?item.extras,
              MediaItemMapper.artworkVersionKey:
                  DateTime.now().millisecondsSinceEpoch,
            }
          : item.extras;

      if (bytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/art_${item.id}.jpg');
        await file.writeAsBytes(bytes);
        final fileUri = Uri.file(file.path);
        _cachedArtUris[item.id] = fileUri;
        return item.copyWith(artUri: fileUri, extras: extras);
      }

      return bumpArtworkVersion ? item.copyWith(extras: extras) : item;
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
  Future<void> setNextTracks(List<MediaItem> upcomingTracks) async {
    await _playbackService.setNextTracks(upcomingTracks);
    queue.add(_playbackService.fullTracks);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    await _playbackService.removeTrack(index);
    queue.add(_playbackService.fullTracks);
  }

  @override
  Future<void> removeQueueRange(int startIndex, int endIndex) async {
    await _playbackService.removeTrackRange(startIndex, endIndex);
    queue.add(_playbackService.fullTracks);
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    await _playbackService.insertTrack(index, mediaItem);
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

  Future<void> dispose() async {
    await _playbackSub.cancel();
  }
}
