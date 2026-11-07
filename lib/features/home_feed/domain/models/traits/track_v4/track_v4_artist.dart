import 'package:flutter/foundation.dart';

/// 1:1 replica of Spotify Android's `p199p/x8d1.java` (`TrackV4.Artist`).
@immutable
final class TrackV4Artist {
  final String uri;
  final String name;

  const TrackV4Artist({
    required this.uri,
    required this.name,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackV4Artist && other.uri == uri && other.name == name;
  }

  @override
  int get hashCode => Object.hash(uri, name);
}
