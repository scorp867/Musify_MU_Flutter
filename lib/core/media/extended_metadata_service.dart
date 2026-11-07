import 'dart:developer' as dev;
import 'dart:io';

import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_client.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/kodiak/table/table_key.dart';
import 'package:musify_mu/core/network/result/network_result.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// App-wide service for resolving Kodiak `TrackV4` (kind 10) and `EpisodeV4` (kind 12)
/// metadata backed directly by `DataPool` and binary `KodiakDiskCache`.
class ExtendedMetadataService {
  static const _legacyJsonlFileName = 'track_meta.jsonl';

  final DataPool _dataPool;
  final ExtendedMetadataClient _metadataClient;
  final AppCacheManager? _cacheManager;
  Future<void>? _initFuture;

  ExtendedMetadataService({
    required DataPool dataPool,
    required ExtendedMetadataClient metadataClient,
    AppCacheManager? cacheManager,
  }) : _dataPool = dataPool,
       _metadataClient = metadataClient,
       _cacheManager = cacheManager;

  /// Ensures binary `KodiakDiskCache` is loaded into `_dataPool` and cleans up
  /// any legacy `track_meta.jsonl` file.
  Future<void> ensureLoaded() {
    return _initFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    await _dataPool.ensureDiskLoaded();
    final cacheManager = _cacheManager;
    if (cacheManager != null && cacheManager.hasUser) {
      try {
        final dir = await cacheManager.featureDir('metadata');
        final legacy = File(
          '${dir.path}${Platform.pathSeparator}$_legacyJsonlFileName',
        );
        if (await legacy.exists()) {
          await legacy.delete();
        }
      } catch (e) {
        dev.log(
          'ExtendedMetadataService: failed to remove legacy jsonl: $e',
          name: 'Metadata',
        );
      }
    }
  }

  /// Synchronously returns cached `TrackV4` for `uri`, or `null` if not cached.
  TrackV4? getCachedTrack(String uri) => _dataPool.getTrait<TrackV4>(uri);

  /// Synchronously returns cached `EpisodeV4` for `uri`, or `null` if not cached.
  EpisodeV4? getCachedEpisode(String uri) => _dataPool.getTrait<EpisodeV4>(uri);

  /// Resolves `TrackV4` metadata for `uris` in batches of 50.
  Future<Map<String, TrackV4>> fetchTracks(List<String> uris) async {
    if (uris.isEmpty) return const {};

    await ensureLoaded();

    final results = <String, TrackV4>{};
    final uncached = <String>[];

    for (final uri in uris) {
      if (!uri.startsWith('spotify:track:')) continue;
      if (_dataPool.getTrait<TrackV4>(uri) case final cached?) {
        results[uri] = cached;
      } else {
        uncached.add(uri);
      }
    }

    if (uncached.isEmpty) return results;

    const batchSize = 50;
    for (var i = 0; i < uncached.length; i += batchSize) {
      final batch = uncached.skip(i).take(batchSize).toList(growable: false);
      final fetched = await _fetchEntitiesBatch(batch);
      results.addAll(fetched.tracks);
    }

    return results;
  }

  /// Resolves `TrackV4` and `EpisodeV4` metadata for `uris` in a single network request.
  Future<({Map<String, TrackV4> tracks, Map<String, EpisodeV4> episodes})>
  fetchEntitiesSingleRequest(List<String> uris) async {
    if (uris.isEmpty) {
      return (
        tracks: const <String, TrackV4>{},
        episodes: const <String, EpisodeV4>{},
      );
    }

    await ensureLoaded();

    final tracks = <String, TrackV4>{};
    final episodes = <String, EpisodeV4>{};
    final uncached = <String>[];

    for (final uri in uris) {
      if (uri.startsWith('spotify:episode:')) {
        if (_dataPool.getTrait<EpisodeV4>(uri) case final cachedEp?) {
          episodes[uri] = cachedEp;
        } else {
          uncached.add(uri);
        }
      } else if (uri.startsWith('spotify:track:')) {
        if (_dataPool.getTrait<TrackV4>(uri) case final cachedTrack?) {
          tracks[uri] = cachedTrack;
        } else {
          uncached.add(uri);
        }
      }
    }

    if (uncached.isEmpty) {
      return (tracks: tracks, episodes: episodes);
    }

    final fetched = await _fetchEntitiesBatch(uncached);
    tracks.addAll(fetched.tracks);
    episodes.addAll(fetched.episodes);
    return (tracks: tracks, episodes: episodes);
  }

