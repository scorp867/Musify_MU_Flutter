import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/playback_trait.pb.dart'
    as pb;
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';
import 'package:musify_mu/features/player/data/mappers/spotify_audio_file_mapper.dart';
import 'package:musify_mu/features/player/data/services/spotify_head_resolver.dart';
import 'package:musify_mu/features/player/data/services/spotify_hex_utils.dart';
import 'package:musify_mu/features/player/domain/models/spotify_audio_file.dart';
import 'package:musify_mu/features/player/domain/models/spotify_audio_format.dart';

/// Plugin for ExtensionKind 212 (PLAYBACK_TRAIT).
/// Direct 1:1 equivalent to Spotify Android's `p.aks0` decoder plugin.
///
/// Decodes `com.spotify.contentagnostic.v2.PlaybackTrait` protobuf payloads,
/// extracting audio file IDs, audio formats/bitrates, head chunk URLs,
/// and pass-through CDN streams.
class PlaybackTraitPlugin implements ExtendedMetadataPlugin<PlaybackTrait> {
  const PlaybackTraitPlugin();

  @override
  Type get traitType => PlaybackTrait;

  @override
  int get extensionKindValue => 212;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.PLAYBACK_TRAIT;

  @override
  PlaybackTrait parse(Uint8List payload) {
    final trait = pb.PlaybackTrait.fromBuffer(payload);
    final audioTracks = <PlaybackAudioTrack>[];
    final audioFiles = <SpotifyAudioFile>[];
    final hostedEntries = <({
      int formatNumber,
      String fileIdHex,
      List<int>? rawBytes,
      int? bitrate,
      SpotifyAudioFormat? mappedFormat,
    })>[];

    String passThroughCdnUrl = '';

    for (final entry in trait.audio) {
      final formatNumber = entry.key;
      // In Spotify's contentagnostic.v2.PlaybackTrait, entry.key is AudioMediaFormat:
      // 0 = UNSPECIFIED, 1 = STEREO, 2 = SPATIAL, 3 = ADAPTIVE.
      final playback = entry.value;

      int startMs = 0;
      int endMs = 0;
      if (playback.hasOffsets()) {
        final offsets = playback.offsets;
        if (offsets.hasStart()) {
          startMs = (offsets.start.seconds.toInt() * 1000) +
              ((offsets.start.nanos) ~/ 1000000);
        }
        if (offsets.hasEnd()) {
          endMs = (offsets.end.seconds.toInt() * 1000) +
              ((offsets.end.nanos) ~/ 1000000);
        }
      }

      final reportingUri = playback.reportingUri;

      // 1. Hosted audio stream (ap7 in Spotify aks0.java)
      if (playback.hasHosted()) {
        final hosted = playback.hosted;

        // Check audio_id first (1:1 with Spotify aks0.java line 57)
        if (hosted.hasAudioId() && hosted.audioId.isNotEmpty) {
          final fileIdHex = SpotifyHexUtils.formatFileId(hosted.audioId);

          if (fileIdHex.isNotEmpty && fileIdHex.length == 40) {
            audioTracks.add(PlaybackAudioTrack(
              formatNumber: formatNumber,
              fileIdHex: fileIdHex,
              reportingUri: reportingUri,
              startOffsetMs: startMs,
              endOffsetMs: endMs,
            ));

            // Map channel format to corresponding Vorbis format:
            // 1 (STEREO) -> OGG_VORBIS_160, 2 (SPATIAL) -> OGG_VORBIS_320, 0 (UNSPECIFIED) -> OGG_VORBIS_96
            final mappedFormat = formatNumber == 1
                ? SpotifyAudioFormat.oggVorbis160
                : (formatNumber == 2
                    ? SpotifyAudioFormat.oggVorbis320
                    : SpotifyAudioFormat.oggVorbis96);

            final mapped = SpotifyAudioFileMapper.fromHex(
              fileIdHex: fileIdHex,
              format: mappedFormat,
            );
            if (mapped case final validMapped?) {
              audioFiles.add(validMapped);
            }

            hostedEntries.add((
              formatNumber: formatNumber,
              fileIdHex: fileIdHex,
              rawBytes: hosted.audioId,
              bitrate: null,
              mappedFormat: mappedFormat,
            ));
          }
        }

        // Also check nested files inside hosted (1:1 with AudioHosted.files)
        for (final file in hosted.files) {
          if (file.hasFileId() && file.fileId.isNotEmpty) {
            final fileIdHex = SpotifyHexUtils.formatFileId(file.fileId);

            if (fileIdHex.isNotEmpty && fileIdHex.length == 40) {
              audioTracks.add(PlaybackAudioTrack(
                formatNumber: formatNumber,
                fileIdHex: fileIdHex,
                reportingUri: reportingUri,
                averageBitrate: file.averageBitrate,
                startOffsetMs: startMs,
                endOffsetMs: endMs,
              ));

              final mappedFormat =
                  SpotifyAudioFileMapper.mapFromBitrate(file.averageBitrate);

              final mapped = SpotifyAudioFileMapper.fromHex(
                fileIdHex: fileIdHex,
                format: mappedFormat,
              );
              if (mapped case final validMapped?) {
                audioFiles.add(validMapped);
              }

              hostedEntries.add((
                formatNumber: formatNumber,
                fileIdHex: fileIdHex,
                rawBytes: file.fileId,
                bitrate: file.averageBitrate,
                mappedFormat: mappedFormat,
              ));
            }
          }
        }
      }

      // 2. Pass-through CDN audio stream (bp7 in Spotify aks0.java)
      if (playback.hasPassThrough()) {
        final passThrough = playback.passThrough;
        if (passThrough.hasFlatFile() && passThrough.flatFile.cdnUrl.isNotEmpty) {
          final cdn = passThrough.flatFile.cdnUrl;
          if (passThroughCdnUrl.isEmpty) {
            passThroughCdnUrl = cdn;
          }
          audioTracks.add(PlaybackAudioTrack(
            formatNumber: formatNumber,
            cdnUrl: cdn,
            reportingUri: reportingUri,
            startOffsetMs: startMs,
            endOffsetMs: endMs,
          ));
        }
      }
    }

    // Select primary audio file ID using Spotify's vorbis bitrate fallback hierarchy:
    // 160 kbps -> 320 kbps -> 96 kbps
    final selectedHead = SpotifyAudioFileMapper.selectHeadFile(audioFiles);
    final selectedTrack = SpotifyAudioFileMapper.selectFullTrackFile(audioFiles);

    final String primaryFileIdHex;
    final String headUrl;
    if (selectedHead case final validHead? when validHead.fileIdHex.isNotEmpty) {
      primaryFileIdHex = validHead.fileIdHex;
      headUrl = SpotifyHeadResolver.instance.buildHeadUrl(primaryFileIdHex);
    } else if (selectedTrack case final validTrack? when validTrack.fileIdHex.isNotEmpty) {
      primaryFileIdHex = validTrack.fileIdHex;
      headUrl = validTrack.format.isVorbis
          ? SpotifyHeadResolver.instance.buildHeadUrl(primaryFileIdHex)
          : '';
    } else {
      final firstWithHex = audioTracks.where((t) => t.fileIdHex.isNotEmpty).firstOrNull;
      primaryFileIdHex = firstWithHex?.fileIdHex ?? '';
      headUrl = '';
    }

    // Clean, formatted per-track logging for PlaybackTrait
    _logPlaybackTraitSummary(
      hostedEntries: hostedEntries,
      passThroughCdnUrl: passThroughCdnUrl,
      selectedHead: selectedHead,
      headUrl: headUrl,
      fallbackFileId: primaryFileIdHex,
    );

    return PlaybackTrait(
      audioTracks: List.unmodifiable(audioTracks),
      primaryFileIdHex: primaryFileIdHex,
      headUrl: headUrl,
      passThroughCdnUrl: passThroughCdnUrl,
    );
  }

