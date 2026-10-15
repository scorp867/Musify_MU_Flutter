---
title: "prefetch_level.dart"
path: "lib/features/player/domain/models/prefetch_level.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player, prefetch, audio-engine]
lines: 6
incoming_dependencies: 3
outgoing_dependencies: 0
---

# prefetch_level.dart

> Source File: `[lib/features/player/domain/models/prefetch_level.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/domain/models/prefetch_level.dart)`
> Layer: `lib/features/player/domain/models`

## Executive Summary
`prefetch_level.dart` defines the `PrefetchLevel` enumeration matching Spotify's `com.spotify.player.model.command.options.PrefetchLevel`. It controls whether upcoming media sources are proactively buffered ahead of time into Slot 1 of the audio player.

**Primary Architecture Role**: Domain Enum / Configuration

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- Leaf component: No external or internal dependencies.

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `prepare_play_options.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/prepare_play_options|prepare_play_options.dart]] |
| `playback_queue_manager.dart` | `lib/core/audio` | [[04-Reference/lib/core/audio/playback_queue_manager|playback_queue_manager.dart]] |
| `queue_replication_test.dart` | `test/features/player` | [[04-Reference/test/features/player/queue_replication_test|queue_replication_test.dart]] |

## Declarations & API Breakdown

### Enums
#### `enum PrefetchLevel`
- `none`: Proactive media source preloading is disabled.
- `media`: Proactively preloads the next immediate audio track into Slot 1 of the playback queue pipeline for 0ms gapless transition.

## State & Data Flow Analysis
- Consumed by `PlaybackQueueManager` to toggle and populate Slot 1 in `ConcatenatingAudioSource`.

## Implementation Highlight
```dart
/// 1:1 with Spotify's com.spotify.player.model.command.options.PrefetchLevel
enum PrefetchLevel {
  none,
  media,
}
```
