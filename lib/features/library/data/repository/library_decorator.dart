import 'dart:developer' as dev;
import 'dart:isolate';

import 'package:musify_mu/core/media/extended_metadata_service.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';
import 'package:musify_mu/features/library/data/cache/library_cache.dart';
import 'package:musify_mu/features/library/data/cache/playlist_detail_cache.dart';
import 'package:musify_mu/features/library/data/mappers/library_mapper.dart';
import 'package:musify_mu/features/library/data/sources/library_remote_source.dart';
import 'package:musify_mu/features/library/domain/models/library_item.dart';

/// Enriches raw library items with cached artwork, names, and track counts.
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
  }) : _librarySource = librarySource,
       _libraryCache = libraryCache,
       _playlistCache = playlistCache,
       _metadataService = metadataService;

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

      final rootlistCover = item.imageUrl;
      String? customUrl;
      if (rootlistCover != null && rootlistCover.isNotEmpty) {
        customUrl = rootlistCover;
      } else if (entry != null && entry.isCustomCover) {
        if (entry.coverUrl case final cachedCover? when cachedCover.isNotEmpty) {
          customUrl = cachedCover;
        }
      }

      if (customUrl != null) {
        result[i] = item.copyWith(
          imageUrl: customUrl,
          mosaicImageUrls: const [],
          trackCount: (entry != null && entry.trackUris.isNotEmpty)
              ? entry.trackUris.length
              : item.trackCount,
        );

        if (entry != null &&
            (!entry.isCustomCover || entry.coverUrl != customUrl)) {
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

  Future<List<LibraryItem>> decorateArtists(List<LibraryItem> artists) async {
    if (artists.isEmpty) return artists;

    final needsFetch = <LibraryItem>[];
    final decorated = <LibraryItem>[];

    for (final artist in artists) {
      final cached = _libraryCache.getDecoration(artist.uri);
      if (cached != null) {
        decorated.add(
          artist.copyWith(name: cached.name, imageUrl: cached.imageUrl),
        );
      } else {
        needsFetch.add(artist);
      }
    }

    if (needsFetch.isEmpty) return decorated;

    try {
      final uris = needsFetch.map((a) => a.uri).toList();
      final responseBytes = await _librarySource.fetchArtistDecorations(uris);
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
      dev.log(
        'Artist decoration error: $e',
        name: 'Library',
        error: e,
        stackTrace: st,
      );
      decorated.addAll(needsFetch);
    }

    return decorated;
  }

  /// Extracts the first 4 unique album art URLs from `TrackV4.albumCover`.
  Future<List<String>> getMosaicUrls(List<String> trackUris) async {
    if (trackUris.isEmpty) return const [];

    await _metadataService.ensureLoaded();

    final seen = <String>{};
    final urls = <String>[];

    for (final uri in trackUris) {
      if (!uri.startsWith('spotify:track:')) continue;
      final cached = _metadataService.getCachedTrack(uri);
      if (cached == null) continue;

      final imageUrl = cached.albumCover.urlForSize(ImageSize.large);
      if (imageUrl.isNotEmpty && seen.add(imageUrl)) {
        urls.add(imageUrl);
        if (urls.length >= 4) return urls;
      }
    }

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
            final track = fetched[uri] ?? _metadataService.getCachedTrack(uri);
            if (track == null) continue;

            final imageUrl = track.albumCover.urlForSize(ImageSize.large);
            if (imageUrl.isNotEmpty && seen.add(imageUrl)) {
              urls.add(imageUrl);
              if (urls.length >= 4) return urls;
            }
          }
        } catch (e) {
          dev.log(
            'Failed to fetch candidate tracks for mosaic: $e',
            name: 'Library',
          );
        }
      }
    }

    return urls;
  }
}
