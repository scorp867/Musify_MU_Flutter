import 'package:flutter/foundation.dart';

import 'trait.dart';

/// Concert location metadata (ExtensionKind 123).
@immutable
final class ConcertLocationTrait extends Trait {
  final String venue;
  final String city;

  const ConcertLocationTrait({this.venue = '', this.city = ''});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConcertLocationTrait &&
        other.venue == venue &&
        other.city == city;
  }

  @override
  int get hashCode => Object.hash(venue, city);
}
