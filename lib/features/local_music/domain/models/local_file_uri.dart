import 'dart:convert';

import 'package:musify_mu/features/local_music/domain/models/added_local_file.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_metadata.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';

/// 1:1 Spotify Local Files URI encoder & mapper matching
/// `OpenedAudioFiles.toSpotifyLocalUri` (`xr81.m92424e`) and `rpl1.m76696q`.
abstract final class LocalFileUri {
  static const String localTrackPrefix = 'spotify:local:';
  static const String localImagePrefix = 'spotify:localfileimage:';

  /// Encodes a local URI component identically to `xr81.m92424e`:
  /// UTF-8 `URLEncoder.encode` with `*` encoded as `%2A`.
  static String encodeComponent(String input) {
    if (input.isEmpty) return '';
    final bytes = utf8.encode(input);
    final out = StringBuffer();
    const hex = '0123456789ABCDEF';
    for (final byte in bytes) {
      final isLower = byte >= 0x61 && byte <= 0x7A;
      final isUpper = byte >= 0x41 && byte <= 0x5A;
      final isDigit = byte >= 0x30 && byte <= 0x39;
      final isSafePunct = byte == 0x2E || byte == 0x2D || byte == 0x5F;
      if (isLower || isUpper || isDigit || isSafePunct) {
        out.writeCharCode(byte);
      } else if (byte == 0x20) {
        out.write('+');
      } else {
        out.write('%');
        out.write(hex[(byte >> 4) & 0x0F]);
        out.write(hex[byte & 0x0F]);
      }
    }
    return out.toString();
  }

  /// Builds `spotify:local:<encodedArtist>:<encodedAlbum>:<encodedTitle>:<durationSeconds>`.
  static String fromMetadata({
    required String artist,
    required String album,
    required String title,
    required int durationSeconds,
  }) {
    final safeDuration = durationSeconds < 0 ? 0 : durationSeconds;
    return '$localTrackPrefix'
        '${encodeComponent(artist)}:'
        '${encodeComponent(album)}:'
        '${encodeComponent(title)}:'
        '$safeDuration';
  }

  /// Builds `spotify:local:...` from a [LocalFile].
  static String fromLocalFile(LocalFile file) {
    final meta = switch (file.metadata) {
      final m? => m,
      null => const LocalFileMetadata(),
    };
    return fromMetadata(
      artist: meta.artist,
      album: meta.album,
      title: meta.title,
      durationSeconds: meta.duration,
    );
  }

  /// Converts `LocalFile` to `AddedLocalFile` matching `OpenedAudioFiles.toAddedLocalFile`.
  static AddedLocalFile toAddedLocalFile(LocalFile file) {
    final meta = switch (file.metadata) {
      final m? => m,
      null => const LocalFileMetadata(),
    };
    return AddedLocalFile(
      duration: meta.duration,
      albumName: meta.album,
      artistName: meta.artist,
      trackTitle: meta.title,
      localTrackUri: fromLocalFile(file),
    );
  }

  /// Maps `spotify:local:...` to `spotify:localfileimage:...` matching `rpl1.m76696q`.
  static String toLocalFileImageUri(String localTrackUri) {
    if (localTrackUri.startsWith(localImagePrefix)) {
      return localTrackUri;
    }
    if (localTrackUri.startsWith(localTrackPrefix)) {
      return '$localImagePrefix${localTrackUri.substring(localTrackPrefix.length)}';
    }
    return localTrackUri;
  }

  /// Maps `spotify:localfileimage:...` back to `spotify:local:...`.
  static String toLocalTrackUri(String uri) {
    if (uri.startsWith(localTrackPrefix)) {
      return uri;
    }
    if (uri.startsWith(localImagePrefix)) {
      return '$localTrackPrefix${uri.substring(localImagePrefix.length)}';
    }
    return uri;
  }

  static bool isLocalTrackUri(String? uri) =>
      uri != null && uri.startsWith(localTrackPrefix);

  static bool isLocalImageUri(String? uri) =>
      uri != null && uri.startsWith(localImagePrefix);

  static bool isAnyLocalUri(String? uri) =>
      isLocalTrackUri(uri) || isLocalImageUri(uri);

  /// Builds a canonical Spotify [ContextTrack] for a [LocalFile].
  static ContextTrack toContextTrack(LocalFile file, {required int uidIndex}) {
    final meta = switch (file.metadata) {
      final m? => m,
      null => const LocalFileMetadata(),
    };
    final trackUri = fromLocalFile(file);
    final imageUri = toLocalFileImageUri(trackUri);
    final durationMs = meta.duration > 0 ? meta.duration * 1000 : 0;

    return ContextTrack.builder(trackUri)
        .uid('local_$uidIndex')
        .metadata({
          ContextTrackMetadata.keyIsLocal: 'true',
          ContextTrackMetadata.keyLocalFilePath: file.path,
          ContextTrackMetadata.keyTitle: meta.title,
          ContextTrackMetadata.keyArtistName: meta.artist,
          if (meta.album.isNotEmpty)
            ContextTrackMetadata.keyAlbumTitle: meta.album,
          ContextTrackMetadata.keyDuration: durationMs.toString(),
          ContextTrackMetadata.keyImageUrl: imageUri,
          ContextTrackMetadata.keyImageSmallUrl: imageUri,
          ContextTrackMetadata.keyImageLargeUrl: imageUri,
          ContextTrackMetadata.keyThumbnailImageUrl: imageUri,
          ContextTrackMetadata.keyIsQueued: 'false',
        })
        .build();
  }
}
