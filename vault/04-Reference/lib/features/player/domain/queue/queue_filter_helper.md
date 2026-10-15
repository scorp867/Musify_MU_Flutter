---
title: "queue_filter_helper.dart"
path: "lib/features/player/domain/queue/queue_filter_helper.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player, queue, filter, helper]
lines: 43
incoming_dependencies: 4
outgoing_dependencies: 2
---

# queue_filter_helper.dart

> Source File: `[lib/features/player/domain/queue/queue_filter_helper.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/domain/queue/queue_filter_helper.dart)`
> Layer: `lib/features/player/domain/queue`

## Executive Summary
`queue_filter_helper.dart` provides pure static utility algorithms replicating Spotify Android's `p.hxl0` and `p.s5j` queue filtering routines. It partitions user-queued tracks (`is_queued == true`) from ambient context tracks (`is_queued == false`), extracts visible tracks while respecting bans/hiding, and stamps `isQueued` state and provider tags into metadata.

**Primary Architecture Role**: Domain Service / Queue Filter Engine

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `context_track.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/context_track|context_track.dart]] |
| `player_queue.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/player_queue|player_queue.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `queue_mutator.dart` | `lib/features/player/domain/queue` | [[04-Reference/lib/features/player/domain/queue/queue_mutator|queue_mutator.dart]] |
| `queue_bloc.dart` | `lib/features/player/application/queue` | [[04-Reference/lib/features/player/application/queue/queue_bloc|queue_bloc.dart]] |
| `queue_sheet_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/queue_sheet_screen|queue_sheet_screen.dart]] |
| `queue_replication_test.dart` | `test/features/player` | [[04-Reference/test/features/player/queue_replication_test|queue_replication_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `abstract class QueueFilterHelper`
- **Archetype**: Static Utility / Pure Domain Service

**Methods & Handlers:**
| Method | Return Type | Parameters | Spotify Parity & Description |
|--------|-------------|------------|------------------------------|
| `getUserQueue` | `List<ContextTrack>` | `PlayerQueue playerQueue` | `hxl0.d(playerQueue)`: Filters tracks where `isQueued == true` |
| `getContextQueue` | `List<ContextTrack>` | `PlayerQueue playerQueue` | `hxl0.b(playerQueue)`: Filters tracks where `!isQueued` |
| `getVisibleUpcomingTracks` | `List<ContextTrack>` | `PlayerQueue playerQueue` | `s5j.a`: Filters out banned (`collection.is_banned`) and hidden tracks |
| `setIsQueued` | `ContextTrack` | `ContextTrack contextTrack, bool isQueued` | `hxl0.e`: Returns track copy with `isQueued` and `provider` ('queue'/'context') set |

## State & Data Flow Analysis
- Pure stateless functions with zero side effects. Used across domain transformations, BLoC state reconciliation, and presentation filtering in `QueueSheetScreen`.

## Implementation Highlight
```dart
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';

/// 1:1 with Spotify's p.hxl0 and p.s5j queue filtering and metadata management
abstract class QueueFilterHelper {
  /// 1:1 with hxl0.d(playerQueue): Filters tracks where is_queued == true
  static List<ContextTrack> getUserQueue(PlayerQueue playerQueue) {
    return playerQueue.nextTracks
        .where((track) => track.isQueued)
        .toList();
  }

  /// 1:1 with hxl0.b(playerQueue): Filters tracks where is_queued != true
  static List<ContextTrack> getContextQueue(PlayerQueue playerQueue) {
    return playerQueue.nextTracks
        .where((track) => !track.isQueued)
        .toList();
  }
// ...
```
