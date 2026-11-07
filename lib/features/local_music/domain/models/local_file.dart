import 'package:flutter/foundation.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_metadata.dart';

/// 1:1 Spotify `com.spotify.localfiles.proto.LocalFile`.
@immutable
final class LocalFile {
  final String path;
  final LocalFileMetadata? metadata;

  const LocalFile({
    required this.path,
    this.metadata,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalFile &&
          other.path == path &&
          other.metadata == metadata);

  @override
  int get hashCode => Object.hash(path, metadata);
}
