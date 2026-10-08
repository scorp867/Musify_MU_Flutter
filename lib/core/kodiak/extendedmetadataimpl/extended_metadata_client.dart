import 'dart:developer' as dev;
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/batched_extension_response_parser.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/kodiak_cell_mapper.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/plugins/builtin_plugins.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/network/result/network_result.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Low-level network client for Spotify Extended Metadata endpoint.
/// Direct 1:1 equivalent to Spotify Android's `p.l1w` (`ExtendedMetadataClientImpl`).
class ExtendedMetadataClient {
  /// Payloads larger than 32 KB are offloaded to a background isolate to prevent UI frame drops.
  /// Smaller payloads (< 32 KB) decode synchronously in < 0.3 ms to avoid isolate thread scheduling overhead.
  static const int _isolateOffloadThresholdBytes = 32 * 1024;

  final SpotifyTransport _transport;
  final RuntimeContext _ctx;
  final ExtendedMetadataPluginRegistry _registry;

  ExtendedMetadataClient({
    required SpotifyTransport transport,
    required RuntimeContext ctx,
    required ExtendedMetadataPluginRegistry registry,
  })  : _transport = transport,
        _ctx = ctx,
        _registry = registry;

  ExtendedMetadataPluginRegistry get registry => _registry;

  /// Pure static worker function for isolate execution.
  /// Does NOT capture any instance state or references to [ExtendedMetadataClient].
  static Map<String, Map<Type, Trait>> _parseInIsolateWorker(Uint8List bytes) {
    final registry = ExtendedMetadataPluginRegistry(
      createDefaultExtendedMetadataPlugins(),
    );
    return BatchedExtensionResponseParser.parse(bytes, registry);
  }

  /// Decodes protobuf payloads adaptively based on byte size.
  Future<Map<String, Map<Type, Trait>>> _parsePayload(Uint8List bytes) async {
    if (bytes.length < _isolateOffloadThresholdBytes) {
      return BatchedExtensionResponseParser.parse(bytes, _registry);
    }
    return await Isolate.run(() => _parseInIsolateWorker(bytes));
  }

  /// Fetches traits for the given set of cell keys, returning typed [NetworkResult].
  Future<NetworkResult<Map<CellKey, Trait>>> fetchCellsResult(
      Set<CellKey> keys) async {
    if (keys.isEmpty) return const NetworkSuccess({});

    // Group keys by entityUri -> List<ExtensionKind>
    final entityQueries = <String, Set<int>>{};
    for (final key in keys) {
      final plugin = _registry.pluginForType(key.table.traitType);
      if (plugin == null) continue;
      entityQueries
          .putIfAbsent(key.entityUri, () => {})
          .add(plugin.extensionKindValue);
    }

    if (entityQueries.isEmpty) {
      dev.log('[Metadata] entityQueries is empty for ${keys.length} keys', name: 'Metadata');
      return const NetworkSuccess({});
    }

    final payload = _buildRequest(entityQueries);
    dev.log(
      '[Metadata] POSTing ${entityQueries.length} entities (${payload.length}B) via ${_transport.runtimeType} to /extended-metadata/v0/extended-metadata',
      name: 'Metadata',
    );
    final result = await _transport.postResult(
      '/extended-metadata/v0/extended-metadata',
      Uint8List.fromList(payload),
    );

    if (result is NetworkFailure<Uint8List>) {
      dev.log('[Metadata] POST failed: ${result.error}', name: 'Metadata');
      return NetworkFailure<Map<CellKey, Trait>>(
        result.error,
        statusCode: result.statusCode,
      );
    }

    final bytes = (result as NetworkSuccess<Uint8List>).data;
    final status = result.statusCode;
    if (bytes.isEmpty) {
      dev.log('[Metadata] POST succeeded with empty bytes!', name: 'Metadata');
      return NetworkSuccess<Map<CellKey, Trait>>({}, statusCode: status);
    }

    try {
      dev.log(
        '[Metadata] Received ${bytes.length} bytes (header: ${bytes.take(4).map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")}), decoding...',
        name: 'Metadata',
      );
      final parsedMap = await _parsePayload(bytes);
      dev.log(
        '[Metadata] BatchedExtensionResponseParser returned ${parsedMap.length} entities: ${parsedMap.keys.toList()}',
        name: 'Metadata',
      );
      final mapped = KodiakCellMapper.map(parsedMap);
      dev.log('[Metadata] KodiakCellMapper mapped ${mapped.length} cells', name: 'Metadata');
      return NetworkSuccess(mapped, statusCode: status);
    } catch (e, st) {
      dev.log('[Metadata] PARSE ERROR: $e\n$st', name: 'Metadata');
      return NetworkFailure<Map<CellKey, Trait>>(
        NetworkException(
          message: 'Failed to parse extended metadata protobuf: $e',
          reason: NetworkFailureReason.parseError,
          cause: e,
        ),
        statusCode: status,
      );
    }
  }

  /// Fetches traits for the given set of cell keys in a single batched HTTP request.
  Future<Map<CellKey, Trait>> fetchCells(Set<CellKey> keys) async {
    final result = await fetchCellsResult(keys);
    return result.dataOrNull ?? const {};
  }

  List<int> _buildRequest(Map<String, Set<int>> entityQueries) {
    final taskId = List<int>.generate(16, (_) => Random().nextInt(256));

    final request = BatchedEntityRequest()
      ..header = (BatchedEntityRequestHeader()
        ..country = _ctx.country
        ..catalogue = _ctx.catalogue
        ..taskId = taskId);

    for (final entry in entityQueries.entries) {
      final entityReq = EntityRequest()..entityUri = entry.key;
      for (final kindVal in entry.value) {
        final extKind = ExtensionKind.valueOf(kindVal) ??
            ExtensionKind.UNKNOWN_EXTENSION;
        entityReq.query.add(ExtensionQuery()..extensionKind = extKind);
      }
      request.entityRequest.add(entityReq);
    }

    return request.writeToBuffer();
  }
}
