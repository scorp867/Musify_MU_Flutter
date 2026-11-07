import 'dart:collection';
import 'package:flutter/foundation.dart';

/// 1:1 replica of Spotify Android's `p199p/b9d1.java` (`TrackV4.ContentRating`).
@immutable
final class TrackV4ContentRating {
  final String country;
  final UnmodifiableListView<String> tags;

  TrackV4ContentRating({
    required this.country,
    required List<String> tags,
  }) : tags = UnmodifiableListView<String>(List<String>.of(tags));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackV4ContentRating &&
        other.country == country &&
        listEquals(other.tags, tags);
  }

  @override
  int get hashCode => Object.hash(country, Object.hashAll(tags));
}
