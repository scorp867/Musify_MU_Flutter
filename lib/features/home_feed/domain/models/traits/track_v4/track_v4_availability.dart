import 'dart:collection';
import 'package:flutter/foundation.dart';

/// 1:1 replica of Spotify Android's `p199p/a9d1.java` (`TrackV4.Availability`).
@immutable
final class TrackV4Availability {
  final UnmodifiableListView<String> catalogueStrs;

  TrackV4Availability({
    required List<String> catalogueStrs,
  }) : catalogueStrs = UnmodifiableListView<String>(
         List<String>.of(catalogueStrs),
       );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackV4Availability &&
        listEquals(other.catalogueStrs, catalogueStrs);
  }

  @override
  int get hashCode => Object.hashAll(catalogueStrs);
}
