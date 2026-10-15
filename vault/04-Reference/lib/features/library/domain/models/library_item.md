---
title: "library_item.dart"
path: "lib/features/library/domain/models/library_item.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, library]
lines: 64
incoming_dependencies: 5
outgoing_dependencies: 0
---

# library_item.dart

> Source File: `[lib/features/library/domain/models/library_item.dart](file:///c:/Users/Admin/Musify_MU/lib/features/library/domain/models/library_item.dart)`
> Layer: `lib/features/library/domain/models`

## Executive Summary
`library_item.dart` is an essential file in `lib/features/library/domain/models` providing definitions for `LibraryItem`.
**Primary Architecture Role**: Domain Model / Entity

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `playlist_detail_bloc.dart` | `lib/features/playlist_detail/application` | [[04-Reference/lib/features/playlist_detail/application/playlist_detail_bloc|playlist_detail_bloc.dart]] |
| `playlist_detail_screen.dart` | `lib/features/playlist_detail/presentation` | [[04-Reference/lib/features/playlist_detail/presentation/playlist_detail_screen|playlist_detail_screen.dart]] |
| `library_view_data.dart` | `lib/features/library/domain/models` | [[04-Reference/lib/features/library/domain/models/library_view_data|library_view_data.dart]] |
| `library_mapper.dart` | `lib/features/library/data/mappers` | [[04-Reference/lib/features/library/data/mappers/library_mapper|library_mapper.dart]] |
| `library_decorator.dart` | `lib/features/library/data/repository` | [[04-Reference/lib/features/library/data/repository/library_decorator|library_decorator.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class LibraryItem`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `uri` | `String` |
| `type` | `String` |
| `name` | `String` |
| `imageUrl` | `String?` |
| `ownerName` | `String?` |
| `addedAt` | `DateTime?` |
| `isPinned` | `bool` |
| `trackCount` | `int?` |
| `mosaicImageUrls` | `List<String>` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `copyWith` | `LibraryItem` | `{ String? name, String? imageUrl, String? owner...` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:equatable/equatable.dart';

/// A single item in the user's library (playlist, artist, show, album).
class LibraryItem extends Equatable {
  final String uri;
  final String type;
  final String name;
  final String? imageUrl;
  final String? ownerName;
  final DateTime? addedAt;
  final bool isPinned;
  final int? trackCount;

  /// First 4 unique album art URLs for client-side mosaic rendering.
  /// Non-empty only for playlists without a custom cover.
  final List<String> mosaicImageUrls;

  const LibraryItem({
    required this.uri,
    required this.type,
    required this.name,
    this.imageUrl,
    this.ownerName,
    this.addedAt,
    this.isPinned = false,
    this.trackCount,
    this.mosaicImageUrls = const [],
  });

  @override
  List<Object?> get props => [
        uri,
        type,
        name,
        imageUrl,
        ownerName,
        addedAt,
        isPinned,
        trackCount,
        mosaicImageUrls,
      ];

  /// Creates a copy with updated fields.
  LibraryItem copyWith({
    String? name,
// ... [remaining code in source file] ...
```
