import 'dart:typed_data';

import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/protocol/generated/spotify/metadata.pb.dart'
    as meta_pb;
import 'package:musify_mu/core/utils/spotify_base62.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

import 'plugin_utils.dart';

/// Plugin for ExtensionKind 8 (`ARTIST_V4`).
/// Decodes `spotify.metadata.Artist` into [ArtistV4] for artist biography,
/// name, popularity, and portrait images.
class ArtistV4Plugin implements ExtendedMetadataPlugin<ArtistV4> {
  const ArtistV4Plugin();

  static final RegExp _htmlTagPattern = RegExp(r'<[^>]*>');

  @override
  Type get traitType => ArtistV4;

  @override
  int get extensionKindValue => 8;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.ARTIST_V4;

  @override
  ArtistV4 parse(Uint8List payload) {
    final artist = meta_pb.Artist.fromBuffer(payload);

    final id = artist.gid.length == 16
        ? SpotifyBase62.encode16ByteGid(Uint8List.fromList(artist.gid))
        : '';

    String biographyText = '';
    for (final bio in artist.biography) {
      if (bio.hasText() && bio.text.trim().isNotEmpty) {
        biographyText = _sanitizeBiographyText(bio.text);
        if (biographyText.isNotEmpty) {
          break;
        }
      }
    }

    CoverImage portrait = const CoverImage();
    if (artist.hasPortraitGroup() && artist.portraitGroup.image.isNotEmpty) {
      portrait = decodeCoverImageGroup(artist.portraitGroup);
    } else if (artist.portrait.isNotEmpty) {
      portrait = decodeCoverImageGroup(
        meta_pb.ImageGroup(image: artist.portrait),
      );
    } else {
      for (final bio in artist.biography) {
        if (bio.portraitGroup.isNotEmpty &&
            bio.portraitGroup.first.image.isNotEmpty) {
          portrait = decodeCoverImageGroup(bio.portraitGroup.first);
          break;
        }
        if (bio.portrait.isNotEmpty) {
          portrait = decodeCoverImageGroup(
            meta_pb.ImageGroup(image: bio.portrait),
          );
          break;
        }
      }
    }

    return ArtistV4(
      id: id,
      name: artist.name,
      biography: biographyText,
      portrait: portrait,
      popularity: artist.popularity,
    );
  }

  /// Strips Spotify inline anchor markup (`<a href="spotify:...">Name</a>`)
  /// and decodes common HTML entities into plain display text.
  static String _sanitizeBiographyText(String raw) {
    return raw
        .replaceAll(_htmlTagPattern, '')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}
