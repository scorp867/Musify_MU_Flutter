import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/cache/cache_policy.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Cached payload from disk containing known traits and resolved kinds.
class KodiakDiskCacheData {
  final Map<String, Map<String, Trait>> traits;
  final Map<String, Set<int>> resolvedKinds;

  const KodiakDiskCacheData({
    required this.traits,
    required this.resolvedKinds,
  });
}

/// Disk cache for Kodiak DataPool.
///
/// Persists known traits and resolved ExtensionKind queries so that subsequent
/// app launches have instant metadata available without triggering network fetches.
class KodiakDiskCache {
  static const _policy = CachePolicy.standard;

  final AppCacheManager _cacheManager;
  Timer? _saveDebounceTimer;

  KodiakDiskCache({required AppCacheManager cacheManager})
      : _cacheManager = cacheManager;

  Future<File?> _getCacheFile() async {
    if (!_cacheManager.hasUser) return null;
    try {
      final dir = await _cacheManager.featureDir('kodiak');
      return File('${dir.path}${Platform.pathSeparator}kodiak_traits.json');
    } catch (_) {
      return null;
    }
  }

  /// Loads cached traits and resolved query statuses from disk.
  Future<KodiakDiskCacheData?> load() async {
    try {
      final file = await _getCacheFile();
      if (file == null || !await file.exists()) return null;

      final content = await file.readAsString();
      if (content.isEmpty) return null;

      final json = jsonDecode(content) as Map<String, dynamic>;
      final cachedAt = json['cachedAt'] as int? ?? 0;
      if (_policy.isExpired(cachedAt)) return null;

      final rawTraits = json['traits'] as Map<String, dynamic>? ?? {};
      final deserializedTraits = <String, Map<String, Trait>>{};

      for (final entityEntry in rawTraits.entries) {
        final uri = entityEntry.key;
        final traitMap = entityEntry.value as Map<String, dynamic>? ?? {};
        final parsedMap = <String, Trait>{};

        for (final t in traitMap.entries) {
          final trait = Trait.fromJson(t.key, t.value as Map<String, dynamic>);
          if (trait != null) {
            parsedMap[t.key] = trait;
          }
        }

        if (parsedMap.isNotEmpty) {
          deserializedTraits[uri] = parsedMap;
        }
      }

      final rawResolved = json['resolvedKinds'] as Map<String, dynamic>? ?? {};
      final deserializedResolved = <String, Set<int>>{};

      for (final entry in rawResolved.entries) {
        final list = (entry.value as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toSet() ??
            {};
        if (list.isNotEmpty) {
          deserializedResolved[entry.key] = list;
        }
      }

      return KodiakDiskCacheData(
        traits: deserializedTraits,
        resolvedKinds: deserializedResolved,
      );
    } catch (e) {
      dev.log('KodiakDiskCache: load failed: $e');
      return null;
    }
  }

  /// Immediately saves the given traits and resolved kinds to disk.
  Future<void> save({
    required Map<String, Map<String, Trait>> traits,
    required Map<String, Set<int>> resolvedKinds,
  }) async {
    try {
      final file = await _getCacheFile();
      if (file == null) return;

      final serializedTraits = <String, Map<String, dynamic>>{};
      for (final entry in traits.entries) {
        final entityTraits = <String, dynamic>{};
        for (final t in entry.value.entries) {
          entityTraits[t.key] = t.value.toJson();
        }
        if (entityTraits.isNotEmpty) {
          serializedTraits[entry.key] = entityTraits;
        }
      }

      final serializedResolved = <String, List<int>>{};
      for (final entry in resolvedKinds.entries) {
        if (entry.value.isNotEmpty) {
          serializedResolved[entry.key] = entry.value.toList();
        }
      }

      final json = {
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'traits': serializedTraits,
        'resolvedKinds': serializedResolved,
      };

      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      dev.log('KodiakDiskCache: write failed: $e');
    }
  }

  /// Debounces saving to avoid blocking I/O on rapid viewport scrolls.
  void scheduleSave({
    required Map<String, Map<String, Trait>> traits,
    required Map<String, Set<int>> resolvedKinds,
  }) {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(seconds: 2), () {
      save(traits: traits, resolvedKinds: resolvedKinds);
    });
  }

  void dispose() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = null;
  }
}
