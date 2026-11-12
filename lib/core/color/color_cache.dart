import 'dart:async';
import 'dart:collection';
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
  static const int _maxEntries = 500;
  static const Duration _persistDebounce = Duration(milliseconds: 500);

  final AppCacheManager _cacheManager;

  final LinkedHashMap<String, _SchemeEntry> _entries =
      LinkedHashMap<String, _SchemeEntry>();
  bool _loaded = false;
  int _loadedGeneration = -1;
  Future<void>? _loadFuture;
  Timer? _persistTimer;
  Future<void>? _activePersist;
  bool _persistDirty = false;
  bool _disposed = false;

  ColorCache({required AppCacheManager cacheManager})
      : _cacheManager = cacheManager;

  Future<Directory> get _cacheDir => _cacheManager.featureDir('colors');

  /// Returns cached scheme for [artworkUrl], or null if not cached/expired.
  ArtworkColorScheme? get(String artworkUrl) {
    _checkGeneration();
    final entry = _entries.remove(artworkUrl);
    if (entry == null) return null;
    if (_policy.isExpired(entry.cachedAt)) {
      return null;
    }
    _entries[artworkUrl] = entry;
    return ArtworkColorScheme.fromArgbList(entry.argbColors);
  }

  /// Stores extracted scheme for [artworkUrl] and persists to disk.
  Future<void> put(String artworkUrl, ArtworkColorScheme scheme) async {
    if (_disposed) return;
    _checkGeneration();
    if (!_loaded || _loadedGeneration != _cacheManager.generation) {
      await load();
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    _entries.remove(artworkUrl);
    if (_entries.length >= _maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    _entries[artworkUrl] = _SchemeEntry(
      argbColors: scheme.toArgbList(),
      cachedAt: now,
    );
    _schedulePersist();
  }

  /// Loads the cache from disk into memory. Call once at startup.
  Future<void> load() async {
    if (_disposed) return;
    if (_loaded && _loadedGeneration == _cacheManager.generation) return;
    if (_loadFuture case final pending?) {
      return pending;
    }
    final future = _loadInternal();
    _loadFuture = future;
    try {
      await future;
    } finally {
      _loadFuture = null;
    }
  }

  Future<void> _loadInternal() async {
    final targetGen = _cacheManager.generation;
    _loaded = true;
    _loadedGeneration = targetGen;
    _entries.clear();

    try {
      final dir = await _cacheDir;
      if (_disposed || _cacheManager.generation != targetGen) return;
      final file = File(
        '${dir.path}${Platform.pathSeparator}colors.json',
      );
      if (!await file.exists()) return;

      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      // Version check: clear stale v1 caches
      final versionRaw = decoded['_v'];
      final version = versionRaw is int ? versionRaw : 1;
      if (version != _formatVersion) {
        await file.delete();
        return;
      }

      for (final e in decoded.entries) {
        if (e.key.startsWith('_')) continue; // skip metadata keys
        final v = e.value;
        if (v is! Map<String, dynamic>) continue;
        final cachedAtRaw = v['t'];
        final cachedAt = cachedAtRaw is int ? cachedAtRaw : 0;
        if (_policy.isExpired(cachedAt)) continue;

        final rawColors = v['c'];
        if (rawColors is! List) continue;
        final colorsList = <int>[];
        var valid = true;
        for (final item in rawColors) {
          if (item is int) {
            colorsList.add(item);
          } else {
            valid = false;
            break;
          }
        }
        if (!valid || colorsList.length < 5) continue;

        if (_entries.length >= _maxEntries) {
          _entries.remove(_entries.keys.first);
        }
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
    _persistTimer?.cancel();
    _persistTimer = null;
    _persistDirty = false;
    _entries.clear();
    try {
      final dir = await _cacheDir;
      final file = File(
        '${dir.path}${Platform.pathSeparator}colors.json',
      );
      if (await file.exists()) await file.delete();
      final tmpFile = File(
        '${dir.path}${Platform.pathSeparator}colors.json.tmp',
      );
      if (await tmpFile.exists()) await tmpFile.delete();
    } catch (e) {
      dev.log('ColorCache: clear failed: $e');
    }
  }

  void dispose() {
    _disposed = true;
    _persistTimer?.cancel();
    _persistTimer = null;
    _persistDirty = false;
    _entries.clear();
  }

  void _schedulePersist() {
    if (_disposed) return;
    _persistDirty = true;
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDebounce, () {
      _persistTimer = null;
      unawaited(_flushPersist());
    });
  }

  Future<void> _flushPersist() {
    final active = _activePersist;
    if (active != null) {
      return active;
    }
    final future = _runPersistLoop().whenComplete(() {
      _activePersist = null;
    });
    _activePersist = future;
    return future;
  }

  Future<void> _runPersistLoop() async {
    while (_persistDirty && !_disposed) {
      _persistDirty = false;
      await _persist();
    }
  }

  Future<void> _persist() async {
    try {
      final dir = await _cacheDir;
      final file = File(
        '${dir.path}${Platform.pathSeparator}colors.json',
      );
      final tmpFile = File(
        '${dir.path}${Platform.pathSeparator}colors.json.tmp',
      );

      final map = <String, dynamic>{'_v': _formatVersion};
      for (final e in _entries.entries) {
        map[e.key] = {
          'c': e.value.argbColors,
          't': e.value.cachedAt,
        };
      }
      await tmpFile.writeAsString(jsonEncode(map));
      if (await tmpFile.exists()) {
        await tmpFile.rename(file.path);
      }
    } catch (e) {
      dev.log('ColorCache: persist failed: $e');
    }
  }

  void _checkGeneration() {
    if (_loadedGeneration != _cacheManager.generation) {
      _persistTimer?.cancel();
      _persistTimer = null;
      _persistDirty = false;
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
