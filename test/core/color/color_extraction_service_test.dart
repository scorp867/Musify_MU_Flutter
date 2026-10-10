import 'dart:io' as io;
import 'dart:ui' as ui;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
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
}

class FakeCacheManager extends Fake implements BaseCacheManager {}

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
  });
}
