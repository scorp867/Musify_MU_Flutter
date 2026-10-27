import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/cache/cache_policy.dart';
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_client.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/plugins/builtin_plugins.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/kodiak/table/table_key.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Resolved metadata for a single track or episode.
///
/// Shared across the whole app: library mosaic, playlist detail,
/// now playing, queue, playback, etc.
class TrackMeta {
  final String uri;
  final String title;
  final String subtitle; // artist names joined
  final String albumName;

  /// Image URLs by size. Keys: 'small' (~64px), 'medium' (~300px), 'large' (~640px).
  final Map<String, String> imageUrls;

  /// Best cover URL (largest available).
  String get imageUrl =>
      imageUrls['large'] ??
      imageUrls['medium'] ??
      imageUrls['small'] ??
      '';

  /// Thumbnail cover URL (small ~64px, falling back to medium then large).
  String get thumbnailImageUrl =>
      imageUrls['small'] ??
      imageUrls['medium'] ??
      imageUrls['large'] ??
      '';

  /// Raw hex image ID of the largest cover (for mosaic URL construction).
  final String? largeImageHex;

  final int durationMs;

  const TrackMeta({
    required this.uri,
    this.title = '',
    this.subtitle = '',
    this.albumName = '',
    this.imageUrls = const {},
    this.largeImageHex,
    this.durationMs = 0,
  });
}

/// App-wide centralized service for fetching and caching entity metadata
/// via the extended-metadata endpoint.
///
/// Uses TRACK_V4 (10) for tracks and EPISODE_V4 (12) for episodes.
/// Two-layer cache: in-memory LRU (hot path) + disk (persistence).
///
/// Consumers:
///   - Library: playlist mosaic covers (first 4 track images)
///   - Playlist detail: full track list with metadata
///   - Now Playing / Queue: track info display
///   - Playback: duration, title, artist
class ExtendedMetadataService {
  final ExtendedMetadataClient _metadataClient;

  // Layer 1: In-memory LRU for zero-cost reads.
  final _memCache = _LruCache<String, TrackMeta>(2000);

  // Layer 2: Disk persistence.
  final _TrackMetaDiskCache _diskCache;

  bool _diskLoaded = false;

  ExtendedMetadataService({
    required SpotifyTransport client,
    required RuntimeContext ctx,
    required AppCacheManager cacheManager,
    ExtendedMetadataClient? metadataClient,
  })  : _metadataClient = metadataClient ??
            ExtendedMetadataClient(
              transport: client,
              ctx: ctx,
              registry: ExtendedMetadataPluginRegistry(
                createDefaultExtendedMetadataPlugins(),
              ),
            ),
        _diskCache = _TrackMetaDiskCache(cacheManager: cacheManager);

  /// Loads disk cache into memory (called once lazily).
  Future<void> _ensureDiskLoaded() async {
    if (_diskLoaded) return;
    _diskLoaded = true;

    final entries = await _diskCache.loadAll();
    for (final entry in entries.entries) {
      _memCache.put(entry.key, entry.value);
    }
    if (entries.isNotEmpty) {
      dev.log(
        'ExtMetadataService: loaded ${entries.length} entries from disk',
        name: 'Metadata',
      );
    }
  }

  /// Ensures disk cache has been loaded into memory.
  Future<void> ensureLoaded() => _ensureDiskLoaded();

  /// Returns cached metadata for a URI, or null if not cached.
  TrackMeta? getCached(String uri) => _memCache.get(uri);

