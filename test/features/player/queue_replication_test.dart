import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/features/local_music/domain/entities/domain_track.dart';
import 'package:musify_mu/features/local_music/domain/local_context_resolver.dart';
import 'package:musify_mu/features/player/application/queue/queue_bloc.dart';
import 'package:musify_mu/features/player/application/queue/queue_event.dart';
import 'package:musify_mu/features/player/domain/models/command_options.dart';
import 'package:musify_mu/features/player/domain/models/context_page.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';
import 'package:musify_mu/features/player/domain/models/prefetch_level.dart';
import 'package:musify_mu/features/player/domain/models/prepare_play_options.dart';
import 'package:musify_mu/features/player/domain/models/set_queue_command.dart';
import 'package:musify_mu/features/player/domain/models/update_page_command.dart';
import 'package:musify_mu/features/player/domain/queue/queue_filter_helper.dart';
import 'package:musify_mu/features/player/domain/queue/queue_mutator.dart';

void main() {
  group('Spotify Queue 1:1 Domain & Operational Logic Tests', () {
    test(
      'ContextTrack models 1:1 properties from com.spotify.player.model',
      () {
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
      },
    );

    test(
      'PlayerQueue nextTracks combines userQueue and contextTracks in order',
      () {
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

        const queue = PlayerQueue(nextTracks: [u1, c1, c2], revision: '1');

        expect(queue.nextTracks.length, equals(3));
        expect(queue.nextTracks[0].uid, equals('uid_u1'));
        expect(queue.nextTracks[1].uid, equals('uid_c1'));
        expect(queue.nextTracks[2].uid, equals('uid_c2'));
        expect(queue.hasUserQueue, isTrue);
        expect(queue.hasContextTracks, isTrue);
      },
    );

    test(
      'Cross-section reordering converts context track to user-queued track',
      () {
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
      },
    );

    test(
      'Cross-section reordering converts user-queued track to context track',
      () {
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
      },
    );

    test('Track removal deletes from contextTracks or userQueue by uid', () {
      const u0 = ContextTrack(uri: 'u0', uid: 'uid_u0', isQueued: true);
      const c0 = ContextTrack(uri: 'c0', uid: 'uid_c0', isQueued: false);

      const queue = PlayerQueue(nextTracks: [u0, c0], revision: '1');

      // Remove context track c0
      final updatedContext = queue.contextTracks
          .where((t) => t.uid != 'uid_c0')
          .toList();
      final updatedQueue = queue.copyWith(
        contextTracks: updatedContext,
        revision: '2',
      );

      expect(updatedQueue.contextTracks, isEmpty);
      expect(updatedQueue.userQueue.length, equals(1));
      expect(updatedQueue.revision, equals('2'));
    });

    group('QueueFilterHelper 1:1 with hxl0.java & s5j.java', () {
      test('getUserQueue returns only isQueued tracks', () {
        const u1 = ContextTrack(uri: 'u1', uid: 'uid_u1', isQueued: true);
        const u2 = ContextTrack(uri: 'u2', uid: 'uid_u2', isQueued: true);
        const c1 = ContextTrack(uri: 'c1', uid: 'uid_c1', isQueued: false);
        const queue = PlayerQueue(revision: '1', nextTracks: [u1, u2, c1]);

        final userQueue = QueueFilterHelper.getUserQueue(queue);
        expect(userQueue.length, equals(2));
        expect(userQueue.first.uid, equals('uid_u1'));
        expect(userQueue.last.uid, equals('uid_u2'));
      });

      test('getContextQueue returns non-queued tracks', () {
        const u1 = ContextTrack(uri: 'u1', uid: 'uid_u1', isQueued: true);
        const c1 = ContextTrack(uri: 'c1', uid: 'uid_c1', isQueued: false);
        const c2 = ContextTrack(uri: 'c2', uid: 'uid_c2', isQueued: false);
        const queue = PlayerQueue(revision: '1', nextTracks: [u1, c1, c2]);

        final contextQueue = QueueFilterHelper.getContextQueue(queue);
        expect(contextQueue.length, equals(2));
        expect(contextQueue.first.uid, equals('uid_c1'));
        expect(contextQueue.last.uid, equals('uid_c2'));
      });

      test('setIsQueued synchronizes both boolean and metadata map', () {
        const track = ContextTrack(uri: 'u1', uid: 'uid_u1', isQueued: false);
        final queuedTrack = QueueFilterHelper.setIsQueued(track, true);
        expect(queuedTrack.isQueued, isTrue);
        expect(queuedTrack.metadata['is_queued'], equals('true'));

        final unqueuedTrack = QueueFilterHelper.setIsQueued(queuedTrack, false);
        expect(unqueuedTrack.isQueued, isFalse);
        expect(unqueuedTrack.metadata['is_queued'], equals('false'));
      });
    });

    group('QueueMutator 1:1 with zfy.java, lwp0.java, and pml0.java', () {
      test(
        'addToQueue appends to user queue, deduplicates, and increments revision',
        () {
          const existingU1 = ContextTrack(
            uri: 'u1',
            uid: 'uid_u1',
            isQueued: true,
          );
          const existingC1 = ContextTrack(
            uri: 'c1',
            uid: 'uid_c1',
            isQueued: false,
          );
          const queue = PlayerQueue(
            revision: '1',
            nextTracks: [existingU1, existingC1],
          );

          const newTrack = ContextTrack(
            uri: 'u2',
            uid: 'uid_u2',
            isQueued: false,
          );
          const duplicateTrack = ContextTrack(
            uri: 'u1',
            uid: 'uid_u1',
            isQueued: false,
          );

          final updated = QueueMutator.addToQueue(queue, [
            duplicateTrack,
            newTrack,
          ]);
          expect(updated.revision, equals('2'));
          expect(updated.nextTracks.length, equals(3));
          expect(updated.nextTracks[0].uid, equals('uid_u1'));
          expect(updated.nextTracks[0].isQueued, isTrue);
          expect(updated.nextTracks[1].uid, equals('uid_u2'));
          expect(updated.nextTracks[1].isQueued, isTrue);
          expect(updated.nextTracks[2].uid, equals('uid_c1'));
          expect(updated.nextTracks[2].isQueued, isFalse);
        },
      );

      test(
        'addToQueue creates user-queued track while preserving context queue (1:1 with uvn.java:58)',
        () {
          const existingC1 = ContextTrack(
            uri: 'track_1',
            uid: 'context_uid_1',
            isQueued: false,
          );
          const existingC2 = ContextTrack(
            uri: 'track_2',
            uid: 'context_uid_2',
            isQueued: false,
          );
          const queue = PlayerQueue(
            revision: '1',
            nextTracks: [existingC1, existingC2],
          );

          const queuedC1 = ContextTrack(
            uri: 'track_1',
            uid: 'track_1_q_1',
            isQueued: true,
          );

          final updated = QueueMutator.addToQueue(queue, [queuedC1]);
          expect(updated.revision, equals('2'));
          expect(updated.nextTracks.length, equals(3));
          expect(updated.nextTracks[0].uid, equals('track_1_q_1'));
          expect(updated.nextTracks[0].isQueued, isTrue);
          expect(updated.nextTracks[1].uid, equals('context_uid_1'));
          expect(updated.nextTracks[1].isQueued, isFalse);
          expect(updated.nextTracks[2].uid, equals('context_uid_2'));
          expect(updated.nextTracks[2].isQueued, isFalse);
        },
      );

      test('playAsNext prepends to front of queue with isQueued = true', () {
        const existingU1 = ContextTrack(
          uri: 'u1',
          uid: 'uid_u1',
          isQueued: true,
        );
        const existingC1 = ContextTrack(
          uri: 'c1',
          uid: 'uid_c1',
          isQueued: false,
        );
        const queue = PlayerQueue(
          revision: '5',
          nextTracks: [existingU1, existingC1],
        );

        const nextTrack = ContextTrack(
          uri: 'urgent',
          uid: 'uid_urgent',
          isQueued: false,
        );
        final updated = QueueMutator.playAsNext(queue, [nextTrack]);

        expect(updated.revision, equals('6'));
        expect(updated.nextTracks.first.uid, equals('uid_urgent'));
        expect(updated.nextTracks.first.isQueued, isTrue);
        expect(updated.nextTracks[1].uid, equals('uid_u1'));
      });

      test('reorder stamps items according to partition placement', () {
        const u1 = ContextTrack(uri: 'u1', uid: 'uid_u1', isQueued: true);
        const c1 = ContextTrack(uri: 'c1', uid: 'uid_c1', isQueued: false);
        const queue = PlayerQueue(revision: '10', nextTracks: [u1, c1]);

        final updated = QueueMutator.reorder(
          queue,
          userQueuePartition: [c1],
          contextQueuePartition: [u1],
        );

        expect(updated.revision, equals('11'));
        expect(updated.nextTracks[0].uid, equals('uid_c1'));
        expect(updated.nextTracks[0].isQueued, isTrue);
        expect(updated.nextTracks[1].uid, equals('uid_u1'));
        expect(updated.nextTracks[1].isQueued, isFalse);
      });

      test('removeTrack removes track by uid and increments revision', () {
        const u1 = ContextTrack(uri: 'u1', uid: 'uid_u1', isQueued: true);
        const c1 = ContextTrack(uri: 'c1', uid: 'uid_c1', isQueued: false);
        const queue = PlayerQueue(revision: '3', nextTracks: [u1, c1]);

        final updated = QueueMutator.removeTrack(queue, 'uid_u1');
        expect(updated.revision, equals('4'));
        expect(updated.nextTracks.length, equals(1));
        expect(updated.nextTracks.first.uid, equals('uid_c1'));
      });

      test('clearUserQueue purges user queue while keeping context tracks', () {
        const u1 = ContextTrack(uri: 'u1', uid: 'uid_u1', isQueued: true);
        const u2 = ContextTrack(uri: 'u2', uid: 'uid_u2', isQueued: true);
        const c1 = ContextTrack(uri: 'c1', uid: 'uid_c1', isQueued: false);
        const queue = PlayerQueue(revision: '7', nextTracks: [u1, u2, c1]);

        final updated = QueueMutator.clearUserQueue(queue);
        expect(updated.revision, equals('8'));
        expect(updated.userQueue, isEmpty);
        expect(updated.contextTracks.length, equals(1));
        expect(updated.contextTracks.first.uid, equals('uid_c1'));
      });

      test(
        'advancePlayhead promotes next track and moves current to history',
        () {
          const current = ContextTrack(uri: 'current', uid: 'uid_curr');
          const next1 = ContextTrack(
            uri: 'next1',
            uid: 'uid_next1',
            isQueued: true,
          );
          const next2 = ContextTrack(
            uri: 'next2',
            uid: 'uid_next2',
            isQueued: false,
          );
          const queue = PlayerQueue(
            revision: '1',
            track: current,
            nextTracks: [next1, next2],
            prevTracks: [],
          );

          final updated = QueueMutator.advancePlayhead(queue);
          expect(updated.revision, equals('2'));
          expect(updated.track?.uid, equals('uid_next1'));
          expect(updated.nextTracks.length, equals(1));
          expect(updated.nextTracks.first.uid, equals('uid_next2'));
          expect(updated.prevTracks.length, equals(1));
          expect(updated.prevTracks.first.uid, equals('uid_curr'));
        },
      );
    });

    group('PrefetchLevel & PreparePlayOptions', () {
      test('PrefetchLevel enum contains none and media', () {
        expect(PrefetchLevel.values, contains(PrefetchLevel.none));
        expect(PrefetchLevel.values, contains(PrefetchLevel.media));
      });

      test('PreparePlayOptions defaults and properties', () {
        const options = PreparePlayOptions(
          prefetchLevel: PrefetchLevel.media,
          alwaysPlaySomething: true,
          skipToTrackUid: 'uid_target',
        );
        expect(options.prefetchLevel, equals(PrefetchLevel.media));
        expect(options.alwaysPlaySomething, isTrue);
        expect(options.skipToTrackUid, equals('uid_target'));
      });
    });

    group('Precise Reordering Tests (Downward and Upward)', () {
      test(
        'Dragging downward from index 0 to index 3 places track exactly at index 3',
        () {
          const t0 = ContextTrack(uri: 't0', uid: 'uid_0');
          const t1 = ContextTrack(uri: 't1', uid: 'uid_1');
          const t2 = ContextTrack(uri: 't2', uid: 'uid_2');
          const t3 = ContextTrack(uri: 't3', uid: 'uid_3');
          const t4 = ContextTrack(uri: 't4', uid: 'uid_4');
          final list = [t0, t1, t2, t3, t4];

          // Moving 0 to 3:
          final moved = list.removeAt(0);
          list.insert(3, moved);

          expect(list[3].uid, equals('uid_0'));
          expect(
            list.map((t) => t.uid).toList(),
            equals(['uid_1', 'uid_2', 'uid_3', 'uid_0', 'uid_4']),
          );
        },
      );

      test(
        'Dragging upward from index 3 to index 0 places track exactly at index 0',
        () {
          const t0 = ContextTrack(uri: 't0', uid: 'uid_0');
          const t1 = ContextTrack(uri: 't1', uid: 'uid_1');
          const t2 = ContextTrack(uri: 't2', uid: 'uid_2');
          const t3 = ContextTrack(uri: 't3', uid: 'uid_3');
          const t4 = ContextTrack(uri: 't4', uid: 'uid_4');
          final list = [t0, t1, t2, t3, t4];

          // Moving 3 to 0:
          final moved = list.removeAt(3);
          list.insert(0, moved);

          expect(list[0].uid, equals('uid_3'));
          expect(
            list.map((t) => t.uid).toList(),
            equals(['uid_3', 'uid_0', 'uid_1', 'uid_2', 'uid_4']),
          );
        },
      );

      test(
        'QueueMutator.reorderTrack 1:1 with gxl0.java: downward drag across partition',
        () {
          // Initial upcoming queue:
          // Index 0: u0 (user queue)
          // Index 1: u1 (user queue)
          // Index 2: c0 (context queue)
          // Index 3: c1 (context queue)
          const u0 = ContextTrack(
            uri: 'u0',
            uid: 'uid_u0',
            isQueued: true,
            provider: 'queue',
          );
          const u1 = ContextTrack(
            uri: 'u1',
            uid: 'uid_u1',
            isQueued: true,
            provider: 'queue',
          );
          const c0 = ContextTrack(
            uri: 'c0',
            uid: 'uid_c0',
            isQueued: false,
            provider: 'context',
          );
          const c1 = ContextTrack(
            uri: 'c1',
            uid: 'uid_c1',
            isQueued: false,
            provider: 'context',
          );
          const queue = PlayerQueue(
            revision: '1',
            nextTracks: [u0, u1, c0, c1],
          );

          // Drag u0 downward from index 0 to index 2 (into context queue partition)
          final result = QueueMutator.reorderTrack(
            queue,
            draggedTrack: u0,
            targetVisibleIndex: 2,
            isTargetInUserQueue: false,
          );

          // Target index 2 was originally c0. u0 should be placed at c0's position.
          // Sequence should be: [u1, u0, c0, c1] or [u1, c0, u0, c1] depending on slot.
          // In gxl0.java: targetTrackUid = visibleTracks[2].uid = 'uid_c0'.
          // Full list indices: i2 (u0) = 0, i (c0) = 2.
          // removeAt(0) -> [u1, c0, c1].
          // insert(2, u0) -> [u1, c0, u0, c1].
          expect(
            result.nextTracks.map((t) => t.uid).toList(),
            equals(['uid_u1', 'uid_c0', 'uid_u0', 'uid_c1']),
          );
          // Stamped as context track:
          final movedTrack = result.nextTracks.firstWhere(
            (t) => t.uid == 'uid_u0',
          );
          expect(movedTrack.isQueued, isFalse);
          expect(movedTrack.provider, equals('context'));
        },
      );

      test(
        'QueueMutator.reorderTrack 1:1 with gxl0.java: upward drag across partition',
        () {
          const u0 = ContextTrack(
            uri: 'u0',
            uid: 'uid_u0',
            isQueued: true,
            provider: 'queue',
          );
          const c0 = ContextTrack(
            uri: 'c0',
            uid: 'uid_c0',
            isQueued: false,
            provider: 'context',
          );
          const c1 = ContextTrack(
            uri: 'c1',
            uid: 'uid_c1',
            isQueued: false,
            provider: 'context',
          );
          const queue = PlayerQueue(revision: '1', nextTracks: [u0, c0, c1]);

          // Drag c1 (visible index 2) upward to index 0 (into user queue, before u0)
          final result = QueueMutator.reorderTrack(
            queue,
            draggedTrack: c1,
            targetVisibleIndex: 0,
            isTargetInUserQueue: true,
          );

          // targetTrackUid = visibleTracks[0].uid = 'uid_u0'.
          // i2 (c1) = 2, i (u0) = 0.
          // removeAt(2) -> [u0, c0].
          // insert(0, c1) -> [c1, u0, c0].
          expect(
            result.nextTracks.map((t) => t.uid).toList(),
            equals(['uid_c1', 'uid_u0', 'uid_c0']),
          );
          final movedTrack = result.nextTracks.firstWhere(
            (t) => t.uid == 'uid_c1',
          );
          expect(movedTrack.isQueued, isTrue);
          expect(movedTrack.provider, equals('queue'));
        },
      );
    });

    group('UpdatePageCommand and Context Pagination 1:1 with Spotify', () {
      test(
        'QueueMutator.updatePage cleanly appends page tracks without delimiter',
        () {
          const u1 = ContextTrack(uri: 'u1', uid: 'uid_u1', isQueued: true);
          const c1 = ContextTrack(uri: 'c1', uid: 'uid_c1', isQueued: false);
          const queue = PlayerQueue(revision: '10', nextTracks: [u1, c1]);

          const pageTrack1 = ContextTrack(
            uri: 'page1_t1',
            uid: 'uid_p1_t1',
            isQueued: false,
          );
          const pageTrack2 = ContextTrack(
            uri: 'page1_t2',
            uid: 'uid_p1_t2',
            isQueued: false,
          );
          const newPage = ContextPage(
            pageUrl: 'context://page/1',
            nextPageUrl: 'context://page/2',
            tracks: [pageTrack1, pageTrack2],
          );

          final command = UpdatePageCommand.create(newPage);
          expect(command.page, equals(newPage));

          final updatedQueue = QueueMutator.updatePage(queue, command.page);

          expect(updatedQueue.revision, equals('11'));
          // nextTracks should now be: [u1, c1, pageTrack1, pageTrack2]
          expect(updatedQueue.nextTracks.length, equals(4));
          expect(updatedQueue.nextTracks[0].uid, equals('uid_u1'));
          expect(updatedQueue.nextTracks[1].uid, equals('uid_c1'));
          expect(updatedQueue.nextTracks[2].uid, equals('uid_p1_t1'));
          expect(updatedQueue.nextTracks[3].uid, equals('uid_p1_t2'));

          // Visible context queue must contain pageTrack1 and pageTrack2
          final visibleContext = QueueFilterHelper.getContextQueue(
            updatedQueue,
          );
          expect(visibleContext.length, equals(3));
          expect(
            visibleContext.map((t) => t.uid).toList(),
            equals(['uid_c1', 'uid_p1_t1', 'uid_p1_t2']),
          );
        },
      );

      test(
        'LocalContextResolver chunks offline tracks without delimiter pseudo-tracks',
        () {
          final mockTracks = List.generate(
            120,
            (i) => {
              'songId': 1000 + i,
              'title': 'Local Song $i',
              'artist': 'Artist ${i % 5}',
              'album': 'Album ${i % 3}',
              'duration': 180000,
              'dataPath': '/storage/emulated/0/Music/song_$i.mp3',
            },
          );

          final context = LocalContextResolver.buildContext(
            rawTracks: mockTracks,
            pageSize: 50,
          );

          // 120 tracks / 50 per page = 3 pages (50, 50, 20)
          expect(context.pages.length, equals(3));
          expect(context.pages[0].tracks?.length, equals(50));
          expect(
            context.pages[0].nextPageUrl,
            equals('context://local:all_tracks?page=1'),
          );
          expect(context.pages[1].tracks?.length, equals(50));
          expect(
            context.pages[1].nextPageUrl,
            equals('context://local:all_tracks?page=2'),
          );
          expect(context.pages[2].tracks?.length, equals(20));
          expect(context.pages[2].nextPageUrl, isEmpty);

          // Start playback at song index 5 (Page 0)
          final initialQueue = LocalContextResolver.createInitialQueue(
            context: context,
            initialTrackIndex: 5,
            pageSize: 50,
          );

          expect(initialQueue.track?.title, equals('Local Song 5'));
          // Upcoming in page 0: songs 6..49 (44 tracks) cleanly without delimiter
          expect(initialQueue.nextTracks.length, equals(44));

          // QueueFilterHelper returns all upcoming context tracks
          final visibleUpcoming = QueueFilterHelper.getContextQueue(
            initialQueue,
          );
          expect(visibleUpcoming.length, equals(44));
          expect(visibleUpcoming.first.title, equals('Local Song 6'));
          expect(visibleUpcoming.last.title, equals('Local Song 49'));
        },
      );

      test(
        'LocalContextResolver.buildContextFromDomainTracks chunks DomainTracks into 50-track pages',
        () {
          final domainTracks = List.generate(
            110,
            (i) => DomainTrack(
              id: 'track_$i',
              title: 'Track Title $i',
              artist: 'Artist ${i % 4}',
              album: 'Album ${i % 2}',
              duration: 200000,
              dataPath: '/storage/music/track_$i.flac',
              songId: 5000 + i,
              dateModified: DateTime.fromMillisecondsSinceEpoch(
                1700000000000 + i,
              ),
            ),
          );

          final context = LocalContextResolver.buildContextFromDomainTracks(
            tracks: domainTracks,
            pageSize: 50,
          );

          expect(context.pages.length, equals(3));
          expect(context.pages[0].tracks?.length, equals(50));
          expect(context.pages[1].tracks?.length, equals(50));
          expect(context.pages[2].tracks?.length, equals(10));

          // Verify ContextTrack properties matching DomainTrack
          final firstTrack = context.pages[0].tracks!.first;
          expect(firstTrack.uri, equals('track_0'));
          expect(firstTrack.uid, equals('local_uid_5000_0'));
          expect(
            firstTrack.metadata['dataPath'],
            equals('/storage/music/track_0.flac'),
          );
          expect(firstTrack.isQueued, isFalse);
          expect(firstTrack.provider, equals('context'));

          // Verify resolver can lookup pages by url
          final resolvedPage1 = LocalContextResolver.resolvePage(
            context.pages[1].pageUrl,
          );
          expect(resolvedPage1, isNotNull);
          expect(resolvedPage1?.tracks?.length, equals(50));
          expect(resolvedPage1?.tracks?.first.uid, equals('local_uid_5050_50'));
        },
      );

      test('SetQueueCommand and CommandOptions 1:1 modeling', () {
        const u0 = ContextTrack(uri: 'u0', uid: 'uid_u0', isQueued: true);
        const queue = PlayerQueue(revision: '1', nextTracks: [u0]);
        const options = CommandOptions(
          overrideRestrictions: true,
          onlyForPlaybackId: 'pb_1',
        );

        final cmd = SetQueueCommand.builder(queue).options(options).build();
        expect(cmd.nextTracks.length, equals(1));
        expect(cmd.options.overrideRestrictions, isTrue);
        expect(cmd.options.onlyForPlaybackId, equals('pb_1'));
      });

      test(
        'LocalContextResolver.playDomainTracks loads only 50-track page chunk into player',
        () async {
          final mockTracks = List.generate(
            424,
            (i) => DomainTrack(
              id: 'local_track_$i',
              title: 'Song $i',
              artist: 'Artist ${i % 10}',
              album: 'Album ${i % 5}',
              duration: 210000,
              dataPath: '/storage/emulated/0/Music/song_$i.mp3',
              songId: 2000 + i,
            ),
          );

          final fakeController = _FakePlaybackController();

          // 1. Play song 0 -> Should only pass 50 tracks of page 0 to playQueue
          await LocalContextResolver.playDomainTracks(
            playback: fakeController,
            tracks: mockTracks,
            initialTrackIndex: 0,
          );

          expect(fakeController.playQueueItems.length, equals(50));
          expect(fakeController.playQueueIndex, equals(0));
          expect(
            fakeController.playQueueItems.first.id,
            equals('local_track_0'),
          );
          expect(
            fakeController.playQueueItems.last.id,
            equals('local_track_49'),
          );

          // 2. Play song 120 -> Should pass 50 tracks of page 2 (100..149) with offset 20
          await LocalContextResolver.playDomainTracks(
            playback: fakeController,
            tracks: mockTracks,
            initialTrackIndex: 120,
          );

          expect(fakeController.playQueueItems.length, equals(50));
          expect(fakeController.playQueueIndex, equals(20));
          expect(
            fakeController.playQueueItems.first.id,
            equals('local_track_100'),
          );
          expect(
            fakeController.playQueueItems[20].id,
            equals('local_track_120'),
          );
          expect(
            fakeController.playQueueItems.last.id,
            equals('local_track_149'),
          );
        },
      );

      test(
        'QueueBloc cross-partition dragging removes isQueued without badge reappearing on sync',
        () async {
          final fakeController = _FakePlaybackController();
          final bloc = QueueBloc(playbackController: fakeController);
          bloc.add(const QueueStarted());
          await pumpEventQueue();

          // Simulate initial 5-track queue in playbackController
          final mediaItems = List.generate(
            5,
            (i) => MediaItem(
              id: 'track_$i',
              title: 'Track $i',
              artist: 'Artist',
              extras: {'uid': 'uid_$i', 'is_queued': false},
            ),
          );

          fakeController.simulateData(mediaItems, mediaItems[0]);
          await pumpEventQueue();

          // Now user adds track_3 to queue
          final contextTrack3 = ContextTrack.fromMediaItem(mediaItems[3]);
          bloc.add(QueueTrackAdded(contextTrack3));
          await pumpEventQueue();

          expect(bloc.state.hasUserQueue, isTrue);
          expect(bloc.state.queue.userQueue.length, equals(1));
          final queuedItemUid = bloc.state.queue.userQueue.first.uid;
          expect(bloc.state.queue.userQueue.first.isQueued, isTrue);

          // Visible upcoming: [queuedItem (idx 0), track_1 (idx 1), track_2 (idx 2), ...]
          // User drags queuedItem from index 0 to index 2 (into context queue)
          bloc.add(const QueueReordered(0, 2));
          await pumpEventQueue();

          // Dragged item must now have isQueued = false
          final reorderedItem = bloc.state.queue.nextTracks.firstWhere(
            (t) => t.uid == queuedItemUid,
          );
          expect(reorderedItem.isQueued, isFalse);
          expect(bloc.state.hasUserQueue, isFalse);

          // When audio engine confirms setNextTracks and emits updated queue stream:
          fakeController.simulateData([
            mediaItems[0],
            ...fakeController.nextTracks,
          ], mediaItems[0]);
          await pumpEventQueue();

          // The item must STAY unqueued! Badge must not come back!
          final postSyncItem = bloc.state.queue.nextTracks.firstWhere(
            (t) => t.uid == queuedItemUid,
          );
          expect(postSyncItem.isQueued, isFalse);
          expect(bloc.state.hasUserQueue, isFalse);

          await bloc.close();
          fakeController.dispose();
        },
      );

      test(
        'QueueBloc handles QueueNextPageRequested and updates queue with next page',
        () async {
          final mockTracks = List.generate(
            120,
            (i) => DomainTrack(
              id: 'page_track_$i',
              title: 'Track $i',
              artist: 'Artist',
              duration: 180000,
              songId: 3000 + i,
            ),
          );

          final fakeController = _FakePlaybackController();
          final context = LocalContextResolver.buildContextFromDomainTracks(
            tracks: mockTracks,
          );

          final bloc = QueueBloc(playbackController: fakeController);
          bloc.add(const QueueStarted());
          await pumpEventQueue();

          final page0Items = context.pages[0].tracks!
              .map((t) => t.toMediaItem())
              .toList();
          fakeController.simulateData(page0Items, page0Items[0]);
          await pumpEventQueue();

          expect(bloc.state.queue.contextTracks.length, equals(49));
          expect(
            bloc.state.queue.nextTracks.any((t) => t.isDelimiter),
            isFalse,
          );

          // Dispatch QueueNextPageRequested
          bloc.add(const QueueNextPageRequested());
          await pumpEventQueue();

          // The next 50 tracks should now be loaded into the queue
          expect(bloc.state.queue.nextTracks.length, greaterThan(50));
          expect(fakeController.nextTracks.length, greaterThan(50));

          await bloc.close();
          fakeController.dispose();
        },
      );

      test(
        'QueueBloc fast-path preserves revision when syncing with audio engine',
        () async {
          final fakeController = _FakePlaybackController();
          final bloc = QueueBloc(playbackController: fakeController);
          bloc.add(const QueueStarted());
          await pumpEventQueue();

          const mediaA = MediaItem(
            id: 'track:a',
            title: 'Track A',
            artist: 'Artist',
          );
          const mediaB = MediaItem(
            id: 'track:b',
            title: 'Track B',
            artist: 'Artist',
          );
          const mediaC = MediaItem(
            id: 'track:c',
            title: 'Track C',
            artist: 'Artist',
          );

          fakeController.simulateData([mediaA, mediaB, mediaC], mediaA);
          await pumpEventQueue();

          final initialRevision = bloc.state.queue.revision;

          // Simulate audio engine queue stream emission with the same tracks
          fakeController.simulateData([mediaA, mediaB, mediaC], mediaA);
          await pumpEventQueue();

          // Revision must be preserved so ReorderableListView does not reset or jump
          expect(bloc.state.queue.revision, equals(initialRevision));

          await bloc.close();
          fakeController.dispose();
        },
      );

      test(
        'QueueTrackAdded updates state immediately and does not get reset by backend setNextTracks response',
        () async {
          final fakeController = _FakePlaybackController();
          final bloc = QueueBloc(playbackController: fakeController);
          bloc.add(const QueueStarted());
          await pumpEventQueue();

          const mediaA = MediaItem(
            id: 'track:a',
            title: 'Track A',
            artist: 'Artist',
          );
          const mediaB = MediaItem(
            id: 'track:b',
            title: 'Track B',
            artist: 'Artist',
          );
          const mediaC = MediaItem(
            id: 'track:c',
            title: 'Track C',
            artist: 'Artist',
          );

          fakeController.simulateData([mediaA, mediaB, mediaC], mediaA);
          await pumpEventQueue();

          expect(bloc.state.queue.userQueue, isEmpty);
          expect(bloc.state.queue.contextTracks.length, equals(2));

          // Swipe mediaC to add to queue
          final contextC = bloc.state.queue.contextTracks.firstWhere(
            (t) => t.uri == 'track:c',
          );
          bloc.add(QueueTrackAdded(contextC));
          await pumpEventQueue();

          // 1. Immediately in user queue
          expect(bloc.state.queue.userQueue.length, equals(1));
          final queuedItem = bloc.state.queue.userQueue.first;
          expect(queuedItem.uri, equals('track:c'));
          expect(queuedItem.isQueued, isTrue);

          // 2. Controller received nextTracks immediately without delay
          expect(fakeController.nextTracks.length, equals(3));
          expect(fakeController.nextTracks.first.id, equals('track:c'));

          // 3. Audio engine emits updated queue stream back to bloc
          fakeController.simulateData([
            mediaA,
            ...fakeController.nextTracks,
          ], mediaA);
          await pumpEventQueue();

          // 4. Queued item MUST NOT be reset or deleted!
          expect(bloc.state.queue.userQueue.length, equals(1));
          expect(bloc.state.queue.userQueue.first.uri, equals('track:c'));
          expect(bloc.state.queue.userQueue.first.isQueued, isTrue);
          expect(bloc.state.queue.nextTracks.first.uri, equals('track:c'));

          await bloc.close();
          fakeController.dispose();
        },
      );

      test(
        'QueueTrackTapped with no user-queued tracks immediately slices nextTracks to tracks below tapped track',
        () async {
          final fakeController = _FakePlaybackController();
          final bloc = QueueBloc(playbackController: fakeController);
          bloc.add(const QueueStarted());
          await pumpEventQueue();

          final mediaItems = List.generate(
            20,
            (i) =>
                MediaItem(id: 'track:$i', title: 'Track $i', artist: 'Artist'),
          );

          fakeController.simulateData(mediaItems, mediaItems.first);
          await pumpEventQueue();

          expect(bloc.state.queue.userQueue, isEmpty);
          expect(bloc.state.queue.contextTracks.length, equals(19));

          // Tap Track 14 (which is at index 13 of nextTracks)
          final tappedTrack = bloc.state.queue.contextTracks.firstWhere(
            (t) => t.uri == 'track:14',
          );
          bloc.add(QueueTrackTapped(track: tappedTrack, absoluteIndex: 14));
          await pumpEventQueue();

          // Immediately after tap (before 375ms delay and before audio engine responds):
          // 1. Now playing should be track:14
          expect(bloc.state.nowPlaying?.uri, equals('track:14'));
          // 2. Upcoming tracks should ONLY contain tracks below track:14 (i.e. tracks 15..19)
          expect(bloc.state.queue.nextTracks.length, equals(5));
          expect(bloc.state.queue.nextTracks.first.uri, equals('track:15'));
          expect(bloc.state.queue.nextTracks.last.uri, equals('track:19'));
          // 3. None of the skipped tracks (track:1..14) should be in nextTracks!
          expect(
            bloc.state.queue.nextTracks.any((t) => t.uri == 'track:1'),
            isFalse,
          );
          expect(
            bloc.state.queue.nextTracks.any((t) => t.uri == 'track:13'),
            isFalse,
          );
          expect(
            bloc.state.queue.nextTracks.any((t) => t.uri == 'track:14'),
            isFalse,
          );

          await bloc.close();
          fakeController.dispose();
        },
      );
    });
  });
}

