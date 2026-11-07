import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/cache/cache_policy.dart';
import 'package:musify_mu/core/kodiak/dataloader/kodiak_disk_cache_data.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/batched_extension_response_parser.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry.dart';
import 'package:musify_mu/core/protocol/generated/spotify/entity_extension_data.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';
import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart'
    as pb_any;

export 'kodiak_disk_cache_data.dart';

/// Binary Protobuf disk cache for Kodiak DataPool.
///
/// Format (`kodiak_extensions.bin`):
/// `[8-byte big-endian int64 cachedAtMs][BatchedExtensionResponse protobuf bytes]`
class KodiakDiskCache {
  static const _fileName = 'kodiak_extensions.bin';
  static const _legacyJsonFileName = 'kodiak_traits.json';
  static const _policy = CachePolicy.standard;

  final AppCacheManager _cacheManager;
  Timer? _saveDebounceTimer;

  KodiakDiskCache({required AppCacheManager cacheManager})
    : _cacheManager = cacheManager;

  Future<File?> _getCacheFile() async {
    if (!_cacheManager.hasUser) return null;
    try {
      final dir = await _cacheManager.featureDir('kodiak');
      return File('${dir.path}${Platform.pathSeparator}$_fileName');
    } catch (e) {
      dev.log('KodiakDiskCache: failed to resolve cache dir: $e');
      return null;
    }
  }

  Future<void> _deleteLegacyJsonIfPresent() async {
    if (!_cacheManager.hasUser) return;
    try {
      final dir = await _cacheManager.featureDir('kodiak');
      final legacy = File(
        '${dir.path}${Platform.pathSeparator}$_legacyJsonFileName',
      );
      if (await legacy.exists()) {
        await legacy.delete();
      }
    } catch (e) {
      dev.log('KodiakDiskCache: failed to delete legacy json: $e');
    }
  }

  /// Loads cached traits, raw payloads, and resolved query statuses from disk.
  Future<KodiakDiskCacheData?> load(
    ExtendedMetadataPluginRegistry registry,
  ) async {
    await _deleteLegacyJsonIfPresent();
    try {
      final file = await _getCacheFile();
      if (file == null || !await file.exists()) return null;

      final bytes = await file.readAsBytes();
      if (bytes.length <= 8) return null;

      final cachedAt = ByteData.sublistView(bytes, 0, 8).getInt64(
        0,
        Endian.big,
      );
      if (_policy.isExpired(cachedAt)) {
        await file.delete();
        return null;
      }

      final protoBytes = Uint8List.sublistView(bytes, 8);
      final decoded = BatchedExtensionResponseParser.parseWithRaw(
        protoBytes,
        registry,
      );

      final traitsByTypeName = <String, Map<String, Trait>>{};
      for (final entry in decoded.parsed.entries) {
        final uriTraits = <String, Trait>{};
        for (final traitEntry in entry.value.entries) {
          uriTraits[traitEntry.key.toString()] = traitEntry.value;
        }
        if (uriTraits.isNotEmpty) {
          traitsByTypeName[entry.key] = uriTraits;
        }
      }

      return KodiakDiskCacheData(
        traits: traitsByTypeName,
        rawPayloads: decoded.rawPayloads,
        resolvedKinds: decoded.resolvedKinds,
      );
    } catch (e) {
      dev.log('KodiakDiskCache: load failed: $e');
      return null;
    }
  }

  /// Immediately saves raw binary extension payloads and resolved kinds to disk.
  Future<void> save({
    required Map<(int, String), Uint8List> rawPayloads,
    required Map<String, Set<int>> resolvedKinds,
  }) async {
    if (rawPayloads.isEmpty && resolvedKinds.isEmpty) return;
    try {
      final file = await _getCacheFile();
      if (file == null) return;

      final byKind = <int, List<EntityExtensionData>>{};

      for (final entry in rawPayloads.entries) {
        final (kindVal, uri) = entry.key;
        if (uri.isEmpty || entry.value.isEmpty) continue;
        byKind.putIfAbsent(kindVal, () => <EntityExtensionData>[]).add(
          EntityExtensionData(
            header: EntityExtensionDataHeader(statusCode: 200),
            entityUri: uri,
            extensionData: pb_any.Any(value: entry.value),
          ),
        );
      }

      for (final entry in resolvedKinds.entries) {
        final uri = entry.key;
        if (uri.isEmpty) continue;
        for (final kindVal in entry.value) {
          if (rawPayloads.containsKey((kindVal, uri))) continue;
          byKind.putIfAbsent(kindVal, () => <EntityExtensionData>[]).add(
            EntityExtensionData(
              header: EntityExtensionDataHeader(statusCode: 404),
              entityUri: uri,
            ),
          );
        }
      }

      if (byKind.isEmpty) return;

      final response = BatchedExtensionResponse();
      for (final entry in byKind.entries) {
        final kindEnum = ExtensionKind.valueOf(entry.key);
        if (kindEnum == null) continue;
        response.extendedMetadata.add(
          EntityExtensionDataArray(
            extensionKind: kindEnum,
            extensionData: entry.value,
          ),
        );
      }

      final protoBytes = response.writeToBuffer();
      final out = Uint8List(8 + protoBytes.length);
      ByteData.sublistView(
        out,
        0,
        8,
      ).setInt64(0, DateTime.now().millisecondsSinceEpoch, Endian.big);
      out.setRange(8, out.length, protoBytes);

      final tmpFile = File('${file.path}.tmp');
      await tmpFile.writeAsBytes(out, flush: true);
      await tmpFile.rename(file.path);
    } catch (e) {
      dev.log('KodiakDiskCache: write failed: $e');
    }
  }

  /// Debounces saving to avoid blocking I/O on rapid viewport scrolls.
  void scheduleSave({
    required Map<(int, String), Uint8List> rawPayloads,
    required Map<String, Set<int>> resolvedKinds,
  }) {
    _saveDebounceTimer?.cancel();
    final rawSnapshot = Map<(int, String), Uint8List>.of(rawPayloads);
    final resolvedSnapshot = <String, Set<int>>{
      for (final e in resolvedKinds.entries) e.key: Set<int>.of(e.value),
    };
    _saveDebounceTimer = Timer(const Duration(seconds: 2), () {
      save(rawPayloads: rawSnapshot, resolvedKinds: resolvedSnapshot);
    });
  }

  void dispose() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = null;
  }
}
