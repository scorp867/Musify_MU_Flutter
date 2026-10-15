---
title: "data_pool.dart"
path: "lib/core/kodiak/dataloader/data_pool.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, kodiak, dataloader, sdui, data-pool]
lines: 46
incoming_dependencies: 8
outgoing_dependencies: 3
---

# data_pool.dart

> Source File: `[lib/core/kodiak/dataloader/data_pool.dart](file:///c:/Users/Admin/Musify_MU/lib/core/kodiak/dataloader/data_pool.dart)`
> Layer: `lib/core/kodiak/dataloader` (Kodiak SDUI Core Contract)

## Executive Summary
`data_pool.dart` defines the `DataPool` interface, the central reactive data store for Spotify's Server-Driven UI (SDUI) in Musify MU. It is a direct 1:1 equivalent to Spotify Android's `com.spotify.kodiak.dataloader.DataPool`. It manages entity traits, offline disk caching, batch viewport trait queries, and broadcast update streams for individual entity URIs.

**Primary Architecture Role**: Centralized SDUI Reactive Trait Cache & DataPool Contract

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `data_statement.dart` | `lib/core/kodiak/statement` | [[04-Reference/lib/core/kodiak/statement/data_statement|data_statement.dart]] |
| `cell_key.dart` | `lib/core/kodiak/table` | [[04-Reference/lib/core/kodiak/table/cell_key|cell_key.dart]] |
| `traits.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/traits|traits.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `app.dart` | `lib/app` | [[04-Reference/lib/app/app|app.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `data_pool_impl.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool_impl|data_pool_impl.dart]] |
| `kodiak_reactive_card.dart` | `lib/core/kodiak/element` | [[04-Reference/lib/core/kodiak/element/kodiak_reactive_card|kodiak_reactive_card.dart]] |
| `home_feed_bloc.dart` | `lib/features/home_feed/application` | [[04-Reference/lib/features/home_feed/application/home_feed_bloc|home_feed_bloc.dart]] |
| `home_repository.dart` | `lib/features/home_feed/data` | [[04-Reference/lib/features/home_feed/data/home_repository|home_repository.dart]] |
| `kodiak_data_layer_test.dart` | `test/features/home_feed` | [[04-Reference/test/features/home_feed/kodiak_data_layer_test|kodiak_data_layer_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `abstract interface class DataPool`

**Query & Inspection Methods:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `ensureDiskLoaded` | `Future<void>` | None | Asynchronously ensures offline disk cache is parsed into memory |
| `getTrait<T extends Trait>` | `T?` | `String uri` | Synchronous lookup of a specific typed trait for an entity URI |
| `getTraits` | `Map<String, Trait>?` | `String uri` | Synchronous lookup of all resolved traits for an entity URI |
| `hasRequiredTraits` | `bool` | `String uri, DataStatement statement` | Checks whether all mandatory traits declared by the statement exist |
| `isKindResolved` | `bool` | `String uri, int kind` | Checks whether an extension kind has already been resolved |

**Reactive Stream & Ingestion Methods:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `watchEntity` | `Stream<Map<String, Trait>>` | `String uri` | Reactive broadcast stream emitting when traits for `uri` update |
| `ingestTraits` | `void` | `String uri, Map<String, Trait> traits` | Ingests pre-loaded traits (e.g. from Casita eager payloads) |
| `ingestBatch` | `void` | `Map<String, Map<String, Trait>> batch` | Batch ingestion of multiple entity traits |
| `ingestCells` | `void` | `Map<CellKey, Trait> cells` | Ingests raw `CellKey` entries into underlying data source |
| `loadBatch` | `Future<void>` | `List<String> uris, DataStatement statement` | Computes missing required traits and fetches them over network |
| `dispose` | `void` | None | Releases memory cache and closes stream controllers |

## State & Data Flow Analysis
- **Two-Tier Hydration (SDUI)**:
  1. Eager Hydration: Casita home feed returns Level 1 traits (`IdentityTrait`, `VisualIdentityTrait`) directly in the protobuf payload. `ingestBatch` writes these to memory synchronously.
  2. Lazy / Viewport Hydration: When cards scroll into view, `loadBatch` checks `hasRequiredTraits`. Only missing extension kinds are queried via `ExtendedMetadataClient`.
- **Targeted Reactive Rebuilds**:
  Instead of rebuilding the entire list view when metadata arrives, widgets subscribe to `watchEntity(item.uri)`. Only the specific cards that received new traits re-render.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Memory Footprint on Infinite Feeds
> Ingesting thousands of entities without an eviction strategy can expand memory usage. `DataPoolImpl` pairs memory with `KodiakDiskCache` to persist elements to SQLite/disk and cap active in-memory entity count.

## Implementation Highlight
```dart
abstract interface class DataPool {
  Future<void> ensureDiskLoaded();
  T? getTrait<T extends Trait>(String uri);
  Map<String, Trait>? getTraits(String uri);
  bool hasRequiredTraits(String uri, DataStatement statement);
  bool isKindResolved(String uri, int kind);
  Stream<Map<String, Trait>> watchEntity(String uri);
  void ingestTraits(String uri, Map<String, Trait> traits);
  void ingestBatch(Map<String, Map<String, Trait>> batch);
  void ingestCells(Map<CellKey, Trait> cells);
  Future<void> loadBatch({
    required List<String> uris,
    required DataStatement statement,
  });
  void dispose();
}
```