  /// Fetches metadata for the given URIs.
  /// Returns only URIs that were successfully resolved.
  /// Cached results are returned immediately; only uncached URIs hit the network.
  Future<Map<String, TrackMeta>> fetchTracks(List<String> uris) async {
    if (uris.isEmpty) return {};

    await _ensureDiskLoaded();

    final results = <String, TrackMeta>{};
    final uncached = <String>[];

    for (final uri in uris) {
      final cached = _memCache.get(uri);
      if (cached != null) {
        results[uri] = cached;
      } else {
        uncached.add(uri);
      }
    }

    if (uncached.isEmpty) return results;

    // Fetch in batches of 50 (extended-metadata limit).
    const batchSize = 50;
    final newEntries = <String, TrackMeta>{};

    for (var i = 0; i < uncached.length; i += batchSize) {
      final batch = uncached.skip(i).take(batchSize).toList();
      final fetched = await _fetchBatch(batch);
      for (final entry in fetched.entries) {
        _memCache.put(entry.key, entry.value);
        results[entry.key] = entry.value;
        newEntries[entry.key] = entry.value;
      }
    }

    // Persist new entries to disk (fire-and-forget).
    if (newEntries.isNotEmpty) {
      _diskCache.putAll(newEntries);
    }

    dev.log(
      'ExtMetadataService: ${results.length} resolved '
      '(${uncached.length} fetched, ${uris.length - uncached.length} cached)',
      name: 'Metadata',
    );

    return results;
  }

  /// Fetches metadata for all given URIs in a single network request without batching.
  /// Direct 1:1 implementation matching Kodiak single-flight datastatement decoration.
  Future<Map<String, TrackMeta>> fetchTracksSingleRequest(List<String> uris) async {
    if (uris.isEmpty) return {};

    await _ensureDiskLoaded();

    final results = <String, TrackMeta>{};
    final uncached = <String>[];

    for (final uri in uris) {
      final cached = _memCache.get(uri);
      if (cached != null) {
        results[uri] = cached;
      } else {
        uncached.add(uri);
      }
    }

    if (uncached.isEmpty) return results;

    // Fetch all uncached URIs in a single request without chunking
    final fetched = await _fetchBatch(uncached);
    for (final entry in fetched.entries) {
      _memCache.put(entry.key, entry.value);
      results[entry.key] = entry.value;
    }

    if (fetched.isNotEmpty) {
      _diskCache.putAll(fetched);
    }

    dev.log(
      'ExtMetadataService (single-request): ${results.length} resolved '
      '(${uncached.length} fetched in 1 request, ${uris.length - uncached.length} cached)',
      name: 'Metadata',
    );

    return results;
  }

  /// Convenience: fetch metadata for up to N unique track URIs from a list.
  /// Useful for mosaic cover generation where only first 4 are needed.
  Future<List<TrackMeta>> fetchFirst(List<String> uris, int count) async {
    // Deduplicate while preserving order.
    final unique = <String>[];
    final seen = <String>{};
    for (final uri in uris) {
      if (uri.startsWith('spotify:track:') && seen.add(uri)) {
        unique.add(uri);
        if (unique.length >= count) break;
      }
    }

    if (unique.isEmpty) return [];

    final map = await fetchTracks(unique);
    return unique.map((u) => map[u]).whereType<TrackMeta>().toList();
  }

  // ─── Network ──────────────────────────────────────────────────────

  Future<Map<String, TrackMeta>> _fetchBatch(List<String> uris) async {
    try {
      final keys = uris.map((u) {
        if (u.startsWith('spotify:episode:')) {
          return CellKey(const TableKey<EpisodeMetaTrait>(), u);
        }
        return CellKey(const TableKey<TrackMetaTrait>(), u);
      }).toSet();
      final cells = await _metadataClient.fetchCells(keys);
      final results = <String, TrackMeta>{};
      for (final entry in cells.entries) {
        final trait = entry.value;
        if (trait is TrackMetaTrait) {
          results[entry.key.entityUri] = TrackMeta(
            uri: entry.key.entityUri,
            title: trait.title,
            subtitle: trait.subtitle,
            albumName: trait.albumName,
            imageUrls: trait.imageUrls,
            largeImageHex: trait.largeImageHex,
            durationMs: trait.durationMs,
          );
        }
      }
      return results;
    } catch (e, st) {
      dev.log(
        'ExtMetadataService batch error: $e',
        name: 'Metadata',
        error: e,
        stackTrace: st,
      );
      return {};
    }
  }
}

/// Disk persistence for TrackMeta.
///
/// Uses a single JSONL file (one JSON object per line) for fast append-only writes.
/// Format: {"u":"spotify:track:xxx","t":"Title","s":"Artist","a":"Album","i":{"small":"url","medium":"url","large":"url"},"h":"hexId","d":12345}
class _TrackMetaDiskCache {
  static const _policy = CachePolicy.durable;
  static const _fileName = 'track_meta.jsonl';

