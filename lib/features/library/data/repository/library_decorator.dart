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

  /// Decorates playlists with cached metadata, track counts, and covers.
  Future<List<LibraryItem>> decoratePlaylists(
    List<LibraryItem> playlists,
  ) async {
    if (playlists.isEmpty) return playlists;

    final result = List<LibraryItem>.from(playlists);

    for (var i = 0; i < result.length; i++) {
      final item = result[i];
      final parts = item.uri.split(':');
      if (parts.length < 3 || parts[1] != 'playlist') continue;

      final playlistId = parts[2];
      final entry = await _playlistCache.get(playlistId);

      // 1. Custom cover: If item already has a custom cover from the rootlist
      // or if cache recorded it as a custom cover, use it unconditionally.
      final rootlistCover = item.imageUrl;
      final cachedIsCustom = entry?.isCustomCover ?? false;
      final hasCustomCover = (rootlistCover != null && rootlistCover.isNotEmpty) ||
          (cachedIsCustom && entry?.coverUrl != null && entry!.coverUrl!.isNotEmpty);

      if (hasCustomCover) {
        final customUrl = (rootlistCover != null && rootlistCover.isNotEmpty)
            ? rootlistCover
            : entry!.coverUrl!;
        result[i] = item.copyWith(
          imageUrl: customUrl,
          mosaicImageUrls: const [],
          trackCount: entry?.trackUris.isNotEmpty == true
              ? entry!.trackUris.length
              : item.trackCount,
        );

        if (entry != null && (!entry.isCustomCover || entry.coverUrl != customUrl)) {
          await _playlistCache.put(
            playlistId: playlistId,
            revision: entry.revision,
            trackUris: entry.trackUris,
            coverUrl: customUrl,
            isCustomCover: true,
            mosaicImageUrls: const [],
          );
        }
        continue;
      }

      // 2. No custom cover: Use cached mosaic/cover or resolve once if missing.
      if (entry != null && entry.trackUris.isNotEmpty) {
        var mosaicUrls = entry.mosaicImageUrls;
        var coverUrl = entry.coverUrl;

        if (mosaicUrls.isEmpty && (coverUrl == null || coverUrl.isEmpty)) {
          final trackArts = await getMosaicUrls(entry.trackUris);
          if (trackArts.length >= 4) {
            mosaicUrls = trackArts.take(4).toList();
            coverUrl = mosaicUrls.first;
          } else if (trackArts.isNotEmpty) {
            mosaicUrls = const [];
            coverUrl = trackArts.first;
          }
          await _playlistCache.put(
            playlistId: playlistId,
            revision: entry.revision,
            trackUris: entry.trackUris,
            coverUrl: coverUrl,
            isCustomCover: false,
            mosaicImageUrls: mosaicUrls,
          );
        }

        result[i] = item.copyWith(
          imageUrl: coverUrl,
          mosaicImageUrls: mosaicUrls,
          trackCount: entry.trackUris.length,
        );
      }
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

  /// Extracts the first 4 unique album art URLs, fetching metadata on-demand
  /// if tracks are not already present in memory/disk cache.
  Future<List<String>> getMosaicUrls(List<String> trackUris) async {
    if (trackUris.isEmpty) return const [];

    await _metadataService.ensureLoaded();

    final seen = <String>{};
    final urls = <String>[];

    // Pass 1: Try in-memory / disk cache
    for (final uri in trackUris) {
      if (!uri.startsWith('spotify:track:')) continue;
      final cached = _metadataService.getCached(uri);
      if (cached == null) continue;

      final imageUrl = cached.imageUrl;
      if (imageUrl.isNotEmpty && seen.add(imageUrl)) {
        urls.add(imageUrl);
        if (urls.length >= 4) return urls;
      }
    }

    // Pass 2: If fewer than 4 unique artworks were found in cache,
    // fetch metadata for candidate tracks (up to 12) from network.
    if (urls.length < 4) {
      final candidates = <String>[];
      final candidateSeen = <String>{};
      for (final uri in trackUris) {
        if (uri.startsWith('spotify:track:') && candidateSeen.add(uri)) {
          candidates.add(uri);
          if (candidates.length >= 12) break;
        }
      }

      if (candidates.isNotEmpty) {
        try {
          final fetched = await _metadataService.fetchTracks(candidates);
          for (final uri in candidates) {
            final meta = fetched[uri] ?? _metadataService.getCached(uri);
            if (meta == null) continue;

            final imageUrl = meta.imageUrl;
            if (imageUrl.isNotEmpty && seen.add(imageUrl)) {
              urls.add(imageUrl);
              if (urls.length >= 4) return urls;
            }
          }
        } catch (e) {
          dev.log('Failed to fetch candidate tracks for mosaic: $e',
              name: 'Library');
        }
      }
    }

    return urls;
  }
}
