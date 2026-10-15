---
title: "queue_mutator.dart"
path: "lib/features/player/domain/queue/queue_mutator.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player, queue, mutator, operational-transformation]
lines: 262
incoming_dependencies: 2
outgoing_dependencies: 4
---

# queue_mutator.dart

> Source File: `[lib/features/player/domain/queue/queue_mutator.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/domain/queue/queue_mutator.dart)`
> Layer: `lib/features/player/domain/queue`

## Executive Summary
`queue_mutator.dart` implements the core mathematical and operational transformations of Spotify's playback queue engine (1:1 with Spotify's `p.zfy`, `p.lwp0`, `p.pml0`, and `p.gxl0`). It manages queue additions, play-next prepending, partition-aware drag-and-drop reordering, range removals, playhead advance transitions, and Cosmos page updates with monotonic revision incrementing.

**Primary Architecture Role**: Pure Operational Transformation / Queue State Algebra

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `context_page.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/context_page|context_page.dart]] |
| `context_track.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/context_track|context_track.dart]] |
| `player_queue.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/player_queue|player_queue.dart]] |
| `queue_filter_helper.dart` | `lib/features/player/domain/queue` | [[04-Reference/lib/features/player/domain/queue/queue_filter_helper|queue_filter_helper.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `queue_bloc.dart` | `lib/features/player/application/queue` | [[04-Reference/lib/features/player/application/queue/queue_bloc|queue_bloc.dart]] |
| `queue_replication_test.dart` | `test/features/player` | [[04-Reference/test/features/player/queue_replication_test|queue_replication_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `abstract class QueueMutator`
- **Archetype**: Static Domain Service / Pure Functional State Machine

**Core Queue Operations:**
| Method | Return Type | Parameters | Spotify Logic Reference |
|--------|-------------|------------|-------------------------|
| `addToQueue` | `PlayerQueue` | `PlayerQueue playerQueue, List<ContextTrack> tracksToAdd` | `zfy.java:681-715` (case 0): Appends to user queue, deduplicates by UID, increments revision |
| `playAsNext` | `PlayerQueue` | `PlayerQueue playerQueue, List<ContextTrack> tracksToPrepend` | `zfy.java:670-676` (case 1): Prepends to front of user queue with `isQueued = true` |
| `reorderTrack` | `PlayerQueue` | `PlayerQueue playerQueue, {required ContextTrack draggedTrack, required int targetVisibleIndex, required bool isTargetInUserQueue}` | `gxl0.java:29-75`: Calculates target partition slot, handles upward/downward shifts across user/context boundary |
| `reorder` | `PlayerQueue` | `PlayerQueue playerQueue, {required List<ContextTrack> userQueuePartition, required List<ContextTrack> contextQueuePartition}` | Batch partition reassembly |
| `removeTrack` | `PlayerQueue` | `PlayerQueue playerQueue, String uid` | Removes track by UID across either user queue or context queue |
| `removeRange` | `PlayerQueue` | `PlayerQueue playerQueue, int start, int count` | Truncates track range from single linear nextTracks |
| `clearUserQueue` | `PlayerQueue` | `PlayerQueue playerQueue` | Flushes all `isQueued == true` tracks, keeping context tracks intact |
| `advancePlayhead` | `PlayerQueue` | `PlayerQueue playerQueue` | Shifts next track to active playhead (`track`) and pushes old playhead into `prevTracks` |
| `updatePage` | `PlayerQueue` | `PlayerQueue playerQueue, ContextPage page` | Replaces delimiter or appends resolved page tracks |
| `appendPage` | `PlayerQueue` | `PlayerQueue playerQueue, ContextPage page` | Appends page tracks to active queue |

## State & Data Flow Analysis
- Replaces ad-hoc list manipulation across BLoCs and presentation widgets with pure, idempotent, unit-tested state transformations.
- Guarantee: Every queue mutation yields a new `PlayerQueue` with an incremented revision string (e.g. `'1' -> '2'`).

## Implementation Highlight
```dart
import 'package:musify_mu/features/player/domain/models/context_page.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';
import 'queue_filter_helper.dart';

/// 1:1 with Spotify's p.zfy (case 25), p.lwp0, and p.pml0 queue algebra
abstract class QueueMutator {
  static String _nextRevision(String currentRevision) {
    final parsed = int.tryParse(currentRevision) ?? 0;
    return (parsed + 1).toString();
  }

  static PlayerQueue addToQueue(
    PlayerQueue playerQueue,
    List<ContextTrack> tracksToAdd,
  ) {
    if (tracksToAdd.isEmpty) return playerQueue;
// ...
```
