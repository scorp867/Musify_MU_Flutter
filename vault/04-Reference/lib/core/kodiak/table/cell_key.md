---
title: "cell_key.dart"
path: "lib/core/kodiak/table/cell_key.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, kodiak]
lines: 27
incoming_dependencies: 12
outgoing_dependencies: 1
---

# cell_key.dart

> Source File: `[lib/core/kodiak/table/cell_key.dart](file:///c:/Users/Admin/Musify_MU/lib/core/kodiak/table/cell_key.dart)`
> Layer: `lib/core/kodiak/table`

## Executive Summary
`cell_key.dart` is an essential file in `lib/core/kodiak/table` providing definitions for `CellKey`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `table_key.dart` | `lib/core/kodiak/table` | [[04-Reference/lib/core/kodiak/table/table_key|table_key.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `casita_parser.dart` | `lib/features/home_feed/data` | [[04-Reference/lib/features/home_feed/data/casita_parser|casita_parser.dart]] |
| `extended_metadata_service.dart` | `lib/core/media` | [[04-Reference/lib/core/media/extended_metadata_service|extended_metadata_service.dart]] |
| `data_pool.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool|data_pool.dart]] |
| `data_pool_impl.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool_impl|data_pool_impl.dart]] |
| `extended_metadata_client.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/extended_metadata_client|extended_metadata_client.dart]] |
| `extended_metadata_data_source.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/extended_metadata_data_source|extended_metadata_data_source.dart]] |
| `kodiak_cell_mapper.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/kodiak_cell_mapper|kodiak_cell_mapper.dart]] |
| `metadata_subscription.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/metadata_subscription|metadata_subscription.dart]] |
| `data_source.dart` | `lib/core/kodiak/table` | [[04-Reference/lib/core/kodiak/table/data_source|data_source.dart]] |
| `data_source_subscription.dart` | `lib/core/kodiak/table` | [[04-Reference/lib/core/kodiak/table/data_source_subscription|data_source_subscription.dart]] |
| `kodiak_data_layer_test.dart` | `test/features/home_feed` | [[04-Reference/test/features/home_feed/kodiak_data_layer_test|kodiak_data_layer_test.dart]] |
| `network_reconnect_retry_test.dart` | `test/core/kodiak` | [[04-Reference/test/core/kodiak/network_reconnect_retry_test|network_reconnect_retry_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class CellKey`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `table` | `TableKey` |
| `entityUri` | `String` |
| `_hash` | `int` |
| `operator` | `bool` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `toString` | `String` | `(none)` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:musify_mu/core/kodiak/table/table_key.dart';

/// Uniquely identifies a single cell in the Kodiak SDUI cache.
/// Formed by combining a table identifier (`TableKey`) with an entity URI.
/// Direct 1:1 equivalent to Spotify Android's `p.vq4`.
class CellKey {
  final TableKey table;
  final String entityUri;
  final int _hash;

  CellKey(this.table, this.entityUri)
      : _hash = entityUri.hashCode ^ (table.hashCode * 31);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellKey &&
          runtimeType == other.runtimeType &&
          table == other.table &&
          entityUri == other.entityUri;

  @override
  int get hashCode => _hash;

  @override
  String toString() => 'CellKey(${table.traitType}, $entityUri)';
}
```