class _FakePlaybackController implements PlaybackController {
  final _mediaItemController = StreamController<MediaItem?>.broadcast();
  final _playbackStateController = StreamController<PlaybackState>.broadcast();
  final _queueController = StreamController<List<MediaItem>>.broadcast();
  final _sequenceStateController = StreamController<SequenceState?>.broadcast();
  final _playerStateController = StreamController<PlayerState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _bufferedPositionController = StreamController<Duration>.broadcast();

  List<MediaItem> playQueueItems = [];
  int playQueueIndex = -1;
  List<MediaItem> nextTracks = [];
  MediaItem? _current;
  List<MediaItem> _currentQueue = [];
  SequenceState? _sequenceState;
  final PlayerState _playerState = PlayerState(true, ProcessingState.ready);

  void simulateData(List<MediaItem> queue, MediaItem current) {
    _currentQueue = queue;
    _current = current;
    _queueController.add(queue);
    _mediaItemController.add(current);
  }

  void dispose() {
    _mediaItemController.close();
    _playbackStateController.close();
    _queueController.close();
    _sequenceStateController.close();
    _playerStateController.close();
    _positionController.close();
    _bufferedPositionController.close();
  }

  @override
  Stream<SequenceState?> get sequenceStateStream => _sequenceStateController.stream;
  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  @override
  Stream<Duration> get positionStream => _positionController.stream;
  @override
  Stream<Duration> get bufferedPositionStream => _bufferedPositionController.stream;
  @override
  SequenceState? get sequenceState => _sequenceState;
  @override
  PlayerState get playerState => _playerState;

