import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/protocol/generated/spotify/metadata.pb.dart'
    as meta_pb;
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';
import 'package:musify_mu/features/player/data/mappers/spotify_audio_file_mapper.dart';
import 'package:musify_mu/features/player/data/services/spotify_head_resolver.dart';
import 'package:musify_mu/features/player/domain/models/spotify_audio_file.dart';

/// Plugin for ExtensionKind 10 (TRACK_V4).
/// Provides complete track metadata matching Spotify Android's TrackV4 extension,
/// including 1:1 extraction of full track AudioFiles and preview Head files.
class TrackV4Plugin implements ExtendedMetadataPlugin<TrackMetaTrait> {
  const TrackV4Plugin();

  @override
  Type get traitType => TrackMetaTrait;

  @override
  int get extensionKindValue => 10;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.TRACK_V4;

  @override
  TrackMetaTrait parse(Uint8List payload) {
    final track = meta_pb.Track.fromBuffer(payload);
    final title = track.name;
    final artists = track.artist.map((a) => a.name).where((n) => n.isNotEmpty);
    final subtitle = artists.join(', ');
    final albumName = track.hasAlbum() ? track.album.name : '';
    final duration = track.hasDuration() ? track.duration : 0;
    final trackUri = track.hasGid()
        ? 'spotify:track:${track.gid.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}'
        : '';

    final imageUrls = <String, String>{};
    String? largeImageHex;

    if (track.hasAlbum() && track.album.hasCoverGroup()) {
      for (final image in track.album.coverGroup.image) {
        if (!image.hasFileId() || image.fileId.isEmpty) continue;
        final hex = image.fileId
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        final url = 'https://i.scdn.co/image/$hex';

        switch (image.size) {
          case meta_pb.Image_Size.SMALL:
            imageUrls['small'] = url;
            break;
          case meta_pb.Image_Size.LARGE:
            imageUrls['medium'] = url;
            largeImageHex ??= hex;
            break;
          case meta_pb.Image_Size.XLARGE:
            imageUrls['large'] = url;
            largeImageHex = hex;
            break;
          default:
            imageUrls.putIfAbsent('medium', () => url);
            largeImageHex ??= hex;
        }
      }
    }

    final List<SpotifyAudioFile> fullTrackFiles = <SpotifyAudioFile>[];
    final List<({meta_pb.AudioFile_Format format, List<int> rawBytes, SpotifyAudioFile? mapped})> parsedAudioEntries = [];

    for (final file in track.file) {
      if (file.hasFileId() && file.hasFormat()) {
        final mapped = SpotifyAudioFileMapper.mapFromRaw(
          fileIdBytes: file.fileId,
          formatNumber: file.format.value,
        );
        parsedAudioEntries.add((
          format: file.format,
          rawBytes: file.fileId,
          mapped: mapped,
        ));
        if (mapped case final validMapped?) {
          fullTrackFiles.add(validMapped);
        }
      }
    }

    final List<SpotifyAudioFile> previewFiles = <SpotifyAudioFile>[];
    final List<({meta_pb.AudioFile_Format format, List<int> rawBytes, SpotifyAudioFile? mapped})> parsedPreviewEntries = [];

    for (final preview in track.preview) {
      if (preview.hasFileId() && preview.hasFormat()) {
        final mapped = SpotifyAudioFileMapper.mapFromRaw(
          fileIdBytes: preview.fileId,
          formatNumber: preview.format.value,
        );
        parsedPreviewEntries.add((
          format: preview.format,
          rawBytes: preview.fileId,
          mapped: mapped,
        ));
        if (mapped case final validMapped?) {
          previewFiles.add(validMapped);
        }
      }
    }

    // In Spotify, Chunk 0 Head files are 128 KiB Vorbis headers of the full track audio streams.
    // We check fullTrackFiles first for Vorbis formats (OGG_VORBIS_160 / 320 / 96).
    // As a strict safeguard, selectHeadFile ONLY returns Vorbis formats and returns null for non-Vorbis.
    final SpotifyAudioFile? selectedHead =
        SpotifyAudioFileMapper.selectHeadFile(fullTrackFiles) ??
        SpotifyAudioFileMapper.selectHeadFile(previewFiles);

    final SpotifyAudioFile? selectedTrack =
        SpotifyAudioFileMapper.selectFullTrackFile(fullTrackFiles);

    // Only set headUrl if a valid Vorbis head file is present.
    // If no Vorbis stream is available, headUrl remains empty so the player can gracefully bypass
    // the head file download and directly stream the full track.
    final String fileId;
    final String headUrl;
    if (selectedHead case final validHead? when validHead.fileIdHex.isNotEmpty) {
      fileId = validHead.fileIdHex;
      headUrl = SpotifyHeadResolver.instance.buildHeadUrl(fileId);
    } else {
      fileId = selectedTrack?.fileIdHex ?? '';
      headUrl = '';
    }

    // Clean, formatted per-track logging displaying all received formats and head selection
    _logTrackMetadata(
      trackTitle: title,
      subtitle: subtitle,
      trackUri: trackUri,
      audioEntries: parsedAudioEntries,
      previewEntries: parsedPreviewEntries,
      selectedHead: selectedHead,
      headUrl: headUrl,
      fallbackFileId: fileId,
    );

    return TrackMetaTrait(
      uri: trackUri,
      title: title,
      subtitle: subtitle,
      albumName: albumName,
      imageUrls: imageUrls,
      largeImageHex: largeImageHex,
      durationMs: duration,
      fileId: fileId,
      headUrl: headUrl,
    );
  }

