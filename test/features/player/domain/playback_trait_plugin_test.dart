import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/kodiak_cell_mapper.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/plugins/builtin_plugins.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/kodiak/table/table_key.dart';
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/playback_trait.pb.dart'
    as pb;
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';
import 'package:musify_mu/features/player/data/services/spotify_head_resolver.dart';
import 'package:musify_mu/features/player/data/services/spotify_hex_utils.dart';

void main() {
  group('PlaybackTraitPlugin (ExtensionKind 212 - 1:1 with Spotify aks0.java)', () {
    const plugin = PlaybackTraitPlugin();

    test('verifies extension kind and trait type contracts', () {
      expect(plugin.extensionKindValue, equals(212));
      expect(plugin.extensionKind, equals(ExtensionKind.PLAYBACK_TRAIT));
      expect(plugin.traitType, equals(PlaybackTrait));
    });

    test('parses PlaybackTrait with hosted audio_id and offsets', () {
      final dummyFileIdBytes = List<int>.generate(20, (i) => i + 1);
      final expectedHex = SpotifyHexUtils.formatFileId(dummyFileIdBytes);

      final proto = pb.PlaybackTrait()
        ..audio.add(
          pb.AudioMapEntry()
            ..key = 1 // OGG_VORBIS_160
            ..value = (pb.AudioPlayback()
              ..reportingUri = 'spotify:play:report:123'
              ..offsets = (pb.PlaybackOffsets()
                ..start = (pb.Duration()..seconds = Int64(10)..nanos = 500000000)
                ..end = (pb.Duration()..seconds = Int64(40)..nanos = 0))
              ..hosted = (pb.AudioHosted()..audioId = dummyFileIdBytes)),
        );

      final payload = proto.writeToBuffer();
      final trait = plugin.parse(payload);

      expect(trait.hasAudio, isTrue);
      expect(trait.primaryFileIdHex, equals(expectedHex));
      expect(
        trait.headUrl,
        equals(SpotifyHeadResolver.instance.buildHeadUrl(expectedHex)),
      );
      expect(trait.audioTracks.length, equals(1));
      expect(trait.audioTracks.first.formatNumber, equals(1));
      expect(trait.audioTracks.first.reportingUri, equals('spotify:play:report:123'));
      expect(trait.audioTracks.first.startOffsetMs, equals(10500));
      expect(trait.audioTracks.first.endOffsetMs, equals(40000));
    });

    test('Vorbis bitrate fallback: prefers 160 kbps, then falls back to closest 320 kbps, then 96 kbps', () {
      final fileId96 = List<int>.filled(20, 0x09);
      final fileId320 = List<int>.filled(20, 0x32);
      final hex320 = SpotifyHexUtils.formatFileId(fileId320);

      // Scenario: 160 is missing, only 96 and 320 are provided
      final proto = pb.PlaybackTrait()
        ..audio.addAll([
          pb.AudioMapEntry()
            ..key = 0 // OGG_VORBIS_96
            ..value = (pb.AudioPlayback()
              ..hosted = (pb.AudioHosted()..audioId = fileId96)),
          pb.AudioMapEntry()
            ..key = 2 // OGG_VORBIS_320
            ..value = (pb.AudioPlayback()
              ..hosted = (pb.AudioHosted()..audioId = fileId320)),
        ]);

      final trait = plugin.parse(proto.writeToBuffer());

      // Closest Vorbis bitrate fallback must pick 320 kbps
      expect(trait.primaryFileIdHex, equals(hex320));
      expect(
        trait.headUrl,
        equals(SpotifyHeadResolver.instance.buildHeadUrl(hex320)),
      );
    });

    test('parses pass-through CDN stream when hosted is absent', () {
      const cdnUrl = 'https://audio4-fa.scdn.co/stream/dummy.aac';

      final proto = pb.PlaybackTrait()
        ..audio.add(
          pb.AudioMapEntry()
            ..key = 10 // MP4_128
            ..value = (pb.AudioPlayback()
              ..passThrough = (pb.AudioPassThrough()
                ..flatFile = (pb.FlatFile()..cdnUrl = cdnUrl))),
        );

      final trait = plugin.parse(proto.writeToBuffer());

      expect(trait.hasAudio, isTrue);
      expect(trait.primaryFileIdHex, isEmpty);
      expect(trait.passThroughCdnUrl, equals(cdnUrl));
      expect(trait.audioTracks.first.cdnUrl, equals(cdnUrl));
    });

    test('registered in createDefaultExtendedMetadataPlugins and plugin registry', () {
      final registry = ExtendedMetadataPluginRegistry(
        createDefaultExtendedMetadataPlugins(),
      );

      final pluginByKind = registry.pluginForKind(212);
      expect(pluginByKind, isNotNull);
      expect(pluginByKind, isA<PlaybackTraitPlugin>());

      final pluginByType = registry.pluginForType(PlaybackTrait);
      expect(pluginByType, isNotNull);
      expect(pluginByType, isA<PlaybackTraitPlugin>());
    });

    test('KodiakCellMapper maps PlaybackTrait into typed CellKey', () {
      const trackUri = 'spotify:track:2YBt1Fy6ZLBCjxYjI8v2YW';
      const trait = PlaybackTrait(
        primaryFileIdHex: '0102030405060708090a0b0c0d0e0f1011121314',
        headUrl: 'https://heads-fa.spotifycdn.com/head/0102030405060708090a0b0c0d0e0f1011121314',
      );

      final input = {
        trackUri: {PlaybackTrait: trait},
      };

      final mapped = KodiakCellMapper.map(input);
      final expectedKey = CellKey(const TableKey<PlaybackTrait>(), trackUri);

      expect(mapped.containsKey(expectedKey), isTrue);
      expect(mapped[expectedKey], equals(trait));
    });
  });
}
