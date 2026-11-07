import 'dart:collection';
import 'package:flutter/foundation.dart';

import 'traits.dart';

export 'traits.dart';

/// Pure Spotify SDUI entity container holding a canonical URI, content type,
/// and immutable map of Kodiak/Eagerload traits.
@immutable
final class SpotifyEntity {
  final String uri;
  final ContentType type;
  final UnmodifiableMapView<String, Trait> traits;

  SpotifyEntity({
    required this.uri,
    required this.type,
    required Map<String, Trait> traits,
  }) : traits = UnmodifiableMapView<String, Trait>(
         Map<String, Trait>.of(traits),
       );

  /// Typed trait accessor by runtime trait class key.
  T? getTrait<T extends Trait>() {
    final trait = traits[T.toString()];
    if (trait is T) {
      return trait;
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpotifyEntity &&
        other.uri == uri &&
        other.type == type &&
        mapEquals(other.traits, traits);
  }

  @override
  int get hashCode =>
      Object.hash(uri, type, Object.hashAllUnordered(traits.entries));
}
