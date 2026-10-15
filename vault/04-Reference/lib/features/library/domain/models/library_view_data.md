---
title: "library_view_data.dart"
path: "lib/features/library/domain/models/library_view_data.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, library]
lines: 39
incoming_dependencies: 4
outgoing_dependencies: 1
---

# library_view_data.dart

> Source File: `[lib/features/library/domain/models/library_view_data.dart](file:///c:/Users/Admin/Musify_MU/lib/features/library/domain/models/library_view_data.dart)`
> Layer: `lib/features/library/domain/models`

## Executive Summary
`library_view_data.dart` is an essential file in `lib/features/library/domain/models` providing definitions for `LibraryViewData`.
**Primary Architecture Role**: Domain Model / Entity

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `library_item.dart` | `lib/features/library/domain/models` | [[04-Reference/lib/features/library/domain/models/library_item|library_item.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `library_view.dart` | `lib/features/library/presentation` | [[04-Reference/lib/features/library/presentation/library_view|library_view.dart]] |
| `library_repository.dart` | `lib/features/library/domain/repositories` | [[04-Reference/lib/features/library/domain/repositories/library_repository|library_repository.dart]] |
| `load_library.dart` | `lib/features/library/domain/usecases` | [[04-Reference/lib/features/library/domain/usecases/load_library|load_library.dart]] |
| `library_repository_impl.dart` | `lib/features/library/data/repository` | [[04-Reference/lib/features/library/data/repository/library_repository_impl|library_repository_impl.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class LibraryViewData`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `items` | `List<LibraryItem>` |
| `pinnedUris` | `Set<String>` |
| `sorted` | `final` |
| `aTime` | `final` |
| `bTime` | `final` |
| `sorted` | `return` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `filterByType` | `List<LibraryItem>` | `String type` |
| `where` | `dynamic` | `(item` |
| `sortedByRecents` | `List<LibraryItem>` | `(none)` |
| `sort` | `dynamic` | `(a, b` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:equatable/equatable.dart';

export 'library_item.dart';

import 'package:musify_mu/features/library/domain/models/library_item.dart';

/// Aggregated library data ready for the UI.
class LibraryViewData extends Equatable {
  final List<LibraryItem> items;
  final Set<String> pinnedUris;

  const LibraryViewData({
    required this.items,
    this.pinnedUris = const {},
  });

  @override
  List<Object?> get props => [items, pinnedUris];

  /// Items filtered by type.
  List<LibraryItem> filterByType(String type) {
    return items.where((item) => item.type == type).toList();
  }

  /// Items sorted by recency (added_at descending), with pinned items first.
  List<LibraryItem> sortedByRecents() {
    final sorted = List<LibraryItem>.from(items);
    sorted.sort((a, b) {
      // Pinned items first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      // Then by added_at descending
      final aTime = a.addedAt ?? DateTime(1970);
      final bTime = b.addedAt ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });
    return sorted;
  }
}
```