  final AppCacheManager _cacheManager;
  File? _file;
  int _fileGeneration = -1;

  _TrackMetaDiskCache({required AppCacheManager cacheManager})
      : _cacheManager = cacheManager;

  Future<File> _getFile() async {
    if (_file != null && _fileGeneration == _cacheManager.generation) {
      return _file!;
    }
    final dir = await _cacheManager.featureDir('metadata');
    _file = File('${dir.path}${Platform.pathSeparator}$_fileName');
    _fileGeneration = _cacheManager.generation;
    return _file!;
  }

  /// Loads all entries from disk, deduplicating by URI.
  Future<Map<String, TrackMeta>> loadAll() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return {};

      final content = await file.readAsString();
      if (content.isEmpty) return {};

      final results = <String, TrackMeta>{};

      for (final line in content.split('\n')) {
        if (line.isEmpty) continue;
        try {
          final j = jsonDecode(line) as Map<String, dynamic>;

          // Check expiry.
          final ts = j['ts'] as int? ?? 0;
          if (_policy.isExpired(ts)) continue;

          final meta = _fromJson(j);
          if (meta != null) {
            results[meta.uri] = meta;
          }
        } catch (e) {
          dev.log('Parse disk cache line failed: $e');
        }
      }

      return results;
    } catch (e) {
      dev.log('Load disk cache failed: $e');
      return {};
    }
  }

  /// Appends new entries to disk (fire-and-forget).
  Future<void> putAll(Map<String, TrackMeta> entries) async {
    try {
      final file = await _getFile();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final sb = StringBuffer();

      for (final entry in entries.entries) {
        sb.writeln(jsonEncode(_toJson(entry.value, ts)));
      }

      await file.writeAsString(
        sb.toString(),
        mode: FileMode.append,
        flush: true,
      );
      await _compactIfNeeded();
    } catch (e) {
      dev.log('Write to disk cache failed: $e');
    }
  }

  Future<void> _compactIfNeeded() async {
    try {
      if (_file == null) return;
      final lines = await _file!.readAsLines();
      if (lines.length < 5000) return;
      final valid = <String>[];
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final map = jsonDecode(line) as Map<String, dynamic>;
          final ts = map['ts'] as int? ?? 0;
          if (!_policy.isExpired(ts)) valid.add(line);
        } catch (e) {
          dev.log('Compact cache check line failed: $e');
        }
      }
      await _file!.writeAsString(valid.isNotEmpty ? '${valid.join('\n')}\n' : '');
    } catch (e) {
      dev.log('Compact cache file rewrite failed: $e');
    }
  }

  static Map<String, dynamic> _toJson(TrackMeta meta, int ts) => {
        'u': meta.uri,
        't': meta.title,
        's': meta.subtitle,
        'a': meta.albumName,
        'i': meta.imageUrls,
        if (meta.largeImageHex != null) 'h': meta.largeImageHex,
        'd': meta.durationMs,
        'ts': ts,
      };

  static TrackMeta? _fromJson(Map<String, dynamic> j) {
    final uri = j['u'] as String?;
    if (uri == null || uri.isEmpty) return null;

    return TrackMeta(
      uri: uri,
      title: j['t'] as String? ?? '',
      subtitle: j['s'] as String? ?? '',
      albumName: j['a'] as String? ?? '',
      imageUrls: (j['i'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
      largeImageHex: j['h'] as String?,
      durationMs: j['d'] as int? ?? 0,
    );
  }
}

/// Simple bounded LRU cache.
class _LruCache<K, V> {
  _LruCache(this._maxSize);
  final int _maxSize;
  final LinkedHashMap<K, V> _map = LinkedHashMap<K, V>();

  V? get(K key) {
    final value = _map.remove(key);
    if (value != null) {
      _map[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    _map.remove(key);
    _map[key] = value;
    if (_map.length > _maxSize) {
      _map.remove(_map.keys.first);
    }
  }

  Map<K, V> get entries => _map;
}
