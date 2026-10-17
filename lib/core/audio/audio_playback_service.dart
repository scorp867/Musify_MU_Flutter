// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify_mu/core/audio/playback_queue_manager.dart';

/// Owns the [AudioPlayer] instance and coordinates native transport and queue operations.
///
/// Uses [ConcatenatingAudioSource] inside [PlaybackQueueManager] as the single source
/// of truth for queue order, native gapless transitions, shuffle order, and loop modes.
class AudioPlaybackService {
  final AudioPlayer _player = AudioPlayer();
  late final PlaybackQueueManager _queueManager;

  void Function(List<MediaItem> tracks)? onQueueChanged;

  AudioPlaybackService() {
    _queueManager = PlaybackQueueManager(_player);
    _queueManager.onQueueChanged = (tracks) => onQueueChanged?.call(tracks);
  }

  AudioPlayer get player => _player;

  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;

  SequenceState? get sequenceState => _player.sequenceState;
  PlayerState get playerState => _player.playerState;

  Future<void> setAudioSource(String uri) async {
    _queueManager.reset();
    final parsedUri = uri.contains('://') ? Uri.parse(uri) : Uri.file(uri);
    await _player.setAudioSource(AudioSource.uri(parsedUri));
  }

  Future<void> setQueue(List<MediaItem> tracks, int initialIndex) {
    return _queueManager.setQueue(tracks, initialIndex);
  }

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> stop() => _player.stop();

  Future<void> seekToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_player.loopMode == LoopMode.all && fullTracks.isNotEmpty) {
      await _player.seek(Duration.zero, index: 0);
    }
  }

  Future<void> seekToPrevious() async {
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero);
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

  Future<void> setShuffleModeEnabled(bool enabled) =>
      _queueManager.setShuffleModeEnabled(enabled);

  Future<void> setLoopMode(LoopMode mode) =>
      _queueManager.setLoopMode(mode);

  Future<void> dispose() async {
    await _queueManager.dispose();
    await _player.dispose();
  }
}
