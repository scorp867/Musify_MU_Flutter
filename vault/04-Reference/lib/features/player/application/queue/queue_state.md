---
title: "queue_state.dart"
path: "lib/features/player/application/queue/queue_state.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 60
incoming_dependencies: 1
outgoing_dependencies: 2
---

# queue_state.dart

> Source File: `[lib/features/player/application/queue/queue_state.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/application/queue/queue_state.dart)`
> Layer: `lib/features/player/application/queue`

## Executive Summary
`queue_state.dart` is an essential file in `lib/features/player/application/queue` providing definitions for `QueueState`.
**Primary Architecture Role**: Domain Model / Entity

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `context_track.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/context_track|context_track.dart]] |
| `player_queue.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/player_queue|player_queue.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `queue_sheet_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/queue_sheet_screen|queue_sheet_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class QueueState`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `queue` | `PlayerQueue` |
| `currentIndex` | `int` |
| `totalTracks` | `int` |
| `isPlaying` | `bool` |
| `shuffleMode` | `AudioServiceShuffleMode` |
| `repeatMode` | `AudioServiceRepeatMode` |
| `lastAddedUid` | `String?` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `copyWith` | `QueueState` | `{ PlayerQueue? queue, int? currentIndex, int? t...` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';

class QueueState extends Equatable {
  final PlayerQueue queue;
  final int currentIndex;
  final int totalTracks;
  final bool isPlaying;
  final AudioServiceShuffleMode shuffleMode;
  final AudioServiceRepeatMode repeatMode;

  const QueueState({
    this.queue = const PlayerQueue(revision: '0'),
    this.currentIndex = -1,
    this.totalTracks = 0,
    this.isPlaying = true,
    this.shuffleMode = AudioServiceShuffleMode.none,
    this.repeatMode = AudioServiceRepeatMode.none,
  });

  ContextTrack? get nowPlaying => queue.currentTrack;
  List<ContextTrack> get userQueue => queue.userQueue;
  List<ContextTrack> get contextTracks => queue.contextTracks;
  List<ContextTrack> get nextTracks => queue.nextTracks;

  bool get hasQueue => nowPlaying != null;
  bool get hasUpcoming => nextTracks.isNotEmpty;
  bool get hasUserQueue => userQueue.isNotEmpty;
  bool get hasContextTracks => contextTracks.isNotEmpty;

  QueueState copyWith({
    PlayerQueue? queue,
    int? currentIndex,
    int? totalTracks,
    bool? isPlaying,
    AudioServiceShuffleMode? shuffleMode,
    AudioServiceRepeatMode? repeatMode,
  }) {
    return QueueState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      totalTracks: totalTracks ?? this.totalTracks,
      isPlaying: isPlaying ?? this.isPlaying,
// ... [remaining code in source file] ...
```
