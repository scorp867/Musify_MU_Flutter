import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Defines the contract for controlling audio playback and observing playback state.
abstract interface class PlaybackController {
  Stream<MediaItem?> get mediaItem;
  Stream<PlaybackState> get playbackState;
  Stream<List<MediaItem>> get queue;
  MediaItem? get currentMediaItem;
  int get audioWindowEndIndex;

  Stream<SequenceState?> get sequenceStateStream;
  Stream<PlayerState> get playerStateStream;
  Stream<Duration> get positionStream;
  Stream<Duration> get bufferedPositionStream;
  SequenceState? get sequenceState;
  PlayerState get playerState;

  Future<void> playQueue(List<MediaItem> tracks, int initialIndex);
  Future<void> reorderQueueItem(int fromIndex, int toIndex);
  Future<void> setNextTracks(List<MediaItem> upcomingTracks);
  Future<void> removeQueueItemAt(int index);
  Future<void> removeQueueRange(int startIndex, int endIndex);
  Future<void> insertQueueItem(int index, MediaItem mediaItem);
  Future<void> updateCurrentMediaItem(MediaItem item);
  Future<void> refreshArtwork();
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> skipToQueueItem(int index);
  Future<void> setShuffleMode(AudioServiceShuffleMode mode);
  Future<void> setRepeatMode(AudioServiceRepeatMode mode);
}
