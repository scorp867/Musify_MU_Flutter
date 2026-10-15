---
title: "extended_metadata_plugin_registry.dart"
path: "lib/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, kodiak]
lines: 44
incoming_dependencies: 7
outgoing_dependencies: 1
---

# extended_metadata_plugin_registry.dart

> Source File: `[lib/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry.dart](file:///c:/Users/Admin/Musify_MU/lib/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry.dart)`
> Layer: `lib/core/kodiak/extendedmetadataimpl`

## Executive Summary
`extended_metadata_plugin_registry.dart` is an essential file in `lib/core/kodiak/extendedmetadataimpl` providing definitions for `ExtendedMetadataPluginRegistry`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `extended_metadata_plugin.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/extended_metadata_plugin|extended_metadata_plugin.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `casita_parser.dart` | `lib/features/home_feed/data` | [[04-Reference/lib/features/home_feed/data/casita_parser|casita_parser.dart]] |
| `extended_metadata_service.dart` | `lib/core/media` | [[04-Reference/lib/core/media/extended_metadata_service|extended_metadata_service.dart]] |
| `data_pool_impl.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool_impl|data_pool_impl.dart]] |
| `batched_extension_response_parser.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/batched_extension_response_parser|batched_extension_response_parser.dart]] |
| `extended_metadata_client.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/extended_metadata_client|extended_metadata_client.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `kodiak_data_layer_test.dart` | `test/features/home_feed` | [[04-Reference/test/features/home_feed/kodiak_data_layer_test|kodiak_data_layer_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class ExtendedMetadataPluginRegistry`
- **Archetype**: Kodiak Trait Plugin / Reactive Element

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `type` | `final` |
| `kind` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `pluginForType` | `ExtendedMetadataPlugin?` | `Type type` |
| `pluginForKind` | `ExtendedMetadataPlugin?` | `int kind` |
| `dump` | `String` | `(none)` |
| `map` | `dynamic` | `(p` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
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
```
