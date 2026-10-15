---
title: "diff_op.dart"
path: "lib/features/library/domain/services/diff_op.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, library]
lines: 44
incoming_dependencies: 2
outgoing_dependencies: 0
---

# diff_op.dart

> Source File: `[lib/features/library/domain/services/diff_op.dart](file:///c:/Users/Admin/Musify_MU/lib/features/library/domain/services/diff_op.dart)`
> Layer: `lib/features/library/domain/services`

## Executive Summary
`diff_op.dart` is an essential file in `lib/features/library/domain/services` providing definitions for `DiffOp`, `AddOp`, `RemOp`, `MovOp`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `playlist_diff_engine.dart` | `lib/features/library/domain/services` | [[04-Reference/lib/features/library/domain/services/playlist_diff_engine|playlist_diff_engine.dart]] |
| `playlist_mapper.dart` | `lib/features/library/data/mappers` | [[04-Reference/lib/features/library/data/mappers/playlist_mapper|playlist_mapper.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class DiffOp`
- **Archetype**: Core Component

#### `class AddOp`
- **Archetype**: Core Component
- **Extends**: `DiffOp`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `fromIndex` | `int` |
| `uris` | `List<String>` |
| `addFirst` | `bool` |
| `addLast` | `bool` |

#### `class RemOp`
- **Archetype**: Core Component
- **Extends**: `DiffOp`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `fromIndex` | `int` |
| `length` | `int` |

#### `class MovOp`
- **Archetype**: Core Component
- **Extends**: `DiffOp`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `fromIndex` | `int` |
| `toIndex` | `int` |
| `length` | `int` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
/// Domain-level diff operations. No protobuf dependency.
sealed class DiffOp {
  const DiffOp();
}

/// Insert tracks at a position (or at the start/end).
class AddOp extends DiffOp {
  final int fromIndex;
  final List<String> uris;
  final bool addFirst;
  final bool addLast;

  const AddOp({
    required this.fromIndex,
    required this.uris,
    this.addFirst = false,
    this.addLast = false,
  });
}

/// Remove [length] tracks starting at [fromIndex].
class RemOp extends DiffOp {
  final int fromIndex;
  final int length;

  const RemOp({required this.fromIndex, required this.length});
}

/// Move [length] tracks from [fromIndex] to [toIndex].
///
/// [toIndex] uses Spotify's OT convention: it refers to the position
/// in the **original** array (before removal). When fromIndex < toIndex,
/// the actual insertion point after removal is `toIndex - length`.
class MovOp extends DiffOp {
  final int fromIndex;
  final int toIndex;
  final int length;

  const MovOp({
    required this.fromIndex,
    required this.toIndex,
    required this.length,
  });
}
```
