import 'dart:developer' as dev;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:musify_mu/core/media/extended_metadata_service.dart';
import 'package:musify_mu/core/protocol/generated/spotify/playlist/playlist_detail.pb.dart'
    as detail_pb;
import 'package:musify_mu/core/protocol/generated/spotify/playlist/rootlist.pb.dart'
    as rootlist_pb;
import 'package:musify_mu/features/library/data/playlist_detail_cache.dart';
import 'package:musify_mu/features/spotify_client/spotify_client.dart';

/// Fetched playlist data ready for consumption.
class PlaylistDetail {
  final String playlistId;
  final String revision;
  final String name;
  final String? description;
  final String ownerUsername;
  final int trackCount;
  final List<String> trackUris;
  final String? coverUrl;

  /// First 4 unique album art URLs for client-side mosaic rendering.
  /// Empty if the playlist has a custom cover.
  final List<String> mosaicImageUrls;

  final bool canEditItems;
  final bool canEditMetadata;

  const PlaylistDetail({
    required this.playlistId,
    required this.revision,
    required this.name,
    this.description,
    required this.ownerUsername,
    required this.trackCount,
    required this.trackUris,
    this.coverUrl,
    this.mosaicImageUrls = const [],
    this.canEditItems = false,
    this.canEditMetadata = false,
  });
}

/// Fetches individual playlist data with revision-based diff support.
///
/// Flow:
///   1. First fetch: GET /playlist/v2/playlist/{id} → full response
///   2. Subsequent: GET /playlist/v2/playlist/{id}/diff?revision={rev}&handlesContent=
///      → if revision unchanged, skip parse; otherwise full response
///   3. Cache revision + track URIs + cover URL
///   4. Decorate first 4 tracks via [ExtendedMetadataService] for mosaic covers
class PlaylistDetailFetcher {
  final SpotifyClient _client;
  final PlaylistDetailCache _cache;
  final ExtendedMetadataService _metadataService;

  PlaylistDetailFetcher({
    required SpotifyClient client,
    required ExtendedMetadataService metadataService,
    PlaylistDetailCache? cache,
  })  : _client = client,
        _metadataService = metadataService,
        _cache = cache ?? PlaylistDetailCache();

  PlaylistDetailCache get cache => _cache;

