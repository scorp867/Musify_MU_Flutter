import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_playback_service.dart';
import 'playback_controller.dart';

/// Bridges [AudioPlaybackService] with the system notification and lockscreen via [BaseAudioHandler].
///
/// Drives [playbackState], [mediaItem], and [queue] deterministically from native
/// [SequenceState] and [PlayerState] streams without dual-state drift or reactionary resyncs.
class AudioNotificationHandler extends BaseAudioHandler
    with SeekHandler
    implements PlaybackController {
  final AudioPlaybackService _playbackService;
  final OnAudioQuery _audioQuery;
  final Map<String, MediaItem> _latestMediaItems = {};
  final Map<String, Future<MediaItem>> _artworkRequests = {};
  final Map<String, Uri> _cachedArtUris = {};

  late final StreamSubscription<SequenceState?> _sequenceSub;
  late final StreamSubscription<PlayerState> _playerStateSub;

  int? _pendingInitialIndex;

  AudioNotificationHandler(this._playbackService, this._audioQuery) {
    _sequenceSub = _playbackService.sequenceStateStream.listen(_onSequenceStateChanged);
    _playerStateSub = _playbackService.playerStateStream.listen(_onPlayerStateChanged);
  }

  void _addLatestMediaItem(MediaItem item) {
    if (_latestMediaItems.length > 500) {
      final keysToRemove = _latestMediaItems.keys.take(_latestMediaItems.length - 400).toList();
      for (final key in keysToRemove) {
        _latestMediaItems.remove(key);
      }
    }
    _latestMediaItems[item.id] = item;
  }

  void _onSequenceStateChanged(SequenceState? sequenceState) {
    if (sequenceState == null || sequenceState.sequence.isEmpty) {
      _pendingInitialIndex = null;
      mediaItem.add(null);
      queue.add(const []);
      _publishPlaybackState();
      return;
    }

    final effectiveTracks = sequenceState.effectiveSequence
        .map((source) => source.tag as MediaItem)
        .toList(growable: false);
    queue.add(effectiveTracks);

    // If an initial seek is pending (cold start), ignore transient events until
    // currentIndex reaches the target initialIndex to prevent flashing track 0.
    if (_pendingInitialIndex != null) {
      if (sequenceState.currentIndex == _pendingInitialIndex) {
        _pendingInitialIndex = null;
      } else {
        return;
      }
    }

    final currentSource = sequenceState.currentSource;
    if (currentSource != null) {
      final taggedItem = currentSource.tag as MediaItem;
      final item = _latestMediaItems[taggedItem.id] ?? taggedItem;
      _addLatestMediaItem(item);

      if (item.id != mediaItem.valueOrNull?.id) {
        final cachedArtUri = _cachedArtUris[item.id];
        final initialItem = cachedArtUri != null && item.artUri != cachedArtUri
            ? item.copyWith(artUri: cachedArtUri)
            : item;
        _addLatestMediaItem(initialItem);
        mediaItem.add(initialItem);

        if (cachedArtUri == null) {
          _fetchAndCacheArtwork(initialItem).then((updatedItem) {
            if (mediaItem.valueOrNull?.id == updatedItem.id &&
                mediaItem.valueOrNull?.artUri != updatedItem.artUri) {
              _addLatestMediaItem(updatedItem);
              mediaItem.add(updatedItem);
            }
          });
        }
      }
    } else {
      mediaItem.add(null);
    }

    _publishPlaybackState();
  }

  void _onPlayerStateChanged(PlayerState _) {
    _publishPlaybackState();
  }

  void _publishPlaybackState({int? overrideQueueIndex}) {
    final player = _playbackService.player;
    final sequenceState = player.sequenceState;
    final playing = player.playing;
    final queueIndex = overrideQueueIndex ?? sequenceState.currentIndex;

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
        processingState: switch (player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: playing,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
        queueIndex: queueIndex,
        shuffleMode: player.shuffleModeEnabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        repeatMode: switch (player.loopMode) {
          LoopMode.one => AudioServiceRepeatMode.one,
          LoopMode.all => AudioServiceRepeatMode.all,
          LoopMode.off => AudioServiceRepeatMode.none,
        },
      ),
    );
  }

  Future<void> playTrack(MediaItem item, String uri) async {
    item = await _fetchAndCacheArtwork(item);
    _addLatestMediaItem(item);
    mediaItem.add(item);

    await _playbackService.setAudioSource(uri);
    await _playbackService.play();
  }

  @override
  Future<void> playQueue(List<MediaItem> tracks, int initialIndex) async {
    if (tracks.isEmpty) {
      throw ArgumentError('Queue tracks cannot be empty.');
    }
    if (initialIndex < 0 || initialIndex >= tracks.length) {
      throw RangeError.range(initialIndex, 0, tracks.length - 1, 'initialIndex');
    }

    for (final item in tracks) {
      _addLatestMediaItem(item);
    }

    _pendingInitialIndex = initialIndex;

    // Immediately publish the target item and playback state so UI never flashes track 0
    final targetItem = _latestMediaItems[tracks[initialIndex].id] ?? tracks[initialIndex];
    mediaItem.add(targetItem);
    _publishPlaybackState(overrideQueueIndex: initialIndex);

    await _playbackService.setQueue(tracks, initialIndex);
    await _playbackService.play();
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
    final item = currentMediaItem;
    if (item == null) return;
    _cachedArtUris.remove(item.id);
    final updatedItem =
        await _fetchAndCacheArtwork(item, bumpArtworkVersion: true);
    _addLatestMediaItem(updatedItem);
    mediaItem.add(updatedItem);
  }

  Future<MediaItem> _fetchAndCacheArtwork(
    MediaItem item, {
    bool bumpArtworkVersion = false,
  }) {
    final requestKey =
        '${item.id}_${bumpArtworkVersion ? "bump" : "nobump"}';
    final existingRequest = _artworkRequests[requestKey];
    if (existingRequest != null) return existingRequest;

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
      // Artwork caching failure does not interrupt playback.
    }
    return item;
  }

  @override
  MediaItem? get currentMediaItem => mediaItem.valueOrNull;

  @override
  int get audioWindowEndIndex => _playbackService.windowEndIndex;

  @override
  Stream<SequenceState?> get sequenceStateStream =>
      _playbackService.sequenceStateStream;

  @override
  Stream<PlayerState> get playerStateStream =>
      _playbackService.playerStateStream;

  @override
  Stream<Duration> get positionStream => _playbackService.positionStream;

  @override
  Stream<Duration> get bufferedPositionStream =>
      _playbackService.bufferedPositionStream;

  @override
  SequenceState? get sequenceState => _playbackService.sequenceState;

  @override
  PlayerState get playerState => _playbackService.playerState;

  @override
  Future<void> reorderQueueItem(int fromIndex, int toIndex) =>
      _playbackService.reorderTrack(fromIndex, toIndex);

  @override
  Future<void> setNextTracks(List<MediaItem> upcomingTracks) =>
      _playbackService.setNextTracks(upcomingTracks);

  @override
  Future<void> removeQueueItemAt(int index) =>
      _playbackService.removeTrack(index);

  @override
  Future<void> removeQueueRange(int startIndex, int endIndex) =>
      _playbackService.removeTrackRange(startIndex, endIndex);

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) =>
      _playbackService.insertTrack(index, mediaItem);

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

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) =>
      _playbackService.setShuffleModeEnabled(
        shuffleMode == AudioServiceShuffleMode.all ||
            shuffleMode == AudioServiceShuffleMode.group,
      );

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) {
    final loopMode = switch (repeatMode) {
      AudioServiceRepeatMode.one => LoopMode.one,
      AudioServiceRepeatMode.all || AudioServiceRepeatMode.group => LoopMode.all,
      _ => LoopMode.off,
    };
    return _playbackService.setLoopMode(loopMode);
  }

  Future<void> dispose() async {
    await _sequenceSub.cancel();
    await _playerStateSub.cancel();
    await _playbackService.dispose();
  }
}
