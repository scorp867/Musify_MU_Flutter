import 'package:flutter/foundation.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_image_state.dart';

/// 1:1 Spotify `com.spotify.localfiles.proto.LocalFile$Metadata`.
///
/// Note: [duration] is in seconds, matching `MediaStoreReader.duration`
/// (`cursor.getInt(durationColumn) / 1000`).
@immutable
final class LocalFileMetadata {
  final String title;
  final String album;
  final String artist;
  final int duration;
  final LocalFileImageState imageState;

  const LocalFileMetadata({
    this.title = '',
    this.album = '',
    this.artist = '',
    this.duration = 0,
    this.imageState = LocalFileImageState.unknown,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalFileMetadata &&
          other.title == title &&
          other.album == album &&
          other.artist == artist &&
          other.duration == duration &&
          other.imageState == imageState);

  @override
  int get hashCode => Object.hash(
    title,
    album,
    artist,
    duration,
    imageState,
  );
}
