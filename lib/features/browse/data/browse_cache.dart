import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:musify_mu/features/browse/data/browse_metadata_fetcher.dart';
import 'package:path_provider/path_provider.dart';

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
  static const _fileName = 'browse_traits_cache.json';

  /// Per-item TTL. Individual card data (genre name, image, color)
  /// changes very rarely -- days or weeks.
  static const _itemTtl = Duration(days: 7);

  File? _cacheFile;
  Map<String, _CachedTrait>? _memoryCache;

  Future<File> _getCacheFile() async {
    if (_cacheFile != null) return _cacheFile!;
    final dir = await getApplicationSupportDirectory();
    _cacheFile = File('${dir.path}/$_fileName');
    return _cacheFile!;
  }

  /// Loads the cache into memory (once).
  Future<Map<String, _CachedTrait>> _ensureLoaded() async {
    if (_memoryCache != null) return _memoryCache!;

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

    _memoryCache ??= {};
    final now = DateTime.now();
    _memoryCache!.removeWhere((key, value) => now.difference(value.cachedAt) >= _itemTtl);
    
    return _memoryCache!;
  }

  /// Given a list of URIs, returns:
  ///   - `cached`: already-resolved cards from cache (fresh ones only)
  ///   - `missing`: URIs that need to be fetched from extended-metadata
  Future<({Map<String, BrowseCardData> cached, List<String> missing})>
      partition(List<String> uris) async {
    final cache = await _ensureLoaded();
    final now = DateTime.now();

    final cached = <String, BrowseCardData>{};
    final missing = <String>[];

    for (final uri in uris) {
      final entry = cache[uri];
      if (entry != null && now.difference(entry.cachedAt) < _itemTtl) {
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
    final now = DateTime.now();

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
      final now = DateTime.now();
      final validEntries = cache.entries
          .where((e) => now.difference(e.value.cachedAt) < _itemTtl)
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
  final DateTime cachedAt;

  _CachedTrait({required this.data, required this.cachedAt});

  Map<String, dynamic> toJson() => {
        'name': data.name,
        'type': data.type,
        'imageUrl': data.imageUrl,
        'bgColor': data.bgColorArgb,
        'cachedAt': cachedAt.millisecondsSinceEpoch,
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
      cachedAt: DateTime.fromMillisecondsSinceEpoch(
        map['cachedAt'] as int? ?? 0,
      ),
    );
  }
}
