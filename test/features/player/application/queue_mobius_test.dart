import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/application/queue/mobius/mobius_loop.dart';
import 'package:musify_mu/features/player/application/queue/mobius/mobius_types.dart';
import 'package:musify_mu/features/player/application/queue/mobius/queue_effect.dart';
import 'package:musify_mu/features/player/application/queue/mobius/queue_event.dart';
import 'package:musify_mu/features/player/application/queue/mobius/queue_mobius_update.dart';
import 'package:musify_mu/features/player/application/queue/mobius/queue_model.dart';
import 'package:musify_mu/features/player/data/queue/queue_key_resolver.dart';
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
          .provider('queue')
          .metadata({
            ContextTrackMetadata.keyTitle: 'User Track',
            ContextTrackMetadata.keyIsQueued: 'true',
          })
          .build();
    });

    test('AddToQueueEvent emits AddToQueueEffect', () {
      final initial = QueueModel(
        playerQueue: PlayerQueue(nextTracks: [track1]),
        contextTracks: [track1],
      );
      final next = queueMobiusUpdate(initial, AddToQueueEvent(track: track2));

      expect(next.hasEffects, isTrue);
      expect(next.effects.first, isA<AddToQueueEffect>());
    });

    test('RemoveTrackEvent marks pending removal and emits RemoveTracksEffect', () {
      final initial = QueueModel(
        playerQueue: PlayerQueue(nextTracks: [userTrack, track1]),
        userQueue: [userTrack],
        contextTracks: [track1],
      );
      final next = queueMobiusUpdate(initial, RemoveTrackEvent(userTrack));

      expect(next.hasModel, isTrue);
      final model = next.model;
      expect(model, isNotNull);
      if (model != null) {
        final key = QueueKeyResolver.resolveKey(userTrack);
        expect(model.pendingRemovalKeys.contains(key), isTrue);
        expect(model.visibleTracks.contains(userTrack), isFalse);
      }
      expect(next.hasEffects, isTrue);
      expect(next.effects.first, isA<RemoveTracksEffect>());
    });

    test('ReorderTrackEvent dispatches ReorderTrackEffect without premature state mutation', () {
      final initial = QueueModel(
        playerQueue: PlayerQueue(nextTracks: [track1, track2]),
        contextTracks: [track1, track2],
      );
      final next = queueMobiusUpdate(
        initial,
        ReorderTrackEvent(track: track2, destinationVisibleIndex: 0),
      );

      expect(next.hasModel, isFalse);
      expect(next.hasEffects, isTrue);
      expect(next.effects.first, isA<ReorderTrackEffect>());
    });

    test('ClearQueueEvent dispatches ClearQueueEffect', () {
      final initial = QueueModel(
        playerQueue: PlayerQueue(nextTracks: [userTrack, track1]),
        userQueue: [userTrack],
        contextTracks: [track1],
      );
      final next = queueMobiusUpdate(initial, const ClearQueueEvent());

      expect(next.hasModel, isFalse);
      expect(next.hasEffects, isTrue);
      expect(next.effects.first, isA<ClearQueueEffect>());
    });

    test('ToggleShuffleEvent computes next shuffle mode and dispatches ToggleShuffleEffect', () {
      final initial = QueueModel(
        playerState: PlayerState(
          options: const PlayerOptions(shufflingContext: false),
        ),
      );
      final next = queueMobiusUpdate(initial, const ToggleShuffleEvent());

      expect(next.hasEffects, isTrue);
      final effect = next.effects.first as ToggleShuffleEffect;
      expect(effect.enableShuffle, isTrue);
    });

    test('ToggleRepeatEvent cycles None -> Context -> Track -> None', () {
      // 1. None -> Context
      final state0 = QueueModel(
        playerState: PlayerState(
          options: const PlayerOptions(
            repeatingContext: false,
            repeatingTrack: false,
          ),
        ),
      );
      final next1 = queueMobiusUpdate(state0, const ToggleRepeatEvent());
      final effect1 = next1.effects.first as ToggleRepeatEffect;
      expect(effect1.repeatingContext, isTrue);
      expect(effect1.repeatingTrack, isFalse);

      // 2. Context -> Track
      final state1 = QueueModel(
        playerState: PlayerState(
          options: const PlayerOptions(
            repeatingContext: true,
            repeatingTrack: false,
          ),
        ),
      );
      final next2 = queueMobiusUpdate(state1, const ToggleRepeatEvent());
      final effect2 = next2.effects.first as ToggleRepeatEffect;
      expect(effect2.repeatingContext, isFalse);
      expect(effect2.repeatingTrack, isTrue);

      // 3. Track -> None
      final state2 = QueueModel(
        playerState: PlayerState(
          options: const PlayerOptions(
            repeatingContext: false,
            repeatingTrack: true,
          ),
        ),
      );
      final next3 = queueMobiusUpdate(state2, const ToggleRepeatEvent());
      final effect3 = next3.effects.first as ToggleRepeatEffect;
      expect(effect3.repeatingContext, isFalse);
      expect(effect3.repeatingTrack, isFalse);
    });

    test('TogglePlayPauseEvent dispatches TogglePlayPauseEffect without premature state mutation', () {
      final initial = QueueModel(
        playerState: const PlayerState(isPlaying: false),
      );
      final next = queueMobiusUpdate(initial, const TogglePlayPauseEvent());

      expect(next.hasModel, isFalse);
      expect(next.hasEffects, isTrue);
      expect(next.effects.first, isA<TogglePlayPauseEffect>());
    });

    test('SkipToNextTrackEvent and SkipToPrevTrackEvent dispatch effects without model change', () {
      final initial = QueueModel.empty();

      final nextSkip = queueMobiusUpdate(initial, const SkipToNextTrackEvent());
      expect(nextSkip.hasModel, isFalse);
      expect(nextSkip.hasEffects, isTrue);
      expect(nextSkip.effects.first, isA<SkipToNextTrackEffect>());

      final prevSkip = queueMobiusUpdate(initial, const SkipToPrevTrackEvent());
      expect(prevSkip.hasModel, isFalse);
      expect(prevSkip.hasEffects, isTrue);
      expect(prevSkip.effects.first, isA<SkipToPrevTrackEffect>());
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
          return const QueueUpdatedEvent(PlayerQueue.empty);
        }
        return null;
      });

      final loop = MobiusLoop<QueueModel, QueueEvent, QueueEffect>(
        initialModel: QueueModel(
          playerQueue: PlayerQueue(nextTracks: [sampleTrack]),
        ),
        update: queueMobiusUpdate,
        effectHandler: effectHandler,
      );

      final emissions = <QueueModel>[];
      final sub = loop.models.listen(emissions.add);

      loop.dispatchEvent(const ClearQueueEvent());

      await Future.delayed(const Duration(milliseconds: 50));

      expect(handledEffects.length, equals(1));
      expect(handledEffects.first, isA<ClearQueueEffect>());
      expect(emissions.isNotEmpty, isTrue);

      await sub.cancel();
      loop.dispose();
    });
  });
}

class _MockEffectHandler implements MobiusEffectHandler<QueueEffect, QueueEvent> {
  final Future<QueueEvent?> Function(QueueEffect) _handler;
  _MockEffectHandler(this._handler);

  @override
  Future<QueueEvent?> handleEffect(QueueEffect effect) => _handler(effect);
}
