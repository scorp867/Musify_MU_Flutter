import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_options.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';
import 'package:musify_mu/features/player/domain/models/player_state.dart';

void main() {
  group('PlayerQueueMobiusController Reactive State Tests', () {
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

    test('initial state matches empty QueueModel defaults', () {
      final controller = PlayerQueueMobiusController(
        initialModel: QueueModel.empty(),
      );
      expect(controller.state.visibleTracks, isEmpty);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.isPlaying, isFalse);
      expect(controller.state.isShuffling, isFalse);
      controller.close();
    });

    test('QueueUpdatedEvent updates queue and partitions user queue and context tracks', () async {
      final controller = PlayerQueueMobiusController(
        initialModel: QueueModel.empty(),
      );
      final newQueue = PlayerQueue(
        track: track1,
        nextTracks: [track2],
      );

      controller.dispatch(QueueUpdatedEvent(newQueue));
      await expectLater(
        controller.stream,
        emits(isA<QueueModel>()
            .having((s) => s.nowPlaying?.uid, 'nowPlaying', 'uid1')
            .having((s) => s.visibleTracks.length, 'visibleTracks.length', 1)),
      );
      controller.close();
    });

    test('PlayerStateChangedEvent updates player state, isPlaying and options', () async {
      final controller = PlayerQueueMobiusController(
        initialModel: QueueModel.empty(),
      );
      final playerState = PlayerState(
        isPlaying: true,
        isPaused: false,
        options: const PlayerOptions(
          shufflingContext: true,
          repeatingContext: true,
        ),
      );

      controller.dispatch(PlayerStateChangedEvent(playerState));
      await expectLater(
        controller.stream,
        emits(isA<QueueModel>()
            .having((s) => s.isPlaying, 'isPlaying', isTrue)
            .having((s) => s.isShuffling, 'isShuffling', isTrue)
            .having((s) => s.repeatContext, 'repeatContext', isTrue)),
      );
      controller.close();
    });

    test('RemoveTrackEvent marks pending removal in state for instant UI animation', () async {
      final initialQueue = PlayerQueue(
        track: track1,
        nextTracks: [track2],
      );
      final controller = PlayerQueueMobiusController(
        initialModel: QueueModel(
          playerQueue: initialQueue,
          contextTracks: [track2],
        ),
      );

      controller.dispatch(RemoveTrackEvent(track2));

      await expectLater(
        controller.stream,
        emits(isA<QueueModel>()
            .having((s) => s.visibleTracks, 'visibleTracks', isEmpty)
            .having((s) => s.pendingRemovalKeys.isNotEmpty, 'pendingRemovalKeys', isTrue)),
      );
      controller.close();
    });
  });
}
