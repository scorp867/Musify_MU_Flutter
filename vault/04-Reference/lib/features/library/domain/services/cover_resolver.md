---
title: "cover_resolver.dart"
path: "lib/features/library/domain/services/cover_resolver.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, library]
lines: 103
incoming_dependencies: 3
outgoing_dependencies: 0
---

# cover_resolver.dart

> Source File: `[lib/features/library/domain/services/cover_resolver.dart](file:///c:/Users/Admin/Musify_MU/lib/features/library/domain/services/cover_resolver.dart)`
> Layer: `lib/features/library/domain/services`

## Executive Summary
`cover_resolver.dart` is an essential file in `lib/features/library/domain/services` providing definitions for `CoverResolution`, `DiffCoverChange`, `CoverSet`, `CoverRemoved`, `CoverResolver`.
**Primary Architecture Role**: Parser / Data Mapper, Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `playlist_mapper.dart` | `lib/features/library/data/mappers` | [[04-Reference/lib/features/library/data/mappers/playlist_mapper|playlist_mapper.dart]] |
| `library_repository_impl.dart` | `lib/features/library/data/repository` | [[04-Reference/lib/features/library/data/repository/library_repository_impl|library_repository_impl.dart]] |
| `cover_resolver_test.dart` | `test/features/library` | [[04-Reference/test/features/library/cover_resolver_test|cover_resolver_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class CoverResolution`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `coverUrl` | `String?` |
| `isCustomCover` | `bool` |
| `mosaicImageUrls` | `List<String>` |

#### `class DiffCoverChange`
- **Archetype**: Core Component

#### `class CoverSet`
- **Archetype**: Core Component
- **Extends**: `DiffCoverChange`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `url` | `String` |

#### `class CoverRemoved`
- **Archetype**: Core Component
- **Extends**: `DiffCoverChange`

#### `class CoverResolver`
- **Archetype**: Parser / Data Mapper

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `resolve` | `CoverResolution` | `{ required bool wasCustomCover, required String...` |
| `resolveFromFull` | `CoverResolution` | `{ required String? customCoverUrl, required Lis...` |
| `_buildCover` | `CoverResolution` | `List<String> urls` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
/// Result of cover resolution for a playlist.
class CoverResolution {
  final String? coverUrl;
  final bool isCustomCover;
  final List<String> mosaicImageUrls;

  const CoverResolution({
    this.coverUrl,
    this.isCustomCover = false,
    this.mosaicImageUrls = const [],
  });
}

/// What the diff did to the cover (if anything).
sealed class DiffCoverChange {
  const DiffCoverChange();
}

/// Diff explicitly set a new custom cover URL.
class CoverSet extends DiffCoverChange {
  final String url;
  const CoverSet(this.url);
}

/// Diff explicitly removed the custom cover (no_value contained LIST_PICTURE).
class CoverRemoved extends DiffCoverChange {
  const CoverRemoved();
}

/// Determines playlist cover from diff changes and cached state.
/// Pure logic, zero external dependencies.
class CoverResolver {
  const CoverResolver._();

  /// Given the previous cover state and diff changes, determines
  /// whether to keep the custom cover or resolve from tracks.
  ///
  /// Matching Spotify Android:
  /// - If the playlist has >= 4 unique album artworks, builds a 2x2 mosaic.
  /// - If the playlist has 1..3 unique artworks, takes the first track's
  ///   album art as a single cover (mosaic is not generated).
  /// - If the playlist has 0 tracks, cover is null (shows placeholder).
  static CoverResolution resolve({
    required bool wasCustomCover,
    required String? cachedCoverUrl,
// ... [remaining code in source file] ...
```
