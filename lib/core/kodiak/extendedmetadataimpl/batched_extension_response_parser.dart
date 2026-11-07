import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Parses `BatchedExtensionResponse` protobuf payloads using `ExtendedMetadataPluginRegistry`.
/// Direct 1:1 equivalent to Spotify Android's `p.rya1.l`.
class BatchedExtensionResponseParser {
  /// Parses bytes and returns nested Map of `EntityUri -> (TraitType -> Trait)`.
  static Map<String, Map<Type, Trait>> parse(
    Uint8List data,
    ExtendedMetadataPluginRegistry registry,
  ) {
    final response = BatchedExtensionResponse.fromBuffer(data);
    return parseProtobuf(response, registry);
  }

  /// Parses bytes and returns parsed traits, raw protobuf extension bytes per `(kind, uri)`,
  /// and resolved extension kinds per URI.
  static ({
    Map<String, Map<Type, Trait>> parsed,
    Map<(int, String), Uint8List> rawPayloads,
    Map<String, Set<int>> resolvedKinds,
  })
  parseWithRaw(Uint8List data, ExtendedMetadataPluginRegistry registry) {
    final response = BatchedExtensionResponse.fromBuffer(data);
    return parseProtobufWithRaw(response, registry);
  }

  /// Parses a [BatchedExtensionResponse] protobuf object.
  static Map<String, Map<Type, Trait>> parseProtobuf(
    BatchedExtensionResponse response,
    ExtendedMetadataPluginRegistry registry,
  ) {
    return parseProtobufWithRaw(response, registry).parsed;
  }

  /// Parses a [BatchedExtensionResponse] protobuf object while preserving raw
  /// binary trait payloads for binary disk caching.
  static ({
    Map<String, Map<Type, Trait>> parsed,
    Map<(int, String), Uint8List> rawPayloads,
    Map<String, Set<int>> resolvedKinds,
  })
  parseProtobufWithRaw(
    BatchedExtensionResponse response,
    ExtendedMetadataPluginRegistry registry,
  ) {
    final results = <String, Map<Type, Trait>>{};
    final rawPayloads = <(int, String), Uint8List>{};
    final resolvedKinds = <String, Set<int>>{};

    for (final array in response.extendedMetadata) {
      final kindValue = array.extensionKind.value;
      final plugin = registry.pluginForKind(kindValue);
      if (plugin == null) continue;

      for (final extData in array.extensionData) {
        final uri = extData.entityUri;
        if (uri.isEmpty) continue;

        final statusCode =
            (extData.hasHeader() && extData.header.hasStatusCode())
            ? extData.header.statusCode
            : 200;

        resolvedKinds.putIfAbsent(uri, () => <int>{}).add(kindValue);

        if (statusCode != 200 || !extData.hasExtensionData()) continue;

        final payload = extData.extensionData.value;
        if (payload.isEmpty) continue;

        final rawBytes = Uint8List.fromList(payload);
        try {
          final trait = plugin.parse(rawBytes);
          results.putIfAbsent(uri, () => <Type, Trait>{})[plugin.traitType] =
              trait;
          rawPayloads[(kindValue, uri)] = rawBytes;
        } catch (e, st) {
          dev.log(
            '[MetadataParser] Error parsing ${plugin.traitType} for $uri: $e\n$st',
            name: 'Metadata',
          );
        }
      }
    }

    return (
      parsed: results,
      rawPayloads: rawPayloads,
      resolvedKinds: resolvedKinds,
    );
  }
}
