import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/media/local_file_image_loader.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/data/datasources/device_music_data_source.dart';
import 'package:musify_mu/features/local_music/data/datasources/local_tracks_store.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_uri.dart';
import 'package:on_audio_query/on_audio_query.dart';

final Uint8List _kValidPngBytes = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
  0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99,
  0x3D, 0x1D, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
  0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _FakeLocalTracksStore implements LocalTracksStore {
  List<LocalTrack> tracks;
  final StreamController<List<LocalTrack>> watchController =
      StreamController<List<LocalTrack>>.broadcast();
  int getAllCallCount = 0;

  _FakeLocalTracksStore(this.tracks);

  @override
  Future<List<LocalTrack>> getAll() async {
    getAllCallCount++;
    await Future<void>.delayed(Duration.zero);
    return tracks;
  }

  @override
  Stream<List<LocalTrack>> watchAll() => watchController.stream;

  void emitWatchUpdate(List<LocalTrack> updated) {
    tracks = updated;
    watchController.add(updated);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDeviceMusicDataSource implements DeviceMusicDataSource {
  final Map<int, Uint8List?> artworkBySongId = <int, Uint8List?>{};
  final List<(int songId, int size)> artworkCalls = <(int, int)>[];

  @override
  Future<Uint8List?> queryArtwork(int songId, {int size = 80}) async {
    artworkCalls.add((songId, size));
    return artworkBySongId[songId];
  }

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<List<SongModel>> querySongs() async => const <SongModel>[];

  @override
  Stream<void> get changes => const Stream<void>.empty();
}

LocalTrack _makeTrack({
  required int id,
  required int songId,
  required String title,
  String? artist,
  String? album,
  int durationMs = 180000,
  String dataPath = '/storage/emulated/0/Music/song.mp3',
}) {
  return LocalTrack(
    id: id,
    songId: songId,
    title: title,
    artist: artist,
    album: album,
    dataPath: dataPath,
    duration: durationMs,
    dateModified: 1700000000,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const artworkChannel = MethodChannel('um.musify.mu/local_artwork');

  group('LocalFileImageLoader', () {
    late _FakeLocalTracksStore store;
    late _FakeDeviceMusicDataSource deviceMusic;
    late LocalFileImageLoader loader;
    late List<MethodCall> platformCalls;
    late Uint8List? Function(MethodCall call) platformHandler;

    setUp(() {
      platformCalls = <MethodCall>[];
      platformHandler = (_) => null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(artworkChannel, (call) async {
        platformCalls.add(call);
        return platformHandler(call);
      });

      store = _FakeLocalTracksStore(const <LocalTrack>[]);
      deviceMusic = _FakeDeviceMusicDataSource();
      loader = LocalFileImageLoader(
        store: store,
        deviceMusic: deviceMusic,
      );
    });

    tearDown(() async {
      loader.dispose();
      await store.watchController.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(artworkChannel, null);
    });

    test(
      'normalizes querySize into 256 and 720 canonical buckets for both MediaStore and file URIs',
      () async {
        final track = _makeTrack(
          id: 1,
          songId: 101,
          title: 'Bucket Song',
          artist: 'Artist A',
          album: 'Album A',
          dataPath: '/storage/emulated/0/Music/bucket_song.mp3',
        );
        store.tracks = <LocalTrack>[track];
        deviceMusic.artworkBySongId[101] = _kValidPngBytes;
        platformHandler = (_) => _kValidPngBytes;

        final trackUri = LocalFileUri.fromMetadata(
          artist: 'Artist A',
          album: 'Album A',
          title: 'Bucket Song',
          durationSeconds: 180,
        );

        await loader.loadBytes(trackUri, querySize: 200);
        await loader.loadBytes(trackUri, querySize: 300);
        await loader.loadBytes(trackUri, querySize: 320);

        expect(deviceMusic.artworkCalls, equals(<(int, int)>[(101, 256)]));

        await loader.loadBytes(trackUri, querySize: 512);
        await loader.loadBytes(trackUri, querySize: 800);
        expect(
          deviceMusic.artworkCalls,
          equals(<(int, int)>[(101, 256), (101, 720)]),
        );

        await loader.loadFileArtworkBytes(
          '/vault/.nomedia/t1.mp3',
          maxDimension: 180,
        );
        await loader.loadFileArtworkBytes(
          '/vault/.nomedia/t1.mp3',
          maxDimension: 280,
        );
        await loader.loadFileArtworkBytes(
          '/vault/.nomedia/t1.mp3',
          maxDimension: 600,
        );

        expect(platformCalls.length, equals(2));
        expect(
          (platformCalls[0].arguments as Map)['maxDimension'],
          equals(256),
        );
        expect(
          (platformCalls[1].arguments as Map)['maxDimension'],
          equals(720),
        );
      },
    );

    test(
      'reuses cached 720 full-size bytes for 256 thumbnail requests with zero extra I/O',
      () async {
        final track = _makeTrack(
          id: 1,
          songId: 202,
          title: 'Reuse Song',
          artist: 'Artist R',
          album: 'Album R',
          dataPath: '/storage/emulated/0/Music/reuse.mp3',
        );
        store.tracks = <LocalTrack>[track];
        deviceMusic.artworkBySongId[202] = _kValidPngBytes;

        final uri = LocalFileUri.fromMetadata(
          artist: 'Artist R',
          album: 'Album R',
          title: 'Reuse Song',
          durationSeconds: 180,
        );

        final fullBytes = await loader.loadBytes(uri, querySize: 720);
        expect(fullBytes, equals(_kValidPngBytes));
        expect(deviceMusic.artworkCalls.length, equals(1));

        final thumbBytes = await loader.loadBytes(uri, querySize: 200);
        expect(thumbBytes, equals(_kValidPngBytes));
        expect(deviceMusic.artworkCalls.length, equals(1));

        final thumbProvider = await loader.loadProvider(
          uri,
          querySize: 120,
          decodeWidthPx: 120,
          decodeHeightPx: 120,
        );
        expect(thumbProvider, isA<ResizeImage>());
        expect(deviceMusic.artworkCalls.length, equals(1));
        expect(
          loader.getProviderSync(
            uri,
            querySize: 120,
            decodeWidthPx: 120,
            decodeHeightPx: 120,
          ),
          same(thumbProvider),
        );
      },
    );

    test(
      'deduplicates concurrent index loads and avoids redundant getAll() scans for unknown tracks',
      () async {
        final tracks = List<LocalTrack>.generate(
          5,
          (i) => _makeTrack(
            id: i + 1,
            songId: 300 + i,
            title: 'Track $i',
            artist: 'Artist $i',
            album: 'Album $i',
            dataPath: '/Music/t$i.mp3',
          ),
        );
        store.tracks = tracks;
        for (var i = 0; i < 5; i++) {
          deviceMusic.artworkBySongId[300 + i] = _kValidPngBytes;
        }

        final uris = List<String>.generate(
          5,
          (i) => LocalFileUri.fromMetadata(
            artist: 'Artist $i',
            album: 'Album $i',
            title: 'Track $i',
            durationSeconds: 180,
          ),
        );

        await Future.wait(
          uris.map((uri) => loader.loadBytes(uri, querySize: 256)),
        );
        expect(store.getAllCallCount, equals(1));

        // Unknown tracks trigger at most one fallback index refresh total.
        await loader.loadBytes(
          LocalFileUri.fromMetadata(
            artist: 'Ghost 1',
            album: 'None',
            title: 'Missing 1',
            durationSeconds: 120,
          ),
          querySize: 256,
        );
        await loader.loadBytes(
          LocalFileUri.fromMetadata(
            artist: 'Ghost 2',
            album: 'None',
            title: 'Missing 2',
            durationSeconds: 120,
          ),
          querySize: 256,
        );
        expect(store.getAllCallCount, equals(2));
      },
    );

    test(
      'cross-marks known missing file paths when spotify:local fallback yields no artwork and resets on index rebuild',
      () async {
        const missingPath = '/storage/emulated/0/Music/no_cover.mp3';
        store.tracks = <LocalTrack>[
          _makeTrack(
            id: 1,
            songId: 404,
            title: 'No Art Song',
            artist: 'Silent Artist',
            album: 'Empty Album',
            dataPath: missingPath,
          ),
        ];

        final localUri = LocalFileUri.fromMetadata(
          artist: 'Silent Artist',
          album: 'Empty Album',
          title: 'No Art Song',
          durationSeconds: 180,
        );

        final firstResult = await loader.loadBytes(localUri, querySize: 256);
        expect(firstResult, isNull);
        expect(deviceMusic.artworkCalls.length, equals(1));
        expect(platformCalls.length, equals(1));
        expect(loader.isKnownMissing(localUri, querySize: 256), isTrue);
        expect(
          loader.isKnownMissing(
            LocalFileUri.toFileUri(missingPath),
            querySize: 256,
          ),
          isTrue,
        );

        // Subsequent file: request short-circuits with zero channel calls.
        final secondResult =
            await loader.loadFileArtworkBytes(missingPath, maxDimension: 256);
        expect(secondResult, isNull);
        expect(platformCalls.length, equals(1));

        // Emitting updated tracks from store clears _knownMissing so new art loads.
        platformHandler = (_) => _kValidPngBytes;
        store.emitWatchUpdate(store.tracks);
        await Future<void>.delayed(Duration.zero);

        expect(loader.isKnownMissing(localUri, querySize: 256), isFalse);
        final recovered = await loader.loadBytes(localUri, querySize: 256);
        expect(recovered, equals(_kValidPngBytes));
        expect(platformCalls.length, equals(2));
      },
    );

    test('dispose clears caches, unsubscribes watcher, and ignores later calls', () async {
      await loader.loadFileArtworkBytes('/vault/file.mp3');
      loader.dispose();

      final result = await loader.loadFileArtworkBytes('/vault/after_dispose.mp3');
      expect(result, isNull);
      expect(platformCalls.length, equals(1));
    });
  });
}
