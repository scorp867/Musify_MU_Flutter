---
title: "local_music_state.dart"
path: "lib/features/local_music/presentation/bloc/local_music_state.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, local_music]
lines: 35
incoming_dependencies: 3
outgoing_dependencies: 1
---

# local_music_state.dart

> Source File: `[lib/features/local_music/presentation/bloc/local_music_state.dart](file:///c:/Users/Admin/Musify_MU/lib/features/local_music/presentation/bloc/local_music_state.dart)`
> Layer: `lib/features/local_music/presentation/bloc`

## Executive Summary
`local_music_state.dart` is an essential file in `lib/features/local_music/presentation/bloc` providing definitions for `LocalMusicState`, `LocalMusicInitial`, `LocalMusicLoading`, `LocalMusicLoaded`, `LocalMusicError`.
**Primary Architecture Role**: Core Component, Domain Model / Entity

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `domain_track.dart` | `lib/features/local_music/domain/entities` | [[04-Reference/lib/features/local_music/domain/entities/domain_track|domain_track.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `local_music_screen.dart` | `lib/features/local_music/presentation/screens` | [[04-Reference/lib/features/local_music/presentation/screens/local_music_screen|local_music_screen.dart]] |
| `offline_library_view.dart` | `lib/features/library/presentation` | [[04-Reference/lib/features/library/presentation/offline_library_view|offline_library_view.dart]] |
| `offline_browse_view.dart` | `lib/features/browse/presentation` | [[04-Reference/lib/features/browse/presentation/offline_browse_view|offline_browse_view.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class LocalMusicState`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

#### `class LocalMusicInitial`
- **Archetype**: Core Component
- **Extends**: `LocalMusicState`

#### `class LocalMusicLoading`
- **Archetype**: Core Component
- **Extends**: `LocalMusicState`

#### `class LocalMusicLoaded`
- **Archetype**: Core Component
- **Extends**: `LocalMusicState`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `tracks` | `List<DomainTrack>` |

#### `class LocalMusicError`
- **Archetype**: Core Component
- **Extends**: `LocalMusicState`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `message` | `String` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:equatable/equatable.dart';
import 'package:musify_mu/features/local_music/domain/entities/domain_track.dart';

abstract class LocalMusicState extends Equatable {
  const LocalMusicState();

  @override
  List<Object?> get props => [];
}

class LocalMusicInitial extends LocalMusicState {
  const LocalMusicInitial();
}

class LocalMusicLoading extends LocalMusicState {
  const LocalMusicLoading();
}

class LocalMusicLoaded extends LocalMusicState {
  final List<DomainTrack> tracks;

  const LocalMusicLoaded(this.tracks);

  @override
  List<Object?> get props => [tracks];
}

class LocalMusicError extends LocalMusicState {
  final String message;

  const LocalMusicError(this.message);

  @override
  List<Object?> get props => [message];
}
```
