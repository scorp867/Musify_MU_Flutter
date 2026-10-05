import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:ui';

import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/cache/cache_policy.dart';

/// Persistent color cache backed by [AppCacheManager].
///
/// Stores extracted colors keyed by artwork URL.
/// On cache hit, returns the color instantly from memory.
/// Entries are persisted to disk as JSON and survive app restarts.
///
/// Cache invalidation:
/// - TTL-based (7 days via [CachePolicy.durable])
/// - URL-based (if artwork URL changes, old entry is irrelevant)
class ColorCache {
  static const _policy = CachePolicy.durable;

  final AppCacheManager _cacheManager;

  /// In-memory LRU: artworkUrl -> _ColorEntry
  final Map<String, _ColorEntry> _entries = {};
  bool _loaded = false;
  int _loadedGeneration = -1;

  ColorCache({required AppCacheManager cacheManager})
      : _cacheManager = cacheManager;

  Future<Directory> get _cacheDir => _cacheManager.featureDir('colors');

  /// Returns cached color for [artworkUrl], or null if not cached/expired.
  Color? get(String artworkUrl) {
    _checkGeneration();
    final entry = _entries[artworkUrl];
    if (entry == null) return null;
    if (_policy.isExpired(entry.cachedAt)) {
      _entries.remove(artworkUrl);
      return null;
    }
    return Color.fromARGB(255, entry.r, entry.g, entry.b);
  }

  /// Stores extracted color for [artworkUrl] and persists to disk.
  Future<void> put(String artworkUrl, Color color) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _entries[artworkUrl] = _ColorEntry(
      r: (color.r * 255.0).round().clamp(0, 255),
      g: (color.g * 255.0).round().clamp(0, 255),
      b: (color.b * 255.0).round().clamp(0, 255),
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

      for (final e in map.entries) {
        final v = e.value as Map<String, dynamic>;
        final cachedAt = v['t'] as int? ?? 0;
        if (_policy.isExpired(cachedAt)) continue;

        _entries[e.key] = _ColorEntry(
          r: v['r'] as int,
          g: v['g'] as int,
          b: v['b'] as int,
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

      final map = <String, dynamic>{};
      for (final e in _entries.entries) {
        map[e.key] = {
          'r': e.value.r,
          'g': e.value.g,
          'b': e.value.b,
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

class _ColorEntry {
  final int r;
  final int g;
  final int b;
  final int cachedAt;

  const _ColorEntry({
    required this.r,
    required this.g,
    required this.b,
    required this.cachedAt,
  });
}
