import 'package:flutter/foundation.dart';

/// 1:1 replica of Spotify Android's `p199p/d9d1.java` (`TrackV4.Alternative`).
@immutable
final class TrackV4Alternative {
  final String uri;

  const TrackV4Alternative({required this.uri});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackV4Alternative && other.uri == uri;
  }

  @override
  int get hashCode => uri.hashCode;
}
