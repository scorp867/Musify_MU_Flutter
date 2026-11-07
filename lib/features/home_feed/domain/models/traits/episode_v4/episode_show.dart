import 'package:flutter/foundation.dart';

/// 1:1 replica of Spotify Android's `p199p/iey.java` (`EpisodeV4.Show`).
@immutable
final class EpisodeShow {
  final String name;
  final String uri;

  const EpisodeShow({
    required this.name,
    required this.uri,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EpisodeShow && other.name == name && other.uri == uri;
  }

  @override
  int get hashCode => Object.hash(name, uri);
}
