---
title: "set_queue_command.dart"
path: "lib/features/player/domain/models/set_queue_command.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player, command, queue]
lines: 85
incoming_dependencies: 1
outgoing_dependencies: 3
---

# set_queue_command.dart

> Source File: `[lib/features/player/domain/models/set_queue_command.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/domain/models/set_queue_command.dart)`
> Layer: `lib/features/player/domain/models`

## Executive Summary
`set_queue_command.dart` provides `SetQueueCommand` and `SetQueueCommandBuilder`, replicating Spotify's `com.spotify.player.model.command.SetQueueCommand`. It models explicit queue replacement instructions containing revision identifiers, upcoming tracks, history, and command options.

**Primary Architecture Role**: Domain Command / Builder Pattern

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `command_options.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/command_options|command_options.dart]] |
| `context_track.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/context_track|context_track.dart]] |
| `player_queue.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/player_queue|player_queue.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `queue_replication_test.dart` | `test/features/player` | [[04-Reference/test/features/player/queue_replication_test|queue_replication_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class SetQueueCommand`
- **Archetype**: Domain Command

**Key Fields & Properties:**
| Field Name | Type | Description |
|------------|------|-------------|
| `queueRevision` | `String` | Monotonic revision target |
| `nextTracks` | `List<ContextTrack>` | Linear list of upcoming tracks |
| `prevTracks` | `List<ContextTrack>` | Historical played tracks |
| `options` | `CommandOptions` | Accompanying execution options |

**Methods & Handlers:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `builder` | `SetQueueCommandBuilder` | `PlayerQueue playerQueue` | Creates builder initialized from a `PlayerQueue` |
| `builderWithTracks` | `SetQueueCommandBuilder` | `String queueRevision, List<ContextTrack> nextTracks, List<ContextTrack> prevTracks` | Direct track-list builder factory |
| `create` | `SetQueueCommand` | `PlayerQueue playerQueue` | Shorthand instantiation from a `PlayerQueue` |
| `toJson` | `Map<String, dynamic>` | None | Serializes to map payload |

#### `class SetQueueCommandBuilder`
- Fluent builder allowing progressive construction of `SetQueueCommand` instances (`queueRevision()`, `nextTracks()`, `prevTracks()`, `options()`, `build()`).

## State & Data Flow Analysis
- Formatted by application logic or remote sync services to instruct the audio engine to atomically update its internal queue state.

## Implementation Highlight
```dart
import 'command_options.dart';
import 'context_track.dart';
import 'player_queue.dart';

/// 1:1 with com.spotify.player.model.command.SetQueueCommand
class SetQueueCommand {
  const SetQueueCommand({
    required this.queueRevision,
    required this.nextTracks,
    this.prevTracks = const [],
    this.options = CommandOptions.empty,
  });

  static SetQueueCommandBuilder builder(PlayerQueue playerQueue) {
    return SetQueueCommandBuilder()
      ..queueRevision(playerQueue.revision)
      ..nextTracks(playerQueue.nextTracks)
      ..prevTracks(playerQueue.prevTracks);
  }
// ...
```
