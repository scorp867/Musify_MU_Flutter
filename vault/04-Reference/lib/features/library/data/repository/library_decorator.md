---
title: "library_decorator.dart"
path: "lib/features/library/data/repository/library_decorator.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, library]
lines: 229
incoming_dependencies: 1
outgoing_dependencies: 6
---

# library_decorator.dart

> Source File: `[lib/features/library/data/repository/library_decorator.dart](file:///c:/Users/Admin/Musify_MU/lib/features/library/data/repository/library_decorator.dart)`
> Layer: `lib/features/library/data/repository`

## Executive Summary
`library_decorator.dart` is an essential file in `lib/features/library/data/repository` providing definitions for `LibraryDecorator`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `extended_metadata_service.dart` | `lib/core/media` | [[04-Reference/lib/core/media/extended_metadata_service|extended_metadata_service.dart]] |
| `library_cache.dart` | `lib/features/library/data/cache` | [[04-Reference/lib/features/library/data/cache/library_cache|library_cache.dart]] |
| `playlist_detail_cache.dart` | `lib/features/library/data/cache` | [[04-Reference/lib/features/library/data/cache/playlist_detail_cache|playlist_detail_cache.dart]] |
| `library_mapper.dart` | `lib/features/library/data/mappers` | [[04-Reference/lib/features/library/data/mappers/library_mapper|library_mapper.dart]] |
| `library_remote_source.dart` | `lib/features/library/data/sources` | [[04-Reference/lib/features/library/data/sources/library_remote_source|library_remote_source.dart]] |
| `library_item.dart` | `lib/features/library/domain/models` | [[04-Reference/lib/features/library/domain/models/library_item|library_item.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `library_repository_impl.dart` | `lib/features/library/data/repository` | [[04-Reference/lib/features/library/data/repository/library_repository_impl|library_repository_impl.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class LibraryDecorator`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_librarySource` | `LibraryRemoteSource` |
| `_libraryCache` | `LibraryCache` |
| `_playlistCache` | `PlaylistDetailCache` |
| `_metadataService` | `ExtendedMetadataService` |
| `result` | `final` |
| `item` | `final` |
| `parts` | `final` |
| `playlistId` | `final` |
| `entry` | `final` |
| `rootlistCover` | `final` |
| `cachedIsCustom` | `final` |
| `hasCustomCover` | `final` |
| `customUrl` | `final` |
| `mosaicUrls` | `var` |
| `coverUrl` | `var` |
| `trackArts` | `final` |
| `result` | `return` |
| `needsFetch` | `final` |
| `decorated` | `final` |
| `cached` | `final` |
| `uris` | `final` |
| `responseBytes` | `final` |
| `decorated` | `return` |
| `freshlyDecorated` | `final` |
| `decorationsToCache` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `decoratePlaylists` | `Future<List<LibraryItem>>` | `List<LibraryItem> playlists,` |
| `decorateArtists` | `Future<List<LibraryItem>>` | `List<LibraryItem> artists,` |
| `map` | `dynamic` | `(a` |
| `run` | `dynamic` | `(` |
| `getMosaicUrls` | `Future<List<String>>` | `List<String> trackUris` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Background Isolate execution: arguments and return payloads must strictly cross isolate boundaries.

## Implementation Highlight
```dart
import 'dart:developer' as dev;
import 'dart:isolate';

import 'package:musify_mu/core/media/extended_metadata_service.dart';
import 'package:musify_mu/features/library/data/cache/library_cache.dart';
import 'package:musify_mu/features/library/data/cache/playlist_detail_cache.dart';
import 'package:musify_mu/features/library/data/mappers/library_mapper.dart';
import 'package:musify_mu/features/library/data/sources/library_remote_source.dart';
import 'package:musify_mu/features/library/domain/models/library_item.dart';

/// Enriches raw library items with cached artwork, names, and track counts.
/// Handles both playlist decoration (from PlaylistDetailCache) and
/// artist decoration (from LibraryCache + extended-metadata network).
class LibraryDecorator {
  final LibraryRemoteSource _librarySource;
  final LibraryCache _libraryCache;
  final PlaylistDetailCache _playlistCache;
  final ExtendedMetadataService _metadataService;

  const LibraryDecorator({
    required LibraryRemoteSource librarySource,
    required LibraryCache libraryCache,
    required PlaylistDetailCache playlistCache,
    required ExtendedMetadataService metadataService,
  })  : _librarySource = librarySource,
        _libraryCache = libraryCache,
        _playlistCache = playlistCache,
        _metadataService = metadataService;

  /// Decorates playlists with cached metadata, track counts, and covers.
  Future<List<LibraryItem>> decoratePlaylists(
    List<LibraryItem> playlists,
  ) async {
    if (playlists.isEmpty) return playlists;

    final result = List<LibraryItem>.from(playlists);

    for (var i = 0; i < result.length; i++) {
      final item = result[i];
      final parts = item.uri.split(':');
      if (parts.length < 3 || parts[1] != 'playlist') continue;

      final playlistId = parts[2];
      final entry = await _playlistCache.get(playlistId);

// ... [remaining code in source file] ...
```
