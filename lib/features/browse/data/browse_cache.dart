import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/cache/cache_policy.dart';
import 'package:musify_mu/core/protocol/generated/spotify/entity_extension_data.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/browse/data/browse_metadata_fetcher.dart';

/// Binary Protobuf per-URI cache for browse card traits (`IdentityTrait` + `VisualIdentityTrait`).
///
/// Format (`browse_traits.bin`):
/// `[8-byte big-endian int64 cachedAtMs][BatchedExtensionResponse protobuf bytes]`
class BrowseTraitCache {
  static const _fileName = 'browse_traits.bin';
  static const _legacyJsonFileName = 'browse_traits.json';
  static const _policy = CachePolicy.durable;

  final AppCacheManager _cacheManager;
  Map<String, BrowseCardData>? _memoryCards;
  Map<(int, String), EntityExtensionData>? _rawEntries;
  int _cachedAtMs = 0;
  int _loadedGeneration = -1;

  BrowseTraitCache({required AppCacheManager cacheManager})
    : _cacheManager = cacheManager;

  Future<File> _getCacheFile() async {
    final dir = await _cacheManager.featureDir('browse');
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  Future<void> _deleteLegacyJsonIfPresent() async {
    try {
      final dir = await _cacheManager.featureDir('browse');
      final legacy = File(
        '${dir.path}${Platform.pathSeparator}$_legacyJsonFileName',
      );
      if (await legacy.exists()) {
        await legacy.delete();
      }
    } catch (e) {
      dev.log(
        'BrowseTraitCache: failed to remove legacy json: $e',
        name: 'Browse',
      );
    }
  }

  Future<Map<String, BrowseCardData>> _ensureLoaded() async {
    if (_memoryCards case final existing?
        when _loadedGeneration == _cacheManager.generation) {
      return existing;
    }

    final cards = <String, BrowseCardData>{};
    final rawEntries = <(int, String), EntityExtensionData>{};
    _memoryCards = cards;
    _rawEntries = rawEntries;
    _cachedAtMs = 0;
    _loadedGeneration = _cacheManager.generation;

    await _deleteLegacyJsonIfPresent();

    try {
      final file = await _getCacheFile();
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.length > 8) {
          final header = ByteData.sublistView(bytes, 0, 8);
          final cachedAt = header.getInt64(0, Endian.big);
          if (!_policy.isExpired(cachedAt)) {
            final protoBytes = Uint8List.sublistView(bytes, 8);
            final response = BatchedExtensionResponse.fromBuffer(protoBytes);
            for (final array in response.extendedMetadata) {
              final kindVal = array.extensionKind.value;
              for (final extData in array.extensionData) {
                if (extData.entityUri.isNotEmpty) {
                  rawEntries[(kindVal, extData.entityUri)] = extData;
                }
              }
            }
            cards.addAll(BrowseMetadataFetcher.parseResponse(protoBytes));
            _cachedAtMs = cachedAt;
          }
        }
      }
    } catch (e) {
      dev.log('BrowseTraitCache: load error: $e', name: 'Browse');
    }

    return cards;
  }

  Future<({Map<String, BrowseCardData> cached, List<String> missing})>
  partition(List<String> uris) async {
    final cache = await _ensureLoaded();

    final cached = <String, BrowseCardData>{};
    final missing = <String>[];

    for (final uri in uris) {
      if (cache[uri] case final data?) {
        cached[uri] = data;
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

  /// Merges freshly fetched binary `BatchedExtensionResponse` payload into the cache.
  Future<void> putRawResponse(
    Uint8List rawResponseBytes,
    Map<String, BrowseCardData> freshCards,
  ) async {
    if (rawResponseBytes.isEmpty || freshCards.isEmpty) return;

    final cards = await _ensureLoaded();
    final rawEntries = _rawEntries;
    if (rawEntries == null) return;

    final response = BatchedExtensionResponse.fromBuffer(rawResponseBytes);
    for (final array in response.extendedMetadata) {
      final kindVal = array.extensionKind.value;
      for (final extData in array.extensionData) {
        if (extData.entityUri.isNotEmpty) {
          rawEntries[(kindVal, extData.entityUri)] = extData;
        }
      }
    }

    cards.addAll(freshCards);
    _cachedAtMs = DateTime.now().millisecondsSinceEpoch;
    await _persist(rawEntries, _cachedAtMs);

    dev.log(
      'BrowseTraitCache: stored ${freshCards.length} new traits '
      '(total: ${cards.length})',
      name: 'Browse',
    );
  }

  Future<void> _persist(
    Map<(int, String), EntityExtensionData> rawEntries,
    int cachedAtMs,
  ) async {
    if (rawEntries.isEmpty) return;
    try {
      final byKind = <int, List<EntityExtensionData>>{};
      for (final entry in rawEntries.entries) {
        final (kindVal, _) = entry.key;
        byKind.putIfAbsent(kindVal, () => <EntityExtensionData>[]).add(
          entry.value,
        );
      }

      final merged = BatchedExtensionResponse();
      for (final entry in byKind.entries) {
        final kindEnum = ExtensionKind.valueOf(entry.key);
        if (kindEnum == null) continue;
        final array = EntityExtensionDataArray()
          ..extensionKind = kindEnum
          ..extensionData.addAll(entry.value);
        merged.extendedMetadata.add(array);
      }

      final protoBytes = merged.writeToBuffer();
      final out = Uint8List(8 + protoBytes.length);
      ByteData.sublistView(out, 0, 8).setInt64(0, cachedAtMs, Endian.big);
      out.setRange(8, out.length, protoBytes);

      final file = await _getCacheFile();
      final tmpFile = File('${file.path}.tmp');
      await tmpFile.writeAsBytes(out, flush: true);
      await tmpFile.rename(file.path);
    } catch (e) {
      dev.log('BrowseTraitCache: persist error: $e', name: 'Browse');
    }
  }
}
