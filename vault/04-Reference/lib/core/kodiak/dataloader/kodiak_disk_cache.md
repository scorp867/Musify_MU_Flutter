---
title: "kodiak_disk_cache.dart"
path: "lib/core/kodiak/dataloader/kodiak_disk_cache.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, kodiak]
lines: 154
incoming_dependencies: 2
outgoing_dependencies: 3
---

# kodiak_disk_cache.dart

> Source File: `[lib/core/kodiak/dataloader/kodiak_disk_cache.dart](file:///c:/Users/Admin/Musify_MU/lib/core/kodiak/dataloader/kodiak_disk_cache.dart)`
> Layer: `lib/core/kodiak/dataloader`

## Executive Summary
`kodiak_disk_cache.dart` is an essential file in `lib/core/kodiak/dataloader` providing definitions for `KodiakDiskCacheData`, `KodiakDiskCache`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `app_cache_manager.dart` | `lib/core/cache` | [[04-Reference/lib/core/cache/app_cache_manager|app_cache_manager.dart]] |
| `cache_policy.dart` | `lib/core/cache` | [[04-Reference/lib/core/cache/cache_policy|cache_policy.dart]] |
| `traits.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/traits|traits.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `data_pool_impl.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool_impl|data_pool_impl.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class KodiakDiskCacheData`
- **Archetype**: Core Component

#### `class KodiakDiskCache`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_cacheManager` | `AppCacheManager` |
| `_saveDebounceTimer` | `Timer?` |
| `dir` | `final` |
| `null` | `return` |
| `file` | `final` |
| `content` | `final` |
| `json` | `final` |
| `cachedAt` | `final` |
| `rawTraits` | `final` |
| `deserializedTraits` | `final` |
| `uri` | `final` |
| `traitMap` | `final` |
| `parsedMap` | `final` |
| `trait` | `final` |
| `rawResolved` | `final` |
| `deserializedResolved` | `final` |
| `list` | `final` |
| `null` | `return` |
| `file` | `final` |
| `serializedTraits` | `final` |
| `entityTraits` | `final` |
| `serializedResolved` | `final` |
| `json` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `_getCacheFile` | `Future<File?>` | `(none)` |
| `load` | `Future<KodiakDiskCacheData?>` | `(none)` |
| `map` | `dynamic` | `(e` |
| `save` | `Future<void>` | `{ required Map<String, Map<String, Trait>> trai...` |
| `scheduleSave` | `void` | `{ required Map<String, Map<String, Trait>> trai...` |
| `dispose` | `void` | `(none)` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/cache/cache_policy.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Cached payload from disk containing known traits and resolved kinds.
class KodiakDiskCacheData {
  final Map<String, Map<String, Trait>> traits;
  final Map<String, Set<int>> resolvedKinds;

  const KodiakDiskCacheData({
    required this.traits,
    required this.resolvedKinds,
  });
}

/// Disk cache for Kodiak DataPool.
///
/// Persists known traits and resolved ExtensionKind queries so that subsequent
/// app launches have instant metadata available without triggering network fetches.
class KodiakDiskCache {
  static const _policy = CachePolicy.standard;

  final AppCacheManager _cacheManager;
  Timer? _saveDebounceTimer;

  KodiakDiskCache({required AppCacheManager cacheManager})
      : _cacheManager = cacheManager;

  Future<File?> _getCacheFile() async {
    if (!_cacheManager.hasUser) return null;
    try {
      final dir = await _cacheManager.featureDir('kodiak');
      return File('${dir.path}${Platform.pathSeparator}kodiak_traits.json');
    } catch (_) {
      return null;
    }
  }

  /// Loads cached traits and resolved query statuses from disk.
  Future<KodiakDiskCacheData?> load() async {
// ... [remaining code in source file] ...
```
