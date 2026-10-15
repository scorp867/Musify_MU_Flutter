---
title: "local_music_bloc.dart"
path: "lib/features/local_music/presentation/bloc/local_music_bloc.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, local_music]
lines: 42
incoming_dependencies: 6
outgoing_dependencies: 3
---

# local_music_bloc.dart

> Source File: `[lib/features/local_music/presentation/bloc/local_music_bloc.dart](file:///c:/Users/Admin/Musify_MU/lib/features/local_music/presentation/bloc/local_music_bloc.dart)`
> Layer: `lib/features/local_music/presentation/bloc`

## Executive Summary
`local_music_bloc.dart` is an essential file in `lib/features/local_music/presentation/bloc` providing definitions for `LocalMusicBloc`.
**Primary Architecture Role**: BLoC State Machine

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `local_music_playback_synchronizer.dart` | `lib/features/local_music/application` | [[04-Reference/lib/features/local_music/application/local_music_playback_synchronizer|local_music_playback_synchronizer.dart]] |
| `domain_track.dart` | `lib/features/local_music/domain/entities` | [[04-Reference/lib/features/local_music/domain/entities/domain_track|domain_track.dart]] |
| `local_music_repository.dart` | `lib/features/local_music/domain/repositories` | [[04-Reference/lib/features/local_music/domain/repositories/local_music_repository|local_music_repository.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `main.dart` | `lib` | [[04-Reference/lib/main|main.dart]] |
| `app.dart` | `lib/app` | [[04-Reference/lib/app/app|app.dart]] |
| `local_music_screen.dart` | `lib/features/local_music/presentation/screens` | [[04-Reference/lib/features/local_music/presentation/screens/local_music_screen|local_music_screen.dart]] |
| `offline_library_view.dart` | `lib/features/library/presentation` | [[04-Reference/lib/features/library/presentation/offline_library_view|offline_library_view.dart]] |
| `offline_browse_view.dart` | `lib/features/browse/presentation` | [[04-Reference/lib/features/browse/presentation/offline_browse_view|offline_browse_view.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class LocalMusicBloc`
- **Archetype**: BLoC State Machine
- **Extends**: `Bloc<LocalMusicEvent, LocalMusicState>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `repository` | `LocalMusicRepository` |
| `playbackSynchronizer` | `LocalMusicPlaybackSynchronizer?` |
| `synchronizer` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `_onLoadLocalTracks` | `Future<void>` | `LoadLocalTracks event, Emitter<LocalMusicState>...` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/local_music/application/local_music_playback_synchronizer.dart';
import 'package:musify_mu/features/local_music/domain/entities/domain_track.dart';
import 'package:musify_mu/features/local_music/domain/repositories/local_music_repository.dart';

import 'local_music_event.dart';
import 'local_music_state.dart';

class LocalMusicBloc extends Bloc<LocalMusicEvent, LocalMusicState> {
  final LocalMusicRepository repository;
  final LocalMusicPlaybackSynchronizer? playbackSynchronizer;

  LocalMusicBloc({required this.repository, this.playbackSynchronizer})
    : super(const LocalMusicInitial()) {
    on<LoadLocalTracks>(_onLoadLocalTracks);
  }

  Future<void> _onLoadLocalTracks(
    LoadLocalTracks event,
    Emitter<LocalMusicState> emit,
  ) async {
    emit(const LocalMusicLoading());
    try {
      await emit.forEach(
        repository.getLocalTracks(),
        onData: (List<DomainTrack> tracks) {
          final synchronizer = playbackSynchronizer;
          if (synchronizer != null) {
            unawaited(synchronizer.synchronize(tracks));
          }
          return LocalMusicLoaded(tracks);
        },
        onError: (error, stackTrace) =>
            LocalMusicError('Failed to load local tracks: $error'),
      );
    } catch (error) {
      emit(LocalMusicError('Failed to load local tracks: $error'));
    }
  }
}
```
