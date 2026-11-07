import 'package:flutter/foundation.dart';

import 'audio_file_format.dart';

/// 1:1 replica of Spotify Android's `p199p/z8d1.java` (`TrackV4AudioFile`).
@immutable
final class TrackV4AudioFile {
  final String fileId;
  final AudioFileFormat format;

  const TrackV4AudioFile({
    required this.fileId,
    required this.format,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackV4AudioFile &&
        other.fileId == fileId &&
        other.format == format;
  }

  @override
  int get hashCode => Object.hash(fileId, format);
}
