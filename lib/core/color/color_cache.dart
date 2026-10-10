import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/cache/cache_policy.dart';
import 'package:musify_mu/core/color/artwork_color_scheme.dart';

/// Persistent color scheme cache backed by [AppCacheManager].
///
/// Stores extracted [ArtworkColorScheme]s keyed by artwork URL or identifier.
/// On cache hit, returns the scheme instantly from memory.
/// Entries are persisted to disk as JSON and survive app restarts.
///
/// Cache invalidation:
/// - TTL-based (7 days via [CachePolicy.durable])
/// - URL-based (if artwork URL changes, old entry is irrelevant)
class ColorCache {
  static const _policy = CachePolicy.durable;
  static const _formatVersion = 2;

  final AppCacheManager _cacheManager;

  final Map<String, _SchemeEntry> _entries = {};
  bool _loaded = false;
  int _loadedGeneration = -1;

  ColorCache({required AppCacheManager cacheManager})
      : _cacheManager = cacheManager;

  Future<Directory> get _cacheDir => _cacheManager.featureDir('colors');

  /// Returns cached scheme for [artworkUrl], or null if not cached/expired.
  ArtworkColorScheme? get(String artworkUrl) {
    _checkGeneration();
    final entry = _entries[artworkUrl];
    if (entry == null) return null;
    if (_policy.isExpired(entry.cachedAt)) {
      _entries.remove(artworkUrl);
      return null;
    }
    return ArtworkColorScheme.fromArgbList(entry.argbColors);
  }

  /// Stores extracted scheme for [artworkUrl] and persists to disk.
  Future<void> put(String artworkUrl, ArtworkColorScheme scheme) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _entries[artworkUrl] = _SchemeEntry(
      argbColors: scheme.toArgbList(),
      cachedAt: now,
    );
    await _persist();
  }

  /// Loads the cache from disk into memory. Call once at startup.
  Future<void> load() async {
    if (_loaded && _loadedGeneration == _cacheManager.generation) return;
    _loaded = true;
    _loadedGeneration = _cacheManager.generation;
    _entries.clear();

    try {
      final dir = await _cacheDir;
      final file = File(
        '${dir.path}${Platform.pathSeparator}colors.json',
      );
      if (!await file.exists()) return;

      final raw = await file.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;

      // Version check: clear stale v1 caches
      final version = map['_v'] as int? ?? 1;
      if (version != _formatVersion) {
        await file.delete();
        return;
      }

      for (final e in map.entries) {
        if (e.key.startsWith('_')) continue; // skip metadata keys
        final v = e.value as Map<String, dynamic>;
        final cachedAt = v['t'] as int? ?? 0;
        if (_policy.isExpired(cachedAt)) continue;

        final colorsList = (v['c'] as List<dynamic>).cast<int>();
        if (colorsList.length < 5) continue;

        _entries[e.key] = _SchemeEntry(
          argbColors: colorsList,
          cachedAt: cachedAt,
        );
      }
    } catch (e) {
      dev.log('ColorCache: load failed: $e');
    }
  }

  /// Removes all cached colors from memory and disk.
  Future<void> clear() async {
    _entries.clear();
    try {
      final dir = await _cacheDir;
      final file = File(
        '${dir.path}${Platform.pathSeparator}colors.json',
      );
      if (await file.exists()) await file.delete();
    } catch (e) {
      dev.log('ColorCache: clear failed: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final dir = await _cacheDir;
      final file = File(
        '${dir.path}${Platform.pathSeparator}colors.json',
      );

      final map = <String, dynamic>{'_v': _formatVersion};
      for (final e in _entries.entries) {
        map[e.key] = {
          'c': e.value.argbColors,
          't': e.value.cachedAt,
        };
      }
      await file.writeAsString(jsonEncode(map), flush: true);
    } catch (e) {
      dev.log('ColorCache: persist failed: $e');
    }
  }

  void _checkGeneration() {
    if (_loadedGeneration != _cacheManager.generation) {
      _entries.clear();
      _loaded = false;
    }
  }
}

class _SchemeEntry {
  final List<int> argbColors;
  final int cachedAt;

  const _SchemeEntry({
    required this.argbColors,
    required this.cachedAt,
  });
}
