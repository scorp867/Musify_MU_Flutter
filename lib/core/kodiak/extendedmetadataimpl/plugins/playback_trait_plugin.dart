import 'dart:developer' as dev;
import 'dart:typed_data';

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
/// extracting audio clip IDs (hosted audio_id `ap7`), pass-through CDN streams (`bp7`),
/// bitrates, and preview offsets matching Spotify's native implementation.
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

    String passThroughCdnUrl = '';

    for (final entry in trait.audio) {
      final formatNumber = entry.key;
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

          if (fileIdHex.isNotEmpty && (fileIdHex.length == 32 || fileIdHex.length == 40)) {
            audioTracks.add(PlaybackAudioTrack(
              formatNumber: formatNumber,
              fileIdHex: fileIdHex,
              reportingUri: reportingUri,
              startOffsetMs: startMs,
              endOffsetMs: endMs,
            ));

            // Legacy/mock fallback: If hosted.files is empty and audioId is 40 hex chars,
            // allow formatNumber to map to a SpotifyAudioFormat (used in unit test mocks).
            final SpotifyAudioFormat? audioIdFormat = (hosted.files.isEmpty && fileIdHex.length == 40)
                ? SpotifyAudioFormat.fromNumber(formatNumber)
                : null;

            if (audioIdFormat != null) {
              audioFiles.add(SpotifyAudioFile(
                fileIdHex: fileIdHex.toLowerCase(),
                format: audioIdFormat,
              ));
            }
          }
        }

        // Also check nested files inside hosted (1:1 with AudioHosted.files)
        for (final file in hosted.files) {
          if (file.hasFileId() && file.fileId.isNotEmpty) {
            final fileIdHex = SpotifyHexUtils.formatFileId(file.fileId);

            if (fileIdHex.isNotEmpty && fileIdHex.length == 40) {
              // Format is determined 1:1 by protobuf format tag 2 (exact match with Kotlin MusifyMU),
              // falling back to averageBitrate if format tag 2 is omitted:
              final int? explicitFormatCode = file.hasFormat() && file.format != 0 ? file.format : null;
              final SpotifyAudioFormat? mappedFormat = (explicitFormatCode != null
                      ? (SpotifyAudioFormat.fromProtobufFormat(explicitFormatCode) ??
                         SpotifyAudioFormat.fromNumber(explicitFormatCode))
                      : null) ??
                  SpotifyAudioFileMapper.mapFromBitrate(file.averageBitrate) ??
                  (file.averageBitrate == 0 ? SpotifyAudioFormat.fromNumber(formatNumber) : null);

              final resolvedFormatNumber = explicitFormatCode ??
                  (mappedFormat?.number ?? formatNumber);

              audioTracks.add(PlaybackAudioTrack(
                formatNumber: resolvedFormatNumber,
                fileIdHex: fileIdHex,
                reportingUri: reportingUri,
                averageBitrate: file.averageBitrate,
                startOffsetMs: startMs,
                endOffsetMs: endMs,
              ));

              if (mappedFormat != null) {
                final mapped = SpotifyAudioFileMapper.fromHex(
                  fileIdHex: fileIdHex,
                  format: mappedFormat,
                );
                if (mapped case final validMapped?) {
                  audioFiles.add(validMapped);
                }
              }
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
    } else {
      primaryFileIdHex = '';
      headUrl = '';
    }

    final String aacFileIdHex;
    if (selectedTrack case final validTrack? when validTrack.format.isMp4 && validTrack.fileIdHex.isNotEmpty) {
      aacFileIdHex = validTrack.fileIdHex;
    } else {
      aacFileIdHex = '';
    }

    dev.log(
      '[PlaybackTrait] head=${selectedHead?.format.name ?? "none"} '
      'track=${selectedTrack?.format.name ?? "none"} '
      'files=${audioFiles.length}',
      name: 'Metadata.FileId',
    );

    return PlaybackTrait(
      audioTracks: List.unmodifiable(audioTracks),
      primaryFileIdHex: primaryFileIdHex,
      aacFileIdHex: aacFileIdHex,
      headUrl: headUrl,
      passThroughCdnUrl: passThroughCdnUrl,
    );
  }
}
