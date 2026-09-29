import 'dart:developer' as dev;
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:musify_mu/core/protocol/generated/spotify/collection/collection_paging.pb.dart'
    as col_pb;
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/identity_trait.pb.dart'
    as identity_pb;
import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/protocol/generated/spotify/metadata.pb.dart'
    as meta_pb;
import 'package:musify_mu/core/protocol/generated/spotify/playlist/rootlist.pb.dart'
    as rootlist_pb;
import 'package:musify_mu/core/media/extended_metadata_service.dart';
import 'package:musify_mu/features/library/data/library_cache.dart';
import 'package:musify_mu/features/library/data/playlist_detail_fetcher.dart';
import 'package:musify_mu/features/library/domain/models/library_view_data.dart';
import 'package:musify_mu/features/spotify_client/spotify_client.dart';

/// Repository for the Library tab.
///
/// Two-layer caching:
///   Layer 1 (Structure): Raw protobuf bytes for rootlist + collections.
///     SWR: yield cached immediately, revalidate in background.
///   Layer 2 (Decoration): Per-URI name + imageUrl with 24h TTL.
///     Only fetches extended-metadata for URIs not already cached.
class LibraryRepository {
  final SpotifyClient _client;
  final String _userId;
  final LibraryCache _cache;
  final PlaylistDetailFetcher _playlistFetcher;

  /// Prevents re-fetching all playlist details on every SWR cycle.
  bool _playlistsSynced = false;

  LibraryRepository({
    required SpotifyClient client,
    required String userId,
    required ExtendedMetadataService metadataService,
    LibraryCache? cache,
    PlaylistDetailFetcher? playlistFetcher,
  })  : _client = client,
        _userId = userId,
        _cache = cache ?? LibraryCache(),
        _playlistFetcher = playlistFetcher ??
            PlaylistDetailFetcher(
              client: client,
              metadataService: metadataService,
            );

  /// SWR stream: yields cached data first (if available), then fresh data.
  Stream<LibraryViewData> getLibrary() async* {
    await _cache.loadDecorations();

    // Layer 1: Try cached structure bytes.
    final cached = await _buildFromCachedBytes();
    if (cached != null) {
      dev.log('LibraryRepo: Yielding cached data', name: 'Library');
      yield cached;
    }

    // Layer 2: Fetch fresh from network.
    final fresh = await fetchFresh();
    if (fresh != null) {
      yield fresh;
    }
  }

  /// Fetches fresh library data from network, caches bytes + decorations.
  Future<LibraryViewData?> fetchFresh() async {
    try {
      // Fire all structure requests in parallel.
      final results = await Future.wait([
        _fetchAndCacheRootlist(),
        _fetchAndCacheCollection('artist'),
        _fetchAndCacheCollection('show'),
        _fetchAndCacheCollection('ylpin'),
        _fetchAndCacheCollection('collection'),
      ]);

      final playlistItems = results[0];
      final artistItems = results[1];
      final showItems = results[2];
      final pinnedUris = results[3];
      final likedSongs = results[4];

      // Sync playlist details ONCE. Subsequent calls only fetch NEW playlists.
      final playlistIds = playlistItems
          .map((item) {
            final parts = item.uri.split(':');
            return parts.length >= 3 && parts[1] == 'playlist' ? parts[2] : '';
          })
          .where((id) => id.isNotEmpty)
          .toList();
      await _syncPlaylistDetails(playlistIds);

      return await _assembleViewData(
        playlistItems,
        artistItems,
        showItems,
        pinnedUris,
        likedSongs,
      );
    } catch (e, st) {
      dev.log('LibraryRepo error: $e', name: 'Library', error: e, stackTrace: st);
      return null;
    }
  }

  // ─── Assembly ────────────────────────────────────────────────────────