  /// Fetches playlist data, using diff if a revision is cached.
  ///
  /// Returns null only on network/parse failure.
  Future<PlaylistDetail?> fetch(String playlistId) async {
    try {
      final cachedRevision = await _cache.getRevision(playlistId);

      Uint8List? bytes;
      final isDiff = cachedRevision != null && cachedRevision.isNotEmpty;

      if (isDiff) {
        bytes = await _fetchDiff(playlistId, cachedRevision);
      } else {
        bytes = await _fetchFull(playlistId);
      }

      if (bytes == null || bytes.isEmpty) return null;

      final detail = await Isolate.run(
        () => _parsePlaylistBytes(bytes!, playlistId),
      );

      if (detail == null) return null;

      // Diff response with no tracks = unchanged playlist.
      // Verify the cached entry is healthy before trusting it.
      if (isDiff && detail.trackUris.isEmpty) {
        final cached = await _cache.get(playlistId);
        final cacheHealthy = cached != null &&
            (cached.coverUrl != null || cached.mosaicImageUrls.isNotEmpty) &&
            cached.trackUris.isNotEmpty;

        if (cacheHealthy) {
          dev.log(
            'PlaylistFetch/$playlistId: unchanged (diff), cache healthy',
            name: 'Library',
          );
          return null; // Existing cache entry is valid.
        }

        // Cache corrupted -- force full re-fetch to repair.
        dev.log(
          'PlaylistFetch/$playlistId: cache corrupted, forcing full fetch',
          name: 'Library',
        );
        bytes = await _fetchFull(playlistId);
        if (bytes == null || bytes.isEmpty) return null;

        final repaired = await Isolate.run(
          () => _parsePlaylistBytes(bytes!, playlistId),
        );
        if (repaired == null || repaired.trackUris.isEmpty) return null;

        // Continue with the repaired detail below.
        // (fall through to track fetch + mosaic build + cache)
        return _processAndCache(playlistId, repaired, bytes!);
      }

      return _processAndCache(playlistId, detail, bytes!);
    } catch (e, st) {
      dev.log(
        'PlaylistFetch/$playlistId error: $e',
        name: 'Library',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Fetches track metadata, builds mosaic, and persists to cache.
  /// Shared by both normal fetch and cache-repair paths.
  Future<PlaylistDetail> _processAndCache(
    String playlistId,
    PlaylistDetail detail,
    Uint8List rawBytes,
  ) async {
    // Fetch ALL track metadata into the centralized cache.
    if (detail.trackUris.isNotEmpty) {
      await _metadataService.fetchTracks(detail.trackUris);
    }

    // If no custom cover, gather mosaic URLs from the now-cached track data.
    var finalDetail = detail;
    if (detail.coverUrl == null || detail.coverUrl!.isEmpty) {
      final mosaicUrls = _getMosaicUrlsFromCache(detail.trackUris);
      finalDetail = PlaylistDetail(
        playlistId: detail.playlistId,
        revision: detail.revision,
        name: detail.name,
        description: detail.description,
        ownerUsername: detail.ownerUsername,
        trackCount: detail.trackCount,
        trackUris: detail.trackUris,
        coverUrl: mosaicUrls.isNotEmpty ? mosaicUrls.first : null,
        mosaicImageUrls: mosaicUrls.length >= 4 ? mosaicUrls : const [],
        canEditItems: detail.canEditItems,
        canEditMetadata: detail.canEditMetadata,
      );
    }

    // Persist to cache.
    await _cache.put(
      playlistId: playlistId,
      revision: finalDetail.revision,
      trackUris: finalDetail.trackUris,
      coverUrl: finalDetail.coverUrl,
      mosaicImageUrls: finalDetail.mosaicImageUrls,
      rawBytes: rawBytes,
    );

    dev.log(
      'PlaylistFetch/$playlistId: ${finalDetail.trackUris.length} tracks, '
      'cover=${finalDetail.coverUrl != null ? "yes" : "no"}, '
      'mosaic=${finalDetail.mosaicImageUrls.length}, '
      'rev=${finalDetail.revision.length > 8 ? finalDetail.revision.substring(0, 8) : finalDetail.revision}...',
      name: 'Library',
    );

    return finalDetail;
  }

  /// Fetches multiple playlists in parallel, returns a map of id → detail.
  Future<Map<String, PlaylistDetail>> fetchBatch(
    List<String> playlistIds,
  ) async {
    final results = <String, PlaylistDetail>{};

    // Fetch in batches of 5 to avoid overwhelming the network.
    const batchSize = 5;
    for (var i = 0; i < playlistIds.length; i += batchSize) {
      final batch = playlistIds.skip(i).take(batchSize).toList();
      final futures = batch.map((id) => fetch(id));
      final batchResults = await Future.wait(futures);

      for (var j = 0; j < batch.length; j++) {
        if (batchResults[j] != null) {
          results[batch[j]] = batchResults[j]!;
        }
      }
    }

    return results;
  }

  // ─── Mosaic ───────────────────────────────────────────────────────

  /// Returns first 4 unique album art URLs from cached track metadata.
  /// Used for client-side mosaic rendering (2x2 grid).
  List<String> _getMosaicUrlsFromCache(List<String> trackUris) {
    final urls = <String>[];
    final seen = <String>{};

    for (final uri in trackUris) {
      if (!uri.startsWith('spotify:track:')) continue;

      final meta = _metadataService.getCached(uri);
      if (meta == null) continue;

      final url = meta.imageUrl;
      if (url.isNotEmpty && seen.add(url)) {
        urls.add(url);
        if (urls.length >= 4) break;
      }
    }

    return urls;
  }

  // ─── Network ──────────────────────────────────────────────────────

  Future<Uint8List?> _fetchFull(String playlistId) async {
    return _client.get('/playlist/v2/playlist/$playlistId');
  }

  Future<Uint8List?> _fetchDiff(
    String playlistId,
    String revision,
  ) async {
    final encodedRev = Uri.encodeComponent(revision);
    return _client.get(
      '/playlist/v2/playlist/$playlistId/diff'
      '?revision=$encodedRev'
      '&handlesContent=',
    );
  }

  // ─── Parsing (static, runs in isolate) ────────────────────────────

  static PlaylistDetail? _parsePlaylistBytes(
    Uint8List bytes,
    String playlistId,
  ) {
    // Try PlaylistResponse first (has diff + capabilities).
    try {
      final response = detail_pb.PlaylistResponse.fromBuffer(bytes);

      final revision = _revisionToString(response.revision);
      final name = response.attributes.name;
      final description = response.attributes.description;
      final owner = response.ownerUsername;
      final trackCount = response.length;

      final trackUris = <String>[];
      for (final item in response.contents.items) {
        if (item.uri.isNotEmpty) {
          trackUris.add(item.uri);
        }
      }

      String? coverUrl = _extractCoverUrl(response.attributes);

      final canEditItems =
          response.hasCapabilities() && response.capabilities.canEditItems;
      final canEditMetadata =
          response.hasCapabilities() && response.capabilities.canEditMetadata;

      return PlaylistDetail(
        playlistId: playlistId,
        revision: revision,
        name: name,
        description: description.isNotEmpty ? description : null,
        ownerUsername: owner,
        trackCount: trackCount,
        trackUris: trackUris,
        coverUrl: coverUrl,
        canEditItems: canEditItems,
        canEditMetadata: canEditMetadata,
      );
    } catch (e) {
      // Fallback: try parsing as SelectedListContent.
      try {
        final response = rootlist_pb.SelectedListContent.fromBuffer(bytes);
        final revision = _revisionToString(response.revision);
        final trackUris = <String>[];
        for (final item in response.contents.items) {
          if (item.uri.isNotEmpty) {
            trackUris.add(item.uri);
          }
        }

        String? coverUrl = _extractCoverUrl(response.attributes);

        return PlaylistDetail(
          playlistId: playlistId,
          revision: revision,
          name: response.attributes.name,
          ownerUsername: response.ownerUsername,
          trackCount: response.length,
          trackUris: trackUris,
          coverUrl: coverUrl,
        );
      } catch (_) {
        return null;
      }
    }
  }

  /// Converts protobuf revision bytes to the string format used by
  /// the diff endpoint: "{counter},{sha1hex}".
  static String _revisionToString(List<int> revisionBytes) {
    if (revisionBytes.length < 24) {
      return revisionBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
    }

    final counter = (revisionBytes[0] << 24) |
        (revisionBytes[1] << 16) |
        (revisionBytes[2] << 8) |
        revisionBytes[3];

    final hash = revisionBytes
        .sublist(4)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '$counter,$hash';
  }

  /// Extracts cover image URL from ListAttributes.
  static String? _extractCoverUrl(rootlist_pb.ListAttributes attrs) {
    // Try picture_size first (pre-built URLs).
    if (attrs.pictureSize.isNotEmpty) {
      return attrs.pictureSize.first.url;
    }

    // Try formatAttributes 'picture' key.
    for (final attr in attrs.formatAttributes) {
      if (attr.key == 'picture') {
        final val = attr.value;
        if (val.startsWith('spotify:image:')) {
          return 'https://i.scdn.co/image/${val.split(':').last}';
        } else if (val.startsWith('http')) {
          return val;
        } else if (val.isNotEmpty) {
          return 'https://i.scdn.co/image/$val';
        }
      }
    }

    // Try raw picture bytes (20-byte hash).
    if (attrs.picture.isNotEmpty && attrs.picture.length == 20) {
      final hex = attrs.picture
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      return 'https://i.scdn.co/image/$hex';
    }

    return null;
  }
}
