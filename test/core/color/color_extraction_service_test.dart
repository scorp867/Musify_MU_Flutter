import 'dart:async';
import 'dart:io' as io;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/color/artwork_color_scheme.dart';
import 'package:musify_mu/core/color/color_cache.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';

class FakeColorCache implements ColorCache {
  final Map<String, ArtworkColorScheme> memory = {};

  @override
  ArtworkColorScheme? get(String artworkUrl) => memory[artworkUrl];

  @override
  Future<void> put(String artworkUrl, ArtworkColorScheme scheme) async {
    memory[artworkUrl] = scheme;
  }

  @override
  Future<void> load() async {}

  @override
  Future<void> clear() async {
    memory.clear();
  }

  @override
  void dispose() {
    memory.clear();
  }
}

class FakeCacheManager extends Fake implements BaseCacheManager {
  final Map<String, Uint8List> bytesByUrl = <String, Uint8List>{};
  final Map<String, Completer<void>> gatesByUrl = <String, Completer<void>>{};
  final List<String> requestedUrls = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getSingleFile) {
      final url = invocation.positionalArguments[0] as String;
      requestedUrls.add(url);
      final bytes = bytesByUrl[url];
      if (bytes == null) {
        return Future<Never>.error(
          io.FileSystemException('Missing fake cached file', url),
        );
      }
      final gate = gatesByUrl[url];
      final fs = IOFileSystem('color_extract_test');
      final fileName = 'tile_${url.hashCode}.png';
      if (gate != null) {
        return gate.future.then(
          (_) => fs.createFile(fileName).then((file) {
            file.writeAsBytesSync(bytes, flush: true);
            return file;
          }),
        );
      }
      return fs.createFile(fileName).then((file) {
        file.writeAsBytesSync(bytes, flush: true);
        return file;
      });
    }
    return super.noSuchMethod(invocation);
  }
}

final Uint8List _kRed1x1Png = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
  0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
  0x00, 0x03, 0x01, 0x01, 0x00, 0xC9, 0xFE, 0x92,
  0xEF, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
  0x44, 0xAE, 0x42, 0x60, 0x82,
]);

