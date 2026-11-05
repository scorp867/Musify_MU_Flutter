import 'dart:developer' as dev;
import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/protocol/generated/spotify/metadata.pb.dart'
    as meta_pb;
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';
import 'package:musify_mu/features/player/data/mappers/spotify_audio_file_mapper.dart';
import 'package:musify_mu/features/player/data/services/spotify_head_resolver.dart';
import 'package:musify_mu/features/player/domain/models/spotify_audio_file.dart';
import 'package:musify_mu/features/player/domain/models/spotify_audio_format.dart';

/// Plugin for ExtensionKind 10 (TRACK_V4).
/// Provides complete track metadata matching Spotify Android's TrackV4 extension (`p199p/a1a.java`),
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
    final canonicalUri = track.hasCanonicalUri() ? track.canonicalUri : '';

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
          case meta_pb.Image_Size.DEFAULT:
            imageUrls['default'] = url;
            imageUrls['medium'] = url;
            break;
          case meta_pb.Image_Size.LARGE:
            imageUrls['large'] = url;
            largeImageHex ??= hex;
            break;
          case meta_pb.Image_Size.XLARGE:
            imageUrls['xlarge'] = url;
            largeImageHex = hex;
            break;
          default:
            imageUrls.putIfAbsent('default', () => url);
            imageUrls.putIfAbsent('medium', () => url);
            largeImageHex ??= hex;
        }
      }
    }

    final List<SpotifyAudioFile> fullTrackFiles = <SpotifyAudioFile>[];

    for (final file in track.file) {
      if (file.hasFileId() && file.hasFormat()) {
        final mapped = SpotifyAudioFileMapper.mapFromRaw(
          fileIdBytes: file.fileId,
          formatNumber: file.format.value,
        );
        if (mapped case final validMapped?) {
          fullTrackFiles.add(validMapped);
        }
      }
    }

    // Relinked track fallback: If primary file list is empty (common for region-restricted
    // or market-relinked tracks), extract audio files from alternative tracks in field 13.
    if (fullTrackFiles.isEmpty && track.alternative.isNotEmpty) {
      for (final altTrack in track.alternative) {
        if (altTrack.file.isNotEmpty) {
          for (final file in altTrack.file) {
            if (file.hasFileId() && file.hasFormat()) {
              final mapped = SpotifyAudioFileMapper.mapFromRaw(
                fileIdBytes: file.fileId,
                formatNumber: file.format.value,
              );
              if (mapped case final validMapped?) {
                fullTrackFiles.add(validMapped);
              }
            }
          }
          if (fullTrackFiles.isNotEmpty) break;
        }
      }
    }

    final List<SpotifyAudioFile> previewFiles = <SpotifyAudioFile>[];

    for (final preview in track.preview) {
      if (preview.hasFileId() && preview.hasFormat()) {
        final mapped = SpotifyAudioFileMapper.mapFromRaw(
          fileIdBytes: preview.fileId,
          formatNumber: preview.format.value,
        );
        if (mapped case final validMapped?) {
          previewFiles.add(validMapped);
        }
      }
    }

    // In Spotify, Chunk 0 Head files are 128 KiB Vorbis headers of the full track audio streams.
    // We check fullTrackFiles first for authentic Vorbis streams (OGG_VORBIS_160 -> 320 -> 96).
    // If fullTrackFiles only carries MP4/AAC streams, check previewFiles for standard Vorbis 160/320 headers.
    // Low-quality 96 kbps preview clips (~25 KB) are strictly rejected to prevent buffer underflow/mismatch.
    final SpotifyAudioFile? selectedHead =
        SpotifyAudioFileMapper.selectHeadFile(fullTrackFiles) ??
        SpotifyAudioFileMapper.selectHeadFile(
          previewFiles.where((f) => f.format != SpotifyAudioFormat.oggVorbis96).toList(),
        );

    final SpotifyAudioFile? selectedTrack =
        SpotifyAudioFileMapper.selectFullTrackFile(fullTrackFiles);

    // Only set headUrl if an authentic Vorbis head file is present.
    // If no Vorbis stream is available, headUrl and fileId remain empty so the player can gracefully
    // bypass the head file download and directly stream the full track without corrupting chunk 0.
    final String fileId;
    final String headUrl;
    if (selectedHead case final validHead? when validHead.fileIdHex.isNotEmpty) {
      fileId = validHead.fileIdHex;
      headUrl = SpotifyHeadResolver.instance.buildHeadUrl(fileId);
    } else {
      fileId = '';
      headUrl = '';
    }

    final String aacFileId;
    if (selectedTrack case final validTrack? when !validTrack.format.isVorbis && validTrack.fileIdHex.isNotEmpty) {
      aacFileId = validTrack.fileIdHex;
    } else {
      aacFileId = '';
    }

    dev.log(
      '[TrackV4] "$title" head=${selectedHead?.format.name ?? "none"} '
      'track=${selectedTrack?.format.name ?? "none"} '
      'files=${fullTrackFiles.length}',
      name: 'Metadata.FileId',
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
      aacFileId: aacFileId,
      headUrl: headUrl,
      canonicalUri: canonicalUri,
    );
  }
}
