import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/data/queue/context_track_extensions.dart';
import 'package:musify_mu/features/player/data/queue/queue_add_handler.dart';
import 'package:musify_mu/features/player/data/queue/queue_clear_handler.dart';
import 'package:musify_mu/features/player/data/queue/queue_helpers.dart';
import 'package:musify_mu/features/player/data/queue/queue_remove_handler.dart';
import 'package:musify_mu/features/player/data/queue/queue_reorder_handler.dart';
import 'package:musify_mu/features/player/data/queue/queue_track_filter.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';

void main() {
  group('Spotify Queue Logic Handlers Parity Tests', () {
    late ContextTrack track1;
    late ContextTrack track2;
    late ContextTrack track3;
    late ContextTrack userQueuedTrack;

    setUp(() {
      track1 = ContextTrack.builder('spotify:track:1')
          .uid('uid1')
          .metadata({
            ContextTrackMetadata.keyTitle: 'Track 1',
            ContextTrackMetadata.keyArtistName: 'Artist 1',
          })
          .build();

      track2 = ContextTrack.builder('spotify:track:2')
          .uid('uid2')
          .metadata({
            ContextTrackMetadata.keyTitle: 'Track 2',
            ContextTrackMetadata.keyArtistName: 'Artist 2',
          })
          .build();

      track3 = ContextTrack.builder('spotify:track:3')
          .uid('uid3')
          .metadata({
            ContextTrackMetadata.keyTitle: 'Track 3',
            ContextTrackMetadata.keyArtistName: 'Artist 3',
          })
          .build();

      userQueuedTrack = ContextTrack.builder('spotify:track:q1')
          .uid('uid_q1')
          .metadata({
            ContextTrackMetadata.keyTitle: 'User Queued 1',
            ContextTrackMetadata.keyIsQueued: 'true',
          })
          .build();
    });

    test('QueueAddHandler: addToEndOfQueue sets isQueued and inserts after user queue, before context tracks', () {
      final initialQueue = PlayerQueue(
        nextTracks: [userQueuedTrack, track1, track2],
      );

      final newTrack = ContextTrack.builder('spotify:track:new')
          .uid('uid_new')
          .metadata({ContextTrackMetadata.keyTitle: 'New Track'})
          .build();

      final updated = QueueAddHandler.addTracks(
        initialQueue,
        [newTrack],
        mode: QueueInsertMode.addToEndOfQueue,
      );

      expect(updated.nextTracks.length, 4);
      expect(updated.nextTracks[0].uid, 'uid_q1');
      expect(updated.nextTracks[1].uid, 'uid_new');
      expect(updated.nextTracks[1].isQueued, true);
      expect(updated.nextTracks[2].uid, 'uid1');
      expect(updated.nextTracks[3].uid, 'uid2');
    });

    test('QueueAddHandler: swiping context track to add to queue preserves it in context tracks (Spotify zfy case 25)', () {
      final initialQueue = PlayerQueue(
        nextTracks: [track1, track2],
      );

      final updated = QueueAddHandler.addTracks(
        initialQueue,
        [track1],
        mode: QueueInsertMode.addToEndOfQueue,
      );

      expect(updated.nextTracks.length, 3);
      expect(updated.nextTracks[0].uid, 'uid1');
      expect(updated.nextTracks[0].isQueued, true);
      expect(updated.nextTracks[1].uid, 'uid1');
      expect(updated.nextTracks[1].isQueued, false);
      expect(updated.nextTracks[2].uid, 'uid2');
      expect(updated.nextTracks[2].isQueued, false);
    });

    test('QueueAddHandler: playNext inserts track at index 0 of nextTracks', () {
      final initialQueue = PlayerQueue(
        nextTracks: [track1, track2],
      );

      final nextTrack = ContextTrack.builder('spotify:track:next')
          .uid('uid_next')
          .metadata({ContextTrackMetadata.keyTitle: 'Play Next Track'})
          .build();

      final updated = QueueAddHandler.addTracks(
        initialQueue,
        [nextTrack],
        mode: QueueInsertMode.playNext,
      );

      expect(updated.nextTracks.length, 3);
      expect(updated.nextTracks.first.uri, 'spotify:track:next');
      expect(updated.nextTracks.first.isQueued, true);
      expect(updated.nextTracks[1].uri, 'spotify:track:1');
    });

    test('QueueRemoveHandler: removes track matching compound queue key', () {
      final initialQueue = PlayerQueue(
        nextTracks: [track1, userQueuedTrack, track2],
      );

      final updated = QueueRemoveHandler.removeTracks(
        initialQueue,
        [userQueuedTrack],
      );

      expect(updated.nextTracks.length, 2);
      expect(updated.nextTracks.any((t) => t.uid == 'uid_q1'), false);
      expect(updated.nextTracks[0].uid, 'uid1');
      expect(updated.nextTracks[1].uid, 'uid2');
    });

    test('QueueRemoveHandler: removing duplicate track with distinct UID removes only targeted track', () {
      final track1Dup = ContextTrack.builder('spotify:track:1')
          .uid('uid1_second_instance')
          .metadata({
            ContextTrackMetadata.keyTitle: 'Track 1',
            ContextTrackMetadata.keyArtistName: 'Artist 1',
          })
          .build();

      final initialQueue = PlayerQueue(
        nextTracks: [track1, track2, track1Dup],
      );

      final updated = QueueRemoveHandler.removeTracks(
        initialQueue,
        [track1],
      );

      expect(updated.nextTracks.length, 2);
      expect(updated.nextTracks[0].uid, 'uid2');
      expect(updated.nextTracks[1].uid, 'uid1_second_instance');
    });

    test('QueueRemoveHandler: removing duplicate track with identical queueKey removes only one instance', () {
      final initialQueue = PlayerQueue(
        nextTracks: [track1, track2, track1],
      );

      final updated = QueueRemoveHandler.removeTracks(
        initialQueue,
        [track1],
      );

      expect(updated.nextTracks.length, 2);
      expect(updated.nextTracks[0].uid, 'uid2');
      expect(updated.nextTracks[1].uid, 'uid1');
    });

    test('QueueClearHandler: removes only user-queued tracks and keeps context tracks', () {
      final initialQueue = PlayerQueue(
        nextTracks: [userQueuedTrack, track1, track2],
      );

      final updated = QueueClearHandler.clearUserQueue(initialQueue);

      expect(updated.nextTracks.length, 2);
      expect(updated.nextTracks.every((t) => !t.isQueued), true);
      expect(updated.nextTracks[0].uid, 'uid1');
      expect(updated.nextTracks[1].uid, 'uid2');
    });

    test('QueueReorderHandler: moves track from bottom to top (Spotify gxl0)', () {
      final initialQueue = PlayerQueue(
        nextTracks: [track1, track2, track3],
      );

      // Move track3 (index 2) to destination index 0
      final updated = QueueReorderHandler.reorderTrack(
        playerQueue: initialQueue,
        trackToMove: track3,
        destinationVisibleIndex: 0,
      );

      expect(updated.nextTracks.length, 3);
      expect(updated.nextTracks[0].uid, 'uid3');
      expect(updated.nextTracks[1].uid, 'uid1');
      expect(updated.nextTracks[2].uid, 'uid2');
    });

    test('QueueReorderHandler: moves track from top to bottom (Spotify gxl0)', () {
      final initialQueue = PlayerQueue(
        nextTracks: [track1, track2, track3],
      );

      // Move track1 (index 0) to destination index 2
      final updated = QueueReorderHandler.reorderTrack(
        playerQueue: initialQueue,
        trackToMove: track1,
        destinationVisibleIndex: 2,
      );

      expect(updated.nextTracks.length, 3);
      expect(updated.nextTracks[0].uid, 'uid2');
      expect(updated.nextTracks[1].uid, 'uid3');
      expect(updated.nextTracks[2].uid, 'uid1');
    });

    test('QueueReorderHandler: cross-sectional reorder updates is_queued metadata (Spotify lr5/ich0)', () {
      // initial queue: [userQueuedTrack, track1, track2]
      final initialQueue = PlayerQueue(
        nextTracks: [userQueuedTrack, track1, track2],
      );

      // 1. Move context track1 (index 1) into user queue slot 0
      final movedToQueued = QueueReorderHandler.reorderTrack(
        playerQueue: initialQueue,
        trackToMove: track1,
        destinationVisibleIndex: 0,
      );

      expect(movedToQueued.nextTracks[0].uid, 'uid1');
      expect(movedToQueued.nextTracks[0].isQueued, true); // Status flipped to true!
      expect(movedToQueued.nextTracks[1].uid, 'uid_q1');
      expect(movedToQueued.nextTracks[2].uid, 'uid2');

      // 2. Move userQueuedTrack (index 0) into context section slot 2
      final movedToContext = QueueReorderHandler.reorderTrack(
        playerQueue: initialQueue,
        trackToMove: userQueuedTrack,
        destinationVisibleIndex: 2,
      );

      expect(movedToContext.nextTracks[0].uid, 'uid1');
      expect(movedToContext.nextTracks[1].uid, 'uid2');
      expect(movedToContext.nextTracks[2].uid, 'uid_q1');
      expect(movedToContext.nextTracks[2].isQueued, false); // Status flipped to false!
    });

    test('QueueTrackFilter: slices queue up to the delimiter track', () {
      final delimiterTrack = ContextTrack.create('spotify:delimiter');

      final tracks = [track1, track2, delimiterTrack];
      final visible = QueueTrackFilter.filterTracks(tracks);

      expect(visible.length, 2);
      expect(visible.contains(delimiterTrack), false);
      expect(visible[0].uid, 'uid1');
      expect(visible[1].uid, 'uid2');
    });

    test('QueueHelpers: correctly separates user queued tracks from context tracks', () {
      final queue = PlayerQueue(
        nextTracks: [userQueuedTrack, track1, track2],
      );

      final userQueued = QueueHelpers.getUserQueuedTracks(queue);
      final contextTracks = QueueHelpers.getContextTracks(queue);

      expect(userQueued.length, 1);
      expect(userQueued.first.uid, 'uid_q1');
      expect(contextTracks.length, 2);
      expect(contextTracks[0].uid, 'uid1');
      expect(contextTracks[1].uid, 'uid2');
    });
  });
}
