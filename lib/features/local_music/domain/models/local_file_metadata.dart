import 'package:flutter/foundation.dart';

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

  const LocalFileMetadata({
    this.title = '',
    this.album = '',
    this.artist = '',
    this.duration = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalFileMetadata &&
          other.title == title &&
          other.album == album &&
          other.artist == artist &&
          other.duration == duration);

  @override
  int get hashCode => Object.hash(
    title,
    album,
    artist,
    duration,
  );
}
