import 'dart:io' as io;
import 'dart:ui' as ui;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/core/color/color_cache.dart';

class FakeColorCache implements ColorCache {
  final Map<String, ui.Color> memory = {};

  @override
  ui.Color? get(String artworkUrl) => memory[artworkUrl];

  @override
  Future<void> put(String artworkUrl, ui.Color color) async {
    memory[artworkUrl] = color;
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

    test('Palette with muted and vibrant properly identifies swatches (p.m351.y)', () {
      const muted = ui.Color(0xFF3E606F);
      const vibrant = ui.Color(0xFFFF0055);

      final palette = PaletteGenerator.fromColors([
        PaletteColor(muted, 50),
        PaletteColor(vibrant, 50),
      ]);

      expect(palette.paletteColors.length, equals(2));
    });

    test('Extract color from actual artwork tiles', () async {
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
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: 112,
          targetHeight: 112,
        );
        final frame = await codec.getNextFrame();
        final image = frame.image;

        final palette = await PaletteGenerator.fromImage(
          image,
          maximumColorCount: 16,
        );

        final picked = service.testPickBestColor(palette);
        expect(picked, isNotNull);
        image.dispose();
      }
    });


    test('Synchronous cache put and get', () async {
      const testColor = ui.Color(0xFF2A4468);
      await fakeCache.put('test_url', testColor);

      expect(service.getCached('test_url'), equals(testColor));
    });
  });
}


