---
title: "data_pool_impl.dart"
path: "lib/core/kodiak/dataloader/data_pool_impl.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, kodiak]
lines: 328
incoming_dependencies: 3
outgoing_dependencies: 12
---

# data_pool_impl.dart

> Source File: `[lib/core/kodiak/dataloader/data_pool_impl.dart](file:///c:/Users/Admin/Musify_MU/lib/core/kodiak/dataloader/data_pool_impl.dart)`
> Layer: `lib/core/kodiak/dataloader`

## Executive Summary
`data_pool_impl.dart` is an essential file in `lib/core/kodiak/dataloader` providing definitions for `DataPoolImpl`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `data_pool.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool|data_pool.dart]] |
| `kodiak_disk_cache.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/kodiak_disk_cache|kodiak_disk_cache.dart]] |
| `extended_metadata_data_source.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/extended_metadata_data_source|extended_metadata_data_source.dart]] |
| `extended_metadata_plugin_registry.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry|extended_metadata_plugin_registry.dart]] |
| `builtin_plugins.dart` | `lib/core/kodiak/extendedmetadataimpl/plugins` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/plugins/builtin_plugins|builtin_plugins.dart]] |
| `data_statement.dart` | `lib/core/kodiak/statement` | [[04-Reference/lib/core/kodiak/statement/data_statement|data_statement.dart]] |
| `cell_key.dart` | `lib/core/kodiak/table` | [[04-Reference/lib/core/kodiak/table/cell_key|cell_key.dart]] |
| `data_source_subscription.dart` | `lib/core/kodiak/table` | [[04-Reference/lib/core/kodiak/table/data_source_subscription|data_source_subscription.dart]] |
| `table_key.dart` | `lib/core/kodiak/table` | [[04-Reference/lib/core/kodiak/table/table_key|table_key.dart]] |
| `network_monitor_service.dart` | `lib/core/network/status` | [[04-Reference/lib/core/network/status/network_monitor_service|network_monitor_service.dart]] |
| `network_status.dart` | `lib/core/network/status` | [[04-Reference/lib/core/network/status/network_status|network_status.dart]] |
| `traits.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/traits|traits.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `kodiak_data_layer_test.dart` | `test/features/home_feed` | [[04-Reference/test/features/home_feed/kodiak_data_layer_test|kodiak_data_layer_test.dart]] |
| `network_reconnect_retry_test.dart` | `test/core/kodiak` | [[04-Reference/test/core/kodiak/network_reconnect_retry_test|network_reconnect_retry_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class DataPoolImpl`
- **Archetype**: Core Component
- **Implements**: `DataPool`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_dataSource` | `ExtendedMetadataDataSourceImpl` |
| `_diskCache` | `KodiakDiskCache?` |
| `_networkMonitor` | `NetworkMonitorService?` |
| `_pluginRegistry` | `ExtendedMetadataPluginRegistry?` |
| `_pendingBatch` | `Set<CellKey>` |
| `_failedRetryKeys` | `Set<CellKey>` |
| `_networkSubscription` | `StreamSubscription<NetworkStatus>?` |
| `_debounceTimer` | `Timer?` |
| `_retryDebounceTimer` | `Timer?` |
| `_diskLoaded` | `bool` |
| `_isDisposed` | `bool` |
| `cached` | `final` |
| `existing` | `final` |
| `existing` | `final` |
| `uriTraits` | `final` |
| `t` | `final` |
| `cellKey` | `final` |
| `trait` | `final` |
| `trait` | `return` |
| `null` | `return` |
| `uriTraits` | `final` |
| `false` | `return` |
| `true` | `return` |
| `controller` | `final` |
| `current` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `ensureDiskLoaded` | `Future<void>` | `(none)` |
| `putIfAbsent` | `dynamic` | `entry.key, (` |
| `putIfAbsent` | `dynamic` | `entry.key, (` |
| `putIfAbsent` | `dynamic` | `uri, (` |
| `getTraits` | `Trait>?` | `String uri` |
| `hasRequiredTraits` | `bool` | `String uri, DataStatement statement` |
| `isKindResolved` | `bool` | `String uri, int kind` |
| `watchEntity` | `Trait>>` | `String uri` |
| `putIfAbsent` | `dynamic` | `uri, (` |
| `run` | `dynamic` | `(` |
| `ingestTraits` | `void` | `String uri, Map<String, Trait> traits` |
| `putIfAbsent` | `dynamic` | `uri, (` |
| `ingestBatch` | `void` | `Map<String, Map<String, Trait>> batch` |
| `putIfAbsent` | `dynamic` | `entry.key, (` |
| `ingestCells` | `void` | `Map<CellKey, Trait> cells` |
| `putIfAbsent` | `dynamic` | `uri, (` |
| `putIfAbsent` | `dynamic` | `uri, (` |
| `loadBatch` | `Future<void>` | `{ required List<String> uris, required DataStat...` |
| `_scheduleBatch` | `void` | `(none)` |
| `_onDataSourceUpdated` | `void` | `List<CellKey> updatedKeys` |
| `putIfAbsent` | `dynamic` | `uri, (` |
| `putIfAbsent` | `dynamic` | `uri, (` |
| `_onNetworkFailure` | `void` | `Set<CellKey> failedKeys` |
| `_initNetworkListener` | `void` | `(none)` |
| `listen` | `dynamic` | `(status` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:async';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/dataloader/kodiak_disk_cache.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_data_source.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/plugins/builtin_plugins.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/kodiak/table/data_source_subscription.dart';
import 'package:musify_mu/core/kodiak/table/table_key.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Concrete implementation of Kodiak DataPool.
/// Direct 1:1 equivalent to Spotify Android's `p.s3n` (`DataPoolImpl`).
class DataPoolImpl implements DataPool {
  final ExtendedMetadataDataSourceImpl _dataSource;
  final KodiakDiskCache? _diskCache;
  final NetworkMonitorService? _networkMonitor;
  final ExtendedMetadataPluginRegistry? _pluginRegistry;

  /// In-memory trait store: URI -> { TraitTypeName -> Trait }
  /// Direct equivalent to Spotify Android `s3n.i` (`iur0`).
  final Map<String, Map<String, Trait>> _store = {};

  /// Tracks resolved extension kinds per URI to avoid duplicate querying.
  final Map<String, Set<int>> _resolvedKinds = {};

  /// Reactive stream controllers per URI for live UI updates.
  final Map<String, StreamController<Map<String, Trait>>> _controllers = {};

  /// Active subscription to the ExtendedMetadataDataSource.
  /// Direct equivalent to Spotify Android `s3n.h` (`fk51`).
  late final DataSourceSubscription _subscription;

  /// Pending batched cell keys to query.
  /// Direct equivalent to Spotify Android `s3n.j` (`LinkedHashSet`).
  final Set<CellKey> _pendingBatch = {};

  /// Failed cell keys awaiting network restoration to retry.
  final Set<CellKey> _failedRetryKeys = {};

  StreamSubscription<NetworkStatus>? _networkSubscription;
  Timer? _debounceTimer;
// ... [remaining code in source file] ...
```
