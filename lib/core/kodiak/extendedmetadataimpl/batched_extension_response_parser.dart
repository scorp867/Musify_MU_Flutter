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

    for (final array in response.extendedMetadata) {
      final kindValue = array.extensionKind.value;
      final plugin = registry.pluginForKind(kindValue);
      if (plugin == null) continue;

      for (final extData in array.extensionData) {
        final uri = extData.entityUri;
        if (uri.isEmpty || !extData.hasExtensionData()) continue;

        final statusCode =
            (extData.hasHeader() && extData.header.hasStatusCode())
                ? extData.header.statusCode
                : 200;
        // Spotify checks statusCode == 200 (rya1.java:1030)
        if (statusCode != 200) continue;

        final payload = extData.extensionData.value;
        if (payload.isEmpty) continue;

        try {
          final trait = plugin.parse(Uint8List.fromList(payload));
          results.putIfAbsent(uri, () => {})[plugin.traitType] = trait;
        } catch (_) {
          // Ignore individual trait parsing error (non-fatal)
        }
      }
    }

    return results;
  }
}