  Future<LibraryViewData> _assembleViewData(
    List<LibraryItem> playlistItems,
    List<LibraryItem> artistItems,
    List<LibraryItem> showItems,
    List<LibraryItem> pinnedUris,
    List<LibraryItem> likedSongs,
  ) async {
    final pinnedSet = pinnedUris.map((e) => e.uri).toSet();

    // Decorate artists: use cached decorations first, fetch only uncached.
    final decoratedArtists = await _decorateArtists(artistItems);

    // Decorate playlists from cache (zero network).
    final decoratedPlaylists = await _decoratePlaylistsFromCache(playlistItems);

    final allItems = <LibraryItem>[
      if (likedSongs.isNotEmpty)
        LibraryItem(
          uri: 'spotify:collection:tracks',
          type: 'playlist',
          name: 'Liked Songs',
          ownerName: _userId,
          addedAt: DateTime.now(),
          isPinned: pinnedSet.contains('spotify:collection:tracks'),
          trackCount: likedSongs.length,
        ),
      ...decoratedPlaylists.map((item) =>
          item.copyWith(isPinned: pinnedSet.contains(item.uri))),
      ...decoratedArtists.map((item) =>
          item.copyWith(isPinned: pinnedSet.contains(item.uri))),
      ...showItems.map((item) =>
          item.copyWith(isPinned: pinnedSet.contains(item.uri))),
    ];

    dev.log(
      'LibraryRepo: ${playlistItems.length} playlists, '
      '${decoratedArtists.length} artists, '
      '${showItems.length} shows, '
      '${pinnedUris.length} pins, '
      '${likedSongs.length} liked songs',
      name: 'Library',
    );

    return LibraryViewData(items: allItems, pinnedUris: pinnedSet);
  }

  // ─── Cached structure → LibraryViewData ────────────────────────────

  Future<LibraryViewData?> _buildFromCachedBytes() async {
    try {
      final cached = await Future.wait([
        _cache.getStructureBytes('rootlist'),
        _cache.getStructureBytes('col_artist'),
        _cache.getStructureBytes('col_show'),
        _cache.getStructureBytes('col_ylpin'),
        _cache.getStructureBytes('col_collection'),
      ]);

      // All structure parts must be available for a valid cached result.
      if (cached.any((b) => b == null)) return null;

      // Parse all cached bytes in parallel isolates.
      final parsed = await Future.wait([
        Isolate.run(() => _parseRootlistBytes(cached[0]!)),
        Isolate.run(() => _parseCollectionBytes(cached[1]!, 'artist')),
        Isolate.run(() => _parseCollectionBytes(cached[2]!, 'show')),
        Isolate.run(() => _parseCollectionBytes(cached[3]!, 'ylpin')),
        Isolate.run(() => _parseCollectionBytes(cached[4]!, 'collection')),
      ]);

      return await _assembleViewData(
        parsed[0], parsed[1], parsed[2], parsed[3], parsed[4],
      );
    } catch (e) {
      dev.log('Cache read error: $e', name: 'Library');
      return null;
    }
  }

  // ─── Rootlist (playlists) ──────────────────────────────────────────

  Future<List<LibraryItem>> _fetchAndCacheRootlist() async {
    final path =
        '/playlist/v2/user/$_userId/rootlist'
        '?decorate=revision%2Cattributes%2Clength%2Cowner%2Ccapabilities'
        '%2Cstatus_code%2Ctimestamp'
        '&from=0&length=120';

    final bytes = await _client.getAndroid(
      path,
      extraHeaders: {
        'spotify-playlist-sync-reason': 'CAU=',
        'spotify-dsa-mode-enabled': 'false',
        'spotify-accept-geoblock': 'dummy',
      },
    );
    if (bytes == null || bytes.isEmpty) return [];

    // Cache raw bytes -- no serialization cost.
    _cache.putStructureBytes('rootlist', bytes);

    try {
      final items = await Isolate.run(() => _parseRootlistBytes(bytes));
      dev.log('Rootlist: parsed ${items.length} items', name: 'Library');
      return items;
    } catch (e, st) {
      dev.log('Rootlist parse error: $e', name: 'Library', error: e, stackTrace: st);
      return [];
    }
  }

