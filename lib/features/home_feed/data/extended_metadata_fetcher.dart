import 'dart:math';
import 'dart:typed_data';

import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/protocol/generated/spotify/metadata.pb.dart'
    as meta;
import 'package:musify_mu/features/spotify_client/spotify_client.dart';

/// Lightweight metadata result from extended-metadata endpoint.
class EntityMeta {
  String title;
  String subtitle;
  String? imageUrl;

  EntityMeta({this.title = '', this.subtitle = '', this.imageUrl});
}

/// Fetches metadata (title, subtitle, image) for URIs that aren't covered
/// by Casita traits. Port of Kotlin SpotifyExtendedMetadataFetcher.
///
/// Endpoint: POST /extended-metadata/v0/extended-metadata
/// Protocol: BatchedEntityRequest → BatchedExtensionResponse (protobuf)
class ExtendedMetadataFetcher {
  final SpotifyClient _client;

  ExtendedMetadataFetcher({required SpotifyClient client}) : _client = client;

  /// Batch-fetches metadata for [uris]. Returns a map of uri → EntityMeta.
  Future<Map<String, EntityMeta>> fetchMetadata(List<String> uris) async {
    if (uris.isEmpty) return {};

    try {
      final payload = _buildRequest(uris);
      final response = await _client.post(
        '/extended-metadata/v0/extended-metadata',
        Uint8List.fromList(payload),
      );
      if (response == null) return {};

      return _parseResponse(response);
    } catch (e) {
      print('❌ ExtendedMetadataFetcher: $e');
      return {};
    }
  }

  /// Builds BatchedEntityRequest from URIs.
  List<int> _buildRequest(List<String> uris) {
    final taskId = List<int>.generate(16, (_) => Random().nextInt(256));

    final request = BatchedEntityRequest()
      ..header = (BatchedEntityRequestHeader()
        ..country = 'IN'
        ..catalogue = 'free'
        ..taskId = taskId);

    for (final uri in uris) {
      final kinds = _kindsForUri(uri);
      final entityReq = EntityRequest()..entityUri = uri;

      for (final kind in kinds) {
        entityReq.query.add(ExtensionQuery()..extensionKind = kind);
      }
      request.entityRequest.add(entityReq);
    }

    return request.writeToBuffer();
  }

  /// Returns appropriate extension kinds for a URI type.
  List<ExtensionKind> _kindsForUri(String uri) {
    if (uri.contains(':track:')) return [ExtensionKind.TRACK_V4];
    if (uri.contains(':album:')) return [ExtensionKind.ALBUM_V4];
    if (uri.contains(':artist:')) return [ExtensionKind.ARTIST_V4];
    if (uri.contains(':episode:')) return [ExtensionKind.EPISODE_V4];
    if (uri.contains(':show:')) return [ExtensionKind.SHOW_V4];
    // Playlists don't have extended-metadata — use playlist/v2 endpoint
    // For collections, no metadata available
    return [];
  }

  /// Parses BatchedExtensionResponse into uri → EntityMeta map.
  Map<String, EntityMeta> _parseResponse(Uint8List data) {
    final results = <String, EntityMeta>{};

    final response = BatchedExtensionResponse.fromBuffer(data);

    for (final array in response.extendedMetadata) {
      final kind = array.extensionKind;

      for (final extData in array.extensionData) {
        final uri = extData.entityUri;
        if (uri.isEmpty || !extData.hasExtensionData()) continue;

        final payload = extData.extensionData.value;
        final entityMeta = EntityMeta();

        switch (kind) {
          case ExtensionKind.TRACK_V4:
            _parseTrack(payload, entityMeta);
          case ExtensionKind.ALBUM_V4:
            _parseAlbum(payload, entityMeta);
          case ExtensionKind.ARTIST_V4:
            _parseArtist(payload, entityMeta);
          case ExtensionKind.EPISODE_V4:
            _parseEpisode(payload, entityMeta);
          case ExtensionKind.SHOW_V4:
            _parseShow(payload, entityMeta);
          default:
            continue;
        }

        if (entityMeta.title.isNotEmpty || entityMeta.imageUrl != null) {
          results[uri] = entityMeta;
        }
      }
    }

    print('✅ ExtendedMetadata: ${results.length} items hydrated');
    return results;
  }

  void _parseTrack(List<int> payload, EntityMeta result) {
    final track = meta.Track.fromBuffer(payload);
    result.title = track.name;
    result.subtitle =
        track.artist.map((a) => a.name).where((n) => n.isNotEmpty).join(', ');

    if (track.hasAlbum() && track.album.hasCoverGroup()) {
      result.imageUrl = _bestImage(track.album.coverGroup);
    }
  }

  void _parseAlbum(List<int> payload, EntityMeta result) {
    final album = meta.Album.fromBuffer(payload);
    result.title = album.name;
    result.subtitle =
        album.artist.map((a) => a.name).where((n) => n.isNotEmpty).join(', ');

    if (album.hasCoverGroup()) {
      result.imageUrl = _bestImage(album.coverGroup);
    }
  }

  void _parseArtist(List<int> payload, EntityMeta result) {
    final artist = meta.Artist.fromBuffer(payload);
    result.title = artist.name;
    result.subtitle = 'Artist';

    if (artist.hasPortraitGroup()) {
      result.imageUrl = _bestImage(artist.portraitGroup);
    }
  }

  void _parseEpisode(List<int> payload, EntityMeta result) {
    final episode = meta.Episode.fromBuffer(payload);
    result.title = episode.name;

    if (episode.hasShow()) {
      result.subtitle = episode.show.name;
    }
    if (episode.hasCoverImage()) {
      result.imageUrl = _bestImage(episode.coverImage);
    }
  }

  void _parseShow(List<int> payload, EntityMeta result) {
    final show = meta.Show.fromBuffer(payload);
    result.title = show.name;
    result.subtitle = show.publisher;

    if (show.hasCoverImage()) {
      result.imageUrl = _bestImage(show.coverImage);
    }
  }

  /// Picks the best image from an ImageGroup — prefers LARGE/XLARGE.
  String? _bestImage(meta.ImageGroup group) {
    if (group.image.isEmpty) return null;

    meta.Image? best;
    int bestPriority = -1;

    for (final img in group.image) {
      if (!img.hasFileId() || img.fileId.isEmpty) continue;

      final priority = switch (img.size) {
        meta.Image_Size.XLARGE => 4,
        meta.Image_Size.LARGE => 3,
        meta.Image_Size.DEFAULT => 2,
        meta.Image_Size.SMALL => 1,
        _ => 0,
      };

      if (priority > bestPriority) {
        bestPriority = priority;
        best = img;
      }
    }

    if (best == null) return null;
    final hex = best.fileId
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'https://i.scdn.co/image/$hex';
  }
}
