import '../../application/queue/player_queue_bloc.dart';
import '../../domain/models/context_track.dart';
import '../../domain/models/player_options.dart';
import '../../domain/models/player_queue.dart';
import '../../domain/models/player_state.dart';

/// Seeds realistic Spotify-parity mock data into the Player and Queue system
/// for interactive runtime verification on emulator or real devices.
abstract class MockQueueSeeder {
  static const String coverStarboy =
      'https://i.scdn.co/image/ab67616d0000b2734718e2b124f79258be7bc452';
  static const String coverAfterHours =
      'https://i.scdn.co/image/ab67616d0000b2738863bc11d2aa12b54f5aeb36';
  static const String coverViews =
      'https://i.scdn.co/image/ab67616d0000b2739416ed64daf84936d89e671c';
  static const String coverBbtm =
      'https://i.scdn.co/image/ab67616d0000b273299723049cf24d1683d789e9';

  /// 1. Now Playing track
  static ContextTrack createNowPlayingTrack() {
    return ContextTrack.builder('spotify:track:4cOdK2wGLETKBW3PvgPWqT')
        .uid('now_playing_starboy')
        .metadata({
          ContextTrackMetadata.keyTitle: 'Starboy',
          ContextTrackMetadata.keyArtistName: 'The Weeknd, Daft Punk',
          ContextTrackMetadata.keyAlbumTitle: 'Starboy',
          ContextTrackMetadata.keyDuration: '230493',
          ContextTrackMetadata.keyImageLargeUrl: coverStarboy,
          ContextTrackMetadata.keyImageUrl: coverStarboy,
          ContextTrackMetadata.keyIsQueued: 'false',
        })
        .build();
  }

  /// 2. User-queued tracks (3 tracks explicitly added by user)
  static List<ContextTrack> createUserQueuedTracks() {
    return [
      ContextTrack.builder('spotify:track:0VjIjW4GlUZAMYd2vXMi3b')
          .uid('user_q_blinding_lights')
          .metadata({
            ContextTrackMetadata.keyTitle: 'Blinding Lights',
            ContextTrackMetadata.keyArtistName: 'The Weeknd',
            ContextTrackMetadata.keyAlbumTitle: 'After Hours',
            ContextTrackMetadata.keyDuration: '200040',
            ContextTrackMetadata.keyImageLargeUrl: coverAfterHours,
            ContextTrackMetadata.keyImageUrl: coverAfterHours,
            ContextTrackMetadata.keyIsQueued: 'true',
          })
          .build(),
      ContextTrack.builder('spotify:track:5QO792alxR8CYgvuV3W5GZ')
          .uid('user_q_save_your_tears')
          .metadata({
            ContextTrackMetadata.keyTitle: 'Save Your Tears',
            ContextTrackMetadata.keyArtistName: 'The Weeknd',
            ContextTrackMetadata.keyAlbumTitle: 'After Hours',
            ContextTrackMetadata.keyDuration: '215626',
            ContextTrackMetadata.keyImageLargeUrl: coverAfterHours,
            ContextTrackMetadata.keyImageUrl: coverAfterHours,
            ContextTrackMetadata.keyIsQueued: 'true',
          })
          .build(),
      ContextTrack.builder('spotify:track:1zi7xx7UVEIR53Hj1dwWYb')
          .uid('user_q_one_dance')
          .metadata({
            ContextTrackMetadata.keyTitle: 'One Dance',
            ContextTrackMetadata.keyArtistName: 'Drake, WizKid, Kyla',
            ContextTrackMetadata.keyAlbumTitle: 'Views',
            ContextTrackMetadata.keyDuration: '173986',
            ContextTrackMetadata.keyImageLargeUrl: coverViews,
            ContextTrackMetadata.keyImageUrl: coverViews,
            ContextTrackMetadata.keyIsQueued: 'true',
          })
          .build(),
    ];
  }

