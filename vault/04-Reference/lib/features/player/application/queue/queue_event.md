---
title: "queue_event.dart"
path: "lib/features/player/application/queue/queue_event.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 67
incoming_dependencies: 1
outgoing_dependencies: 1
---

# queue_event.dart

> Source File: `[lib/features/player/application/queue/queue_event.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/application/queue/queue_event.dart)`
> Layer: `lib/features/player/application/queue`

## Executive Summary
`queue_event.dart` is an essential file in `lib/features/player/application/queue` providing definitions for `QueueEvent`, `QueueStarted`, `QueueTrackTapped`, `QueueReordered`, `QueueTrackRemoved`, `QueueTrackAdded`, `QueueCleared`, `QueueShuffleToggled`, `QueueRepeatToggled`, `QueuePlayPauseToggled`, and `QueueNextPageRequested`.
**Primary Architecture Role**: Core Component, Domain Model / Entity

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `context_track.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/context_track|context_track.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `queue_sheet_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/queue_sheet_screen|queue_sheet_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class QueueEvent`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

#### `class QueueStarted`
- **Archetype**: Core Component
- **Extends**: `QueueEvent`

#### `class QueueTrackTapped`
- **Archetype**: Core Component
- **Extends**: `QueueEvent`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `track` | `ContextTrack` |
| `absoluteIndex` | `int` |

#### `class QueueReordered`
- **Archetype**: Core Component
- **Extends**: `QueueEvent`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `oldIndex` | `int` |
| `newIndex` | `int` |

#### `class QueueTrackRemoved`
- **Archetype**: Core Component
- **Extends**: `QueueEvent`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `uid` | `String` |

#### `class QueueTrackAdded`
- **Archetype**: Core Component
- **Extends**: `QueueEvent`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `track` | `ContextTrack` |

#### `class QueueCleared`
- **Archetype**: Core Component
- **Extends**: `QueueEvent`

#### `class QueueShuffleToggled`
- **Archetype**: Core Component
- **Extends**: `QueueEvent`

#### `class QueueRepeatToggled`
- **Archetype**: Core Component
- **Extends**: `QueueEvent`

#### `class QueuePlayPauseToggled`
- **Archetype**: Core Component
- **Extends**: `QueueEvent`

#### `class QueueNextPageRequested`
- **Archetype**: Core Component
- **Extends**: `QueueEvent`

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:equatable/equatable.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';

abstract class QueueEvent extends Equatable {
  const QueueEvent();

  @override
  List<Object?> get props => [];
}

class QueueStarted extends QueueEvent {
  const QueueStarted();
}

class QueueTrackTapped extends QueueEvent {
  final ContextTrack track;
  final int absoluteIndex;

  const QueueTrackTapped({required this.track, required this.absoluteIndex});

  @override
  List<Object?> get props => [track.uid, absoluteIndex];
}

class QueueReordered extends QueueEvent {
  final int oldIndex;
  final int newIndex;

  const QueueReordered(this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class QueueTrackRemoved extends QueueEvent {
  final String uid;

  const QueueTrackRemoved(this.uid);

  @override
  List<Object?> get props => [uid];
}

class QueueTrackAdded extends QueueEvent {
  final ContextTrack track;
// ... [remaining code in source file] ...
```
