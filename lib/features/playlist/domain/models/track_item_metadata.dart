import 'package:flutter/foundation.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/cover_image.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/image_size.dart';

/// 1:1 Spotify playlist track/episode metadata model (`p.w1y`).
@immutable
final class TrackItemMetadata {
  final CoverImage coverImage;
  final String title;
  final String uri;
  final bool isPlayable;
  final bool isExplicit;
  final bool is19Plus;
  final int durationMs;
  final String albumName;
  final String albumUri;
  final CoverImage albumCoverImage;
  final List<String> artists;
  final List<String> artistUris;
  final int offlineState;
  final String canonicalUri;
  final bool isEpisode;
  final bool isShow;
  final String description;
  final String publishDate;
  final int playbackPositionMs;
  final String showName;

  const TrackItemMetadata({
    this.coverImage = const CoverImage(),
    required this.title,
    required this.uri,
    this.isPlayable = true,
    this.isExplicit = false,
    this.is19Plus = false,
    this.durationMs = 0,
    this.albumName = '',
    this.albumUri = '',
    this.albumCoverImage = const CoverImage(),
    this.artists = const [],
    this.artistUris = const [],
    this.offlineState = 0,
    this.canonicalUri = '',
    this.isEpisode = false,
    this.isShow = false,
    this.description = '',
    this.publishDate = '',
    this.playbackPositionMs = 0,
    this.showName = '',
  });

  /// 1:1 with `w1y.m88051a`: resolves `coverImage` for [size], falling back
  /// to `albumCoverImage` when empty.
  String coverUrlForSize(ImageSize size) {
    final direct = coverImage.urlForSize(size);
    if (direct.isNotEmpty) return direct;
    return albumCoverImage.urlForSize(size);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackItemMetadata &&
          coverImage == other.coverImage &&
          title == other.title &&
          uri == other.uri &&
          isPlayable == other.isPlayable &&
          isExplicit == other.isExplicit &&
          is19Plus == other.is19Plus &&
          durationMs == other.durationMs &&
          albumName == other.albumName &&
          albumUri == other.albumUri &&
          albumCoverImage == other.albumCoverImage &&
          listEquals(artists, other.artists) &&
          listEquals(artistUris, other.artistUris) &&
          offlineState == other.offlineState &&
          canonicalUri == other.canonicalUri &&
          isEpisode == other.isEpisode &&
          isShow == other.isShow &&
          description == other.description &&
          publishDate == other.publishDate &&
          playbackPositionMs == other.playbackPositionMs &&
          showName == other.showName);

  @override
  int get hashCode => Object.hashAll([
    coverImage,
    title,
    uri,
    isPlayable,
    isExplicit,
    is19Plus,
    durationMs,
    albumName,
    albumUri,
    albumCoverImage,
    Object.hashAll(artists),
    Object.hashAll(artistUris),
    offlineState,
    canonicalUri,
    isEpisode,
    isShow,
    description,
    publishDate,
    playbackPositionMs,
    showName,
  ]);
}
