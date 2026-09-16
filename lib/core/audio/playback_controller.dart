import 'package:audio_service/audio_service.dart';

abstract interface class PlaybackController {
  Stream<MediaItem?> get mediaItem;
  Stream<PlaybackState> get playbackState;
  Stream<List<MediaItem>> get queue;
  MediaItem? get currentMediaItem;
  int get audioWindowEndIndex;

  Future<void> playQueue(List<MediaItem> tracks, int initialIndex);
  Future<void> reorderQueueItem(int fromIndex, int toIndex);
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
