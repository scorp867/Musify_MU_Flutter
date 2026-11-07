import 'package:flutter/foundation.dart';

/// 1:1 replica of Spotify Android's `p199p/c9d1.java` (`TrackV4.ExternalId`).
@immutable
final class TrackV4ExternalId {
  final String id;
  final String type;

  const TrackV4ExternalId({
    required this.id,
    required this.type,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackV4ExternalId && other.id == id && other.type == type;
  }

  @override
  int get hashCode => Object.hash(id, type);
}
