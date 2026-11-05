import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/application/queue/mobius/queue_effect.dart';
import 'package:musify_mu/features/player/application/queue/mobius/queue_event.dart';
import 'package:musify_mu/features/player/application/queue/mobius/queue_mobius_update.dart';
import 'package:musify_mu/features/player/application/queue/mobius/queue_model.dart';
import 'package:musify_mu/features/player/data/queue/queue_key_resolver.dart';
import 'package:musify_mu/features/player/data/queue/queue_revision_manager.dart';
import 'package:musify_mu/features/player/data/queue/queue_uid_generator.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';

void main() {
  group('Spotify Pure Mobius Queue Logic Tests', () {
    late ContextTrack track1;
    late ContextTrack track2;
    late ContextTrack track3;
    late ContextTrack userQueuedTrack;

    setUp(() {
      track1 = ContextTrack.builder('spotify:track:1')
          .uid('0123456789abcdef')
          .metadata({
            ContextTrackMetadata.keyTitle: 'Track 1',
            ContextTrackMetadata.keyArtistName: 'Artist 1',
          })
          .build();

      track2 = ContextTrack.builder('spotify:track:2')
          .uid('abcdef0123456789')
          .metadata({
            ContextTrackMetadata.keyTitle: 'Track 2',
            ContextTrackMetadata.keyArtistName: 'Artist 2',
          })
          .build();

      track3 = ContextTrack.builder('spotify:track:3')
          .uid('fedcba9876543210')
          .metadata({
            ContextTrackMetadata.keyTitle: 'Track 3',
            ContextTrackMetadata.keyArtistName: 'Artist 3',
          })
          .build();

      userQueuedTrack = ContextTrack.builder('spotify:track:q1')
          .uid('1122334455667788')
          .provider('queue')
          .metadata({
            ContextTrackMetadata.keyTitle: 'User Queued 1',
            ContextTrackMetadata.keyIsQueued: 'true',
          })
          .build();
    });

    test('QueueKeyResolver: resolves compound key matching Spotify ock1.m68168i0', () {
      final key = QueueKeyResolver.resolveKey(track1);
      expect(key, equals('0123456789abcdefspotify:track:1'));

      final queuedKey = QueueKeyResolver.resolveKey(userQueuedTrack);
      expect(queuedKey, equals('1122334455667788spotify:track:q1queue'));
    });

    test('QueueKeyResolver: identifies queued tracks via isQueued matching Spotify ock1.m68146V', () {
      expect(QueueKeyResolver.isQueued(userQueuedTrack), isTrue);
      expect(QueueKeyResolver.isQueued(track1), isFalse);
    });

    test('QueueUidGenerator: generates valid 16-hex lowercase unique UIDs', () {
      final uid1 = QueueUidGenerator.generateTrackUid();
      final uid2 = QueueUidGenerator.generateTrackUid();

      expect(uid1.length, equals(16));
      expect(uid2.length, equals(16));
      expect(uid1, isNot(equals(uid2)));
      expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(uid1), isTrue);
    });

    test('QueueRevisionManager: manages monotonic queue revisions', () {
      final rev0 = QueueRevisionManager.initialRevision;
      final rev1 = QueueRevisionManager.increment(rev0);
      final rev2 = QueueRevisionManager.increment(rev1);

      expect(rev1, equals('1'));
      expect(rev2, equals('2'));
      expect(QueueRevisionManager.parse(rev2), equals(2));
      expect(QueueRevisionManager.parse('invalid'), equals(0));
    });

    test('queueMobiusUpdate: QueueUpdatedEvent correctly partitions user queue and context tracks', () {
      final queue = PlayerQueue(
        track: track1,
        nextTracks: [userQueuedTrack, track2, track3],
      );

      final next = queueMobiusUpdate(QueueModel.empty(), QueueUpdatedEvent(queue));
      final model = next.model;
      expect(model, isNotNull);

      if (model != null) {
        expect(model.currentTrack, equals(track1));
        expect(model.userQueue.length, equals(1));
        expect(model.userQueue.first, equals(userQueuedTrack));
        expect(model.contextTracks.length, equals(2));
        expect(model.contextTracks.first, equals(track2));
        expect(model.totalQueuedCount, equals(1));
      }
    });

    test('queueMobiusUpdate: RemoveTrackEvent marks key in pendingRemovalKeys and emits RemoveTracksEffect', () {
      final queue = PlayerQueue(
        track: track1,
        nextTracks: [userQueuedTrack, track2],
      );

      final initial = queueMobiusUpdate(QueueModel.empty(), QueueUpdatedEvent(queue)).model;
      expect(initial, isNotNull);

      if (initial != null) {
        final next = queueMobiusUpdate(initial, RemoveTrackEvent(userQueuedTrack));
        final key = QueueKeyResolver.resolveKey(userQueuedTrack);

        final updatedModel = next.model;
        expect(updatedModel, isNotNull);
        if (updatedModel != null) {
          expect(updatedModel.pendingRemovalKeys.contains(key), isTrue);
          expect(updatedModel.visibleTracks.contains(userQueuedTrack), isFalse);
        }
        expect(next.effects, contains(RemoveTracksEffect([userQueuedTrack])));
      }
    });

    test('queueMobiusUpdate: AddToQueueEvent emits AddToQueueEffect without altering context tracks', () {
      final queue = PlayerQueue(
        track: track1,
        nextTracks: [track2, track3],
      );

      final initial = queueMobiusUpdate(QueueModel.empty(), QueueUpdatedEvent(queue)).model;
      expect(initial, isNotNull);

      if (initial != null) {
        final next = queueMobiusUpdate(initial, AddToQueueEvent(track: track2));
        expect(next.effects, contains(AddToQueueEffect(track: track2, playNext: false)));
        expect(initial.contextTracks.length, equals(2));
      }
    });

    test('queueMobiusUpdate: ClearQueueEvent dispatches ClearQueueEffect', () {
      final next = queueMobiusUpdate(QueueModel.empty(), const ClearQueueEvent());
      expect(next.effects, contains(const ClearQueueEffect()));
    });

    test('duplicate tracks in context have distinct keys and removing 1 instance leaves other intact', () {
      final copy1 = ContextTrack.builder('spotify:track:dup')
          .uid('uid_dup_1')
          .provider('context')
          .metadata({ContextTrackMetadata.keyTitle: 'Dup Song'})
          .build();

      final copy2 = ContextTrack.builder('spotify:track:dup')
          .uid('uid_dup_2')
          .provider('context')
          .metadata({ContextTrackMetadata.keyTitle: 'Dup Song'})
          .build();

      final key1 = QueueKeyResolver.resolveKey(copy1);
      final key2 = QueueKeyResolver.resolveKey(copy2);
      expect(key1, isNot(equals(key2)));

      final queue = PlayerQueue(
        nextTracks: [copy1, copy2],
      );

      final initial = queueMobiusUpdate(QueueModel.empty(), QueueUpdatedEvent(queue)).model;
      expect(initial, isNotNull);
      if (initial != null) {
        expect(initial.visibleTracks.length, equals(2));

        final next = queueMobiusUpdate(initial, RemoveTrackEvent(copy1));
        final updated = next.model;
        expect(updated, isNotNull);
        if (updated != null) {
          expect(updated.visibleTracks.length, equals(1));
          expect(updated.visibleTracks.first.uid, equals('uid_dup_2'));
        }
      }
    });

    test('deep immutability: QueueModel lists and sets cannot be mutated in place', () {
      final queue = PlayerQueue(
        nextTracks: [track1, track2],
      );
      final model = queueMobiusUpdate(QueueModel.empty(), QueueUpdatedEvent(queue)).model;
      expect(model, isNotNull);
      if (model != null) {
        expect(() => (model.visibleTracks as dynamic).add(track3), throwsUnsupportedError);
        expect(() => (model.contextTracks as dynamic).add(track3), throwsUnsupportedError);
      }
    });

    test('TrackTappedEvent dispatches SkipToTrackEffect with exact tapped track', () {
      final queuedTrack = ContextTrack.builder('spotify:track:q2')
          .uid('uid_q2')
          .provider('queue')
          .metadata({ContextTrackMetadata.keyIsQueued: 'true', 'provider': 'queue'})
          .build();

      final result = queueMobiusUpdate(QueueModel.empty(), TrackTappedEvent(queuedTrack));
      expect(result.effects.length, equals(1));
      final effect = result.effects.first;
      expect(effect, isA<SkipToTrackEffect>());
      if (effect is SkipToTrackEffect) {
        expect(effect.track.uid, equals('uid_q2'));
        expect(effect.track.uri, equals('spotify:track:q2'));
        expect(effect.track.provider, equals('queue'));
      }
    });
  });
}
