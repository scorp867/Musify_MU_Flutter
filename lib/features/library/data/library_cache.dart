import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/cache/cache_policy.dart';

/// High-performance two-layer cache for Library data.
///
/// Layer 1 (Structure): Raw protobuf bytes cached to disk.
///   - rootlist bytes, collection bytes per set name
///   - Zero serialization cost: read/write raw bytes directly
///
/// Layer 2 (Decoration): Per-URI metadata (name, imageUrl).
///   - In-memory Map for fast lookups, persisted to disk periodically
///   - 24h TTL per entry
class LibraryCache {
  static const _structurePolicy = CachePolicy.frequent;
  static const _decorationPolicy = CachePolicy.standard;

  final AppCacheManager _cacheManager;

  // In-memory decoration cache: uri -> {name, imageUrl, cachedAt}
  final Map<String, _DecorationEntry> _decorations = {};
  bool _decorationsLoaded = false;
  int _loadedGeneration = -1;

  LibraryCache({required AppCacheManager cacheManager})
      : _cacheManager = cacheManager;

  Future<Directory> get _cacheDir => _cacheManager.featureDir('library');

  // ─── Structure cache (raw protobuf bytes) ──────────────────────────

  /// Saves raw protobuf bytes for a structure endpoint.
  Future<void> putStructureBytes(String key, Uint8List bytes) async {
    try {
      final dir = await _cacheDir;
      final sep = Platform.pathSeparator;
      final file = File('${dir.path}${sep}struct_$key.bin');
      final meta = File('${dir.path}${sep}struct_$key.ts');
      await Future.wait([
        file.writeAsBytes(bytes, flush: true),
        meta.writeAsString(
          DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      ]);
    } catch (e) {
      dev.log('Put structure bytes failed: $e');
    }
  }

  /// Reads cached protobuf bytes. Returns null if expired or missing.
  Future<Uint8List?> getStructureBytes(String key) async {
    try {
      final dir = await _cacheDir;
      final sep = Platform.pathSeparator;
      final file = File('${dir.path}${sep}struct_$key.bin');
      final meta = File('${dir.path}${sep}struct_$key.ts');
      if (!await file.exists() || !await meta.exists()) return null;

      final ts = int.parse(await meta.readAsString());
      if (_structurePolicy.isExpired(ts)) return null;

      return await file.readAsBytes();
    } catch (e) {
      dev.log('Get structure bytes failed: $e');
      return null;
    }
  }

  // ─── Decoration cache (per-URI metadata) ───────────────────────────

  /// Returns cached decoration for a URI, or null if missing/expired.
  DecorationData? getDecoration(String uri) {
    _checkGeneration();
    final entry = _decorations[uri];
    if (entry == null) return null;

    if (_decorationPolicy.isExpired(entry.cachedAt)) {
      _decorations.remove(uri);
      return null;
    }
    return DecorationData(name: entry.name, imageUrl: entry.imageUrl);
  }

  /// Filters a list of URIs to only those not in the decoration cache.
  List<String> uncachedUris(List<String> uris) {
    return uris.where((uri) => getDecoration(uri) == null).toList();
  }

  /// Stores decoration data for multiple URIs and persists to disk.
  Future<void> putDecorations(Map<String, DecorationData> entries) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final e in entries.entries) {
      _decorations[e.key] = _DecorationEntry(
        name: e.value.name,
        imageUrl: e.value.imageUrl,
        cachedAt: now,
      );
    }
    await _persistDecorations();
  }

  /// Loads decoration cache from disk into memory.
  Future<void> loadDecorations() async {
    if (_decorationsLoaded &&
        _loadedGeneration == _cacheManager.generation) {
      return;
    }
    _decorationsLoaded = true;
    _loadedGeneration = _cacheManager.generation;
    _decorations.clear();

    try {
      final dir = await _cacheDir;
      final file = File(
        '${dir.path}${Platform.pathSeparator}decorations.json',
      );
      if (!await file.exists()) return;

      final raw = await file.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;

      for (final e in map.entries) {
        final v = e.value as Map<String, dynamic>;
        final cachedAt = v['t'] as int? ?? 0;
        if (_decorationPolicy.isExpired(cachedAt)) continue;

        _decorations[e.key] = _DecorationEntry(
          name: v['n'] as String? ?? '',
          imageUrl: v['i'] as String?,
          cachedAt: cachedAt,
        );
      }
    } catch (e) {
      dev.log('Load decorations failed: $e');
    }
  }

  Future<void> _persistDecorations() async {
    try {
      final dir = await _cacheDir;
      final file = File(
        '${dir.path}${Platform.pathSeparator}decorations.json',
      );

      final map = <String, dynamic>{};
      for (final e in _decorations.entries) {
        map[e.key] = {
          'n': e.value.name,
          if (e.value.imageUrl != null) 'i': e.value.imageUrl,
          't': e.value.cachedAt,
        };
      }
      await file.writeAsString(jsonEncode(map), flush: true);
    } catch (e) {
      dev.log('Persist decorations failed: $e');
    }
  }

  /// Flushes in-memory decorations if the user switched.
  void _checkGeneration() {
    if (_loadedGeneration != _cacheManager.generation) {
      _decorations.clear();
      _decorationsLoaded = false;
    }
  }
}

class _DecorationEntry {
  final String name;
  final String? imageUrl;
  final int cachedAt;

  const _DecorationEntry({
    required this.name,
    this.imageUrl,
    required this.cachedAt,
  });
}

/// Public decoration data for external consumers.
class DecorationData {
  final String name;
  final String? imageUrl;

  const DecorationData({required this.name, this.imageUrl});
}
