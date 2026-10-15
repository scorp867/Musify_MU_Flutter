---
title: "playlist_detail_cache.dart"
path: "lib/features/library/data/cache/playlist_detail_cache.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, library]
lines: 173
incoming_dependencies: 3
outgoing_dependencies: 1
---

# playlist_detail_cache.dart

> Source File: `[lib/features/library/data/cache/playlist_detail_cache.dart](file:///c:/Users/Admin/Musify_MU/lib/features/library/data/cache/playlist_detail_cache.dart)`
> Layer: `lib/features/library/data/cache`

## Executive Summary
`playlist_detail_cache.dart` is an essential file in `lib/features/library/data/cache` providing definitions for `PlaylistDetailCache`, `PlaylistCacheEntry`.
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
#### `class PlaylistDetailCache`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_cacheManager` | `AppCacheManager` |
| `_loadedGeneration` | `int` |
| `dir` | `final` |
| `indexFile` | `final` |
| `raw` | `final` |
| `map` | `final` |
| `v` | `final` |
| `entry` | `final` |
| `entry` | `final` |
| `isCustomCover` | `bool` |
| `mosaicImageUrls` | `List<String>` |
| `dir` | `final` |
| `file` | `final` |
| `dir` | `final` |
| `file` | `final` |
| `null` | `return` |
| `dir` | `final` |
| `indexFile` | `final` |
| `map` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `_ensureIndex` | `Future<void>` | `(none)` |
| `get` | `Future<PlaylistCacheEntry?>` | `String playlistId` |
| `getRevision` | `Future<String?>` | `String playlistId` |
| `getCoverUrl` | `Future<String?>` | `String playlistId` |
| `put` | `Future<void>` | `{ required String playlistId, required String r...` |
| `getRawBytes` | `Future<Uint8List?>` | `String playlistId` |
| `cachedIds` | `Future<Set<String>>` | `(none)` |
| `_persistIndex` | `Future<void>` | `(none)` |

#### `class PlaylistCacheEntry`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `revision` | `String` |
| `coverUrl` | `String?` |
| `isCustomCover` | `bool` |
| `mosaicImageUrls` | `List<String>` |
| `trackUris` | `List<String>` |

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

/// Per-playlist disk cache with revision tracking for diff-based updates.
///
/// Stores for each playlist ID:
///   - Raw protobuf bytes (for isolate parsing)
///   - Revision string (for diff endpoint)
///   - Cover image URL (mosaic or custom)
///   - Track URIs (for mosaic generation)
class PlaylistDetailCache {
  final AppCacheManager _cacheManager;

  // In-memory index: playlistId -> PlaylistCacheEntry
  Map<String, PlaylistCacheEntry>? _index;
  int _loadedGeneration = -1;

  PlaylistDetailCache({required AppCacheManager cacheManager})
      : _cacheManager = cacheManager;

  Future<Directory> get _cacheDir => _cacheManager.featureDir('playlists');

  /// Loads the index from disk if not already loaded.
  Future<void> _ensureIndex() async {
    if (_index != null && _loadedGeneration == _cacheManager.generation) {
      return;
    }
    _index = {};
    _loadedGeneration = _cacheManager.generation;

    try {
      final dir = await _cacheDir;
      final indexFile = File(
        '${dir.path}${Platform.pathSeparator}index.json',
      );
      if (!await indexFile.exists()) return;

      final raw = await indexFile.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;

      for (final e in map.entries) {
// ... [remaining code in source file] ...
```
