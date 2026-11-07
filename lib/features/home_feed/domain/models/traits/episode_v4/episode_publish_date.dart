import 'package:flutter/foundation.dart';

/// 1:1 replica of Spotify Android's `p199p/gey.java` (`EpisodeV4.PublishDate`).
@immutable
final class EpisodePublishDate {
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;

  const EpisodePublishDate({
    this.year = 0,
    this.month = 0,
    this.day = 0,
    this.hour = 0,
    this.minute = 0,
  });

  /// 1:1 replica of `gey.m46785a(Calendar)`.
  DateTime toDateTime({bool isUtc = false}) {
    if (isUtc) {
      return DateTime.utc(year, month, day, hour, minute);
    }
    return DateTime(year, month, day, hour, minute);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EpisodePublishDate &&
        other.year == year &&
        other.month == month &&
        other.day == day &&
        other.hour == hour &&
        other.minute == minute;
  }

  @override
  int get hashCode => Object.hash(year, month, day, hour, minute);
}
