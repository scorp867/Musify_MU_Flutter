import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/protocol/generated/spotify/playlist/playlist_detail.pb.dart'
    as detail_pb;
import 'package:musify_mu/core/protocol/generated/spotify/playlist/rootlist.pb.dart'
    as rootlist_pb;
import 'package:musify_mu/features/library/data/cache/playlist_detail_cache.dart';
import 'package:musify_mu/features/library/data/sources/playlist_remote_source.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_play_client.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:musify_mu/features/playlist/data/client/playlist_data_client.dart';
import 'package:musify_mu/features/playlist/data/client/playlist_modification_client.dart';
import 'package:musify_mu/features/playlist/data/client/playlist_play_client.dart';
import 'package:musify_mu/features/playlist/data/decorator/playlist_kodiak_decorator.dart';
import 'package:musify_mu/features/playlist/data/repositories/playlist_repository_impl.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_entity.dart';

class _FakeEsperantoTransport implements EsperantoTransport {
  String? lastService;
  String? lastMethod;
  Uint8List? lastPayload;

  @override
  Stream<Uint8List> callStream(String service, String method, Uint8List payload) {
    return const Stream<Uint8List>.empty();
  }

  @override
  Future<Uint8List> callSingle(String service, String method, Uint8List payload) async {
    lastService = service;
    lastMethod = method;
    lastPayload = payload;
    return Uint8List(0);
  }

  @override
  Uint8List callSync(String service, String method, Uint8List payload) {
    lastService = service;
    lastMethod = method;
    lastPayload = payload;
    return Uint8List(0);
  }
}

class _MockPlaylistDetailCache implements PlaylistDetailCache {
  final Map<String, Uint8List> memoryCache = {};
  int putCallCount = 0;

  @override
  Future<Uint8List?> getRawBytes(String playlistId) async {
    return memoryCache[playlistId];
  }

