library;

import 'package:flutter/foundation.dart';

/// 1:1 replica of Spotify's `w1y.java` track metadata model.
@immutable
class TrackItemMetadata {
  final String title;
  final String uri;
  final bool isPlayable;
  final bool isExplicit;
  final bool is19Plus;
  final int durationMs;
  final String albumName;
  final String albumUri;
  final List<String> albumCovers;
  final List<String> artists;
  final List<String> artistUris;
  final int offlineState;

  const TrackItemMetadata({
    required this.title,
    required this.uri,
    this.isPlayable = true,
    this.isExplicit = false,
    this.is19Plus = false,
    this.durationMs = 0,
    this.albumName = '',
    this.albumUri = '',
    this.albumCovers = const [],
    this.artists = const [],
    this.artistUris = const [],
    this.offlineState = 0,
  });

  String get artistNamesString => artists.join(', ');

  String get primaryCoverUrl =>
      albumCovers.isNotEmpty ? albumCovers.first : '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackItemMetadata &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          uri == other.uri &&
          isPlayable == other.isPlayable &&
          isExplicit == other.isExplicit &&
          is19Plus == other.is19Plus &&
          durationMs == other.durationMs &&
          albumName == other.albumName &&
          albumUri == other.albumUri &&
          listEquals(albumCovers, other.albumCovers) &&
          listEquals(artists, other.artists) &&
          listEquals(artistUris, other.artistUris) &&
          offlineState == other.offlineState);

  @override
  int get hashCode => Object.hash(
        title,
        uri,
        isPlayable,
        isExplicit,
        is19Plus,
        durationMs,
        albumName,
        albumUri,
        Object.hashAll(albumCovers),
        Object.hashAll(artists),
        Object.hashAll(artistUris),
        offlineState,
      );

  @override
  String toString() =>
      'TrackItemMetadata(title: $title, uri: $uri, artists: $artists, album: $albumName, durationMs: $durationMs)';
}
