import 'dart:developer' as dev;
import 'dart:isolate';

import 'package:musify_mu/core/media/extended_metadata_service.dart';
import 'package:musify_mu/features/library/data/cache/library_cache.dart';
import 'package:musify_mu/features/library/data/cache/playlist_detail_cache.dart';
import 'package:musify_mu/features/library/data/mappers/library_mapper.dart';
import 'package:musify_mu/features/library/data/sources/library_remote_source.dart';
import 'package:musify_mu/features/library/domain/models/library_item.dart';

/// Enriches raw library items with cached artwork, names, and track counts.
/// Handles both playlist decoration (from PlaylistDetailCache) and
/// artist decoration (from LibraryCache + extended-metadata network).
class LibraryDecorator {
  final LibraryRemoteSource _librarySource;
  final LibraryCache _libraryCache;
  final PlaylistDetailCache _playlistCache;
  final ExtendedMetadataService _metadataService;

  const LibraryDecorator({
    required LibraryRemoteSource librarySource,
    required LibraryCache libraryCache,
    required PlaylistDetailCache playlistCache,
    required ExtendedMetadataService metadataService,
  })  : _librarySource = librarySource,
        _libraryCache = libraryCache,
        _playlistCache = playlistCache,
        _metadataService = metadataService;

  /// Decorates playlists from the PlaylistDetailCache. Zero network.
  Future<List<LibraryItem>> decoratePlaylists(
    List<LibraryItem> playlists,
  ) async {
    if (playlists.isEmpty) return playlists;

    final result = List<LibraryItem>.from(playlists);

    for (var i = 0; i < result.length; i++) {
      final parts = result[i].uri.split(':');
      if (parts.length < 3 || parts[1] != 'playlist') continue;

      final entry = await _playlistCache.get(parts[2]);
      if (entry == null) continue;

      result[i] = result[i].copyWith(
        imageUrl: entry.coverUrl,
        trackCount: entry.trackUris.isNotEmpty ? entry.trackUris.length : null,
        mosaicImageUrls: entry.mosaicImageUrls,
      );
    }

    return result;
  }

  /// Decorates artists: uses cached decorations first, fetches only uncached.
  Future<List<LibraryItem>> decorateArtists(
    List<LibraryItem> artists,
  ) async {
    if (artists.isEmpty) return artists;

    final needsFetch = <LibraryItem>[];
    final decorated = <LibraryItem>[];

    for (final artist in artists) {
      final cached = _libraryCache.getDecoration(artist.uri);
      if (cached != null) {
        decorated.add(
            artist.copyWith(name: cached.name, imageUrl: cached.imageUrl));
      } else {
        needsFetch.add(artist);
      }
    }

    if (needsFetch.isEmpty) return decorated;

    try {
      final uris = needsFetch.map((a) => a.uri).toList();
      final responseBytes =
          await _librarySource.fetchArtistDecorations(uris);
      if (responseBytes == null) {
        decorated.addAll(needsFetch);
        return decorated;
      }

      final freshlyDecorated = await Isolate.run(
        () => LibraryMapper.parseArtistDecorations(needsFetch, responseBytes),
      );

      final decorationsToCache = <String, DecorationData>{};
      for (final item in freshlyDecorated) {
        final parts = item.uri.split(':');
        final baseName = parts.length >= 3 ? parts[2] : item.uri;
        if (item.name.isNotEmpty && item.name != baseName) {
          decorationsToCache[item.uri] = DecorationData(
            name: item.name,
            imageUrl: item.imageUrl,
          );
        }
      }
      if (decorationsToCache.isNotEmpty) {
        _libraryCache.putDecorations(decorationsToCache);
      }

      decorated.addAll(freshlyDecorated);
    } catch (e, st) {
      dev.log('Artist decoration error: $e',
          name: 'Library', error: e, stackTrace: st);
      decorated.addAll(needsFetch);
    }

    return decorated;
  }

  /// Extracts the first 4 unique album art URLs from cached track metadata.
  List<String> getMosaicUrls(List<String> trackUris) {
    final seen = <String>{};
    final urls = <String>[];

    for (final uri in trackUris) {
      final cached = _metadataService.getCached(uri);
      if (cached == null) continue;

      final imageUrl = cached.imageUrl;
      if (imageUrl.isNotEmpty && seen.add(imageUrl)) {
        urls.add(imageUrl);
        if (urls.length >= 4) break;
      }
    }

    return urls;
  }
}
