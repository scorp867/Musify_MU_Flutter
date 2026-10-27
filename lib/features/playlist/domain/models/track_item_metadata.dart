library;

import 'package:flutter/foundation.dart';

/// 1:1 replica of Spotify's `w1y.java` and `amb0.java` track & episode metadata model.
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
  final String fileId;
  final String headUrl;
  final String cdnUrl;

  // Podcast episode & show specific metadata fields (Spotify `amb0.java` / `qcb0.java`)
  final bool isEpisode;
  final bool isShow;
  final String description;
  final String publishDate;
  final int playbackPositionMs;
  final String showName;

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
    this.fileId = '',
    this.headUrl = '',
    this.cdnUrl = '',
    this.isEpisode = false,
    this.isShow = false,
    this.description = '',
    this.publishDate = '',
    this.playbackPositionMs = 0,
    this.showName = '',
  });

  String get artistNamesString =>
      artists.isNotEmpty ? artists.join(', ') : (showName.isNotEmpty ? showName : albumName);

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
          offlineState == other.offlineState &&
          fileId == other.fileId &&
          headUrl == other.headUrl &&
          cdnUrl == other.cdnUrl &&
          isEpisode == other.isEpisode &&
          isShow == other.isShow &&
          description == other.description &&
          publishDate == other.publishDate &&
          playbackPositionMs == other.playbackPositionMs &&
          showName == other.showName);

  @override
  int get hashCode => Object.hashAll([
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
        fileId,
        headUrl,
        cdnUrl,
        isEpisode,
        isShow,
        description,
        publishDate,
        playbackPositionMs,
        showName,
      ]);

  @override
  String toString() =>
      'TrackItemMetadata(title: $title, uri: $uri, artists: $artists, isEpisode: $isEpisode, durationMs: $durationMs, cdnUrl: $cdnUrl)';
}
