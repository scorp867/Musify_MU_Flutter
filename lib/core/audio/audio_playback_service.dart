import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify_mu/core/audio/playback_queue_manager.dart';

/// Owns the audio player and transport commands.
///
/// Queue policy and sliding-window pagination live in
/// [PlaybackQueueManager], keeping this service focused on player I/O.
class AudioPlaybackService {
  final AudioPlayer _player = AudioPlayer();
  late final PlaybackQueueManager _queueManager;
  late final StreamSubscription<int?> _indexSubscription;

  void Function(List<MediaItem> tracks)? onQueueChanged;

  AudioPlaybackService() {
    _queueManager = PlaybackQueueManager(_player);
    _queueManager.onQueueChanged = (tracks) => onQueueChanged?.call(tracks);
    _indexSubscription = _player.currentIndexStream.listen(_queueManager.onIndexChanged);
  }

  Future<void> dispose() async {
    await _indexSubscription.cancel();
    await _player.dispose();
  }


  AudioPlayer get player => _player;

  Future<void> setAudioSource(String uri) async {
    // Bug 2.17 fix: Clear queue manager state so index listeners don't
    // operate on a stale playlist when single-track playback bypasses the queue.
    _queueManager.reset();
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(uri)));
    } catch (error) {
      debugPrint('Error loading audio source: $error');
    }
  }

  Future<void> setQueue(List<MediaItem> tracks, int initialIndex) {
    return _queueManager.setQueue(tracks, initialIndex);
  }

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> stop() => _player.stop();

  Future<void> seekToNext() async {
    final nextIndex = _queueManager.currentAbsoluteIndex + 1;
    if (nextIndex < _queueManager.fullTracks.length) {
      await _queueManager.seekToAbsoluteIndex(nextIndex);
    } else if (_queueManager.loopMode == LoopMode.all &&
        _queueManager.fullTracks.isNotEmpty) {
      await _queueManager.seekToAbsoluteIndex(0);
    }
  }

  Future<void> seekToPrevious() async {
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
    } else {
      final prevIndex = _queueManager.currentAbsoluteIndex - 1;
      if (prevIndex >= 0) {
        await _queueManager.seekToAbsoluteIndex(prevIndex);
      } else {
        await _player.seek(Duration.zero);
      }
    }
  }

  Future<void> seekToAbsoluteIndex(int absoluteIndex) =>
      _queueManager.seekToAbsoluteIndex(absoluteIndex);

  int windowToAbsoluteIndex(int windowIndex) =>
      _queueManager.windowToAbsoluteIndex(windowIndex);

  int get windowEndIndex => _queueManager.windowEndIndex;

  List<MediaItem> get fullTracks => _queueManager.fullTracks;

  Future<void> reorderTrack(int fromAbsolute, int toAbsolute) =>
      _queueManager.reorderTrack(fromAbsolute, toAbsolute);

  Future<void> removeTrack(int absoluteIndex) =>
      _queueManager.removeTrack(absoluteIndex);

  Future<void> removeTrackRange(int startAbsolute, int endAbsolute) =>
      _queueManager.removeTrackRange(startAbsolute, endAbsolute);

  Future<void> insertTrack(int absoluteIndex, MediaItem track) =>
      _queueManager.insertTrack(absoluteIndex, track);

  Future<void> setNextTracks(List<MediaItem> upcomingTracks) =>
      _queueManager.setNextTracks(upcomingTracks);

  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;

  // Bug 2.12 fix: Forward shuffle and repeat mode changes to just_audio player.
  Future<void> setShuffleModeEnabled(bool enabled) async {
    _queueManager.setShuffleModeEnabled(enabled);
    await _player.setShuffleModeEnabled(enabled);
  }

  Future<void> setLoopMode(LoopMode mode) async {
    _queueManager.setLoopMode(mode);
    await _player.setLoopMode(mode);
  }
}

