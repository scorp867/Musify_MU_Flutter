---
title: "browse_cache.dart"
path: "lib/features/browse/data/browse_cache.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, browse]
lines: 158
incoming_dependencies: 1
outgoing_dependencies: 3
---

# browse_cache.dart

> Source File: `[lib/features/browse/data/browse_cache.dart](file:///c:/Users/Admin/Musify_MU/lib/features/browse/data/browse_cache.dart)`
> Layer: `lib/features/browse/data`

## Executive Summary
`browse_cache.dart` is an essential file in `lib/features/browse/data` providing definitions for `BrowseTraitCache`, `_CachedTrait`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `app_cache_manager.dart` | `lib/core/cache` | [[04-Reference/lib/core/cache/app_cache_manager|app_cache_manager.dart]] |
| `cache_policy.dart` | `lib/core/cache` | [[04-Reference/lib/core/cache/cache_policy|cache_policy.dart]] |
| `browse_metadata_fetcher.dart` | `lib/features/browse/data` | [[04-Reference/lib/features/browse/data/browse_metadata_fetcher|browse_metadata_fetcher.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `browse_repository.dart` | `lib/features/browse/data` | [[04-Reference/lib/features/browse/data/browse_repository|browse_repository.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class BrowseTraitCache`
- **Archetype**: Kodiak Trait Plugin / Reactive Element

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_cacheManager` | `AppCacheManager` |
| `_loadedGeneration` | `int` |
| `dir` | `final` |
| `file` | `final` |
| `jsonStr` | `final` |
| `map` | `final` |
| `cache` | `final` |
| `cached` | `final` |
| `missing` | `final` |
| `entry` | `final` |
| `cache` | `final` |
| `now` | `final` |
| `cache` | `final` |
| `file` | `final` |
| `validEntries` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `_getCacheFile` | `Future<File>` | `(none)` |
| `_ensureLoaded` | `_CachedTrait>>` | `(none)` |
| `map` | `dynamic` | `(uri, json` |
| `partition` | `>` | `List<String> uris` |
| `putAll` | `Future<void>` | `Map<String, BrowseCardData> freshCards` |
| `_persist` | `Future<void>` | `(none)` |
| `where` | `dynamic` | `(e` |
| `map` | `dynamic` | `(e` |

#### `class _CachedTrait`
- **Archetype**: Kodiak Trait Plugin / Reactive Element

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `data` | `BrowseCardData` |
| `cachedAt` | `int` |
| `map` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `toJson` | `dynamic>` | `(none)` |
| `fromJson` | `dynamic` | `dynamic json` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/cache/cache_policy.dart';
import 'package:musify_mu/features/browse/data/browse_metadata_fetcher.dart';

/// Per-URI cache for browse card traits (IdentityTrait + VisualIdentityTrait).
///
/// Spotify caches individual item traits, not the whole browse response.
/// On revalidation, it only queries extended-metadata for URIs
/// not yet in the local cache (delta fetch).
///
/// Cache structure (JSON file):
/// {
///   "spotify:page:abc123": {
///     "name": "Hindi",
///     "type": "page",
///     "imageUrl": "https://...",
///     "bgColor": 4294912345,
///     "cachedAt": 1695000000000
///   },
///   ...
/// }
class BrowseTraitCache {
  static const _fileName = 'browse_traits.json';
  static const _policy = CachePolicy.durable;

  final AppCacheManager _cacheManager;
  Map<String, _CachedTrait>? _memoryCache;
  int _loadedGeneration = -1;

  BrowseTraitCache({required AppCacheManager cacheManager})
      : _cacheManager = cacheManager;

  Future<File> _getCacheFile() async {
    final dir = await _cacheManager.featureDir('browse');
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  /// Loads the cache into memory (once per user session).
  Future<Map<String, _CachedTrait>> _ensureLoaded() async {
    if (_memoryCache != null &&
        _loadedGeneration == _cacheManager.generation) {
// ... [remaining code in source file] ...
```
