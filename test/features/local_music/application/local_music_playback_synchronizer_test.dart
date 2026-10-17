import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/features/local_music/application/local_music_playback_synchronizer.dart';
import 'package:musify_mu/features/local_music/domain/entities/domain_track.dart';

void main() {
  test('updates the active media item when local metadata changes', () async {
    final controller = FakePlaybackController(
      MediaItem(
        id: 'track-1',
        title: 'Old title',
        artist: 'Artist',
        album: 'Album',
        duration: const Duration(minutes: 3),
        extras: const {
          'songId': 42,
          'dataPath': '/music/track.mp3',
          'dateModified': 1,
        },
      ),
    );
    final synchronizer = LocalMusicPlaybackSynchronizer(controller);

    await synchronizer.synchronize([
      DomainTrack(
        id: 'track-1',
        title: 'New title',
        artist: 'Artist',
        album: 'Album',
        duration: const Duration(minutes: 3).inMilliseconds,
        songId: 42,
        dataPath: '/music/track.mp3',
        dateModified: DateTime.fromMillisecondsSinceEpoch(2000),
      ),
    ]);

    expect(controller.updatedItems, hasLength(1));
    expect(controller.updatedItems.single.title, 'New title');
    expect(controller.updatedItems.single.extras?['dateModified'], 2000);
  });

  test('does not update playback when the active track is unchanged', () async {
    final controller = FakePlaybackController(
      MediaItem(
        id: 'track-1',
        title: 'Title',
        artist: 'Artist',
        album: 'Album',
        duration: const Duration(minutes: 3),
        extras: const {
          'songId': 42,
          'dataPath': '/music/track.mp3',
          'dateModified': 2000,
        },
      ),
    );
    final synchronizer = LocalMusicPlaybackSynchronizer(controller);

    await synchronizer.synchronize([
      DomainTrack(
        id: 'track-1',
        title: 'Title',
        artist: 'Artist',
        album: 'Album',
        duration: const Duration(minutes: 3).inMilliseconds,
        songId: 42,
        dataPath: '/music/track.mp3',
        dateModified: DateTime.fromMillisecondsSinceEpoch(2000),
      ),
    ]);

    expect(controller.updatedItems, isEmpty);
  });
}

class FakePlaybackController implements PlaybackController {
  FakePlaybackController(this.currentMediaItem);

  @override
  MediaItem? currentMediaItem;

  @override
  int get audioWindowEndIndex => 0;

  @override
  Future<void> reorderQueueItem(int fromIndex, int toIndex) async {}

  @override
  Future<void> removeQueueItemAt(int index) async {}

  @override
  Future<void> removeQueueRange(int absoluteFromIndex, int absoluteToIndex) async{}

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {}

  final List<MediaItem> updatedItems = [];

  @override
  Stream<MediaItem?> get mediaItem => Stream.value(currentMediaItem);

  @override
  Stream<PlaybackState> get playbackState => const Stream.empty();

  @override
  Stream<SequenceState?> get sequenceStateStream => const Stream.empty();

  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<Duration> get bufferedPositionStream => const Stream.empty();

  @override
  SequenceState? get sequenceState => null;

  @override
  PlayerState get playerState => PlayerState(false, ProcessingState.idle);

  @override
  Stream<List<MediaItem>> get queue => const Stream.empty();

  @override
  Future<void> playQueue(List<MediaItem> tracks, int initialIndex) async {}

  @override
  Future<void> setNextTracks(List<MediaItem> upcomingTracks) async {}

  @override
  Future<void> updateCurrentMediaItem(MediaItem item) async {
    updatedItems.add(item);
    currentMediaItem = item;
  }

  @override
  Future<void> refreshArtwork() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

  @override
  Future<void> skipToQueueItem(int index) async {}

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode mode) async {}

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) async {}
}
