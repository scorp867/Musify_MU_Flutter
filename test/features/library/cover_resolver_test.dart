import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/library/domain/services/cover_resolver.dart';

void main() {
  group('CoverResolver Spotify Behavior Tests', () {
    test('takes first track album art as single cover when fewer than 4 unique artworks are present', () {
      final res = CoverResolver.resolve(
        wasCustomCover: false,
        cachedCoverUrl: 'https://i.scdn.co/image/old_cover',
        coverChange: null,
        mosaicUrls: const [
          'https://i.scdn.co/image/track1',
          'https://i.scdn.co/image/track2',
        ],
      );

      expect(res.isCustomCover, isFalse);
      expect(res.coverUrl, equals('https://i.scdn.co/image/track1'));
      expect(res.mosaicImageUrls, isEmpty);
    });

    test('takes first track album art when playlist has 1 unique artwork', () {
      final res = CoverResolver.resolve(
        wasCustomCover: false,
        cachedCoverUrl: null,
        coverChange: null,
        mosaicUrls: const ['https://i.scdn.co/image/single_art'],
      );

      expect(res.isCustomCover, isFalse);
      expect(res.coverUrl, equals('https://i.scdn.co/image/single_art'));
      expect(res.mosaicImageUrls, isEmpty);
    });

    test('builds 2x2 mosaic when playlist has 4 or more unique artworks', () {
      const fourArtworks = [
        'https://i.scdn.co/image/art1',
        'https://i.scdn.co/image/art2',
        'https://i.scdn.co/image/art3',
        'https://i.scdn.co/image/art4',
      ];

      final res = CoverResolver.resolve(
        wasCustomCover: false,
        cachedCoverUrl: 'https://i.scdn.co/image/old',
        coverChange: null,
        mosaicUrls: fourArtworks,
      );

      expect(res.isCustomCover, isFalse);
      expect(res.coverUrl, equals('https://i.scdn.co/image/art1'));
      expect(res.mosaicImageUrls, equals(fourArtworks));
    });

    test('CoverSet explicitly sets new custom cover and clears mosaic flag', () {
      final res = CoverResolver.resolve(
        wasCustomCover: false,
        cachedCoverUrl: 'https://i.scdn.co/image/art1',
        coverChange: const CoverSet('https://i.scdn.co/image/custom_picture'),
        mosaicUrls: const ['https://i.scdn.co/image/track1'],
      );

      expect(res.isCustomCover, isTrue);
      expect(res.coverUrl, equals('https://i.scdn.co/image/custom_picture'));
      expect(res.mosaicImageUrls, isEmpty);
    });

    test('resolveFromFull builds single cover from first track when < 4 artworks and no custom cover', () {
      final res = CoverResolver.resolveFromFull(
        customCoverUrl: null,
        mosaicUrls: const ['https://i.scdn.co/image/first_track'],
      );

      expect(res.isCustomCover, isFalse);
      expect(res.coverUrl, equals('https://i.scdn.co/image/first_track'));
      expect(res.mosaicImageUrls, isEmpty);
    });

    test('resolveFromFull sets null cover when playlist has 0 tracks', () {
      final res = CoverResolver.resolveFromFull(
        customCoverUrl: null,
        mosaicUrls: const [],
      );

      expect(res.isCustomCover, isFalse);
      expect(res.coverUrl, isNull);
      expect(res.mosaicImageUrls, isEmpty);
    });

    test('resolveFromFull preserves custom cover unconditionally and ignores track arts', () {
      final res = CoverResolver.resolveFromFull(
        customCoverUrl: 'https://i.scdn.co/image/user_custom_cover',
        mosaicUrls: const [
          'https://i.scdn.co/image/art1',
          'https://i.scdn.co/image/art2',
          'https://i.scdn.co/image/art3',
          'https://i.scdn.co/image/art4',
        ],
      );

      expect(res.isCustomCover, isTrue);
      expect(res.coverUrl, equals('https://i.scdn.co/image/user_custom_cover'));
      expect(res.mosaicImageUrls, isEmpty);
    });

    test('resolve preserves existing custom cover across diffs without coverChange', () {
      final res = CoverResolver.resolve(
        wasCustomCover: true,
        cachedCoverUrl: 'https://i.scdn.co/image/persisted_custom',
        coverChange: null,
        mosaicUrls: const [],
      );

      expect(res.isCustomCover, isTrue);
      expect(res.coverUrl, equals('https://i.scdn.co/image/persisted_custom'));
      expect(res.mosaicImageUrls, isEmpty);
    });

    test('CoverRemoved reverts custom cover to 2x2 mosaic when >= 4 track arts exist', () {
      const fourArtworks = [
        'https://i.scdn.co/image/art1',
        'https://i.scdn.co/image/art2',
        'https://i.scdn.co/image/art3',
        'https://i.scdn.co/image/art4',
      ];

      final res = CoverResolver.resolve(
        wasCustomCover: true,
        cachedCoverUrl: 'https://i.scdn.co/image/old_custom',
        coverChange: const CoverRemoved(),
        mosaicUrls: fourArtworks,
      );

      expect(res.isCustomCover, isFalse);
      expect(res.coverUrl, equals('https://i.scdn.co/image/art1'));
      expect(res.mosaicImageUrls, equals(fourArtworks));
    });
  });
}
