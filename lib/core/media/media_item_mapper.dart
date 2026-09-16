import 'package:audio_service/audio_service.dart';

abstract final class MediaItemMapper {
  static const songIdKey = 'songId';
  static const dataPathKey = 'dataPath';
  static const dateModifiedKey = 'dateModified';
  static const artworkVersionKey = 'artworkVersion';

  static MediaItem fromTrack({
    required String id,
    required String title,
    required String artist,
    String? album,
    int? durationMilliseconds,
    int? songId,
    String? dataPath,
    DateTime? dateModified,
  }) {
    return MediaItem(
      id: id,
      title: title,
      album: album ?? 'Unknown Album',
      artist: artist,
      duration: durationMilliseconds == null
          ? null
          : Duration(milliseconds: durationMilliseconds),
      extras: {
        songIdKey: songId,
        dataPathKey: dataPath,
        dateModifiedKey: dateModified?.millisecondsSinceEpoch,
      },
    );
  }

  static int? songId(MediaItem item) {
    final value = item.extras?[songIdKey];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(item.id);
  }

  static String? dataPath(MediaItem item) {
    final value = item.extras?[dataPathKey];
    return value is String && value.isNotEmpty ? value : null;
  }
}