  void _logTrackMetadata({
    required String trackTitle,
    required String subtitle,
    required String trackUri,
    required List<({meta_pb.AudioFile_Format format, List<int> rawBytes, SpotifyAudioFile? mapped})> audioEntries,
    required List<({meta_pb.AudioFile_Format format, List<int> rawBytes, SpotifyAudioFile? mapped})> previewEntries,
    required SpotifyAudioFile? selectedHead,
    required String headUrl,
    required String fallbackFileId,
  }) {
    final sb = StringBuffer();
    sb.writeln('┌─── [TRACK AUDIO FORMATS] ──────────────────────────────────────────────────────────');
    sb.writeln('│ Track:    "$trackTitle"${subtitle.isNotEmpty ? " - $subtitle" : ""}');
    sb.writeln('│ URI:      $trackUri');
    sb.writeln('├── Available Audio Formats (${audioEntries.length} received):');

    if (audioEntries.isEmpty) {
      sb.writeln('│   (none received)');
    } else {
      for (var i = 0; i < audioEntries.length; i++) {
        final entry = audioEntries[i];
        final formatName = entry.format.name;
        final formatCode = entry.format.value;
        final firstHex = entry.rawBytes
            .take(4)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        final firstRaw = entry.rawBytes
            .take(4)
            .map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}')
            .toList();
        final fullHex = entry.mapped?.fileIdHex ?? 'unparseable';
        final isVorbis = entry.mapped?.format.isVorbis ?? false;
        final vorbisBadge = isVorbis ? ' [VORBIS]' : '';

        sb.writeln('│   [$i] $formatName (code: $formatCode$vorbisBadge)');
        sb.writeln('│       First Bytes: $firstHex $firstRaw -> Full ID: $fullHex');
      }
    }

    if (previewEntries.isNotEmpty) {
      sb.writeln('├── Preview Formats (${previewEntries.length} received):');
      for (var i = 0; i < previewEntries.length; i++) {
        final entry = previewEntries[i];
        final formatName = entry.format.name;
        final formatCode = entry.format.value;
        final firstHex = entry.rawBytes
            .take(4)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        final firstRaw = entry.rawBytes
            .take(4)
            .map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}')
            .toList();
        final fullHex = entry.mapped?.fileIdHex ?? 'unparseable';

        sb.writeln('│   [$i] $formatName (code: $formatCode)');
        sb.writeln('│       First Bytes: $firstHex $firstRaw -> Full ID: $fullHex');
      }
    }

    sb.writeln('├── Head File Decision:');
    if (selectedHead case final head? when head.fileIdHex.isNotEmpty) {
      final headFirstHex = head.fileIdHex.length >= 8 ? head.fileIdHex.substring(0, 8) : head.fileIdHex;
      sb.writeln('│   ✔ PICKED FOR HEAD: [${head.format.name}] (format code: ${head.format.number})');
      sb.writeln('│     File ID: $headFirstHex... (Full: ${head.fileIdHex})');
      sb.writeln('│     CDN URL: $headUrl');
    } else {
      sb.writeln('│   ✖ NO VORBIS FORMAT AVAILABLE -> Head fetch bypassed, streaming directly (File ID: $fallbackFileId)');
    }
    sb.writeln('└────────────────────────────────────────────────────────────────────────────────────');

    final logOutput = sb.toString();
    dev.log(logOutput, name: 'Metadata.FileId');
    debugPrint(logOutput);
  }
}
