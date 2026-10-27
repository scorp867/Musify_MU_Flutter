import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/data/queue/context_track_extensions.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/playlist/application/mobius/playlist_mobius_types.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_entity.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_item.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_metadata.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_screen_state.dart';
import 'package:musify_mu/features/playlist/domain/models/sort_order.dart';
import 'package:musify_mu/features/playlist/domain/models/track_item_metadata.dart';

void main() {
  group('Playlist Playback Resilience & Screen Re-entry Tests (Bug 1)', () {
    const playlistUri = 'spotify:playlist:37i9dQZF1DXcBWIGoYBM5M';
    final dummyPlaylist = PlaylistEntity(
      metadata: const PlaylistMetadata(
        uri: playlistUri,
        name: 'Today\'s Top Hits',
      ),
      items: [
        PlaylistItem(
          uri: 'spotify:track:1',
          uid: 'uid_1',
          rowPosition: 0,
          trackMetadata: const TrackItemMetadata(
            title: 'Track One',
            uri: 'spotify:track:1',
            artists: ['Artist One'],
          ),
        ),
      ],
      isLoaded: true,
    );

    test('PlaylistLoadingState captures PlaybackStateChangedEvent during initial loading', () {
      final initialState = PlaylistLoadingState(playlistUri: playlistUri);

      final next = playlistMobiusUpdate(
        initialState,
        const PlaylistTrackPlaybackStateChangedEvent(
          activeTrackUri: 'spotify:track:1',
          isPlaying: true,
          isShuffleEnabled: true,
        ),
      );

      expect(next.hasModel, isTrue);
      final model = next.model as PlaylistLoadingState;
      expect(model.activeTrackUri, equals('spotify:track:1'));
      expect(model.isPlaying, isTrue);
      expect(model.isShuffleEnabled, isTrue);
    });

    test('PlaylistLoadedEvent preserves playback state captured during PlaylistLoadingState', () {
      final loadingState = const PlaylistLoadingState(
        playlistUri: playlistUri,
        activeTrackUri: 'spotify:track:1',
        isPlaying: true,
        isShuffleEnabled: true,
      );

      final next = playlistMobiusUpdate(
        loadingState,
        PlaylistLoadedEvent(dummyPlaylist),
      );

      expect(next.hasModel, isTrue);
      final model = next.model as PlaylistLoadedState;
      expect(model.activeTrackUri, equals('spotify:track:1'));
      expect(model.isPlaying, isTrue);
      expect(model.isShuffleEnabled, isTrue);
      expect(model.playlist.name, equals('Today\'s Top Hits'));
    });
  });

  group('Queue Item Full Metadata Contract (Bug 2)', () {
    test('Queued ContextTrack preserves complete metadata avoiding placeholder titles', () {
      final item = PlaylistItem(
        uri: 'spotify:track:espresso',
        uid: 'uid_espresso',
        rowPosition: 0,
        trackMetadata: const TrackItemMetadata(
          title: 'Espresso',
          uri: 'spotify:track:espresso',
          artists: ['Sabrina Carpenter'],
          albumName: 'Short n\' Sweet',
          albumCovers: ['https://example.com/cover.jpg'],
          durationMs: 175000,
          isExplicit: true,
        ),
      );

      final queuedTrack = ContextTrack.builder(item.uri)
          .uid(item.uid.isNotEmpty ? item.uid : item.uri)
          .metadata({
            ContextTrackMetadata.keyTitle: item.title,
            ContextTrackMetadata.keyArtistName: item.subtitle,
            ContextTrackMetadata.keyAlbumTitle: item.albumName,
            if (item.coverUrl.isNotEmpty) ContextTrackMetadata.keyImageUrl: item.coverUrl,
            if (item.coverUrl.isNotEmpty) ContextTrackMetadata.keyImageLargeUrl: item.coverUrl,
            if (item.coverUrl.isNotEmpty) ContextTrackMetadata.keyThumbnailImageUrl: item.coverUrl,
            if (item.durationMs > 0) ContextTrackMetadata.keyDuration: item.durationMs.toString(),
            ContextTrackMetadata.keyIsExplicit: item.isExplicit ? 'true' : 'false',
            ContextTrackMetadata.keyEntityUri: item.uri,
            ContextTrackMetadata.keyContextUri: 'spotify:playlist:test',
            ContextTrackMetadata.keyIsQueued: 'true',
          })
          .build();

      expect(queuedTrack.isQueued, isTrue);
      expect(queuedTrack.title, equals('Espresso'));
      expect(queuedTrack.artist, equals('Sabrina Carpenter'));
      expect(queuedTrack.album, equals('Short n\' Sweet'));
      expect(queuedTrack.imageUrl, equals('https://example.com/cover.jpg'));
      expect(queuedTrack.duration, equals(const Duration(milliseconds: 175000)));
      expect(queuedTrack.isExplicit, isTrue);
    });
  });

  group('Optimistic Track Playback Transitions (Bug 3)', () {
    const playlistUri = 'spotify:playlist:37i9dQZF1DXcBWIGoYBM5M';
    final dummyPlaylist = PlaylistEntity(
      metadata: const PlaylistMetadata(
        uri: playlistUri,
        name: 'Hits',
      ),
      items: [
        PlaylistItem(
          uri: 'spotify:track:first',
          uid: 'uid_first',
          rowPosition: 0,
          trackMetadata: const TrackItemMetadata(
            title: 'First Song',
            uri: 'spotify:track:first',
            artists: ['Artist A'],
          ),
        ),
      ],
      isLoaded: true,
    );

    test('PlaylistPlayTappedEvent immediately transitions state to playing with active track', () {
      final loadedState = PlaylistLoadedState(
        playlist: dummyPlaylist,
        displayItems: dummyPlaylist.items,
        sortOrder: ProvidedSortOrder.custom,
        isPlaying: false,
        activeTrackUri: null,
      );

      final next = playlistMobiusUpdate(
        loadedState,
        const PlaylistPlayTappedEvent(trackUri: 'spotify:track:first'),
      );

      expect(next.hasModel, isTrue);
      final model = next.model as PlaylistLoadedState;
      expect(model.isPlaying, isTrue);
      expect(model.activeTrackUri, equals('spotify:track:first'));
      expect(next.effects, hasLength(1));
      expect(next.effects.first, isA<PlayContextEffect>());
    });

    test('PlaylistPlayTappedEvent with null track on playing state toggles pause', () {
      final loadedState = PlaylistLoadedState(
        playlist: dummyPlaylist,
        displayItems: dummyPlaylist.items,
        sortOrder: ProvidedSortOrder.custom,
        isPlaying: true,
        activeTrackUri: 'spotify:track:first',
      );

      final next = playlistMobiusUpdate(
        loadedState,
        const PlaylistPlayTappedEvent(),
      );

      expect(next.hasModel, isTrue);
      final model = next.model as PlaylistLoadedState;
      expect(model.isPlaying, isFalse);
      expect(next.effects, contains(const PausePlaybackEffect()));
    });
  });
}
