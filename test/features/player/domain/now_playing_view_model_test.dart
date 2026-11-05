import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_state.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/now_playing_view_model.dart';
import 'package:musify_mu/features/player/domain/models/player_state.dart';

void main() {
  group('NowPlayingViewModel Unit Tests', () {
    test('extracts track id correctly and filters blocked prefixes', () {
      final normal = ContextTrack.builder('spotify:track:6rqhFgbbKwnb9MLmUQDhG6').build();
      expect(NowPlayingViewModel.extractTrackId(normal, null), equals('6rqhFgbbKwnb9MLmUQDhG6'));

      final ad = ContextTrack.builder('spotify:ad:some_ad_id').build();
      expect(NowPlayingViewModel.extractTrackId(ad, null), isEmpty);

      final episode = ContextTrack.builder('spotify:episode:episode_id').build();
      expect(NowPlayingViewModel.extractTrackId(episode, null), isEmpty);

      expect(NowPlayingViewModel.extractTrackId(null, 12345), equals('12345'));
    });

    test('creates NowPlayingViewModel with fallback values when state is null', () {
      final vm = NowPlayingViewModel.fromPlayerQueueState(
        null,
        fallbackTitle: 'Fallback Song',
        fallbackArtist: 'Fallback Artist',
        fallbackDuration: const Duration(seconds: 200),
      );

      expect(vm.title, equals('Fallback Song'));
      expect(vm.artist, equals('Fallback Artist'));
      expect(vm.duration, equals(const Duration(seconds: 200)));
      expect(vm.isPlaying, isFalse);
    });

    test('creates NowPlayingViewModel from active ContextTrack metadata', () {
      final track = ContextTrack.builder('spotify:track:starboy')
          .metadata({
            ContextTrackMetadata.keyTitle: 'Starboy',
            ContextTrackMetadata.keyArtistName: 'The Weeknd',
            ContextTrackMetadata.keyAlbumTitle: 'Starboy',
            ContextTrackMetadata.keyDuration: '230000',
            ContextTrackMetadata.keyImageUrl: 'https://cdn.example.com/starboy.jpg',
          })
          .build();

      final state = PlayerQueueState(
        playerState: PlayerState(
          track: track,
          isPaused: false,
        ),
      );

      final vm = NowPlayingViewModel.fromPlayerQueueState(state);
      expect(vm.title, equals('Starboy'));
      expect(vm.artist, equals('The Weeknd'));
      expect(vm.album, equals('Starboy'));
      expect(vm.duration, equals(const Duration(milliseconds: 230000)));
      expect(vm.trackId, equals('starboy'));
    });
  });
}
