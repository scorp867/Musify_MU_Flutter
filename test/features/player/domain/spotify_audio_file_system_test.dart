import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/plugins/track_v4_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/metadata.pb.dart' as meta_pb;
import 'package:musify_mu/features/player/data/mappers/spotify_audio_file_mapper.dart';
import 'package:musify_mu/features/player/data/services/spotify_hex_utils.dart';
import 'package:musify_mu/features/player/domain/models/spotify_audio_file.dart';
import 'package:musify_mu/features/player/domain/models/spotify_audio_format.dart';

void main() {
  group('SpotifyAudioFormat (1:1 with p199p/ibc0.java)', () {
    test('verifies all 18 enum numbers and names match Spotify 1:1', () {
      expect(SpotifyAudioFormat.oggVorbis96.number, 0);
      expect(SpotifyAudioFormat.oggVorbis160.number, 1);
      expect(SpotifyAudioFormat.oggVorbis320.number, 2);
      expect(SpotifyAudioFormat.mp3256.number, 3);
      expect(SpotifyAudioFormat.mp3320.number, 4);
      expect(SpotifyAudioFormat.mp3160.number, 5);
      expect(SpotifyAudioFormat.mp396.number, 6);
      expect(SpotifyAudioFormat.mp3160Enc.number, 7);
      expect(SpotifyAudioFormat.aac24.number, 8);
      expect(SpotifyAudioFormat.aac48.number, 9);
      expect(SpotifyAudioFormat.mp4128.number, 10);
      expect(SpotifyAudioFormat.mp4256.number, 11);
      expect(SpotifyAudioFormat.mp4128Dual.number, 12);
      expect(SpotifyAudioFormat.mp4256Dual.number, 13);
      expect(SpotifyAudioFormat.mp4128Cbcs.number, 14);
      expect(SpotifyAudioFormat.mp4256Cbcs.number, 15);
      expect(SpotifyAudioFormat.flacFlac.number, 16);
      expect(SpotifyAudioFormat.mp4Flac.number, 17);
    });

    test('fromNumber maps all indices correctly and returns null for invalid numbers', () {
      for (int i = 0; i <= 17; i++) {
        final format = SpotifyAudioFormat.fromNumber(i);
        expect(format, isNotNull);
        expect(format?.getNumber(), i);
      }
      expect(SpotifyAudioFormat.fromNumber(-1), isNull);
      expect(SpotifyAudioFormat.fromNumber(99), isNull);
    });

    test('categorization getters work as expected', () {
      expect(SpotifyAudioFormat.oggVorbis160.isVorbis, isTrue);
      expect(SpotifyAudioFormat.oggVorbis160.isMp4, isFalse);
      expect(SpotifyAudioFormat.mp4128.isMp4, isTrue);
      expect(SpotifyAudioFormat.mp4128.isAac, isTrue);
      expect(SpotifyAudioFormat.mp4128.isVorbis, isFalse);
    });
  });

  group('SpotifyHexUtils (1:1 with p199p/xel1.java)', () {
    test('formatFileId converts 20-byte SHA-1 digest into 40-character lowercase hex', () {
      // Reference user's actual network trace file ID: d3d7b90c569dd52c0c5ec812ba0b583a8ab8a7ef
      final rawBytes = <int>[
        0xd3, 0xd7, 0xb9, 0x0c, 0x56, 0x9d, 0xd5, 0x2c, 0x0c, 0x5e,
        0xc8, 0x12, 0xba, 0x0b, 0x58, 0x3a, 0x8a, 0xb8, 0xa7, 0xef,
      ];
      final hex = SpotifyHexUtils.formatFileId(rawBytes);
      expect(hex, 'd3d7b90c569dd52c0c5ec812ba0b583a8ab8a7ef');
    });

    test('parseFileId parses 40-char hex string back to exact 20-byte Uint8List', () {
      const hex = 'd3d7b90c569dd52c0c5ec812ba0b583a8ab8a7ef';
      final parsed = SpotifyHexUtils.parseFileId(hex);
      expect(parsed, isNotNull);
      expect(parsed?.length, 20);
      expect(SpotifyHexUtils.formatFileId(parsed), hex);
    });

    test('handles null and invalid inputs gracefully', () {
      expect(SpotifyHexUtils.formatFileId(null), '');
      expect(SpotifyHexUtils.formatFileId(<int>[]), '');
      expect(SpotifyHexUtils.parseFileId(null), isNull);
      expect(SpotifyHexUtils.parseFileId('invalid_short_hex'), isNull);
    });
  });

  group('SpotifyAudioFile (1:1 with p199p/eey.java)', () {
    test('constructs model with fileIdHex and format, generates correct headUrl', () {
      const file = SpotifyAudioFile(
        fileIdHex: 'd3d7b90c569dd52c0c5ec812ba0b583a8ab8a7ef',
        format: SpotifyAudioFormat.oggVorbis160,
      );
      expect(file.fileIdHex, 'd3d7b90c569dd52c0c5ec812ba0b583a8ab8a7ef');
      expect(file.format, SpotifyAudioFormat.oggVorbis160);
      expect(
        file.headUrl,
        'https://heads-fa-tls13.spotifycdn.com/head/d3d7b90c569dd52c0c5ec812ba0b583a8ab8a7ef',
      );
    });

    test('value equality and hashCode behave structurally', () {
      const file1 = SpotifyAudioFile(
        fileIdHex: 'd3d7b90c569dd52c0c5ec812ba0b583a8ab8a7ef',
        format: SpotifyAudioFormat.oggVorbis160,
      );
      const file2 = SpotifyAudioFile(
        fileIdHex: 'd3d7b90c569dd52c0c5ec812ba0b583a8ab8a7ef',
        format: SpotifyAudioFormat.oggVorbis160,
      );
      const file3 = SpotifyAudioFile(
        fileIdHex: 'd3d7b90c569dd52c0c5ec812ba0b583a8ab8a7ef',
        format: SpotifyAudioFormat.mp4128,
      );

      expect(file1, equals(file2));
      expect(file1.hashCode, equals(file2.hashCode));
      expect(file1, isNot(equals(file3)));
    });
  });

  group('SpotifyAudioFileMapper (1:1 with p199p/xjj.java & p199p/a1a.java)', () {
    test('mapFromRaw creates SpotifyAudioFile from raw bytes and format int', () {
      final rawBytes = <int>[
        0xd3, 0xd7, 0xb9, 0x0c, 0x56, 0x9d, 0xd5, 0x2c, 0x0c, 0x5e,
        0xc8, 0x12, 0xba, 0x0b, 0x58, 0x3a, 0x8a, 0xb8, 0xa7, 0xef,
      ];
      final file = SpotifyAudioFileMapper.mapFromRaw(
        fileIdBytes: rawBytes,
        formatNumber: 1, // OGG_VORBIS_160
      );

      expect(file, isNotNull);
      expect(file?.fileIdHex, 'd3d7b90c569dd52c0c5ec812ba0b583a8ab8a7ef');
      expect(file?.format, SpotifyAudioFormat.oggVorbis160);
    });

    test('selectHeadFile prefers OGG_VORBIS_160 chunk 0 format', () {
      const files = <SpotifyAudioFile>[
        SpotifyAudioFile(
          fileIdHex: '1111111111111111111111111111111111111111',
          format: SpotifyAudioFormat.oggVorbis96,
        ),
        SpotifyAudioFile(
          fileIdHex: '2222222222222222222222222222222222222222',
          format: SpotifyAudioFormat.oggVorbis160,
        ),
        SpotifyAudioFile(
          fileIdHex: '3333333333333333333333333333333333333333',
          format: SpotifyAudioFormat.oggVorbis320,
        ),
      ];

      final selected = SpotifyAudioFileMapper.selectHeadFile(files);
      expect(selected, isNotNull);
      expect(selected?.format, SpotifyAudioFormat.oggVorbis160);
      expect(selected?.fileIdHex, '2222222222222222222222222222222222222222');
    });

    test('selectHeadFile falls back to closest Vorbis bitrate when 160 is missing', () {
      const filesWith320 = <SpotifyAudioFile>[
        SpotifyAudioFile(
          fileIdHex: '1111111111111111111111111111111111111111',
          format: SpotifyAudioFormat.oggVorbis96,
        ),
        SpotifyAudioFile(
          fileIdHex: '3333333333333333333333333333333333333333',
          format: SpotifyAudioFormat.oggVorbis320,
        ),
      ];

      // Falls back to Vorbis 320
      final selected320 = SpotifyAudioFileMapper.selectHeadFile(filesWith320);
      expect(selected320?.format, SpotifyAudioFormat.oggVorbis320);
      expect(selected320?.fileIdHex, '3333333333333333333333333333333333333333');

      const filesWithOnly96 = <SpotifyAudioFile>[
        SpotifyAudioFile(
          fileIdHex: '1111111111111111111111111111111111111111',
          format: SpotifyAudioFormat.oggVorbis96,
        ),
      ];

      // Falls back to Vorbis 96
      final selected96 = SpotifyAudioFileMapper.selectHeadFile(filesWithOnly96);
      expect(selected96?.format, SpotifyAudioFormat.oggVorbis96);
      expect(selected96?.fileIdHex, '1111111111111111111111111111111111111111');
    });

    test('selectFullTrackFile prefers MP4_128 (AAC) format', () {
      const files = <SpotifyAudioFile>[
        SpotifyAudioFile(
          fileIdHex: '1111111111111111111111111111111111111111',
          format: SpotifyAudioFormat.oggVorbis320,
        ),
        SpotifyAudioFile(
          fileIdHex: '2222222222222222222222222222222222222222',
          format: SpotifyAudioFormat.mp4128,
        ),
        SpotifyAudioFile(
          fileIdHex: '3333333333333333333333333333333333333333',
          format: SpotifyAudioFormat.mp4256,
        ),
      ];

      final selected = SpotifyAudioFileMapper.selectFullTrackFile(files);
      expect(selected, isNotNull);
      expect(selected?.format, SpotifyAudioFormat.mp4128);
      expect(selected?.fileIdHex, '2222222222222222222222222222222222222222');
    });

    test('selectFullTrackFile falls back through AAC hierarchy when preferred format is missing', () {
      const files = <SpotifyAudioFile>[
        SpotifyAudioFile(
          fileIdHex: '1111111111111111111111111111111111111111',
          format: SpotifyAudioFormat.oggVorbis320,
        ),
        SpotifyAudioFile(
          fileIdHex: '3333333333333333333333333333333333333333',
          format: SpotifyAudioFormat.mp4256,
        ),
      ];

      final selected = SpotifyAudioFileMapper.selectFullTrackFile(files);
      expect(selected, isNotNull);
      expect(selected?.format, SpotifyAudioFormat.mp4256);
      expect(selected?.fileIdHex, '3333333333333333333333333333333333333333');
    });
  });

  group('TrackV4Plugin & Protobuf Integration', () {
    test('parses Track protobuf with file_ and preview_ AudioFiles', () {
      final rawHeadBytes = <int>[
        0xd3, 0xd7, 0xb9, 0x0c, 0x56, 0x9d, 0xd5, 0x2c, 0x0c, 0x5e,
        0xc8, 0x12, 0xba, 0x0b, 0x58, 0x3a, 0x8a, 0xb8, 0xa7, 0xef,
      ];
      final rawTrackBytes = <int>[
        0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff, 0x11, 0x22, 0x33, 0x44,
        0x55, 0x66, 0x77, 0x88, 0x99, 0x00, 0x12, 0x34, 0x56, 0x78,
      ];

      final trackProto = meta_pb.Track(
        gid: <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
        name: 'Test Song',
        duration: 210000,
      );

      // Add full track file (MP4_128)
      trackProto.file.add(
        meta_pb.AudioFile(
          fileId: rawTrackBytes,
          format: meta_pb.AudioFile_Format.MP4_128,
        ),
      );

      // Add preview head file (OGG_VORBIS_160)
      trackProto.preview.add(
        meta_pb.AudioFile(
          fileId: rawHeadBytes,
          format: meta_pb.AudioFile_Format.OGG_VORBIS_160,
        ),
      );

      const plugin = TrackV4Plugin();
      final trait = plugin.parse(Uint8List.fromList(trackProto.writeToBuffer()));

      expect(trait.title, 'Test Song');
      expect(trait.durationMs, 210000);
      expect(trait.fileId, 'd3d7b90c569dd52c0c5ec812ba0b583a8ab8a7ef');
      expect(
        trait.headUrl,
        'https://heads-fa-tls13.spotifycdn.com/head/d3d7b90c569dd52c0c5ec812ba0b583a8ab8a7ef',
      );
    });
  });
}
