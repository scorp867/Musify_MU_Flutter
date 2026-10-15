---
title: "prepare_play_options.dart"
path: "lib/features/player/domain/models/prepare_play_options.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player, command, playback]
lines: 57
incoming_dependencies: 1
outgoing_dependencies: 1
---

# prepare_play_options.dart

> Source File: `[lib/features/player/domain/models/prepare_play_options.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/domain/models/prepare_play_options.dart)`
> Layer: `lib/features/player/domain/models`

## Executive Summary
`prepare_play_options.dart` implements Spotify's `com.spotify.player.model.command.options.PreparePlayOptions`. It encapsulates initialization parameters when preparing a playback queue, including seek position, skip-to targets, prefetch configuration, and initial pause flags.

**Primary Architecture Role**: Domain Model / Command Options

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `prefetch_level.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/prefetch_level|prefetch_level.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `queue_replication_test.dart` | `test/features/player` | [[04-Reference/test/features/player/queue_replication_test|queue_replication_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class PreparePlayOptions extends Equatable`
- **Archetype**: Domain Model / Command Options
- **Extends**: `Equatable`

**Key Fields & Properties:**
| Field Name | Type | Description |
|------------|------|-------------|
| `prefetchLevel` | `PrefetchLevel` | Buffering strategy (`none` vs `media`) |
| `initiallyPaused` | `bool` | Whether playback starts in paused state |
| `alwaysPlaySomething` | `bool` | Fallback flag ensuring playback never stalls empty |
| `seekTo` | `Duration?` | Initial seek offset |
| `skipToTrackUri` | `String?` | Explicit track URI to activate first |
| `skipToTrackUid` | `String?` | Explicit track UID instance identifier |
| `configurationOverride` | `Map<String, String>` | Dynamic player parameters |
| `empty` | `PreparePlayOptions` | Default unconfigured options constant |

**Methods & Handlers:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `copyWith` | `PreparePlayOptions` | Field override parameters | Immutability copy helper |

## State & Data Flow Analysis
- Injected during queue initialization to configure `PlaybackQueueManager` and playback services.

## Implementation Highlight
```dart
import 'package:equatable/equatable.dart';
import 'prefetch_level.dart';

/// 1:1 with Spotify's com.spotify.player.model.command.options.PreparePlayOptions
class PreparePlayOptions extends Equatable {
  final PrefetchLevel prefetchLevel;
  final bool initiallyPaused;
  final bool alwaysPlaySomething;
  final Duration? seekTo;
  final String? skipToTrackUri;
  final String? skipToTrackUid;
  final Map<String, String> configurationOverride;
// ...
```
