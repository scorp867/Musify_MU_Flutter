import 'package:flutter/foundation.dart';

import 'track_v4_artist_role.dart';

/// 1:1 replica of Spotify Android's `p199p/y8d1.java` (`TrackV4.ArtistWithRole`).
@immutable
final class TrackV4ArtistWithRole {
  final String artistUri;
  final String artistName;
  final TrackV4ArtistRole role;

  const TrackV4ArtistWithRole({
    required this.artistUri,
    required this.artistName,
    required this.role,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackV4ArtistWithRole &&
        other.artistUri == artistUri &&
        other.artistName == artistName &&
        other.role == role;
  }

  @override
  int get hashCode => Object.hash(artistUri, artistName, role);
}
