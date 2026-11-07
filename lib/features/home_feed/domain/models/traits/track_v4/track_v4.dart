import 'dart:collection';
import 'package:flutter/foundation.dart';

import '../cover_image.dart';
import '../trait.dart';
import 'track_v4_alternative.dart';
import 'track_v4_artist.dart';
import 'track_v4_artist_with_role.dart';
import 'track_v4_audio_file.dart';
import 'track_v4_availability.dart';
import 'track_v4_content_rating.dart';
import 'track_v4_external_id.dart';

/// 1:1 replica of Spotify Android's `p199p/e9d1.java` (`TrackV4`, ExtensionKind 10).
@immutable
final class TrackV4 extends Trait {
  final String id;
  final String name;
  final CoverImage albumCover;
  final int duration;
  final bool isExplicit;
  final UnmodifiableListView<TrackV4Artist> artists;
  final String albumUri;
  final String albumName;
  final UnmodifiableListView<TrackV4ExternalId> externalIds;
  final UnmodifiableListView<TrackV4ContentRating> contentRatings;
  final UnmodifiableListView<TrackV4Alternative> alternatives;
  final UnmodifiableListView<TrackV4Availability> availabilities;
  final String previewId;
  final int? discNumber;
  final int? trackNumber;
  final String originalTitle;
  final String versionTitle;
  final UnmodifiableListView<TrackV4ArtistWithRole> artistsWithRole;
  final UnmodifiableListView<TrackV4AudioFile> files;

  TrackV4({
    required this.id,
    required this.name,
    this.albumCover = const CoverImage(),
    this.duration = 0,
    this.isExplicit = false,
    List<TrackV4Artist> artists = const [],
    this.albumUri = '',
    this.albumName = '',
    List<TrackV4ExternalId> externalIds = const [],
    List<TrackV4ContentRating> contentRatings = const [],
    List<TrackV4Alternative> alternatives = const [],
    List<TrackV4Availability> availabilities = const [],
    this.previewId = '',
    this.discNumber,
    this.trackNumber,
    this.originalTitle = '',
    this.versionTitle = '',
    List<TrackV4ArtistWithRole> artistsWithRole = const [],
    List<TrackV4AudioFile> files = const [],
  }) : artists = UnmodifiableListView<TrackV4Artist>(
         List<TrackV4Artist>.of(artists),
       ),
       externalIds = UnmodifiableListView<TrackV4ExternalId>(
         List<TrackV4ExternalId>.of(externalIds),
       ),
       contentRatings = UnmodifiableListView<TrackV4ContentRating>(
         List<TrackV4ContentRating>.of(contentRatings),
       ),
       alternatives = UnmodifiableListView<TrackV4Alternative>(
         List<TrackV4Alternative>.of(alternatives),
       ),
       availabilities = UnmodifiableListView<TrackV4Availability>(
         List<TrackV4Availability>.of(availabilities),
       ),
       artistsWithRole = UnmodifiableListView<TrackV4ArtistWithRole>(
         List<TrackV4ArtistWithRole>.of(artistsWithRole),
       ),
       files = UnmodifiableListView<TrackV4AudioFile>(
         List<TrackV4AudioFile>.of(files),
       );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackV4 &&
        other.id == id &&
        other.name == name &&
        other.albumCover == albumCover &&
        other.duration == duration &&
        other.isExplicit == isExplicit &&
        listEquals(other.artists, artists) &&
        other.albumUri == albumUri &&
        other.albumName == albumName &&
        listEquals(other.externalIds, externalIds) &&
        listEquals(other.contentRatings, contentRatings) &&
        listEquals(other.alternatives, alternatives) &&
        listEquals(other.availabilities, availabilities) &&
        other.previewId == previewId &&
        other.discNumber == discNumber &&
        other.trackNumber == trackNumber &&
        other.originalTitle == originalTitle &&
        other.versionTitle == versionTitle &&
        listEquals(other.artistsWithRole, artistsWithRole) &&
        listEquals(other.files, files);
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    albumCover,
    duration,
    isExplicit,
    Object.hashAll(artists),
    albumUri,
    albumName,
    Object.hashAll(externalIds),
    Object.hashAll(contentRatings),
    Object.hashAll(alternatives),
    Object.hashAll(availabilities),
    previewId,
    discNumber,
    trackNumber,
    originalTitle,
    versionTitle,
    Object.hashAll(artistsWithRole),
    Object.hashAll(files),
  ]);
}
