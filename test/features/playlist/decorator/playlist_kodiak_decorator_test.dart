import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/media/extended_metadata_service.dart';
import 'package:musify_mu/features/playlist/data/decorator/playlist_kodiak_decorator.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_entity.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_item.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_metadata.dart';
import 'package:musify_mu/features/playlist/domain/models/track_item_metadata.dart';

class _MockExtendedMetadataService implements ExtendedMetadataService {
  final Map<String, TrackMeta> cannedMetadata;
  int singleRequestCallCount = 0;
  List<String> lastRequestedUris = [];

  _MockExtendedMetadataService(this.cannedMetadata);

  @override
  Future<Map<String, TrackMeta>> fetchTracksSingleRequest(List<String> uris) async {
    singleRequestCallCount++;
    lastRequestedUris = List.from(uris);
    return cannedMetadata;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PlaylistKodiakDecorator Single Flight Decoration Tests', () {
    test('Decorates playlist items and recalculates totalDurationMs in a single request', () async {
      final canned = {
        'spotify:track:track1': const TrackMeta(
          uri: 'spotify:track:track1',
          title: 'Starboy',
          subtitle: 'The Weeknd, Daft Punk',
          albumName: 'Starboy',
          imageUrls: {'large': 'https://i.scdn.co/image/starboy'},
          durationMs: 230480,
        ),
        'spotify:track:track2': const TrackMeta(
          uri: 'spotify:track:track2',
          title: 'Blinding Lights',
          subtitle: 'The Weeknd',
          albumName: 'After Hours',
          imageUrls: {'large': 'https://i.scdn.co/image/blindinglights'},
          durationMs: 200000,
        ),
      };

      final mockService = _MockExtendedMetadataService(canned);
      final decorator = PlaylistKodiakDecorator(metadataService: mockService);

      final initialPlaylist = PlaylistEntity(
        metadata: const PlaylistMetadata(
          uri: 'spotify:playlist:test_uri',
          name: 'Weekend Hits',
          picture: '',
          totalDurationMs: 0,
        ),
        items: const [
          PlaylistItem(
            uri: 'spotify:track:track1',
            uid: '1-spotify:track:track1',
            rowPosition: 0,
            trackMetadata: TrackItemMetadata(
              title: 'Placeholder 1',
              uri: 'spotify:track:track1',
            ),
          ),
          PlaylistItem(
            uri: 'spotify:track:track2',
            uid: '2-spotify:track:track2',
            rowPosition: 1,
            trackMetadata: TrackItemMetadata(
              title: 'Placeholder 2',
              uri: 'spotify:track:track2',
            ),
          ),
        ],
        isLoaded: true,
      );

      final decorated = await decorator.decorate(initialPlaylist);

      // Verifies exact 1 single flight request made
      expect(mockService.singleRequestCallCount, equals(1));
      expect(mockService.lastRequestedUris, equals(['spotify:track:track1', 'spotify:track:track2']));

      // Verifies enriched metadata fields
      expect(decorated.items[0].trackMetadata?.title, equals('Starboy'));
      expect(decorated.items[0].trackMetadata?.artists, equals(['The Weeknd, Daft Punk']));
      expect(decorated.items[0].trackMetadata?.albumName, equals('Starboy'));
      expect(decorated.items[0].trackMetadata?.albumCovers, equals(['https://i.scdn.co/image/starboy']));
      expect(decorated.items[0].trackMetadata?.durationMs, equals(230480));

      expect(decorated.items[1].trackMetadata?.title, equals('Blinding Lights'));
      expect(decorated.items[1].trackMetadata?.artists, equals(['The Weeknd']));
      expect(decorated.items[1].trackMetadata?.durationMs, equals(200000));

      // Verifies recalculated duration and derived cover
      expect(decorated.metadata.totalDurationMs, equals(430480));
      expect(decorated.metadata.picture, equals('https://i.scdn.co/image/starboy'));
    });
  });
}
