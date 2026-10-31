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
  })  : _transport = transport,
        _ctx = ctx,
        _registry = registry;

  ExtendedMetadataPluginRegistry get registry => _registry;

  /// Decodes protobuf payloads deterministically preserving Type equivalence in release AOT mode.
  Future<Map<String, Map<Type, Trait>>> _parsePayload(Uint8List bytes) async {
    return BatchedExtensionResponseParser.parse(bytes, _registry);
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

    // Automatically query ExtensionKind 212 (PLAYBACK_TRAIT) for track/episode/audio entities,
    // or whenever TRACK_V4 (10) or EPISODE_V4 (12) is requested, to retrieve all available audio file IDs.
    for (final entry in entityQueries.entries) {
      final uri = entry.key;
      final kinds = entry.value;
      if (uri.startsWith('spotify:track:') ||
          uri.startsWith('spotify:episode:') ||
          uri.startsWith('spotify:audio:') ||
          kinds.contains(10) ||
          kinds.contains(12)) {
        kinds.add(212);
      }
    }

    final payload = _buildRequest(entityQueries);
    final result = await _transport.postResult(
      '/extended-metadata/v0/extended-metadata',
      Uint8List.fromList(payload),
      priority: NetworkPriority.background,
      ttl: const Duration(seconds: 45),
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
      return NetworkSuccess<Map<CellKey, Trait>>({}, statusCode: status);
    }

    try {
      final parsedMap = await _parsePayload(bytes);
      final mapped = KodiakCellMapper.map(parsedMap);
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
