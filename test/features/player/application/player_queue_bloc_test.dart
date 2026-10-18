import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_bloc.dart';
import 'package:musify_mu/features/player/data/queue/context_track_extensions.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_options.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';
import 'package:musify_mu/features/player/domain/models/player_state.dart';

void main() {
  group('PlayerQueueBloc Parity & Reactive State Tests', () {
    late ContextTrack track1;
    late ContextTrack track2;

    setUp(() {
      track1 = ContextTrack.builder('spotify:track:1')
          .uid('uid1')
          .metadata({
            ContextTrackMetadata.keyTitle: 'Track One',
            ContextTrackMetadata.keyArtistName: 'Artist One',
          })
          .build();

      track2 = ContextTrack.builder('spotify:track:2')
          .uid('uid2')
          .metadata({
            ContextTrackMetadata.keyTitle: 'Track Two',
            ContextTrackMetadata.keyArtistName: 'Artist Two',
          })
          .build();
    });

    test('initial state matches empty PlayerQueue defaults', () {
      final bloc = PlayerQueueBloc();
      expect(bloc.state.queue.nextTracks, isEmpty);
      expect(bloc.state.isLoading, false);
      expect(bloc.state.isPlaying, false);
      expect(bloc.state.isShuffling, false);
      bloc.close();
    });

    test('QueueUpdated event updates queue and clears loading', () async {
      final bloc = PlayerQueueBloc();
      final newQueue = PlayerQueue(
        track: track1,
        nextTracks: [track2],
      );

      bloc.add(QueueUpdated(newQueue));
      await expectLater(
        bloc.stream,
        emits(isA<PlayerQueueState>()
            .having((s) => s.nowPlaying?.uid, 'nowPlaying', 'uid1')
            .having((s) => s.queue.nextTracks.length, 'nextTracks.length', 1)),
      );
      bloc.close();
    });

    test('PlayerStateChanged event updates player state, isPlaying and options', () async {
      final bloc = PlayerQueueBloc();
      final playerState = PlayerState(
        isPlaying: true,
        isPaused: false,
        options: PlayerOptions(
          shufflingContext: true,
          repeatingContext: true,
        ),
      );

      bloc.add(PlayerStateChanged(playerState));
      await expectLater(
        bloc.stream,
        emits(isA<PlayerQueueState>()
            .having((s) => s.isPlaying, 'isPlaying', true)
            .having((s) => s.isShuffling, 'isShuffling', true)
            .having((s) => s.repeatContext, 'repeatContext', true)),
      );
      bloc.close();
    });

    test('AddTracksToQueue performs optimistic update in state', () async {
      final bloc = PlayerQueueBloc();
      bloc.add(AddTracksToQueue([track1, track2]));

      await expectLater(
        bloc.stream,
        emits(isA<PlayerQueueState>()
            .having((s) => s.queue.nextTracks.length, 'nextTracks.length', 2)),
      );
      bloc.close();
    });

    test('ClearQueue clears all user-queued items optimistically', () async {
      final userTrack = ContextTrack.builder('spotify:track:u')
          .uid('user_uid')
          .metadata({ContextTrackMetadata.keyIsQueued: 'true'})
          .build();

      final bloc = PlayerQueueBloc(
        initialQueue: PlayerQueue(nextTracks: [userTrack, track1]),
      );

      bloc.add(const ClearQueue());
      await expectLater(
        bloc.stream,
        emits(isA<PlayerQueueState>()
            .having((s) => s.queue.nextTracks.length, 'nextTracks.length', 1)
            .having((s) => s.hasUserQueue, 'hasUserQueue', false)),
      );
      bloc.close();
    });
  });
}
