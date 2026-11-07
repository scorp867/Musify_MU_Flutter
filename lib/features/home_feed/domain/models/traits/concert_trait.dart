import 'package:flutter/foundation.dart';

import 'trait.dart';

/// Live Concert / Tour event trait (ExtensionKind 122).
@immutable
final class ConcertTrait extends Trait {
  final String title;
  final String artistName;
  final int eventDateTimestamp;

  const ConcertTrait({
    required this.title,
    this.artistName = '',
    this.eventDateTimestamp = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConcertTrait &&
        other.title == title &&
        other.artistName == artistName &&
        other.eventDateTimestamp == eventDateTimestamp;
  }

  @override
  int get hashCode => Object.hash(title, artistName, eventDateTimestamp);
}