  static List<LibraryItem> _parseRootlistBytes(Uint8List bytes) {
    final response = rootlist_pb.SelectedListContent.fromBuffer(bytes);
    final items = <LibraryItem>[];

    final listItems = response.contents.items;
    final metaItems = response.contents.metaItems;

    for (var i = 0; i < listItems.length; i++) {
      final item = listItems[i];
      final uri = item.uri;
      if (uri.isEmpty) continue;

      final meta = (i < metaItems.length) ? metaItems[i] : null;
      final name = meta?.attributes.name ?? _playlistNameFromUri(uri);
      final owner = meta?.ownerUsername ?? '';
      final timestamp = meta?.timestamp.toInt() ?? 0;

      String? imageUrl;
      if (meta != null) {
        // Try picture_size first (has ready-made URLs).
        if (meta.attributes.pictureSize.isNotEmpty) {
          imageUrl = meta.attributes.pictureSize.first.url;
        }

        // Fallback: formatAttributes 'picture' key.
        if (imageUrl == null || imageUrl.isEmpty) {
          for (final attr in meta.attributes.formatAttributes) {
            if (attr.key == 'picture') {
              final val = attr.value;
              if (val.startsWith('spotify:image:')) {
                imageUrl = 'https://i.scdn.co/image/${val.split(':').last}';
              } else if (val.startsWith('http')) {
                imageUrl = val;
              } else if (val.isNotEmpty) {
                // Raw hex image ID.
                imageUrl = 'https://i.scdn.co/image/$val';
              }
              break;
            }
          }
        }

        // Fallback: raw picture bytes (field 3).
        if ((imageUrl == null || imageUrl.isEmpty) &&
            meta.attributes.picture.isNotEmpty) {
          final hex = meta.attributes.picture
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join();
          imageUrl = 'https://i.scdn.co/image/$hex';
        }
      }

      items.add(LibraryItem(
        uri: uri,
        type: _typeFromUri(uri),
        name: name,
        imageUrl: imageUrl,
        ownerName: owner.isNotEmpty ? owner : null,
        addedAt: timestamp > 0
            ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
            : null,
        trackCount: meta?.length,
      ));
    }

    return items;
  }

  // ─── Collection paging ─────────────────────────────────────────────

  Future<List<LibraryItem>> _fetchAndCacheCollection(String setName) async {
    final request = col_pb.PageRequest()
      ..username = _userId
      ..setName = setName
      ..limit = 150;

    final requestBytes = Uint8List.fromList(request.writeToBuffer());

    final bytes = await _client.post(
      '/collection/v2/paging',
      requestBytes,
      contentType: 'application/vnd.collection-v2.spotify.proto',
      extraHeaders: {
        'accept': 'application/vnd.collection-v2.spotify.proto',
      },
    );
    if (bytes == null || bytes.isEmpty) return [];

    // Cache raw bytes.
    _cache.putStructureBytes('col_$setName', bytes);

    try {
      final items = await Isolate.run(
        () => _parseCollectionBytes(bytes, setName),
      );
      dev.log('Collection/$setName: ${items.length} items', name: 'Library');
      return items;
    } catch (e, st) {
      dev.log(
        'Collection/$setName parse error: $e',
        name: 'Library', error: e, stackTrace: st,
      );
      return [];
    }
  }

  static List<LibraryItem> _parseCollectionBytes(
    Uint8List bytes,
    String setName,
  ) {
    final response = col_pb.PageResponse.fromBuffer(bytes);
    final items = <LibraryItem>[];

    for (final item in response.items) {
      final uri = item.uri;
      if (uri.isEmpty) continue;

      final addedAt = item.addedAt.toInt();

      items.add(LibraryItem(
        uri: uri,
        type: _typeFromUri(uri),
        name: _nameFromUri(uri),
        addedAt: addedAt > 0
            ? DateTime.fromMillisecondsSinceEpoch(addedAt * 1000)
            : null,
      ));
    }

    return items;
  }