  @override
  Future<void> put({
    required String playlistId,
    required String revision,
    required List<String> trackUris,
    String? coverUrl,
    bool isCustomCover = false,
    List<String> mosaicImageUrls = const [],
    Uint8List? rawBytes,
  }) async {
    putCallCount++;
    if (rawBytes != null) {
      memoryCache[playlistId] = rawBytes;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockPlaylistRemoteSource implements PlaylistRemoteSource {
  Uint8List? nextResponseBytes;
  bool shouldThrow = false;
  String? lastRequestedId;

  @override
  Future<Uint8List?> fetchFull(String playlistId, {dynamic cancelToken}) async {
    lastRequestedId = playlistId;
    if (shouldThrow) {
      throw Exception('Network connection timed out');
    }
    return nextResponseBytes;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockKodiakDecorator implements PlaylistKodiakDecorator {
  int decorateCallCount = 0;

  @override
  Future<PlaylistEntity> decorate(PlaylistEntity entity) async {
    decorateCallCount++;
    return entity;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Uint8List _createSamplePlaylistBytes(String title) {
  final proto = detail_pb.PlaylistResponse(
    attributes: rootlist_pb.ListAttributes(
      name: title,
      description: 'Test Description',
    ),
    contents: rootlist_pb.ListItems(
      items: [
        rootlist_pb.Item(
          uri: 'spotify:track:track1',
          attributes: rootlist_pb.ItemAttributes(
            addedBy: 'spotify',
          ),
        ),
      ],
    ),
    length: 1,
    upToDate: true,
  );
  return proto.writeToBuffer();
}

void main() {
  late _FakeEsperantoTransport transport;
  late PlaylistDataClient dataClient;
  late PlaylistModificationClient modificationClient;
  late PlaylistPlayClient playClient;
  late ContextPlayerPlayClient contextPlayerPlayClient;
  late _MockPlaylistDetailCache cache;
  late _MockPlaylistRemoteSource remoteSource;
  late _MockKodiakDecorator decorator;
  late PlaylistRepositoryImpl repository;

  setUp(() {
    transport = _FakeEsperantoTransport();
    dataClient = PlaylistDataClient(transport);
    modificationClient = PlaylistModificationClient(transport);
    playClient = PlaylistPlayClient(transport);
    contextPlayerPlayClient = ContextPlayerPlayClient(transport);
    cache = _MockPlaylistDetailCache();
    remoteSource = _MockPlaylistRemoteSource();
    decorator = _MockKodiakDecorator();

    repository = PlaylistRepositoryImpl(
      dataClient: dataClient,
      modificationClient: modificationClient,
      playClient: playClient,
      contextPlayerPlayClient: contextPlayerPlayClient,
      cache: cache,
      remoteSource: remoteSource,
      kodiakDecorator: decorator,
      currentUsername: 'testuser',
    );
  });

  group('PlaylistRepositoryImpl Non-Library Playlist Resolution Tests', () {
    test('Non-library playlist loads from remote source when cache is empty without stalling', () async {
      const playlistUri = 'spotify:playlist:37i9dQZF1DXcBWIGoYBM5M';
      final sampleBytes = _createSamplePlaylistBytes('Today\'s Top Hits');
      remoteSource.nextResponseBytes = sampleBytes;

      final emissions = <PlaylistEntity>[];
      await for (final playlist in repository.subscribe(playlistUri)) {
        emissions.add(playlist);
      }

      expect(remoteSource.lastRequestedId, equals('37i9dQZF1DXcBWIGoYBM5M'));
      expect(emissions.length, equals(1));
      expect(emissions.first.name, equals('Today\'s Top Hits'));
      expect(emissions.first.items.length, equals(1));
      expect(emissions.first.items.first.uri, equals('spotify:track:track1'));
      expect(cache.putCallCount, equals(1));
      expect(decorator.decorateCallCount, equals(1));
    });

    test('Non-library playlist strips query parameters (?si=...) from Spotify URIs', () async {
      const playlistUri = 'spotify:playlist:37i9dQZF1DXcBWIGoYBM5M?si=e2f8964319fb4245';
      final sampleBytes = _createSamplePlaylistBytes('Query Parameter Test');
      remoteSource.nextResponseBytes = sampleBytes;

      final emissions = <PlaylistEntity>[];
      await for (final playlist in repository.subscribe(playlistUri)) {
        emissions.add(playlist);
      }

      expect(remoteSource.lastRequestedId, equals('37i9dQZF1DXcBWIGoYBM5M'));
      expect(emissions.first.name, equals('Query Parameter Test'));
    });

    test('Non-library playlist parses web URLs (https://open.spotify.com/playlist/...)', () async {
      const webUrl = 'https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M?si=abcdef';
      final sampleBytes = _createSamplePlaylistBytes('Web URL Test');
      remoteSource.nextResponseBytes = sampleBytes;

      final emissions = <PlaylistEntity>[];
      await for (final playlist in repository.subscribe(webUrl)) {
        emissions.add(playlist);
      }

      expect(remoteSource.lastRequestedId, equals('37i9dQZF1DXcBWIGoYBM5M'));
      expect(emissions.first.name, equals('Web URL Test'));
    });

    test('Emits stream error when remote fetch fails and cache is empty, avoiding indefinite spinner', () async {
      const playlistUri = 'spotify:playlist:non_existent_or_offline';
      remoteSource.shouldThrow = true;

      expect(
        () => repository.subscribe(playlistUri).toList(),
        throwsA(isA<Exception>()),
      );
    });

    test('Emits cached playlist immediately when available in library cache', () async {
      const playlistId = '37i9dQZF1DXcBWIGoYBM5M';
      const playlistUri = 'spotify:playlist:$playlistId';
      final cachedBytes = _createSamplePlaylistBytes('Cached Library Playlist');
      cache.memoryCache[playlistId] = cachedBytes;

      final remoteBytes = _createSamplePlaylistBytes('Refreshed Remote Playlist');
      remoteSource.nextResponseBytes = remoteBytes;

      final emissions = <PlaylistEntity>[];
      await for (final playlist in repository.subscribe(playlistUri)) {
        emissions.add(playlist);
      }

      // Step 1: cached entity + decorated cached entity
      // Step 2: fresh remote entity
      expect(emissions.isNotEmpty, isTrue);
      expect(emissions.first.name, equals('Cached Library Playlist'));
      expect(emissions.last.name, equals('Refreshed Remote Playlist'));
    });

    test('playPlaylist populates ContextPage with ContextTrack metadata and options', () async {
      const playlistId = '37i9dQZF1DXcBWIGoYBM5M';
      const playlistUri = 'spotify:playlist:$playlistId';
      final cachedBytes = _createSamplePlaylistBytes('Pop Hits');
      cache.memoryCache[playlistId] = cachedBytes;

      await repository.playPlaylist(
        playlistUri: playlistUri,
        skipToUri: 'spotify:track:track1',
        shuffle: true,
      );

      expect(transport.lastService, equals(ContextPlayerPlayClient.serviceName));
      expect(transport.lastMethod, equals('Play'));
      expect(transport.lastPayload, isNotNull);

      final payloadJson = jsonDecode(utf8.decode(transport.lastPayload!)) as Map<String, dynamic>;
      final prep = payloadJson['prepare_play_request'] as Map<String, dynamic>;
      final ctx = prep['context'] as Map<String, dynamic>;
      expect(ctx['uri'], equals(playlistUri));
      expect(ctx['metadata']['context_description'], equals('Pop Hits'));

      final pages = ctx['pages'] as List;
      expect(pages.isNotEmpty, isTrue);
      final tracks = (pages.first as Map<String, dynamic>)['tracks'] as List;
      expect(tracks.length, equals(1));
      final firstTrack = tracks.first as Map<String, dynamic>;
      expect(firstTrack['uri'], equals('spotify:track:track1'));
      expect(firstTrack['metadata'], isNotNull);
      final trackMeta = firstTrack['metadata'] as Map<String, dynamic>;
      expect(trackMeta['context_uri'], equals(playlistUri));

      final opts = prep['options'] as Map<String, dynamic>;
      expect((opts['skip_to'] as Map<String, dynamic>)['track_uri'], equals('spotify:track:track1'));
      expect((opts['player_options_override'] as Map<String, dynamic>)['shuffling_context'], isTrue);
    });
  });
}
