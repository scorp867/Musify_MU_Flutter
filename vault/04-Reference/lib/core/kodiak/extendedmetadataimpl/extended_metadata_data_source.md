---
title: "extended_metadata_data_source.dart"
path: "lib/core/kodiak/extendedmetadataimpl/extended_metadata_data_source.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, kodiak]
lines: 111
incoming_dependencies: 5
outgoing_dependencies: 7
---

# extended_metadata_data_source.dart

> Source File: `[lib/core/kodiak/extendedmetadataimpl/extended_metadata_data_source.dart](file:///c:/Users/Admin/Musify_MU/lib/core/kodiak/extendedmetadataimpl/extended_metadata_data_source.dart)`
> Layer: `lib/core/kodiak/extendedmetadataimpl`

## Executive Summary
`extended_metadata_data_source.dart` is an essential file in `lib/core/kodiak/extendedmetadataimpl` providing definitions for `ExtendedMetadataDataSourceImpl`.
**Primary Architecture Role**: Data Source / Remote Client

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `extended_metadata_client.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/extended_metadata_client|extended_metadata_client.dart]] |
| `metadata_subscription.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/metadata_subscription|metadata_subscription.dart]] |
| `cell_key.dart` | `lib/core/kodiak/table` | [[04-Reference/lib/core/kodiak/table/cell_key|cell_key.dart]] |
| `data_source.dart` | `lib/core/kodiak/table` | [[04-Reference/lib/core/kodiak/table/data_source|data_source.dart]] |
| `data_source_result.dart` | `lib/core/kodiak/table` | [[04-Reference/lib/core/kodiak/table/data_source_result|data_source_result.dart]] |
| `data_source_subscription.dart` | `lib/core/kodiak/table` | [[04-Reference/lib/core/kodiak/table/data_source_subscription|data_source_subscription.dart]] |
| `traits.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/traits|traits.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `data_pool_impl.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool_impl|data_pool_impl.dart]] |
| `metadata_subscription.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/metadata_subscription|metadata_subscription.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `kodiak_data_layer_test.dart` | `test/features/home_feed` | [[04-Reference/test/features/home_feed/kodiak_data_layer_test|kodiak_data_layer_test.dart]] |
| `network_reconnect_retry_test.dart` | `test/core/kodiak` | [[04-Reference/test/core/kodiak/network_reconnect_retry_test|network_reconnect_retry_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class ExtendedMetadataDataSourceImpl`
- **Archetype**: Data Source / Remote Client
- **Implements**: `DataSource`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_client` | `ExtendedMetadataClient?` |
| `_unavailableCells` | `Set<CellKey>` |
| `_subscriptions` | `List<MetadataSubscription>` |
| `updatedKeys` | `final` |
| `sub` | `final` |
| `sub` | `return` |
| `results` | `final` |
| `value` | `final` |
| `results` | `return` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `f` | `void` | `Map<CellKey, Trait> eagerMap` |
| `removeSubscription` | `void` | `MetadataSubscription sub` |
| `getCached` | `DataSourceResult<dynamic>>` | `Set<CellKey> keys` |
| `markUnavailable` | `void` | `CellKey key` |
| `invalidate` | `void` | `Set<CellKey> keys` |
| `supports` | `bool` | `CellKey key` |
| `dispose` | `void` | `(none)` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_client.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/metadata_subscription.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/kodiak/table/data_source.dart';
import 'package:musify_mu/core/kodiak/table/data_source_result.dart';
import 'package:musify_mu/core/kodiak/table/data_source_subscription.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Central Kodiak DataSource for Spotify Extended Metadata.
/// Direct 1:1 equivalent to Spotify Android's `p.t1w` (`ExtendedMetadataDataSourceImpl`).
class ExtendedMetadataDataSourceImpl implements DataSource {
  final ExtendedMetadataClient? _client;

  /// Global in-memory cache of resolved traits.
  /// Direct equivalent to Spotify Android `t1w.d` (`ConcurrentHashMap`).
  final Map<CellKey, Trait> _cellStore = {};

  /// Set of resolved cell keys that have been confirmed unavailable from backend.
  /// Prevents infinite viewport re-fetching.
  final Set<CellKey> _unavailableCells = {};

  /// Active subscriptions.
  /// Direct equivalent to Spotify Android `t1w.c` (`CopyOnWriteArrayList`).
  final List<MetadataSubscription> _subscriptions = [];

  ExtendedMetadataDataSourceImpl({
    ExtendedMetadataClient? client,
  }) : _client = client;

  ExtendedMetadataClient? get client => _client;

  /// Ingests eager traits or external batches into the global cache.
  /// Direct 1:1 equivalent to Spotify Android's `t1w.f(Map)`.
  /// Called right after Casita response is parsed for 0ms cache warmup.
  void f(Map<CellKey, Trait> eagerMap) {
    if (eagerMap.isEmpty) return;

    _cellStore.addAll(eagerMap);

    // Notify all active subscriptions with the updated keys
    final updatedKeys = eagerMap.keys.toList();
    for (final sub in List<MetadataSubscription>.from(_subscriptions)) {
      sub.onDataSourceUpdated(updatedKeys);
    }
  }
// ... [remaining code in source file] ...
```
