import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/cache/cache_policy.dart';
import 'package:musify_mu/features/browse/data/browse_metadata_fetcher.dart';

/// Per-URI cache for browse card traits (IdentityTrait + VisualIdentityTrait).
///
/// Spotify caches individual item traits, not the whole browse response.
/// On revalidation, it only queries extended-metadata for URIs
/// not yet in the local cache (delta fetch).
///
/// Cache structure (JSON file):
/// {
///   "spotify:page:abc123": {
///     "name": "Hindi",
///     "type": "page",
///     "imageUrl": "https://...",
///     "bgColor": 4294912345,
///     "cachedAt": 1695000000000
///   },
///   ...
/// }
class BrowseTraitCache {
  static const _fileName = 'browse_traits.json';
  static const _policy = CachePolicy.durable;

  final AppCacheManager _cacheManager;
  Map<String, _CachedTrait>? _memoryCache;
  int _loadedGeneration = -1;

  BrowseTraitCache({required AppCacheManager cacheManager})
      : _cacheManager = cacheManager;

  Future<File> _getCacheFile() async {
    final dir = await _cacheManager.featureDir('browse');
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  /// Loads the cache into memory (once per user session).
  Future<Map<String, _CachedTrait>> _ensureLoaded() async {
    if (_memoryCache != null &&
        _loadedGeneration == _cacheManager.generation) {
      return _memoryCache!;
    }

    _memoryCache = {};
    _loadedGeneration = _cacheManager.generation;

    try {
      final file = await _getCacheFile();
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _memoryCache = map.map(
          (uri, json) => MapEntry(uri, _CachedTrait.fromJson(json)),
        );
      }
    } catch (e) {
      dev.log('BrowseTraitCache: load error: $e', name: 'Browse');
    }

    return _memoryCache!;
  }

  /// Given a list of URIs, returns:
  ///   - `cached`: already-resolved cards from cache
  ///   - `missing`: URIs that need to be fetched from extended-metadata
  Future<({Map<String, BrowseCardData> cached, List<String> missing})>
      partition(List<String> uris) async {
    final cache = await _ensureLoaded();

    final cached = <String, BrowseCardData>{};
    final missing = <String>[];

    for (final uri in uris) {
      final entry = cache[uri];
      if (entry != null) {
        cached[uri] = entry.data;
      } else {
        missing.add(uri);
      }
    }

    dev.log(
      'BrowseTraitCache: ${cached.length} cached, ${missing.length} delta',
      name: 'Browse',
    );
    return (cached: cached, missing: missing);
  }

  /// Stores freshly fetched traits into the cache.
  Future<void> putAll(Map<String, BrowseCardData> freshCards) async {
    if (freshCards.isEmpty) return;

    final cache = await _ensureLoaded();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final entry in freshCards.entries) {
      cache[entry.key] = _CachedTrait(data: entry.value, cachedAt: now);
    }

    await _persist();

    dev.log(
      'BrowseTraitCache: stored ${freshCards.length} new traits '
      '(total: ${cache.length})',
      name: 'Browse',
    );
  }

  /// Writes the in-memory cache to disk.
  Future<void> _persist() async {
    try {
      final cache = _memoryCache;
      if (cache == null) return;

      final file = await _getCacheFile();
      final validEntries = cache.entries
          .where((e) => !_policy.isExpired(e.value.cachedAt))
          .map((e) => MapEntry(e.key, e.value.toJson()));
      await file.writeAsString(jsonEncode(Map.fromEntries(validEntries)));
    } catch (e) {
      dev.log('BrowseTraitCache: persist error: $e', name: 'Browse');
    }
  }
}

/// A single cached trait entry with timestamp.
class _CachedTrait {
  final BrowseCardData data;
  final int cachedAt;

  _CachedTrait({required this.data, required this.cachedAt});

  Map<String, dynamic> toJson() => {
        'name': data.name,
        'type': data.type,
        'imageUrl': data.imageUrl,
        'bgColor': data.bgColorArgb,
        'cachedAt': cachedAt,
      };

  factory _CachedTrait.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return _CachedTrait(
      data: BrowseCardData(
        name: map['name'] as String? ?? '',
        type: map['type'] as String? ?? '',
        imageUrl: map['imageUrl'] as String?,
        bgColorArgb: map['bgColor'] as int?,
      ),
      cachedAt: map['cachedAt'] as int? ?? 0,
    );
  }
}