  void _logPlaybackTraitSummary({
    required List<({
      int formatNumber,
      String fileIdHex,
      List<int>? rawBytes,
      int? bitrate,
      SpotifyAudioFormat? mappedFormat,
    })> hostedEntries,
    required String passThroughCdnUrl,
    required SpotifyAudioFile? selectedHead,
    required String headUrl,
    required String fallbackFileId,
  }) {
    final sb = StringBuffer();
    sb.writeln('┌─── [PLAYBACK_TRAIT AUDIO FORMATS] ─────────────────────────────────────────────────');
    sb.writeln('├── Available Stream Formats (${hostedEntries.length} hosted received):');

    if (hostedEntries.isEmpty) {
      sb.writeln('│   (none hosted)');
    } else {
      for (var i = 0; i < hostedEntries.length; i++) {
        final entry = hostedEntries[i];
        final formatDesc = entry.formatNumber == 1
            ? 'STEREO'
            : (entry.formatNumber == 2 ? 'SPATIAL' : 'UNSPECIFIED');
        final firstHex = entry.fileIdHex.length >= 8 ? entry.fileIdHex.substring(0, 8) : entry.fileIdHex;
        final rawStr = entry.rawBytes != null
            ? entry.rawBytes!.take(4).map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').toList().toString()
            : '[]';
        final bitrateDesc = entry.bitrate != null ? ' | Bitrate: ${entry.bitrate} bps' : '';
        final isVorbis = entry.mappedFormat?.isVorbis ?? false;
        final vorbisBadge = isVorbis ? ' [VORBIS]' : '';

        sb.writeln('│   [$i] $formatDesc (${entry.formatNumber}$vorbisBadge) -> ${entry.mappedFormat?.name ?? "unmapped"}$bitrateDesc');
        sb.writeln('│       First Bytes: $firstHex $rawStr -> Full ID: ${entry.fileIdHex}');
      }
    }

    if (passThroughCdnUrl.isNotEmpty) {
      sb.writeln('├── Pass-Through CDN Stream:');
      sb.writeln('│   • URL: $passThroughCdnUrl');
    }

    sb.writeln('├── Head File Decision:');
    if (selectedHead case final head? when head.fileIdHex.isNotEmpty) {
      final headFirstHex = head.fileIdHex.length >= 8 ? head.fileIdHex.substring(0, 8) : head.fileIdHex;
      sb.writeln('│   ✔ PICKED FOR HEAD: [${head.format.name}] (format code: ${head.format.number})');
      sb.writeln('│     File ID: $headFirstHex... (Full: ${head.fileIdHex})');
      sb.writeln('│     CDN URL: $headUrl');
    } else {
      sb.writeln('│   ✖ NO VORBIS FORMAT AVAILABLE -> Head fetch bypassed (Fallback ID: ${fallbackFileId.isNotEmpty ? fallbackFileId : "none"})');
    }
    sb.writeln('└────────────────────────────────────────────────────────────────────────────────────');

    final logOutput = sb.toString();
    dev.log(logOutput, name: 'Metadata.FileId');
    debugPrint(logOutput);
  }
}
