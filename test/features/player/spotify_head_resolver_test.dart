import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/data/services/spotify_head_resolver.dart';
import 'package:musify_mu/features/player/data/services/spotify_audio_stream_registry.dart';

void main() {
  group('SpotifyHeadResolver Unit Tests', () {
    final resolver = SpotifyHeadResolver.instance;
    const testFileId = 'd3d7b90c569dd52c0c5ec812ba0b583a8ab8a7ef';

    test('buildHeadUrl produces canonical Spotify CDN URL', () {
      final url = resolver.buildHeadUrl(testFileId);
      expect(
        url,
        equals('https://heads-fa-tls13.spotifycdn.com/head/d3d7b90c569dd52c0c5ec812ba0b583a8ab8a7ef'),
      );
    });

    test('buildHeadUrl supports custom or fallback CDN domain', () {
      final url = resolver.buildHeadUrl(testFileId, cdnDomain: 'heads-ak-tls13.spotifycdn.com');
      expect(
        url,
        equals('https://heads-ak-tls13.spotifycdn.com/head/d3d7b90c569dd52c0c5ec812ba0b583a8ab8a7ef'),
      );
    });

    test('buildPreviewUrl produces canonical p.scdn.co MP3 preview URL', () {
      final url = resolver.buildPreviewUrl(testFileId);
      expect(
        url,
        equals('https://p.scdn.co/mp3-preview/d3d7b90c569dd52c0c5ec812ba0b583a8ab8a7ef'),
      );
    });

    test('normalizeFileId converts 20-byte raw SHA-1 to lowercase hex', () {
      final bytes = <int>[
        0xd3, 0xd7, 0xb9, 0x0c, 0x56, 0x9d, 0xd5, 0x2c, 0x0c, 0x5e,
        0xc8, 0x12, 0xba, 0x0b, 0x58, 0x3a, 0x8a, 0xb8, 0xa7, 0xef,
      ];
      final hex = resolver.normalizeFileId(bytes);
      expect(hex, equals(testFileId));
    });

    test('normalizeFileId strips spotify:file: URI prefix', () {
      final hex = resolver.normalizeFileId('spotify:file:$testFileId');
      expect(hex, equals(testFileId));
    });

    test('headFileSizeBytes is exactly 128 KB (131072 bytes)', () {
      expect(SpotifyHeadResolver.headFileSizeBytes, equals(131072));
    });

    test('SpotifyAudioStreamRegistry stores and retrieves head_file_url and file_id', () {
      final info = TrackStreamInfo(
        fileId: testFileId,
        headUrl: resolver.buildHeadUrl(testFileId),
      );
      SpotifyAudioStreamRegistry.instance.register('spotify:track:123', info);

      final retrieved = SpotifyAudioStreamRegistry.instance.get('spotify:track:123');
      expect(retrieved, isNotNull);
      expect(retrieved?.fileId, equals(testFileId));
      expect(
        retrieved?.headUrl,
        equals('https://heads-fa-tls13.spotifycdn.com/head/d3d7b90c569dd52c0c5ec812ba0b583a8ab8a7ef'),
      );
    });
  });
}
