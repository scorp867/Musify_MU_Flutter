---
title: "playlist_diff_engine.dart"
path: "lib/features/library/domain/services/playlist_diff_engine.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, library, diff, ot, operational-transformation]
lines: 70
incoming_dependencies: 2
outgoing_dependencies: 1
---

# playlist_diff_engine.dart

> Source File: `[lib/features/library/domain/services/playlist_diff_engine.dart](file:///c:/Users/Admin/Musify_MU/lib/features/library/domain/services/playlist_diff_engine.dart)`
> Layer: `lib/features/library/domain/services` (Sequential OT Diff Engine)

## Executive Summary
`playlist_diff_engine.dart` implements `PlaylistDiffEngine`, a pure algorithmic engine that applies Spotify's sequential Operational Transformation (OT) diff operations (`AddOp`, `RemOp`, `MovOp`) to playlist track URI lists. It has zero external dependencies and precisely models Spotify's server-side array indexing conventions.

**Primary Architecture Role**: Sequential Operational Transformation (OT) Playlist Delta Engine

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `diff_op.dart` | `lib/features/library/domain/services` | [[04-Reference/lib/features/library/domain/services/diff_op|diff_op.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `library_repository_impl.dart` | `lib/features/library/data/repository` | [[04-Reference/lib/features/library/data/repository/library_repository_impl|library_repository_impl.dart]] |
| `playlist_detail_cache.dart` | `lib/features/library/data/cache` | [[04-Reference/lib/features/library/data/cache/playlist_detail_cache|playlist_detail_cache.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class PlaylistDiffEngine`

**Public API:**
- `static List<String> apply(List<String> tracks, List<DiffOp> ops)`:
  Applies an ordered sequence of OT operations to a clone of `tracks` and returns the resulting list.

**Internal Operation Handlers:**
- `static void _applyAdd(List<String> tracks, AddOp op)`: Inserts URIs with support for `addLast`, `addFirst`, or indexed position.
- `static void _applyRem(List<String> tracks, RemOp op)`: Removes a contiguous range of URIs starting at `fromIndex`.
- `static void _applyMov(List<String> tracks, MovOp op)`: Handles track reordering.

## State & Data Flow Analysis
- **Sequential Index Transformation Nuance**:
  Spotify's `MovOp.toIndex` references the position in the list **before** the item is removed. If `fromIndex < toIndex`, removing the items before `toIndex` shifts all subsequent elements left by `moveCount`.
  ```dart
  int target;
  if (start < op.toIndex) {
    target = (op.toIndex - moveCount).clamp(0, tracks.length);
  } else {
    target = op.toIndex.clamp(0, tracks.length);
  }
  tracks.insertAll(target, moved);
  ```
  Accurately accounting for this offset is critical to prevent playlist tracks from landing at index `+1` or `-1` during sync.

## Implementation Highlight
```dart
class PlaylistDiffEngine {
  const PlaylistDiffEngine._();

  static List<String> apply(List<String> tracks, List<DiffOp> ops) {
    final result = List<String>.from(tracks);

    for (final op in ops) {
      switch (op) {
        case AddOp():
          _applyAdd(result, op);
        case RemOp():
          _applyRem(result, op);
        case MovOp():
          _applyMov(result, op);
      }
    }

    return result;
  }
}
```
