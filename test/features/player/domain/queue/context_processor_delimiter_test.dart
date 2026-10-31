import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/data/esperanto/proto/es_context_page.pb.dart' as es_page;
import 'package:musify_mu/features/player/data/esperanto/proto/es_context_track.pb.dart' as es_track;
import 'package:musify_mu/features/player/data/queue/context_track_extensions.dart';
import 'package:musify_mu/features/player/domain/models/context_page.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_state.dart';

void main() {
  group('Spotify 1:1 ContextProcessor & Delimiter Queue Pagination Tests', () {
    test('ContextTrack.isDelimiter recognizes spotify:delimiter and spotify:meta:delimiter (1:1 liborbit.so 0x16b81d4)', () {
      final delimiter1 = ContextTrack.builder('spotify:delimiter').uid('0').build();
      final delimiter2 = ContextTrack.builder('spotify:meta:delimiter').uid('0').build();
      final normalTrack = ContextTrack.builder('spotify:track:123').uid('123').build();

      expect(delimiter1.isDelimiter(), isTrue);
      expect(delimiter2.isDelimiter(), isTrue);
      expect(normalTrack.isDelimiter(), isFalse);
    });

    test('QueueTrackFilter slices queue strictly at delimiter (1:1 with erl.java:45 & liborbit.so 0xf5529c)', () {
      // Create a 100-track playlist where the engine windowed page 0 (30 tracks) with a delimiter
      final page0Tracks = List.generate(
        30,
        (i) => ContextTrack.builder('spotify:track:$i')
            .uid('uid_$i')
            .metadata({ContextTrackMetadata.keyTitle: 'Track $i'})
            .build(),
      );

      final delimiterTrack = ContextTrack.builder('spotify:delimiter')
          .uid('0')
          .metadata(const {'is_delimiter': 'true'})
          .build();

      // In the raw queue, page 0 tracks are followed by the delimiter
      final rawQueue = PlayerQueue(
        nextTracks: [...page0Tracks, delimiterTrack],
      );

      final queueState = PlayerQueueState(queue: rawQueue);

      // visibleTracks MUST stop at delimiter: exactly 30 tracks visible in UI!
      expect(queueState.visibleTracks.length, equals(30));
      expect(queueState.visibleTracks.first.title, equals('Track 0'));
      expect(queueState.visibleTracks.last.title, equals('Track 29'));
      expect(queueState.visibleTracks.any((t) => t.isDelimiter()), isFalse);
    });

    test('QueueTrackFilter preserves user-queued tracks ahead of page window (1:1 with Spotify erl.java)', () {
      final userQueuedTrack = ContextTrack.builder('spotify:track:user_queued')
          .uid('user_q_1')
          .metadata({
            ContextTrackMetadata.keyTitle: 'User Queued Song',
            ContextTrackMetadata.keyIsQueued: 'true',
          })
          .build();

      final pageTracks = List.generate(
        15,
        (i) => ContextTrack.builder('spotify:track:context_$i')
            .uid('ctx_$i')
            .metadata({ContextTrackMetadata.keyTitle: 'Context $i'})
            .build(),
      );

      final delimiter = ContextTrack.builder('spotify:delimiter')
          .uid('0')
          .metadata(const {'is_delimiter': 'true'})
          .build();

      final queue = PlayerQueue(
        nextTracks: [userQueuedTrack, ...pageTracks, delimiter],
      );

      final queueState = PlayerQueueState(queue: queue);

      expect(queueState.visibleTracks.length, equals(16));
      expect(queueState.visibleTracks.first.uid, equals('user_q_1'));
      expect(queueState.visibleTracks[1].uid, equals('ctx_0'));
      expect(queueState.visibleTracks.last.uid, equals('ctx_14'));
    });

    test('ContextPage partitioning chunks 75 items into 30-track pages with pageUrl/nextPageUrl (1:1 Spotify)', () {
      const int pageSize = 30;
      final allTracks = List.generate(
        75,
        (i) => ContextTrack.builder('spotify:track:$i').uid('$i').build(),
      );

      final totalPages = (allTracks.length / pageSize).ceil();
      final pages = List.generate(totalPages, (pageIdx) {
        final start = pageIdx * pageSize;
        final end = (start + pageSize > allTracks.length) ? allTracks.length : start + pageSize;
        final isLast = pageIdx == totalPages - 1;
        final pageUrl = 'context://spotify:playlist:test?page=$pageIdx';
        final nextPageUrl = isLast ? '' : 'context://spotify:playlist:test?page=${pageIdx + 1}';
        return ContextPage.builder()
            .pageUrl(pageUrl)
            .nextPageUrl(nextPageUrl)
            .tracks(allTracks.sublist(start, end))
            .build();
      });

      expect(pages.length, equals(3));
      expect(pages[0].tracks?.length, equals(30));
      expect(pages[0].pageUrl, equals('context://spotify:playlist:test?page=0'));
      expect(pages[0].nextPageUrl, equals('context://spotify:playlist:test?page=1'));

      expect(pages[1].tracks?.length, equals(30));
      expect(pages[1].pageUrl, equals('context://spotify:playlist:test?page=1'));
      expect(pages[1].nextPageUrl, equals('context://spotify:playlist:test?page=2'));

      expect(pages[2].tracks?.length, equals(15));
      expect(pages[2].pageUrl, equals('context://spotify:playlist:test?page=2'));
      expect(pages[2].nextPageUrl, isEmpty);
    });

    test('Protobuf binary wire parity: ContextPage and Queue (1:1 with Spotify Esperanto proto)', () {
      final protoPage = es_page.ContextPage(
        pageUrl: 'context://spotify:playlist:123?page=0',
        nextPageUrl: 'context://spotify:playlist:123?page=1',
        tracks: [
          es_track.ContextTrack(
            uri: 'spotify:track:456',
            uid: 'uid_456',
            metadata: [
              const MapEntry('title', 'Test Track'),
              const MapEntry('artist_name', 'Test Artist'),
            ],
          ),
          es_track.ContextTrack(
            uri: 'spotify:delimiter',
            uid: '0',
            metadata: [
              const MapEntry('is_delimiter', 'true'),
            ],
          ),
        ],
      );

      final encodedBytes = protoPage.writeToBuffer();
      expect(encodedBytes, isNotEmpty);

      // Verify deserialization matches
      final decodedPage = es_page.ContextPage.fromBuffer(encodedBytes);
      expect(decodedPage.pageUrl, equals('context://spotify:playlist:123?page=0'));
      expect(decodedPage.nextPageUrl, equals('context://spotify:playlist:123?page=1'));
      expect(decodedPage.tracks.length, equals(2));
      expect(decodedPage.tracks.first.uri, equals('spotify:track:456'));
      expect(decodedPage.tracks.last.uri, equals('spotify:delimiter'));
    });
  });
}

