import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/batched_extension_response_parser.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/kodiak_cell_mapper.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
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
  })  : _transport = transport,
        _ctx = ctx,
        _registry = registry;

  ExtendedMetadataPluginRegistry get registry => _registry;

  /// Fetches traits for the given set of cell keys in a single batched HTTP request.
  Future<Map<CellKey, Trait>> fetchCells(Set<CellKey> keys) async {
    if (keys.isEmpty) return const {};

    // Group keys by entityUri -> List<ExtensionKind>
    final entityQueries = <String, Set<int>>{};
    for (final key in keys) {
      final plugin = _registry.pluginForType(key.table.traitType);
      if (plugin == null) continue;
      entityQueries
          .putIfAbsent(key.entityUri, () => {})
          .add(plugin.extensionKindValue);
    }

    if (entityQueries.isEmpty) return const {};

    final payload = _buildRequest(entityQueries);
    final responseBytes = await _transport.post(
      '/extended-metadata/v0/extended-metadata',
      Uint8List.fromList(payload),
    );

    if (responseBytes == null || responseBytes.isEmpty) return const {};

    // Parse in background isolate to prevent UI frame drops
    final parsedMap = await Isolate.run(
      () => BatchedExtensionResponseParser.parse(responseBytes, _registry),
    );

    return KodiakCellMapper.map(parsedMap);
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