  Future<({Map<String, TrackV4> tracks, Map<String, EpisodeV4> episodes})>
  _fetchEntitiesBatch(List<String> uris) async {
    final keys = <CellKey>{};
    for (final uri in uris) {
      if (uri.startsWith('spotify:episode:')) {
        keys.add(CellKey(const TableKey<EpisodeV4>(), uri));
        keys.add(CellKey(const TableKey<PlaybackTrait>(), uri));
      } else if (uri.startsWith('spotify:track:')) {
        keys.add(CellKey(const TableKey<TrackV4>(), uri));
        keys.add(CellKey(const TableKey<PlaybackTrait>(), uri));
      }
    }

    if (keys.isEmpty) {
      return (
        tracks: const <String, TrackV4>{},
        episodes: const <String, EpisodeV4>{},
      );
    }

    final res = await _metadataClient.fetchCellsRawResult(keys);
    switch (res) {
      case NetworkFailure(:final error):
        dev.log(
          'ExtendedMetadataService batch failure: $error',
          name: 'Metadata',
        );
        return (
          tracks: const <String, TrackV4>{},
          episodes: const <String, EpisodeV4>{},
        );

      case NetworkSuccess(data: final fetched):
        if (fetched.cells.isNotEmpty) {
          _dataPool.ingestCells(fetched.cells);
        }
        if (fetched.rawPayloads.isNotEmpty) {
          _dataPool.ingestRawPayloads(fetched.rawPayloads);
        }

        final tracks = <String, TrackV4>{};
        final episodes = <String, EpisodeV4>{};
        final relinkedByOriginal = <String, String>{};

        for (final uri in uris) {
          if (uri.startsWith('spotify:episode:')) {
            final cell =
                fetched.cells[CellKey(const TableKey<EpisodeV4>(), uri)];
            if (cell is EpisodeV4) {
              episodes[uri] = cell;
            }
          } else if (uri.startsWith('spotify:track:')) {
            final cell = fetched.cells[CellKey(const TableKey<TrackV4>(), uri)];
            if (cell is TrackV4) {
              tracks[uri] = cell;
              if ((cell.name.isEmpty || cell.files.isEmpty) &&
                  cell.alternatives.isNotEmpty) {
                final altUri = cell.alternatives.first.uri;
                if (altUri.isNotEmpty && altUri != uri) {
                  relinkedByOriginal[uri] = altUri;
                }
              }
            }
          }
        }

        if (relinkedByOriginal.isNotEmpty) {
          final altKeys = <CellKey>{
            for (final altUri in relinkedByOriginal.values)
              CellKey(const TableKey<TrackV4>(), altUri),
          };
          final altRes = await _metadataClient.fetchCellsRawResult(altKeys);
          if (altRes case NetworkSuccess(data: final altFetched)) {
            if (altFetched.cells.isNotEmpty) {
              _dataPool.ingestCells(altFetched.cells);
            }
            if (altFetched.rawPayloads.isNotEmpty) {
              _dataPool.ingestRawPayloads(altFetched.rawPayloads);
            }
            for (final entry in relinkedByOriginal.entries) {
              final altCell =
                  altFetched.cells[CellKey(
                    const TableKey<TrackV4>(),
                    entry.value,
                  )];
              if (altCell is TrackV4) {
                final original = tracks[entry.key];
                if (original == null ||
                    original.name.isEmpty ||
                    (original.files.isEmpty && altCell.files.isNotEmpty)) {
                  tracks[entry.key] = altCell;
                }
              }
            }
          }
        }

        return (tracks: tracks, episodes: episodes);
    }
  }
}
