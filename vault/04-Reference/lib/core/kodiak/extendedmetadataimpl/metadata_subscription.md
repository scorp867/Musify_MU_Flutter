---
title: "metadata_subscription.dart"
path: "lib/core/kodiak/extendedmetadataimpl/metadata_subscription.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, kodiak, subscription, batching]
lines: 161
incoming_dependencies: 1
outgoing_dependencies: 7
---

# metadata_subscription.dart

> Source File: `[lib/core/kodiak/extendedmetadataimpl/metadata_subscription.dart](file:///c:/Users/Admin/Musify_MU/lib/core/kodiak/extendedmetadataimpl/metadata_subscription.dart)`
> Layer: `lib/core/kodiak/extendedmetadataimpl` (Kodiak Element Subscription)

## Executive Summary
`metadata_subscription.dart` implements `MetadataSubscription` (direct 1:1 equivalent to Spotify Android's `p.r1w`). It manages active element trait requests, prevents duplicate in-flight network queries, manages local cache snapshots, and dispatches batch requests through `ExtendedMetadataClient`. Crucially, it incorporates Musify MU's transport failure resilience fix: transient network drops do not poison cell keys with permanent `markUnavailable()`.

**Primary Architecture Role**: Element Trait Subscription & In-Flight Batch Dispatcher

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `extended_metadata_client.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/extended_metadata_client|extended_metadata_client.dart]] |
| `extended_metadata_data_source.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/extended_metadata_data_source|extended_metadata_data_source.dart]] |
| `cell_key.dart` | `lib/core/kodiak/table` | [[04-Reference/lib/core/kodiak/table/cell_key|cell_key.dart]] |
| `data_source_result.dart` | `lib/core/kodiak/table` | [[04-Reference/lib/core/kodiak/table/data_source_result|data_source_result.dart]] |
| `data_source_subscription.dart` | `lib/core/kodiak/table` | [[04-Reference/lib/core/kodiak/table/data_source_subscription|data_source_subscription.dart]] |
| `network_result.dart` | `lib/core/network/result` | [[04-Reference/lib/core/network/result/network_result|network_result.dart]] |
| `traits.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/traits|traits.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `extended_metadata_data_source.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/extended_metadata_data_source|extended_metadata_data_source.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class MetadataSubscription implements DataSourceSubscription`

**Internal State:**
- `final Map<CellKey, Trait> _localCache`: Snapshot of traits for this element subscription (Spotify Android `r1w.h`).
- `Set<CellKey> _activeKeys`: Set of keys requested by the current viewport (Spotify Android `r1w.g`).
- `final Set<CellKey> _inFlight`: Set of currently executing network keys to prevent redundant requests.
- `bool _isDisposed`: Disposed guard flag.

**Key Methods:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `request` | `Map<CellKey, DataSourceResult>` | `Set<CellKey> keys` | Returns available traits synchronously and triggers `_dispatchBatch` for missing keys |
| `_dispatchBatch` | `Future<void>` | `Set<CellKey> keysToFetch` | Dispatches network query through `ExtendedMetadataClient` |
| `dispose` | `void` | None | Marks subscription disposed and clears local cache |

## State & Data Flow Analysis
- **Non-Poisoning Resilience (Network Hardening)**:
  ```dart
  if (result is NetworkFailure<Map<CellKey, Trait>>) {
    // If this is a transport glitch (timeout, offline, serverError, rateLimited),
    // DO NOT poison the cache with markUnavailable.
    // Leaving keys un-poisoned allows them to recover when network restores.
    _onNetworkFailure?.call(keysToFetch);
    return;
  }
  ```
  In Spotify Android decompiled code, failed requests originally marked cells as permanently `Unavailable`. In Musify MU, transient network dropouts do not mark keys unavailable, allowing the card to seamlessly fetch traits once the device reconnects.

## Implementation Highlight
```dart
@override
Map<CellKey, DataSourceResult<dynamic>> request(Set<CellKey> keys) {
  if (_isDisposed) return const {};

  _activeKeys = Set.of(keys);

  final results = <CellKey, DataSourceResult<dynamic>>{};
  final missingKeys = <CellKey>{};

  for (final key in keys) {
    final cachedTrait = _localCache[key] ?? _dataSource.getTrait(key);
    if (cachedTrait != null) {
      _localCache[key] = cachedTrait;
      results[key] = Available(cachedTrait);
    } else {
      results[key] = const NotAvailable();
      if (!_inFlight.contains(key)) {
        missingKeys.add(key);
      }
    }
  }

  if (missingKeys.isNotEmpty) {
    _dispatchBatch(missingKeys);
  }

  return results;
}
```