  @override
  Stream<MediaItem?> get mediaItem => _mediaItemController.stream;
  @override
  Stream<PlaybackState> get playbackState => _playbackStateController.stream;
  @override
  Stream<List<MediaItem>> get queue => _queueController.stream;
  @override
  MediaItem? get currentMediaItem => _current;
  @override
  int get audioWindowEndIndex => _currentQueue.length;

  @override
  Future<void> playQueue(List<MediaItem> tracks, int initialIndex) async {
    playQueueItems = tracks;
    playQueueIndex = initialIndex;
  }

  @override
  Future<void> setNextTracks(List<MediaItem> upcomingTracks) async {
    nextTracks = upcomingTracks;
    final current = _current;
    if (current != null) {
      _currentQueue = [current, ...upcomingTracks];
      _queueController.add(_currentQueue);
    }
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {}
  @override
  Future<void> removeQueueItemAt(int index) async {}
  @override
  Future<void> removeQueueRange(int startIndex, int endIndex) async {}
  @override
  Future<void> reorderQueueItem(int fromIndex, int toIndex) async {}
  @override
  Future<void> updateCurrentMediaItem(MediaItem item) async {}
  @override
  Future<void> refreshArtwork() async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> skipToNext() async {}
  @override
  Future<void> skipToPrevious() async {}
  @override
  Future<void> skipToQueueItem(int index) async {}
  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode mode) async {}
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) async {}
}
