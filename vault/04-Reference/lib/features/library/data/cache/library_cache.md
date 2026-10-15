---
title: "library_cache.dart"
path: "lib/features/library/data/cache/library_cache.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, library]
lines: 179
incoming_dependencies: 3
outgoing_dependencies: 1
---

# library_cache.dart

> Source File: `[lib/features/library/data/cache/library_cache.dart](file:///c:/Users/Admin/Musify_MU/lib/features/library/data/cache/library_cache.dart)`
> Layer: `lib/features/library/data/cache`

## Executive Summary
`library_cache.dart` is an essential file in `lib/features/library/data/cache` providing definitions for `LibraryCache`, `_DecorationEntry`, `DecorationData`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `app_cache_manager.dart` | `lib/core/cache` | [[04-Reference/lib/core/cache/app_cache_manager|app_cache_manager.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `library_decorator.dart` | `lib/features/library/data/repository` | [[04-Reference/lib/features/library/data/repository/library_decorator|library_decorator.dart]] |
| `library_repository_impl.dart` | `lib/features/library/data/repository` | [[04-Reference/lib/features/library/data/repository/library_repository_impl|library_repository_impl.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class LibraryCache`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_cacheManager` | `AppCacheManager` |
| `_decorationsLoaded` | `bool` |
| `_loadedGeneration` | `int` |
| `dir` | `final` |
| `sep` | `final` |
| `file` | `final` |
| `meta` | `final` |
| `dir` | `final` |
| `sep` | `final` |
| `file` | `final` |
| `meta` | `final` |
| `null` | `return` |
| `entry` | `final` |
| `now` | `final` |
| `dir` | `final` |
| `file` | `final` |
| `raw` | `final` |
| `map` | `final` |
| `v` | `final` |
| `cachedAt` | `final` |
| `dir` | `final` |
| `file` | `final` |
| `map` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `putStructureBytes` | `Future<void>` | `String key, Uint8List bytes` |
| `getStructureBytes` | `Future<Uint8List?>` | `String key` |
| `getDecoration` | `DecorationData?` | `String uri` |
| `uncachedUris` | `List<String>` | `List<String> uris` |
| `where` | `dynamic` | `(uri` |
| `putDecorations` | `Future<void>` | `Map<String, DecorationData> entries` |
| `loadDecorations` | `Future<void>` | `(none)` |
| `_persistDecorations` | `Future<void>` | `(none)` |
| `_checkGeneration` | `void` | `(none)` |

#### `class _DecorationEntry`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `name` | `String` |
| `imageUrl` | `String?` |
| `cachedAt` | `int` |

#### `class DecorationData`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `name` | `String` |
| `imageUrl` | `String?` |

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
import 'dart:typed_data';

import 'package:musify_mu/core/cache/app_cache_manager.dart';

/// High-performance two-layer cache for Library data.
///
/// Layer 1 (Structure): Raw protobuf bytes cached to disk.
///   - rootlist bytes, collection bytes per set name
///   - Zero serialization cost: read/write raw bytes directly
///
/// Layer 2 (Decoration): Per-URI metadata (name, imageUrl).
///   - In-memory Map for fast lookups, persisted to disk periodically
///   - 24h TTL per entry
class LibraryCache {
  final AppCacheManager _cacheManager;

  // In-memory decoration cache: uri -> {name, imageUrl, cachedAt}
  final Map<String, _DecorationEntry> _decorations = {};
  bool _decorationsLoaded = false;
  int _loadedGeneration = -1;

  LibraryCache({required AppCacheManager cacheManager})
      : _cacheManager = cacheManager;

  Future<Directory> get _cacheDir => _cacheManager.featureDir('library');

  // ─── Structure cache (raw protobuf bytes) ──────────────────────────

  /// Saves raw protobuf bytes for a structure endpoint.
  Future<void> putStructureBytes(String key, Uint8List bytes) async {
    try {
      final dir = await _cacheDir;
      final sep = Platform.pathSeparator;
      final file = File('${dir.path}${sep}struct_$key.bin');
      final meta = File('${dir.path}${sep}struct_$key.ts');
      await Future.wait([
        file.writeAsBytes(bytes, flush: true),
        meta.writeAsString(
          DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      ]);
    } catch (e) {
// ... [remaining code in source file] ...
```
