import 'dart:typed_data';

import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/protocol/generated/spotify/metadata.pb.dart'
    as meta_pb;
import 'package:musify_mu/core/utils/spotify_base62.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

import 'plugin_utils.dart';

/// Plugin for ExtensionKind 10 (`TRACK_V4`).
/// 1:1 replica of Spotify Android's `p199p/a1a.java` returning [TrackV4].
class TrackV4Plugin implements ExtendedMetadataPlugin<TrackV4> {
  const TrackV4Plugin();

  @override
  Type get traitType => TrackV4;

  @override
  int get extensionKindValue => 10;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.TRACK_V4;

  static String _encodeGidOrEmpty(List<int> bytes) {
    if (bytes.length != 16) return '';
    return SpotifyBase62.encode16ByteGid(Uint8List.fromList(bytes));
  }

  static TrackV4ArtistRole _mapArtistRole(meta_pb.ArtistWithRole_Role role) {
    switch (role) {
      case meta_pb.ArtistWithRole_Role.ARTIST_ROLE_MAIN_ARTIST:
        return TrackV4ArtistRole.artistRoleMainArtist;
      case meta_pb.ArtistWithRole_Role.ARTIST_ROLE_FEATURED_ARTIST:
        return TrackV4ArtistRole.artistRoleFeaturedArtist;
      case meta_pb.ArtistWithRole_Role.ARTIST_ROLE_REMIXER:
        return TrackV4ArtistRole.artistRoleRemixer;
      case meta_pb.ArtistWithRole_Role.ARTIST_ROLE_ACTOR:
        return TrackV4ArtistRole.artistRoleActor;
      case meta_pb.ArtistWithRole_Role.ARTIST_ROLE_COMPOSER:
        return TrackV4ArtistRole.artistRoleComposer;
      case meta_pb.ArtistWithRole_Role.ARTIST_ROLE_CONDUCTOR:
        return TrackV4ArtistRole.artistRoleConductor;
      case meta_pb.ArtistWithRole_Role.ARTIST_ROLE_ORCHESTRA:
        return TrackV4ArtistRole.artistRoleOrchestra;
      case meta_pb.ArtistWithRole_Role.ARTIST_ROLE_UNKNOWN:
        return TrackV4ArtistRole.artistRoleUnknown;
    }
    return TrackV4ArtistRole.artistRoleUnknown;
  }

  static String _extractPreviewId(meta_pb.Track track) {
    for (final preview in track.preview) {
      if (preview.fileId.isNotEmpty) {
        return bytesToLowerHex(preview.fileId);
      }
    }
    for (final alt in track.alternative) {
      for (final preview in alt.preview) {
        if (preview.fileId.isNotEmpty) {
          return bytesToLowerHex(preview.fileId);
        }
      }
    }
    return '';
  }

  @override
  TrackV4 parse(Uint8List payload) {
    final track = meta_pb.Track.fromBuffer(payload);

    final id = _encodeGidOrEmpty(track.gid);
    final name = track.name;
    final albumName = track.hasAlbum() ? track.album.name : '';

    String albumUri = '';
    if (track.hasAlbum() && track.album.gid.length == 16) {
      final albumId = _encodeGidOrEmpty(track.album.gid);
      if (albumId.isNotEmpty) {
        albumUri = 'spotify:album:$albumId';
      }
    }

    final albumCover = decodeCoverImageGroup(
      track.hasAlbum() &&
              track.album.hasCoverGroup() &&
              track.album.coverGroup.image.isNotEmpty
          ? track.album.coverGroup
          : null,
    );

    final externalIds = <TrackV4ExternalId>[
      for (final ext in track.externalId)
        TrackV4ExternalId(id: ext.id, type: ext.type),
    ];

    final alternatives = <TrackV4Alternative>[
      for (final alt in track.alternative)
        TrackV4Alternative(
          uri: alt.gid.length == 16
              ? 'spotify:track:${_encodeGidOrEmpty(alt.gid)}'
              : '',
        ),
    ];

    final availabilities = <TrackV4Availability>[
      for (final avail in track.availability)
        TrackV4Availability(catalogueStrs: avail.catalogueStr),
    ];

    final artists = <TrackV4Artist>[
      for (final artist in track.artist)
        TrackV4Artist(
          uri: artist.gid.length == 16
              ? 'spotify:artist:${_encodeGidOrEmpty(artist.gid)}'
              : '',
          name: artist.name,
        ),
    ];

    final contentRatings = <TrackV4ContentRating>[
      for (final rating in track.contentRating)
        TrackV4ContentRating(country: rating.country, tags: rating.tag),
    ];

    final artistsWithRole = <TrackV4ArtistWithRole>[
      for (final item in track.artistWithRole)
        TrackV4ArtistWithRole(
          role: _mapArtistRole(item.role),
          artistUri: item.artistGid.length == 16
              ? 'spotify:artist:${_encodeGidOrEmpty(item.artistGid)}'
              : '',
          artistName: item.artistName,
        ),
    ];

    final files = <TrackV4AudioFile>[
      for (final f in track.file)
        if (f.fileId.isNotEmpty)
          TrackV4AudioFile(
            fileId: bytesToLowerHex(f.fileId),
            format: AudioFileFormat.fromValue(f.format.value),
          ),
    ];

    final previewId = _extractPreviewId(track);
    final discNumber = track.discNumber > 0 ? track.discNumber : null;
    final trackNumber = track.number > 0 ? track.number : null;

    return TrackV4(
      id: id,
      name: name,
      albumCover: albumCover,
      duration: track.duration,
      isExplicit: track.explicit,
      artists: artists,
      albumUri: albumUri,
      albumName: albumName,
      externalIds: externalIds,
      contentRatings: contentRatings,
      alternatives: alternatives,
      availabilities: availabilities,
      previewId: previewId,
      discNumber: discNumber,
      trackNumber: trackNumber,
      originalTitle: track.originalTitle,
      versionTitle: track.versionTitle,
      artistsWithRole: artistsWithRole,
      files: files,
    );
  }
}
