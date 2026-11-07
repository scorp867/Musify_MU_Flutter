import 'dart:collection';
import 'package:flutter/foundation.dart';

import '../trait.dart';

/// 1:1 replica of Spotify Android's `p199p/fey.java` (`EpisodeV4.ContentRating`).
@immutable
final class EpisodeContentRating extends Trait {
  final String country;
  final UnmodifiableListView<String> tags;

  EpisodeContentRating({
    required this.country,
    required List<String> tags,
  }) : tags = UnmodifiableListView<String>(List<String>.of(tags));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EpisodeContentRating &&
        other.country == country &&
        listEquals(other.tags, tags);
  }

  @override
  int get hashCode => Object.hash(country, Object.hashAll(tags));
}
