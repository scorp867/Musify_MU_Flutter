import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/media/local_file_image_loader.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/data/datasources/device_music_data_source.dart';
import 'package:musify_mu/features/local_music/data/datasources/local_tracks_store.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_artwork.dart';
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
  @override
  Future<List<LocalTrack>> getAll() async => const <LocalTrack>[];

  @override
  Stream<List<LocalTrack>> watchAll() => const Stream<List<LocalTrack>>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDeviceMusicDataSource implements DeviceMusicDataSource {
  @override
  Future<Uint8List?> queryArtwork(int songId, {int size = 80}) async => null;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<List<SongModel>> querySongs() async => const <SongModel>[];

  @override
  Stream<void> get changes => const Stream<void>.empty();
}

void main() {
  testWidgets('compact placeholder matches the mini-player artwork slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: PlayerArtworkImage(
            artworkWidth: 40,
            artworkHeight: 40,
            placeholderIconSize: 20,
          ),
        ),
      ),
    );

    final artworkSize = tester.getSize(find.byType(PlayerArtworkPlaceholder));

    expect(artworkSize, const Size(40, 40));
    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
  });

  testWidgets(
    'sync fallback cache hit updates PlayerArtworkImage after primary local URI misses',
    (tester) async {
      const channel = MethodChannel('um.musify.mu/local_artwork');
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async {
          calls.add(call);
          final args = call.arguments as Map;
          if (args['filePath'] == '/vault/fallback_hit.mp3') {
            return _kValidPngBytes;
          }
          return null;
        },
      );

      final loader = LocalFileImageLoader(
        store: _FakeLocalTracksStore(),
        deviceMusic: _FakeDeviceMusicDataSource(),
      );
      final hadPrevious = getIt.isRegistered<LocalFileImageLoader>();
      final LocalFileImageLoader? previous =
          hadPrevious ? getIt<LocalFileImageLoader>() : null;
      if (hadPrevious) {
        getIt.unregister<LocalFileImageLoader>();
      }
      getIt.registerSingleton<LocalFileImageLoader>(loader);

      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
        if (getIt.isRegistered<LocalFileImageLoader>()) {
          getIt.unregister<LocalFileImageLoader>();
        }
        if (previous != null) {
          getIt.registerSingleton<LocalFileImageLoader>(previous);
        }
        loader.dispose();
      });

      // Pre-warm the fallback provider synchronously at thumbnail size (48 <= 220 -> 256).
      final warmed = await loader.loadFileProvider(
        '/vault/fallback_hit.mp3',
        decodeWidthPx: 96,
        decodeHeightPx: 96,
      );
      expect(warmed, isNotNull);
      calls.clear();

      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: PlayerArtworkImage(
              imageUrl: 'file:///vault/missing_primary.mp3',
              fallbackImageUrl: 'file:///vault/fallback_hit.mp3',
              artworkWidth: 48,
              artworkHeight: 48,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Primary missed at thumbnail bucket (256), fallback hit synchronously and rendered Image.
      expect(calls.length, equals(1));
      expect((calls.single.arguments as Map)['maxDimension'], equals(256));
      expect(find.byType(Image), findsOneWidget);
    },
  );

  testWidgets(
    'uses 256 query bucket when height <= 220 even if width is small, and 720 when height > 220',
    (tester) async {
      const channel = MethodChannel('um.musify.mu/local_artwork');
      final recordedMaxDims = <int>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async {
          final args = call.arguments as Map;
          recordedMaxDims.add(args['maxDimension'] as int);
          return _kValidPngBytes;
        },
      );

      final loader = LocalFileImageLoader(
        store: _FakeLocalTracksStore(),
        deviceMusic: _FakeDeviceMusicDataSource(),
      );
      final hadPrevious = getIt.isRegistered<LocalFileImageLoader>();
      final LocalFileImageLoader? previous =
          hadPrevious ? getIt<LocalFileImageLoader>() : null;
      if (hadPrevious) {
        getIt.unregister<LocalFileImageLoader>();
      }
      getIt.registerSingleton<LocalFileImageLoader>(loader);

      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
        if (getIt.isRegistered<LocalFileImageLoader>()) {
          getIt.unregister<LocalFileImageLoader>();
        }
        if (previous != null) {
          getIt.registerSingleton<LocalFileImageLoader>(previous);
        }
        loader.dispose();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Column(
            children: [
              PlayerArtworkImage(
                imageUrl: 'file:///vault/tall_card.mp3',
                artworkWidth: 160,
                artworkHeight: 260,
              ),
              PlayerArtworkImage(
                imageUrl: 'file:///vault/medium_card.mp3',
                artworkWidth: 160,
                artworkHeight: 200,
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(recordedMaxDims, equals(<int>[720, 256]));
    },
  );
}
