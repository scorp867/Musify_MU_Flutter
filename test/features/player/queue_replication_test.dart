import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';

void main() {
  group('Spotify Queue 1:1 Domain & Operational Logic Tests', () {
    test('ContextTrack models 1:1 properties from com.spotify.player.model', () {
      const track = ContextTrack(
        uri: 'spotify:track:123',
        uid: 'track_uid_1',
        provider: 'context',
        isQueued: false,
        metadata: {
          'title': 'Song A',
          'artist_name': 'Artist A',
          'album_title': 'Album A',
          'duration_ms': '210000',
        },
      );

      expect(track.title, equals('Song A'));
      expect(track.artist, equals('Artist A'));
      expect(track.album, equals('Album A'));
      expect(track.duration, equals(const Duration(milliseconds: 210000)));
      expect(track.isQueued, isFalse);
      expect(track.provider, equals('context'));
    });

    test('PlayerQueue nextTracks combines userQueue and contextTracks in order', () {
      const u1 = ContextTrack(
        uri: 'track:u1',
        uid: 'uid_u1',
        isQueued: true,
        provider: 'queue',
      );
      const c1 = ContextTrack(
        uri: 'track:c1',
        uid: 'uid_c1',
        isQueued: false,
        provider: 'context',
      );
      const c2 = ContextTrack(
        uri: 'track:c2',
        uid: 'uid_c2',
        isQueued: false,
        provider: 'context',
      );

      const queue = PlayerQueue(
        userQueue: [u1],
        contextTracks: [c1, c2],
        revision: '1',
      );

      expect(queue.nextTracks.length, equals(3));
      expect(queue.nextTracks[0].uid, equals('uid_u1'));
      expect(queue.nextTracks[1].uid, equals('uid_c1'));
      expect(queue.nextTracks[2].uid, equals('uid_c2'));
      expect(queue.hasUserQueue, isTrue);
      expect(queue.hasContextTracks, isTrue);
    });

    test('Cross-section reordering converts context track to user-queued track', () {
      const u0 = ContextTrack(
        uri: 'track:u0',
        uid: 'uid_u0',
        isQueued: true,
        provider: 'queue',
      );
      const c0 = ContextTrack(
        uri: 'track:c0',
        uid: 'uid_c0',
        isQueued: false,
        provider: 'context',
      );
      const c1 = ContextTrack(
        uri: 'track:c1',
        uid: 'uid_c1',
        isQueued: false,
        provider: 'context',
      );

      final nextTracks = [u0, c0, c1];
      const userQueueCount = 1;

      // Drag c0 (index 1) to target slot 0 (before u0)
      final moved = nextTracks.removeAt(1);
      final isDroppedIntoUserQueue = 0 < userQueueCount;
      final converted = moved.copyWith(
        isQueued: isDroppedIntoUserQueue,
        provider: isDroppedIntoUserQueue ? 'queue' : 'context',
      );
      nextTracks.insert(0, converted);

      expect(converted.isQueued, isTrue);
      expect(converted.provider, equals('queue'));

      final newUserQueue = nextTracks.where((t) => t.isQueued).toList();
      final newContext = nextTracks.where((t) => !t.isQueued).toList();

      expect(newUserQueue.length, equals(2));
      expect(newUserQueue.map((t) => t.uid), equals(['uid_c0', 'uid_u0']));
      expect(newContext.length, equals(1));
      expect(newContext.first.uid, equals('uid_c1'));
    });

    test('Cross-section reordering converts user-queued track to context track', () {
      const u0 = ContextTrack(
        uri: 'track:u0',
        uid: 'uid_u0',
        isQueued: true,
        provider: 'queue',
      );
      const c0 = ContextTrack(
        uri: 'track:c0',
        uid: 'uid_c0',
        isQueued: false,
        provider: 'context',
      );

      final nextTracks = [u0, c0];
      const userQueueCount = 1;

      // Drag u0 (index 0) to target slot 1 (after c0)
      final moved = nextTracks.removeAt(0);
      final isDroppedIntoUserQueue = 1 < userQueueCount;
      final converted = moved.copyWith(
        isQueued: isDroppedIntoUserQueue,
        provider: isDroppedIntoUserQueue ? 'queue' : 'context',
      );
      nextTracks.insert(1, converted);

      expect(converted.isQueued, isFalse);
      expect(converted.provider, equals('context'));

      final newUserQueue = nextTracks.where((t) => t.isQueued).toList();
      final newContext = nextTracks.where((t) => !t.isQueued).toList();

      expect(newUserQueue, isEmpty);
      expect(newContext.length, equals(2));
    });

    test('Track removal deletes from contextTracks or userQueue by uid', () {
      const u0 = ContextTrack(uri: 'u0', uid: 'uid_u0', isQueued: true);
      const c0 = ContextTrack(uri: 'c0', uid: 'uid_c0', isQueued: false);

      final queue = const PlayerQueue(
        userQueue: [u0],
        contextTracks: [c0],
        revision: '1',
      );

      // Remove context track c0
      final updatedContext = queue.contextTracks.where((t) => t.uid != 'uid_c0').toList();
      final updatedQueue = queue.copyWith(
        contextTracks: updatedContext,
        revision: '2',
      );

      expect(updatedQueue.contextTracks, isEmpty);
      expect(updatedQueue.userQueue.length, equals(1));
      expect(updatedQueue.revision, equals('2'));
    });
  });
}
