import 'dart:developer' as dev;
import 'dart:math';
import 'dart:typed_data';

import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/batched_extension_response_parser.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/kodiak_cell_mapper.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/result/network_result.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Low-level network client for Spotify Extended Metadata endpoint.
/// Direct 1:1 equivalent to Spotify Android's `p.l1w` (`ExtendedMetadataClientImpl`).
class ExtendedMetadataClient {
  final SpotifyTransport _transport;
  final RuntimeContext _ctx;
  final ExtendedMetadataPluginRegistry _registry;

  ExtendedMetadataClient({
    required SpotifyTransport transport,
    required RuntimeContext ctx,
    required ExtendedMetadataPluginRegistry registry,
  }) : _transport = transport,
       _ctx = ctx,
       _registry = registry;

  ExtendedMetadataPluginRegistry get registry => _registry;

  /// Fetches traits and raw binary extension payloads for the given set of cell keys.
  Future<
    NetworkResult<
      ({Map<CellKey, Trait> cells, Map<(int, String), Uint8List> rawPayloads})
    >
  >
  fetchCellsRawResult(Set<CellKey> keys) async {
    if (keys.isEmpty) {
      return const NetworkSuccess((
        cells: <CellKey, Trait>{},
        rawPayloads: <(int, String), Uint8List>{},
      ));
    }

    final entityQueries = <String, Set<int>>{};
    for (final key in keys) {
      final plugin = _registry.pluginForType(key.table.traitType);
      if (plugin == null) continue;
      entityQueries
          .putIfAbsent(key.entityUri, () => <int>{})
          .add(plugin.extensionKindValue);
    }

    if (entityQueries.isEmpty) {
      dev.log(
        '[Metadata] entityQueries is empty for ${keys.length} keys',
        name: 'Metadata',
      );
      return const NetworkSuccess((
        cells: <CellKey, Trait>{},
        rawPayloads: <(int, String), Uint8List>{},
      ));
    }

    final payload = _buildRequest(entityQueries);
    final result = await _transport.postResult(
      '/extended-metadata/v0/extended-metadata',
      Uint8List.fromList(payload),
      priority: NetworkPriority.background,
      ttl: const Duration(seconds: 45),
    );

    switch (result) {
      case NetworkFailure<Uint8List>(
        :final error,
        :final statusCode,
      ):
        dev.log('[Metadata] POST failed: $error', name: 'Metadata');
        return NetworkFailure(error, statusCode: statusCode);

      case NetworkSuccess<Uint8List>(
        data: final bytes,
        statusCode: final status,
      ):
        if (bytes.isEmpty) {
          return NetworkSuccess((
            cells: const <CellKey, Trait>{},
            rawPayloads: const <(int, String), Uint8List>{},
          ), statusCode: status);
        }

        try {
          final (:parsed, :rawPayloads, resolvedKinds: _) =
              BatchedExtensionResponseParser.parseWithRaw(bytes, _registry);
          final mapped = KodiakCellMapper.map(parsed);
          return NetworkSuccess((
            cells: mapped,
            rawPayloads: rawPayloads,
          ), statusCode: status);
        } catch (e, st) {
          dev.log('[Metadata] PARSE ERROR: $e\n$st', name: 'Metadata');
          return NetworkFailure(
            NetworkException(
              message: 'Failed to parse extended metadata protobuf: $e',
              reason: NetworkFailureReason.parseError,
              cause: e,
            ),
            statusCode: status,
          );
        }
    }
  }

  /// Fetches traits for the given set of cell keys, returning typed [NetworkResult].
  Future<NetworkResult<Map<CellKey, Trait>>> fetchCellsResult(
    Set<CellKey> keys,
  ) async {
    final result = await fetchCellsRawResult(keys);
    return switch (result) {
      NetworkSuccess(:final data, :final statusCode) => NetworkSuccess(
        data.cells,
        statusCode: statusCode,
      ),
      NetworkFailure(:final error, :final statusCode) => NetworkFailure(
        error,
        statusCode: statusCode,
      ),
    };
  }

  /// Fetches traits for the given set of cell keys in a single batched HTTP request.
  Future<Map<CellKey, Trait>> fetchCells(Set<CellKey> keys) async {
    final result = await fetchCellsResult(keys);
    if (result case NetworkSuccess(:final data)) {
      return data;
    }
    return const {};
  }

  List<int> _buildRequest(Map<String, Set<int>> entityQueries) {
    final random = Random();
    final taskId = List<int>.generate(16, (_) => random.nextInt(256));

    final request = BatchedEntityRequest()
      ..header = (BatchedEntityRequestHeader()
        ..country = _ctx.country
        ..catalogue = _ctx.catalogue
        ..taskId = taskId);

    for (final entry in entityQueries.entries) {
      final entityReq = EntityRequest()..entityUri = entry.key;
      for (final kindVal in entry.value) {
        final mappedKind = ExtensionKind.valueOf(kindVal);
        final extKind = mappedKind != null
            ? mappedKind
            : ExtensionKind.UNKNOWN_EXTENSION;
        entityReq.query.add(ExtensionQuery()..extensionKind = extKind);
      }
      request.entityRequest.add(entityReq);
    }

    return request.writeToBuffer();
  }
}
