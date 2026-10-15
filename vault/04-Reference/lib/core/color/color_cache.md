---
title: "color_cache.dart"
path: "lib/core/color/color_cache.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, color]
lines: 148
incoming_dependencies: 3
outgoing_dependencies: 3
---

# color_cache.dart

> Source File: `[lib/core/color/color_cache.dart](file:///c:/Users/Admin/Musify_MU/lib/core/color/color_cache.dart)`
> Layer: `lib/core/color`

## Executive Summary
`color_cache.dart` is an essential file in `lib/core/color` providing definitions for `ColorCache`, `_SchemeEntry`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `app_cache_manager.dart` | `lib/core/cache` | [[04-Reference/lib/core/cache/app_cache_manager|app_cache_manager.dart]] |
| `cache_policy.dart` | `lib/core/cache` | [[04-Reference/lib/core/cache/cache_policy|cache_policy.dart]] |
| `artwork_color_scheme.dart` | `lib/core/color` | [[04-Reference/lib/core/color/artwork_color_scheme|artwork_color_scheme.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `color_extraction_service.dart` | `lib/core/color` | [[04-Reference/lib/core/color/color_extraction_service|color_extraction_service.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `color_extraction_service_test.dart` | `test/core/color` | [[04-Reference/test/core/color/color_extraction_service_test|color_extraction_service_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class ColorCache`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_cacheManager` | `AppCacheManager` |
| `_loaded` | `bool` |
| `_loadedGeneration` | `int` |
| `entry` | `final` |
| `null` | `return` |
| `now` | `final` |
| `dir` | `final` |
| `file` | `final` |
| `raw` | `final` |
| `map` | `final` |
| `version` | `final` |
| `v` | `final` |
| `cachedAt` | `final` |
| `colorsList` | `final` |
| `dir` | `final` |
| `file` | `final` |
| `dir` | `final` |
| `file` | `final` |
| `map` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `get` | `ArtworkColorScheme?` | `String artworkUrl` |
| `put` | `Future<void>` | `String artworkUrl, ArtworkColorScheme scheme` |
| `load` | `Future<void>` | `(none)` |
| `clear` | `Future<void>` | `(none)` |
| `_persist` | `Future<void>` | `(none)` |
| `_checkGeneration` | `void` | `(none)` |

#### `class _SchemeEntry`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `argbColors` | `List<int>` |
| `cachedAt` | `int` |

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
import 'package:musify_mu/core/color/artwork_color_scheme.dart';

/// Persistent color scheme cache backed by [AppCacheManager].
///
/// Stores extracted [ArtworkColorScheme]s keyed by artwork URL or identifier.
/// On cache hit, returns the scheme instantly from memory.
/// Entries are persisted to disk as JSON and survive app restarts.
///
/// Cache invalidation:
/// - TTL-based (7 days via [CachePolicy.durable])
/// - URL-based (if artwork URL changes, old entry is irrelevant)
class ColorCache {
  static const _policy = CachePolicy.durable;
  static const _formatVersion = 2;

  final AppCacheManager _cacheManager;

  final Map<String, _SchemeEntry> _entries = {};
  bool _loaded = false;
  int _loadedGeneration = -1;

  ColorCache({required AppCacheManager cacheManager})
      : _cacheManager = cacheManager;

  Future<Directory> get _cacheDir => _cacheManager.featureDir('colors');

  /// Returns cached scheme for [artworkUrl], or null if not cached/expired.
  ArtworkColorScheme? get(String artworkUrl) {
    _checkGeneration();
    final entry = _entries[artworkUrl];
    if (entry == null) return null;
    if (_policy.isExpired(entry.cachedAt)) {
      _entries.remove(artworkUrl);
      return null;
    }
    return ArtworkColorScheme.fromArgbList(entry.argbColors);
  }

  /// Stores extracted scheme for [artworkUrl] and persists to disk.
// ... [remaining code in source file] ...
```
