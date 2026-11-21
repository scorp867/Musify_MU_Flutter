import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_state.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/now_playing_view_model.dart';
import 'package:musify_mu/features/player/domain/models/play_origin.dart';
import 'package:musify_mu/features/player/domain/models/player_state.dart';
import 'package:musify_mu/features/player/domain/policies/spotify_track_eligibility_policy.dart';

void main() {
  group('SpotifyTrackEligibilityPolicy', () {
    test('accepts authentic public Spotify songs', () {
      final track = ContextTrack.builder('spotify:track:3ySVdXje5nm31d7vL3jNV3')
          .metadata({
            ContextTrackMetadata.keyTitle: 'Tune Maari Entriyaan',
            ContextTrackMetadata.keyArtistName: 'Sohail Sen',
            ContextTrackMetadata.keyArtistUri:
                'spotify:artist:1wRPtKGflJrBx9BmLsSwlU',
          })
          .build();

      expect(
        SpotifyTrackEligibilityPolicy.isEligibleSpotifySong(track),
        isTrue,
      );
      expect(
        SpotifyTrackEligibilityPolicy.extractEligibleSpotifyTrackId(track),
        equals('3ySVdXje5nm31d7vL3jNV3'),
      );

      final vm = NowPlayingViewModel.fromPlayerQueueState(
        PlayerQueueState(
          playerState: PlayerState(track: track, isPaused: false),
        ),
      );
      expect(vm.isSpotifySong, isTrue);
      expect(vm.trackId, equals('3ySVdXje5nm31d7vL3jNV3'));
      expect(vm.artistUri, equals('spotify:artist:1wRPtKGflJrBx9BmLsSwlU'));
    });

    test('rejects Spotify-sourced Private Vault tracks even when unmasked', () {
      final unmaskedVaultSpotifyTrack = ContextTrack(
        uri: 'spotify:track:3ySVdXje5nm31d7vL3jNV3',
        uid: 'vault_track-1',
        provider: 'musify_vault',
        metadata: const {
          'is_vault_track': 'true',
          'vault_track_id': 'track-1',
          'vault_source_type': 'spotify',
          ContextTrackMetadata.keyArtistUri:
              'spotify:artist:1wRPtKGflJrBx9BmLsSwlU',
        },
      );

      expect(
        SpotifyTrackEligibilityPolicy.isVaultTrack(unmaskedVaultSpotifyTrack),
        isTrue,
      );
      expect(
        SpotifyTrackEligibilityPolicy.isEligibleSpotifySong(
          unmaskedVaultSpotifyTrack,
        ),
        isFalse,
      );
      expect(
        SpotifyTrackEligibilityPolicy.extractEligibleSpotifyTrackId(
          unmaskedVaultSpotifyTrack,
        ),
        isNull,
      );

      final vm = NowPlayingViewModel.fromPlayerQueueState(
        PlayerQueueState(
          playerState: PlayerState(
            track: unmaskedVaultSpotifyTrack,
            isPaused: false,
          ),
        ),
      );
      expect(vm.isSpotifySong, isFalse);
      expect(vm.trackId, isEmpty);
      expect(vm.artistUri, isEmpty);
    });

    test('rejects masked vault tracks and vault playback contexts', () {
      final maskedTrack = ContextTrack(
        uri: 'spotify:track:3ySVdXje5nm31d7vL3jNV3',
        metadata: const {'musify_vault_masked': 'true'},
      );
      expect(
        SpotifyTrackEligibilityPolicy.isEligibleSpotifySong(maskedTrack),
        isFalse,
      );

      final plainTrackInVaultContext = ContextTrack(
        uri: 'spotify:track:3ySVdXje5nm31d7vL3jNV3',
      );
      final vaultPlayerState = PlayerState(
        contextUri: 'spotify:internal:vault-playlist:pl-1',
        contextMetadata: const {'is_vault_context': 'true'},
        playOrigin: const PlayOrigin(featureIdentifier: 'vault_playlist'),
        track: plainTrackInVaultContext,
      );
      expect(
        SpotifyTrackEligibilityPolicy.isEligibleSpotifySong(
          plainTrackInVaultContext,
          playerState: vaultPlayerState,
        ),
        isFalse,
      );
    });

    test('rejects local files in all URI and metadata representations', () {
      final cases = <ContextTrack>[
        ContextTrack.builder('spotify:local:Artist:Album:Title:180').build(),
        ContextTrack.builder('file:///storage/emulated/0/Music/song.mp3')
            .build(),
        ContextTrack.builder('/storage/emulated/0/Music/song.mp3').build(),
        ContextTrack.builder('content://media/external/audio/media/42').build(),
        ContextTrack.builder('spotify:track:3ySVdXje5nm31d7vL3jNV3')
            .metadata({ContextTrackMetadata.keyIsLocal: 'true'})
            .build(),
        ContextTrack.builder('spotify:track:3ySVdXje5nm31d7vL3jNV3')
            .metadata({
              ContextTrackMetadata.keyLocalFilePath:
                  '/storage/emulated/0/Music/song.mp3',
            })
            .build(),
      ];

      for (final track in cases) {
        expect(
          SpotifyTrackEligibilityPolicy.isLocalTrack(track),
          isTrue,
          reason: 'Expected local detection for $track',
        );
        expect(
          SpotifyTrackEligibilityPolicy.isEligibleSpotifySong(track),
          isFalse,
          reason: 'Expected ineligibility for $track',
        );
      }

      final localContextState = PlayerState(
        contextUri: 'spotify:internal:local-files',
        playOrigin: const PlayOrigin(featureIdentifier: 'local_files'),
      );
      expect(
        SpotifyTrackEligibilityPolicy.isEligibleSpotifySong(
          ContextTrack.builder('spotify:track:3ySVdXje5nm31d7vL3jNV3').build(),
          playerState: localContextState,
        ),
        isFalse,
      );
    });

    test('rejects non-song Spotify URIs (ads, episodes, clips, delimiters)', () {
      for (final uri in const [
        'spotify:ad:ad123',
        'spotify:episode:ep123',
        'spotify:clip:clip123',
        'spotify:delimiter',
        'spotify:meta:delimiter',
        'vault:abc123',
        'musify:vault:abc123',
      ]) {
        expect(
          SpotifyTrackEligibilityPolicy.resolveCanonicalSpotifyTrackUri(uri),
          isNull,
          reason: 'Expected URI $uri to be rejected',
        );
        expect(
          SpotifyTrackEligibilityPolicy.isEligibleSpotifySong(
            ContextTrack.builder(uri).build(),
          ),
          isFalse,
        );
      }
    });
  });
}
