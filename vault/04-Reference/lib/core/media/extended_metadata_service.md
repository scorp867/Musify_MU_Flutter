---
title: "extended_metadata_service.dart"
path: "lib/core/media/extended_metadata_service.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, media]
lines: 378
incoming_dependencies: 3
outgoing_dependencies: 10
---

# extended_metadata_service.dart

> Source File: `[lib/core/media/extended_metadata_service.dart](file:///c:/Users/Admin/Musify_MU/lib/core/media/extended_metadata_service.dart)`
> Layer: `lib/core/media`

## Executive Summary
`extended_metadata_service.dart` is an essential file in `lib/core/media` providing definitions for `TrackMeta`, `ExtendedMetadataService`, `_TrackMetaDiskCache`, `_LruCache`.
**Primary Architecture Role**: Service / Controller, Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `app_cache_manager.dart` | `lib/core/cache` | [[04-Reference/lib/core/cache/app_cache_manager|app_cache_manager.dart]] |
| `cache_policy.dart` | `lib/core/cache` | [[04-Reference/lib/core/cache/cache_policy|cache_policy.dart]] |
| `runtime_context.dart` | `lib/core/config` | [[04-Reference/lib/core/config/runtime_context|runtime_context.dart]] |
| `extended_metadata_client.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/extended_metadata_client|extended_metadata_client.dart]] |
| `extended_metadata_plugin_registry.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry|extended_metadata_plugin_registry.dart]] |
| `builtin_plugins.dart` | `lib/core/kodiak/extendedmetadataimpl/plugins` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/plugins/builtin_plugins|builtin_plugins.dart]] |
| `cell_key.dart` | `lib/core/kodiak/table` | [[04-Reference/lib/core/kodiak/table/cell_key|cell_key.dart]] |
| `table_key.dart` | `lib/core/kodiak/table` | [[04-Reference/lib/core/kodiak/table/table_key|table_key.dart]] |
| `spotify_transport.dart` | `lib/core/network/spotify/transport` | [[04-Reference/lib/core/network/spotify/transport/spotify_transport|spotify_transport.dart]] |
| `traits.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/traits|traits.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `library_decorator.dart` | `lib/features/library/data/repository` | [[04-Reference/lib/features/library/data/repository/library_decorator|library_decorator.dart]] |
| `library_repository_impl.dart` | `lib/features/library/data/repository` | [[04-Reference/lib/features/library/data/repository/library_repository_impl|library_repository_impl.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class TrackMeta`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `uri` | `String` |
| `title` | `String` |
| `subtitle` | `String` |
| `albumName` | `String` |
| `largeImageHex` | `String?` |
| `durationMs` | `int` |

#### `class ExtendedMetadataService`
- **Archetype**: Service / Controller

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_metadataClient` | `ExtendedMetadataClient` |
| `_memCache` | `final` |
| `_diskCache` | `_TrackMetaDiskCache` |
| `_diskLoaded` | `bool` |
| `entries` | `final` |
| `results` | `final` |
| `uncached` | `final` |
| `cached` | `final` |
| `batchSize` | `const` |
| `newEntries` | `final` |
| `batch` | `final` |
| `fetched` | `final` |
| `results` | `return` |
| `unique` | `final` |
| `seen` | `final` |
| `map` | `final` |
| `keys` | `final` |
| `cells` | `final` |
| `results` | `final` |
| `trait` | `final` |
| `results` | `return` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `_ensureDiskLoaded` | `Future<void>` | `(none)` |
| `ensureLoaded` | `Future<void>` | `(none)` |
| `getCached` | `TrackMeta?` | `String uri` |
| `fetchTracks` | `TrackMeta>>` | `List<String> uris` |
| `fetchFirst` | `Future<List<TrackMeta>>` | `List<String> uris, int count` |
| `map` | `dynamic` | `(u` |
| `_fetchBatch` | `TrackMeta>>` | `List<String> uris` |
| `map` | `dynamic` | `(u` |

#### `class _TrackMetaDiskCache`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_cacheManager` | `AppCacheManager` |
| `_file` | `File?` |
| `_fileGeneration` | `int` |
| `dir` | `final` |
| `file` | `final` |
| `content` | `final` |
| `results` | `final` |
| `j` | `final` |
| `ts` | `final` |
| `meta` | `final` |
| `results` | `return` |
| `file` | `final` |
| `ts` | `final` |
| `sb` | `final` |
| `lines` | `final` |
| `valid` | `final` |
| `map` | `final` |
| `ts` | `final` |
| `uri` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `_getFile` | `Future<File>` | `(none)` |
| `loadAll` | `TrackMeta>>` | `(none)` |
| `putAll` | `Future<void>` | `Map<String, TrackMeta> entries` |
| `_compactIfNeeded` | `Future<void>` | `(none)` |
| `_toJson` | `dynamic>` | `TrackMeta meta, int ts` |
| `_fromJson` | `TrackMeta?` | `Map<String, dynamic> j` |
| `map` | `dynamic` | `(k, v` |

#### `class _LruCache`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_maxSize` | `int` |
| `value` | `final` |
| `value` | `return` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `get` | `V?` | `K key` |
| `put` | `void` | `K key, V value` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/cache/cache_policy.dart';
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_client.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/plugins/builtin_plugins.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/kodiak/table/table_key.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Resolved metadata for a single track or episode.
///
/// Shared across the whole app: library mosaic, playlist detail,
/// now playing, queue, playback, etc.
class TrackMeta {
  final String uri;
  final String title;
  final String subtitle; // artist names joined
  final String albumName;

  /// Image URLs by size. Keys: 'small' (~64px), 'medium' (~300px), 'large' (~640px).
  final Map<String, String> imageUrls;

  /// Best cover URL (largest available).
  String get imageUrl =>
      imageUrls['large'] ??
      imageUrls['medium'] ??
      imageUrls['small'] ??
      '';

  /// Raw hex image ID of the largest cover (for mosaic URL construction).
  final String? largeImageHex;

  final int durationMs;

  const TrackMeta({
    required this.uri,
    this.title = '',
    this.subtitle = '',
// ... [remaining code in source file] ...
```