// Neutral gray 1x1 PNG (#808080) used so tile fallback progresses to composite.
final Uint8List _kGray1x1Png = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
  0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0xE8, 0x60, 0x60, 0x00,
  0x00, 0x01, 0x84, 0x00, 0x81, 0xFB, 0xDC, 0x5A,
  0x5D, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
  0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ColorExtractionService Algorithm Tests', () {
    late ColorExtractionService service;
    late FakeColorCache fakeCache;
    late FakeCacheManager fakeCacheManager;

    setUp(() {
      fakeCache = FakeColorCache();
      fakeCacheManager = FakeCacheManager();
      service = ColorExtractionService(
        cache: fakeCache,
        cacheManager: fakeCacheManager,
      );
    });

    test('Initial state has no cached entries', () {
      expect(service.getCached('nonexistent'), isNull);
    });

    test('Extract scheme from actual artwork covers and tiles', () async {
      final tests = [
        ('Sherine tile', 'scratch/tile_sherine.png'),
        ('Assala tile', 'scratch/tile_assala.png'),
        ('Full Cover 01 (Spotify)', 'scratch/cover_sp_image_01.png'),
        ('Full Cover 02 (Spotify)', 'scratch/cover_sp_image_02.png'),
        ('Full Cover 03 (Spotify)', 'scratch/cover_sp_image_03.png'),
      ];

      for (final (_, path) in tests) {
        final file = io.File(path);
        if (!file.existsSync()) continue;
        final bytes = await file.readAsBytes();

        final scheme = await service.extractFromBytes(bytes);
        expect(scheme, isNotNull);
        expect(scheme.primary, isNot(equals(const ui.Color(0x00000000))));
        expect(scheme.secondary, isNot(equals(const ui.Color(0x00000000))));
        expect(scheme.accent, isNot(equals(const ui.Color(0x00000000))));
        expect(scheme.onPrimary, isNot(equals(const ui.Color(0x00000000))));
        expect(scheme.surface, isNot(equals(const ui.Color(0x00000000))));
      }
    });

    test('Synchronous cache put and get scheme', () async {
      const testScheme = ArtworkColorScheme(
        primary: ui.Color(0xFF8D4E38),
        secondary: ui.Color(0xFF670A23),
        accent: ui.Color(0xFF990D33),
        onPrimary: ui.Color(0xFFFFFFFF),
        surface: ui.Color(0xFF1E100C),
      );
      await fakeCache.put('test_url', testScheme);

      expect(service.getCached('test_url'), equals(testScheme));
    });

    test('deduplicates concurrent extractFromUrl calls via _inFlightUrl', () async {
      final tempDir = io.Directory.systemTemp.createTempSync('color_url_dedup_');
      const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathChannel, (call) async {
        if (call.method == 'getTemporaryDirectory') {
          return tempDir.path;
        }
        return null;
      });
      addTearDown(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathChannel, null);
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      const url = 'https://cdn.example.com/concurrent_cover.png';
      final gate = Completer<void>();
      fakeCacheManager.bytesByUrl[url] = _kRed1x1Png;
      fakeCacheManager.gatesByUrl[url] = gate;

      final f1 = service.extractFromUrl(url);
      final f2 = service.extractFromUrl(url);
      final f3 = service.extractFromUrl(url);

      gate.complete();
      final results = await Future.wait(<Future<ArtworkColorScheme>>[f1, f2, f3]);

      expect(fakeCacheManager.requestedUrls, equals(<String>[url]));
      expect(results[0], equals(results[1]));
      expect(results[1], equals(results[2]));
    });

    test(
      'deduplicates concurrent extractFromMosaic calls and reuses fetched tile bytes without double downloads',
      () async {
        final tempDir = io.Directory.systemTemp.createTempSync('color_mosaic_');
        const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathChannel, (call) async {
          if (call.method == 'getTemporaryDirectory') {
            return tempDir.path;
          }
          return null;
        });
        addTearDown(() async {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(pathChannel, null);
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });

        final tileUrls = <String>[
          'https://cdn.example.com/t0.png',
          'https://cdn.example.com/t1.png',
          'https://cdn.example.com/t2.png',
          'https://cdn.example.com/t3.png',
        ];
        final gate0 = Completer<void>();
        fakeCacheManager.gatesByUrl[tileUrls[0]] = gate0;
        for (final tileUrl in tileUrls) {
          fakeCacheManager.bytesByUrl[tileUrl] = _kGray1x1Png;
        }

        final f1 = service.extractFromMosaic(tileUrls);
        final f2 = service.extractFromMosaic(tileUrls);
        gate0.complete();

        final results = await Future.wait(<Future<ArtworkColorScheme>>[f1, f2]);
        expect(results[0], equals(results[1]));
        // Each of the 4 tile URLs is fetched at most once even when falling back to composite.
        expect(fakeCacheManager.requestedUrls.length, equals(4));
      },
    );
  });

  group('ColorCache & AppCacheManager Integration Tests', () {
    late io.Directory tempRoot;
    late AppCacheManager cacheManager;
    late ColorCache colorCache;

    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');

    setUp(() async {
      tempRoot = io.Directory.systemTemp.createTempSync('color_cache_test_');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathChannel, (call) async {
        if (call.method == 'getApplicationSupportDirectory') {
          return tempRoot.path;
        }
        return null;
      });
      cacheManager = AppCacheManager();
      colorCache = ColorCache(cacheManager: cacheManager);
    });

    tearDown(() async {
      colorCache.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathChannel, null);
      if (tempRoot.existsSync()) {
        tempRoot.deleteSync(recursive: true);
      }
    });

    test(
      'supports guest fallback before login, enforces 500 LRU cap, debounces atomic disk writes, and resets on setUser',
      () async {
        expect(cacheManager.hasUser, isFalse);
        await colorCache.load();

        const sampleScheme = ArtworkColorScheme(
          primary: ui.Color(0xFF1DB954),
          secondary: ui.Color(0xFF191414),
          accent: ui.Color(0xFF1ED760),
          onPrimary: ui.Color(0xFF000000),
          surface: ui.Color(0xFF121212),
        );

        // Write 505 entries to exercise LRU eviction of the oldest 5.
        for (var i = 0; i < 505; i++) {
          await colorCache.put('https://cdn.example.com/art_$i.jpg', sampleScheme);
        }

        expect(colorCache.get('https://cdn.example.com/art_0.jpg'), isNull);
        expect(colorCache.get('https://cdn.example.com/art_4.jpg'), isNull);
        expect(colorCache.get('https://cdn.example.com/art_504.jpg'), equals(sampleScheme));

        // Wait past the 500ms debounce timer for atomic .tmp -> colors.json write.
        await Future<void>.delayed(const Duration(milliseconds: 650));

        final guestDir = await cacheManager.featureDir('colors');
        expect(guestDir.path, contains('_guest'));
        final jsonFile = io.File('${guestDir.path}${io.Platform.pathSeparator}colors.json');
        final tmpFile = io.File('${guestDir.path}${io.Platform.pathSeparator}colors.json.tmp');
        expect(jsonFile.existsSync(), isTrue);
        expect(tmpFile.existsSync(), isFalse);

        // Switching user increments generation and clears stale guest memory cleanly.
        await cacheManager.setUser('user_alpha');
        expect(colorCache.get('https://cdn.example.com/art_504.jpg'), isNull);

        await colorCache.put('https://cdn.example.com/user_alpha_art.jpg', sampleScheme);
        await Future<void>.delayed(const Duration(milliseconds: 650));
        final userDir = await cacheManager.featureDir('colors');
        expect(userDir.path, contains('user_alpha'));
        expect(
          io.File('${userDir.path}${io.Platform.pathSeparator}colors.json').existsSync(),
          isTrue,
        );
      },
    );
  });
}