  /// 3. Context tracks (5 tracks from current album/context)
  static List<ContextTrack> createContextTracks() {
    return [
      ContextTrack.builder('spotify:track:7fBv74FRwhAknrwBqFsjA9')
          .uid('ctx_cant_feel_my_face')
          .metadata({
            ContextTrackMetadata.keyTitle: "Can't Feel My Face",
            ContextTrackMetadata.keyArtistName: 'The Weeknd',
            ContextTrackMetadata.keyAlbumTitle: 'Beauty Behind the Madness',
            ContextTrackMetadata.keyDuration: '213520',
            ContextTrackMetadata.keyImageLargeUrl: coverBbtm,
            ContextTrackMetadata.keyImageUrl: coverBbtm,
            ContextTrackMetadata.keyIsQueued: 'false',
          })
          .build(),
      ContextTrack.builder('spotify:track:7KXjTSCq5nL1LoYtL7XAwS')
          .uid('ctx_the_hills')
          .metadata({
            ContextTrackMetadata.keyTitle: 'The Hills',
            ContextTrackMetadata.keyArtistName: 'The Weeknd',
            ContextTrackMetadata.keyAlbumTitle: 'Beauty Behind the Madness',
            ContextTrackMetadata.keyDuration: '242253',
            ContextTrackMetadata.keyImageLargeUrl: coverBbtm,
            ContextTrackMetadata.keyImageUrl: coverBbtm,
            ContextTrackMetadata.keyIsQueued: 'false',
          })
          .build(),
      ContextTrack.builder('spotify:track:7szuecWpew9NTYFCj6J8GQ')
          .uid('ctx_in_your_eyes')
          .metadata({
            ContextTrackMetadata.keyTitle: 'In Your Eyes',
            ContextTrackMetadata.keyArtistName: 'The Weeknd',
            ContextTrackMetadata.keyAlbumTitle: 'After Hours',
            ContextTrackMetadata.keyDuration: '237520',
            ContextTrackMetadata.keyImageLargeUrl: coverAfterHours,
            ContextTrackMetadata.keyImageUrl: coverAfterHours,
            ContextTrackMetadata.keyIsQueued: 'false',
          })
          .build(),
      ContextTrack.builder('spotify:track:60VoAjW2qf8n3eK3G35T3F')
          .uid('ctx_heartless')
          .metadata({
            ContextTrackMetadata.keyTitle: 'Heartless',
            ContextTrackMetadata.keyArtistName: 'The Weeknd',
            ContextTrackMetadata.keyAlbumTitle: 'After Hours',
            ContextTrackMetadata.keyDuration: '198266',
            ContextTrackMetadata.keyImageLargeUrl: coverAfterHours,
            ContextTrackMetadata.keyImageUrl: coverAfterHours,
            ContextTrackMetadata.keyIsQueued: 'false',
          })
          .build(),
      ContextTrack.builder('spotify:track:2p8y6cO4dJz1L1Vv7c8N4u')
          .uid('ctx_after_hours')
          .metadata({
            ContextTrackMetadata.keyTitle: 'After Hours',
            ContextTrackMetadata.keyArtistName: 'The Weeknd',
            ContextTrackMetadata.keyAlbumTitle: 'After Hours',
            ContextTrackMetadata.keyDuration: '361000',
            ContextTrackMetadata.keyImageLargeUrl: coverAfterHours,
            ContextTrackMetadata.keyImageUrl: coverAfterHours,
            ContextTrackMetadata.keyIsQueued: 'false',
          })
          .build(),
    ];
  }

  /// Builds the initial mixed PlayerQueue (1 Now Playing + 3 User Queued + 5 Context).
  static PlayerQueue createInitialMockQueue() {
    final nowPlaying = createNowPlayingTrack();
    final userTracks = createUserQueuedTracks();
    final contextTracks = createContextTracks();

    return PlayerQueue.builder()
        .revision('mock_initial_rev_1')
        .track(nowPlaying)
        .nextTracks([...userTracks, ...contextTracks])
        .build();
  }

  /// Builds the initial PlayerState matching the Now Playing track.
  static PlayerState createInitialPlayerState({bool isPlaying = true}) {
    final nowPlaying = createNowPlayingTrack();
    return PlayerState.builder()
        .track(nowPlaying)
        .isPlaying(isPlaying)
        .duration(230493)
        .positionAsOfTimestamp(0)
        .options(
          PlayerOptions.builder()
              .shufflingContext(false)
              .repeatingContext(false)
              .repeatingTrack(false)
              .build(),
        )
        .build();
  }

  /// Seeds initial mock data into the bloc at application startup.
  static void seedInitialState(PlayerQueueBloc bloc, {bool isPlaying = true}) {
    final queue = createInitialMockQueue();
    final state = createInitialPlayerState(isPlaying: isPlaying);

    bloc.add(QueueUpdated(queue));
    bloc.add(PlayerStateChanged(state));
  }

  /// Re-seeds or resets the queue back to initial starting state.
  static void resetQueue(PlayerQueueBloc bloc) {
    seedInitialState(bloc, isPlaying: bloc.state.isPlaying);
  }
}
