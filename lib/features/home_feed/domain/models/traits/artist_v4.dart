import 'package:flutter/foundation.dart';

import 'cover_image.dart';
import 'trait.dart';

/// Artist metadata v4 trait (ExtensionKind 8, `ARTIST_V4`).
/// Decodes `spotify.metadata.Artist` including artist biography and portraits.
@immutable
final class ArtistV4 extends Trait {
  final String id;
  final String name;
  final String biography;
  final CoverImage portrait;
  final int popularity;

  const ArtistV4({
    this.id = '',
    this.name = '',
    this.biography = '',
    this.portrait = const CoverImage(),
    this.popularity = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArtistV4 &&
        other.id == id &&
        other.name == name &&
        other.biography == biography &&
        other.portrait == portrait &&
        other.popularity == popularity;
  }

  @override
  int get hashCode => Object.hash(id, name, biography, portrait, popularity);
}