  // ─── Playlist sync (network, runs ONCE per session) ────────────────

  /// Fetches playlist details for all playlist IDs that haven't been synced yet.
  /// After first sync, only NEW playlists (from rootlist changes) are fetched.
  Future<void> _syncPlaylistDetails(List<String> playlistIds) async {
    if (playlistIds.isEmpty) return;

    List<String> toSync;

    if (!_playlistsSynced) {
      // First sync: fetch all (diff endpoint handles already-cached ones cheaply).
      toSync = playlistIds;
      _playlistsSynced = true;
    } else {
      // Subsequent syncs: only fetch playlists not yet in cache.
      final cached = await _playlistFetcher.cache.cachedIds();
      toSync = playlistIds.where((id) => !cached.contains(id)).toList();
    }

    if (toSync.isEmpty) {
      dev.log('Playlist sync: all ${playlistIds.length} already cached', name: 'Library');
      return;
    }

    dev.log(
      'Playlist sync: ${toSync.length}/${playlistIds.length} to fetch',
      name: 'Library',
    );

    await _playlistFetcher.fetchBatch(toSync);
  }

  // ─── Playlist decoration (cache-only, zero network) ───────────────

  /// Reads cover/mosaic data from PlaylistDetailCache.
  /// No network calls -- sync must have run first.
  Future<List<LibraryItem>> _decoratePlaylistsFromCache(
    List<LibraryItem> playlists,
  ) async {
    if (playlists.isEmpty) return playlists;

    final result = List<LibraryItem>.from(playlists);

    for (var i = 0; i < result.length; i++) {
      final parts = result[i].uri.split(':');
      if (parts.length < 3 || parts[1] != 'playlist') continue;

      final playlistId = parts[2];
      final entry = await _playlistFetcher.cache.get(playlistId);
      if (entry == null) continue;

      result[i] = result[i].copyWith(
        imageUrl: entry.coverUrl,
        trackCount: entry.trackUris.isNotEmpty ? entry.trackUris.length : null,
        mosaicImageUrls: entry.mosaicImageUrls,
      );
    }

    return result;
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  static String _typeFromUri(String uri) {
    final parts = uri.split(':');
    if (parts.length >= 2) return parts[1];
    return 'unknown';
  }

  static String _nameFromUri(String uri) {
    final parts = uri.split(':');
    if (parts.length >= 3) return parts[2];
    return uri;
  }

  static String _playlistNameFromUri(String uri) {
    final parts = uri.split(':');
    if (parts.length >= 3) return 'Playlist ${parts[2].substring(0, 6)}';
    return uri;
  }

  // ─── Artist decoration via extended-metadata ──────────────────────

  Future<List<LibraryItem>> _decorateArtists(List<LibraryItem> artists) async {
    if (artists.isEmpty) return artists;

    // Apply cached decorations first.
    final needsFetch = <LibraryItem>[];
    final decorated = <LibraryItem>[];

    for (final artist in artists) {
      final cached = _cache.getDecoration(artist.uri);
      if (cached != null) {
        decorated.add(artist.copyWith(
          name: cached.name,
          imageUrl: cached.imageUrl,
        ));
      } else {
        needsFetch.add(artist);
      }
    }

    if (needsFetch.isEmpty) {
      dev.log(
        'Artist decoration: all ${artists.length} from cache',
        name: 'Library',
      );
      return decorated;
    }

    dev.log(
      'Artist decoration: ${decorated.length} cached, '
      '${needsFetch.length} need fetch',
      name: 'Library',
    );

    // Fetch only uncached URIs.
    final freshlyDecorated = await _fetchArtistDecorations(needsFetch);
    decorated.addAll(freshlyDecorated);

    return decorated;
  }

  Future<List<LibraryItem>> _fetchArtistDecorations(
    List<LibraryItem> artists,
  ) async {
    final uris = artists.map((a) => a.uri).toList();

    try {
      final taskId = List<int>.generate(16, (_) => Random().nextInt(256));

      final request = BatchedEntityRequest()
        ..header = (BatchedEntityRequestHeader()
          // TODO: Derive from user profile or device locale
          ..country = 'IN'
          // TODO: Derive from user profile or device locale
          ..catalogue = 'free'
          ..taskId = taskId);

      for (final uri in uris) {
        final entityReq = EntityRequest()..entityUri = uri;
        entityReq.query.addAll([
          ExtensionQuery()..extensionKind = ExtensionKind.IDENTITY_TRAIT,
          ExtensionQuery()
            ..extensionKind = ExtensionKind.PUBLISHING_METADATA_TRAIT,
          ExtensionQuery()..extensionKind = ExtensionKind.ARTIST_V4,
        ]);
        request.entityRequest.add(entityReq);
      }

      final responseBytes = await _client.post(
        '/extended-metadata/v0/extended-metadata',
        Uint8List.fromList(request.writeToBuffer()),
      );
      if (responseBytes == null) return artists;

      final result = await Isolate.run(
        () => _parseArtistDecoration(artists, responseBytes),
      );

      // Cache the freshly fetched decorations.
      final decorationsToCache = <String, DecorationData>{};
      for (final item in result) {
        if (item.name.isNotEmpty && item.name != _nameFromUri(item.uri)) {
          decorationsToCache[item.uri] = DecorationData(
            name: item.name,
            imageUrl: item.imageUrl,
          );
        }
      }
      if (decorationsToCache.isNotEmpty) {
        _cache.putDecorations(decorationsToCache);
      }

      return result;
    } catch (e, st) {
      dev.log(
        'Artist decoration error: $e',
        name: 'Library', error: e, stackTrace: st,
      );
      return artists;
    }
  }

  static List<LibraryItem> _parseArtistDecoration(
    List<LibraryItem> artists,
    Uint8List data,
  ) {
    final response = BatchedExtensionResponse.fromBuffer(data);

    final nameMap = <String, String>{};
    final imageMap = <String, String>{};

    for (final array in response.extendedMetadata) {
      final kind = array.extensionKind;

      for (final extData in array.extensionData) {
        final uri = extData.entityUri;
        if (uri.isEmpty || !extData.hasExtensionData()) continue;

        final payload = extData.extensionData.value;
        if (payload.isEmpty) continue;

        try {
          if (kind == ExtensionKind.IDENTITY_TRAIT) {
            final trait = identity_pb.IdentityTrait.fromBuffer(payload);
            if (trait.name.isNotEmpty) {
              nameMap[uri] = trait.name;
            }
          } else if (kind == ExtensionKind.ARTIST_V4) {
            final artist = meta_pb.Artist.fromBuffer(payload);
            if (!nameMap.containsKey(uri) && artist.name.isNotEmpty) {
              nameMap[uri] = artist.name;
            }
            if (artist.hasPortraitGroup()) {
              final images = artist.portraitGroup.image;
              if (images.isNotEmpty) {
                final best = images.reduce(
                  (a, b) => (a.width > b.width) ? a : b,
                );
                if (best.fileId.isNotEmpty) {
                  final hex = best.fileId
                      .map((b) => b.toRadixString(16).padLeft(2, '0'))
                      .join();
                  imageMap[uri] = 'https://i.scdn.co/image/$hex';
                }
              }
            }
          }
        } catch (e) {
          dev.log('Parse artist extension data failed: $e');
        }
      }
    }

    dev.log(
      'Artist decoration: ${nameMap.length} names, ${imageMap.length} images',
      name: 'Library',
    );

    return artists.map((item) {
      return item.copyWith(
        name: nameMap[item.uri],
        imageUrl: imageMap[item.uri],
      );
    }).toList();
  }
}
