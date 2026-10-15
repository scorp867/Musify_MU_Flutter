---
title: "player_queue.dart"
path: "lib/features/player/domain/models/player_queue.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player, queue, domain-model]
lines: 101
incoming_dependencies: 7
outgoing_dependencies: 1
---

# player_queue.dart

> Source File: `[lib/features/player/domain/models/player_queue.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/domain/models/player_queue.dart)`
> Layer: `lib/features/player/domain/models`

## Executive Summary
`player_queue.dart` defines `PlayerQueue` 1:1 with Spotify Android's `com.spotify.player.model.PlayerQueue`. It contains the currently active track (`track`), a single linear `nextTracks` list acting as Spotify's single source of truth, play history (`prevTracks`), and a monotonic `revision` string. User queue and context queue are computed views derived via `isQueued` metadata flags.

**Primary Architecture Role**: Domain Model / Aggregate Entity

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `context_track.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/context_track|context_track.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `queue_bloc.dart` | `lib/features/player/application/queue` | [[04-Reference/lib/features/player/application/queue/queue_bloc|queue_bloc.dart]] |
| `queue_state.dart` | `lib/features/player/application/queue` | [[04-Reference/lib/features/player/application/queue/queue_state|queue_state.dart]] |
| `queue_filter_helper.dart` | `lib/features/player/domain/queue` | [[04-Reference/lib/features/player/domain/queue/queue_filter_helper|queue_filter_helper.dart]] |
| `queue_mutator.dart` | `lib/features/player/domain/queue` | [[04-Reference/lib/features/player/domain/queue/queue_mutator|queue_mutator.dart]] |
| `set_queue_command.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/set_queue_command|set_queue_command.dart]] |
| `local_context_resolver.dart` | `lib/features/local_music/domain` | [[04-Reference/lib/features/local_music/domain/local_context_resolver|local_context_resolver.dart]] |
| `queue_replication_test.dart` | `test/features/player` | [[04-Reference/test/features/player/queue_replication_test|queue_replication_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class PlayerQueue extends Equatable`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

**Key Fields & Properties:**
| Field Name | Type | Description |
|------------|------|-------------|
| `revision` | `String` | Monotonic queue state revision string |
| `track` | `ContextTrack?` | Active playing track playhead |
| `nextTracks` | `List<ContextTrack>` | Single linear upcoming track list (Spotify single source of truth) |
| `prevTracks` | `List<ContextTrack>` | Recently played track history |

**Computed Getters:**
| Getter | Return Type | Description |
|--------|-------------|-------------|
| `currentTrack` | `ContextTrack?` | Direct accessor alias to `track` |
| `userQueue` | `List<ContextTrack>` | `nextTracks.where((t) => t.isQueued && !t.isDelimiter)` |
| `contextTracks` | `List<ContextTrack>` | Ambient upcoming tracks taking non-queued items until delimiter |
| `isEmpty` | `bool` | True if track is null and nextTracks is empty |
| `hasUserQueue` | `bool` | `userQueue.isNotEmpty` |
| `hasContextTracks` | `bool` | `contextTracks.isNotEmpty` |

**Constructors & Methods:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `PlayerQueue.partitioned` | `PlayerQueue` | `{required String revision, ContextTrack? currentTrack, List<ContextTrack> userQueue, List<ContextTrack> contextTracks, List<ContextTrack> prevTracks}` | Compatibility factory stamping partitions into `nextTracks` |
| `copyWith` | `PlayerQueue` | `{String? revision, ContextTrack? track, ContextTrack? currentTrack, List<ContextTrack>? nextTracks, List<ContextTrack>? prevTracks, List<ContextTrack>? userQueue, List<ContextTrack>? contextTracks}` | Immutability copy helper supporting both unified and partitioned signatures |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background isolate.
- **Data Flow**: Central domain model representing playback queue state. All modifications increment `revision` and are managed through `QueueMutator`.

## Implementation Highlight
```dart
import 'package:equatable/equatable.dart';
import 'context_track.dart';

/// 1:1 with Spotify's com.spotify.player.model.PlayerQueue
class PlayerQueue extends Equatable {
  final String revision;
  final ContextTrack? track;
  final List<ContextTrack> nextTracks; // SINGLE linear list (Spotify core source of truth)
  final List<ContextTrack> prevTracks; // History of recently played tracks

  const PlayerQueue({
    required this.revision,
    this.track,
    this.nextTracks = const [],
    this.prevTracks = const [],
  }) : super();
// ...
```
