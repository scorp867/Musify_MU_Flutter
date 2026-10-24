import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/application/queue/mobius/mobius_loop.dart';
import 'package:musify_mu/features/player/application/queue/mobius/mobius_types.dart';
import 'package:musify_mu/features/player/application/queue/mobius/queue_effects.dart';
import 'package:musify_mu/features/player/application/queue/mobius/queue_mobius_update.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_event.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_state.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_options.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';
import 'package:musify_mu/features/player/domain/models/player_state.dart';

void main() {
  group('Spotify Mobius Queue Pure Reducer (queueMobiusUpdate) Tests', () {
    late ContextTrack track1;
    late ContextTrack track2;
    late ContextTrack userTrack;

    setUp(() {
      track1 = ContextTrack.builder('spotify:track:1')
          .uid('uid1')
          .metadata({ContextTrackMetadata.keyTitle: 'Track 1'})
          .build();
      track2 = ContextTrack.builder('spotify:track:2')
          .uid('uid2')
          .metadata({ContextTrackMetadata.keyTitle: 'Track 2'})
          .build();
      userTrack = ContextTrack.builder('spotify:track:u')
          .uid('uid_u')
          .metadata({
            ContextTrackMetadata.keyTitle: 'User Track',
            ContextTrackMetadata.keyIsQueued: 'true',
          })
          .build();
    });

    test('AddTracksToQueue updates model and dispatches AddTracksEffect', () {
      final initial = PlayerQueueState(queue: PlayerQueue(nextTracks: [track1]));
      final next = queueMobiusUpdate(initial, AddTracksToQueue([track2]));

      expect(next.hasModel, true);
      expect(next.model!.queue.nextTracks.length, 2);
      expect(next.hasEffects, true);
      expect(next.effects.first, isA<AddTracksEffect>());
    });

    test('RemoveTracksFromQueue updates model and dispatches RemoveTracksEffect', () {
      final initial = PlayerQueueState(
        queue: PlayerQueue(nextTracks: [track1, track2]),
      );
      final next = queueMobiusUpdate(initial, RemoveTracksFromQueue([track1]));

      expect(next.hasModel, true);
      expect(next.model!.queue.nextTracks.length, 1);
      expect(next.model!.queue.nextTracks.first.uid, 'uid2');
      expect(next.hasEffects, true);
      expect(next.effects.first, isA<RemoveTracksEffect>());
    });

    test('ReorderQueueTrack updates model and dispatches ReorderTrackEffect', () {
      final initial = PlayerQueueState(
        queue: PlayerQueue(nextTracks: [track1, track2]),
      );
      final next = queueMobiusUpdate(
        initial,
        ReorderQueueTrack(track: track2, destinationVisibleIndex: 0),
      );

      expect(next.hasModel, true);
      expect(next.model!.queue.nextTracks.first.uid, 'uid2');
      expect(next.hasEffects, true);
      expect(next.effects.first, isA<ReorderTrackEffect>());
    });

    test('ClearQueue removes user tracks and dispatches ClearQueueEffect', () {
      final initial = PlayerQueueState(
        queue: PlayerQueue(nextTracks: [userTrack, track1]),
      );
      final next = queueMobiusUpdate(initial, const ClearQueue());

      expect(next.hasModel, true);
      expect(next.model!.queue.nextTracks.length, 1);
      expect(next.model!.queue.nextTracks.first.uid, 'uid1');
      expect(next.hasEffects, true);
      expect(next.effects.first, isA<ClearQueueEffect>());
    });

    test('ToggleShuffle cycles shuffle mode and dispatches ToggleShuffleEffect', () {
      final initial = PlayerQueueState(
        playerState: PlayerState(
          options: const PlayerOptions(shufflingContext: false),
        ),
      );
      final next = queueMobiusUpdate(initial, const ToggleShuffle());

      expect(next.hasModel, true);
      expect(next.model!.isShuffling, true);
      expect(next.hasEffects, true);
      final effect = next.effects.first as ToggleShuffleEffect;
      expect(effect.nextShuffle, true);
    });

    test('ToggleRepeat cycles None -> Context -> Track -> None', () {
      // 1. None -> Context
      final state0 = PlayerQueueState(
        playerState: PlayerState(
          options: const PlayerOptions(
            repeatingContext: false,
            repeatingTrack: false,
          ),
        ),
      );
      final next1 = queueMobiusUpdate(state0, const ToggleRepeat());
      expect(next1.model!.repeatContext, true);
      expect(next1.model!.repeatTrack, false);

      // 2. Context -> Track
      final next2 = queueMobiusUpdate(next1.model!, const ToggleRepeat());
      expect(next2.model!.repeatContext, false);
      expect(next2.model!.repeatTrack, true);

      // 3. Track -> None
      final next3 = queueMobiusUpdate(next2.model!, const ToggleRepeat());
      expect(next3.model!.repeatContext, false);
      expect(next3.model!.repeatTrack, false);
    });

    test('TogglePlayPause toggles isPlaying and dispatches PlayPauseEffect', () {
      final initial = PlayerQueueState(
        playerState: const PlayerState(isPlaying: false),
      );
      final next = queueMobiusUpdate(initial, const TogglePlayPause());

      expect(next.hasModel, true);
      expect(next.model!.isPlaying, true);
      expect(next.hasEffects, true);
      final effect = next.effects.first as PlayPauseEffect;
      expect(effect.currentlyPlaying, false);
    });

    test('SkipToNextTrack and SkipToPrevTrack dispatch effects without model change', () {
      final initial = PlayerQueueState();

      final nextSkip = queueMobiusUpdate(initial, const SkipToNextTrack());
      expect(nextSkip.hasModel, false);
      expect(nextSkip.hasEffects, true);
      expect(nextSkip.effects.first, isA<SkipNextEffect>());

      final prevSkip = queueMobiusUpdate(initial, const SkipToPrevTrack());
      expect(prevSkip.hasModel, false);
      expect(prevSkip.hasEffects, true);
      expect(prevSkip.effects.first, isA<SkipPrevEffect>());
    });
  });

  group('MobiusLoop Execution and Feedback Loop Tests', () {
    test('dispatches events, emits model changes, and executes side effects', () async {
      final sampleTrack = ContextTrack.builder('spotify:track:sample')
          .uid('sample_uid')
          .metadata({ContextTrackMetadata.keyIsQueued: 'true'})
          .build();
      final handledEffects = <QueueEffect>[];

      final effectHandler = _MockEffectHandler((effect) async {
        handledEffects.add(effect);
        if (effect is ClearQueueEffect) {
          return const QueueUpdated(PlayerQueue.empty);
        }
        return null;
      });

      final loop = MobiusLoop<PlayerQueueState, PlayerQueueEvent, QueueEffect>(
        initialModel: PlayerQueueState(
          queue: PlayerQueue(nextTracks: [sampleTrack]),
        ),
        update: queueMobiusUpdate,
        effectHandler: effectHandler,
      );

      final emissions = <PlayerQueueState>[];
      final sub = loop.models.listen(emissions.add);

      loop.dispatchEvent(const ClearQueue());

      await Future.delayed(const Duration(milliseconds: 50));

      expect(handledEffects.length, 1);
      expect(handledEffects.first, isA<ClearQueueEffect>());
      expect(emissions.isNotEmpty, true);

      await sub.cancel();
      loop.dispose();
    });
  });
}

class _MockEffectHandler implements MobiusEffectHandler<QueueEffect, PlayerQueueEvent> {
  final Future<PlayerQueueEvent?> Function(QueueEffect) _handler;
  _MockEffectHandler(this._handler);

  @override
  Future<PlayerQueueEvent?> handleEffect(QueueEffect effect) => _handler(effect);
}
