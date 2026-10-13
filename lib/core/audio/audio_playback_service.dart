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

  AudioPlaybackService() {
    _queueManager = PlaybackQueueManager(_player);
    _indexSubscription = _player.currentIndexStream.listen(_queueManager.onIndexChanged);
  }

  Future<void> dispose() async {
    await _indexSubscription.cancel();
    await _player.dispose();
  }


  AudioPlayer get player => _player;

  Future<void> setAudioSource(String uri) async {
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

  Future<void> seekToNext() => _player.seekToNext();

  Future<void> seekToPrevious() => _player.seekToPrevious();

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

  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;
}

