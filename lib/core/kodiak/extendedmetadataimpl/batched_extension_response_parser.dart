import 'dart:developer' as dev;
import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Parses BatchedExtensionResponse protobuf payloads using ExtendedMetadataPluginRegistry.
/// Direct 1:1 equivalent to Spotify Android's `p.rya1.l`.
class BatchedExtensionResponseParser {
  /// Parses bytes and returns nested Map of `EntityUri -> (TraitType -> Trait)`.
  /// Matches Spotify's `xgc0` structure.
  static Map<String, Map<Type, Trait>> parse(
    Uint8List data,
    ExtendedMetadataPluginRegistry registry,
  ) {
    final response = BatchedExtensionResponse.fromBuffer(data);
    return parseProtobuf(response, registry);
  }

  /// Parses a parsed BatchedExtensionResponse protobuf object.
  static Map<String, Map<Type, Trait>> parseProtobuf(
    BatchedExtensionResponse response,
    ExtendedMetadataPluginRegistry registry,
  ) {
    final results = <String, Map<Type, Trait>>{};
    dev.log(
      '[MetadataParser] response has ${response.extendedMetadata.length} arrays',
      name: 'Metadata',
    );

    for (final array in response.extendedMetadata) {
      final kindValue = array.extensionKind.value;
      final plugin = registry.pluginForKind(kindValue);
      dev.log(
        '[MetadataParser] Array kind: $kindValue (${array.extensionKind}), plugin: ${plugin?.runtimeType}, items: ${array.extensionData.length}',
        name: 'Metadata',
      );
      if (plugin == null) {
        dev.log(
          '[MetadataParser] No plugin registered for kind: $kindValue',
          name: 'Metadata',
        );
        continue;
      }

      for (final extData in array.extensionData) {
        final uri = extData.entityUri;
        if (uri.isEmpty || !extData.hasExtensionData()) {
          dev.log(
            '[MetadataParser] $uri hasExtensionData=false',
            name: 'Metadata',
          );
          continue;
        }

        final statusCode =
            (extData.hasHeader() && extData.header.hasStatusCode())
                ? extData.header.statusCode
                : 200;
        // Spotify checks statusCode == 200 (rya1.java:1030)
        if (statusCode != 200) {
          dev.log(
            '[MetadataParser] $uri statusCode=$statusCode (not 200)',
            name: 'Metadata',
          );
          continue;
        }

        final payload = extData.extensionData.value;
        if (payload.isEmpty) {
          dev.log(
            '[MetadataParser] $uri payload is empty',
            name: 'Metadata',
          );
          continue;
        }

        try {
          final trait = plugin.parse(Uint8List.fromList(payload));
          results.putIfAbsent(uri, () => {})[plugin.traitType] = trait;
        } catch (e, st) {
          dev.log(
            '[MetadataParser] Error parsing ${plugin.traitType} for $uri: $e\n$st',
            name: 'Metadata',
          );
        }
      }
    }

    return results;
  }
}
