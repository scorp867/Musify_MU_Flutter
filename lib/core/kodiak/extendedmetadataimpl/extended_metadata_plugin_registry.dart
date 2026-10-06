import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';

/// Registry maintaining all active ExtendedMetadataPlugin decoders.
/// Direct 1:1 equivalent to Spotify Android's `p.c2w` (`ExtendedMetadataPluginRegistry`).
class ExtendedMetadataPluginRegistry {
  final Map<Type, ExtendedMetadataPlugin> _pluginsByType = {};
  final Map<int, ExtendedMetadataPlugin> _pluginsByKind = {};

  ExtendedMetadataPluginRegistry(Iterable<ExtendedMetadataPlugin> plugins) {
    for (final plugin in plugins) {
      final type = plugin.traitType;
      if (_pluginsByType.containsKey(type)) {
        throw ArgumentError(
          'ExtendedMetadataPlugin duplicate type: $type already registered by '
          '${_pluginsByType[type]?.runtimeType}',
        );
      }
      _pluginsByType[type] = plugin;

      final kind = plugin.extensionKindValue;
      if (_pluginsByKind.containsKey(kind)) {
        throw ArgumentError(
          'ExtendedMetadataPlugin duplicate extension kind: $kind already registered by '
          '${_pluginsByKind[kind]?.runtimeType}',
        );
      }
      _pluginsByKind[kind] = plugin;
    }
  }

  /// Finds plugin registered for a Trait Type.
  ExtendedMetadataPlugin? pluginForType(Type type) => _pluginsByType[type];

  /// Finds plugin registered for an integer ExtensionKind ID.
  ExtendedMetadataPlugin? pluginForKind(int kind) => _pluginsByKind[kind];

  /// All registered plugins.
  Iterable<ExtendedMetadataPlugin> get plugins => _pluginsByType.values;

  /// Human-readable list of registered plugins matching Spotify's `c2w.b()`.
  String dump() => _pluginsByType.values
      .map((p) => '${p.runtimeType} for Extension Kind: ${p.extensionKindValue}')
      .join('\n\t');
}
