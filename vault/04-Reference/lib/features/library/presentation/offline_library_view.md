---
title: "offline_library_view.dart"
path: "lib/features/library/presentation/offline_library_view.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, library]
lines: 280
incoming_dependencies: 1
outgoing_dependencies: 8
---

# offline_library_view.dart

> Source File: `[lib/features/library/presentation/offline_library_view.dart](file:///c:/Users/Admin/Musify_MU/lib/features/library/presentation/offline_library_view.dart)`
> Layer: `lib/features/library/presentation`

## Executive Summary
`offline_library_view.dart` is an essential file in `lib/features/library/presentation` providing definitions for `OfflineLibraryView`, `_OfflineLibraryViewState`, `_TrackTile`.
**Primary Architecture Role**: Widget State Lifecycle Handler, Stateful Widget, Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `playback_controller.dart` | `lib/core/audio` | [[04-Reference/lib/core/audio/playback_controller|playback_controller.dart]] |
| `local_context_resolver.dart` | `lib/features/local_music/domain` | [[04-Reference/lib/features/local_music/domain/local_context_resolver|local_context_resolver.dart]] |
| `duration_formatter.dart` | `lib/core/ui/formatters` | [[04-Reference/lib/core/ui/formatters/duration_formatter|duration_formatter.dart]] |
| `app_header.dart` | `lib/core/ui/widgets` | [[04-Reference/lib/core/ui/widgets/app_header|app_header.dart]] |
| `shell_bottom_spacer.dart` | `lib/core/ui/widgets` | [[04-Reference/lib/core/ui/widgets/shell_bottom_spacer|shell_bottom_spacer.dart]] |
| `domain_track.dart` | `lib/features/local_music/domain/entities` | [[04-Reference/lib/features/local_music/domain/entities/domain_track|domain_track.dart]] |
| `local_music_bloc.dart` | `lib/features/local_music/presentation/bloc` | [[04-Reference/lib/features/local_music/presentation/bloc/local_music_bloc|local_music_bloc.dart]] |
| `local_music_state.dart` | `lib/features/local_music/presentation/bloc` | [[04-Reference/lib/features/local_music/presentation/bloc/local_music_state|local_music_state.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `main_screen.dart` | `lib/features/shell/presentation` | [[04-Reference/lib/features/shell/presentation/main_screen|main_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class OfflineLibraryView`
- **Archetype**: Stateful Widget
- **Extends**: `StatefulWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `onMenuPressed` | `VoidCallback?` |
| `onToggleMode` | `VoidCallback?` |
| `playbackController` | `PlaybackController?` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `createState` | `State<OfflineLibraryView>` | `(none)` |

#### `class _OfflineLibraryViewState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<OfflineLibraryView>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_searchQuery` | `String` |
| `q` | `final` |
| `tracks` | `final` |
| `filtered` | `final` |
| `trackCount` | `final` |
| `playback` | `final` |
| `mediaItems` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `_filter` | `List<DomainTrack>` | `List<DomainTrack> tracks` |
| `where` | `dynamic` | `(t` |
| `build` | `Widget` | `BuildContext context` |
| `SafeArea` | `dynamic` | `bottom: false, child: BlocBuilder<LocalMusicBlo...` |
| `TextField` | `dynamic` | `onChanged: (v` |
| `setState` | `dynamic` | `(` |
| `builder` | `dynamic` | `itemCount: filtered.length + 1, itemBuilder: (c...` |
| `_TrackTile` | `return` | `track: filtered[index], onTap: (` |
| `_playTrack` | `void` | `List<DomainTrack> tracks, int index` |
| `map` | `dynamic` | `(t` |

#### `class _TrackTile`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `track` | `DomainTrack` |
| `onTap` | `VoidCallback` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Synchronous setState() invoked without mounted check; can throw if widget is unmounted during async gaps.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';
import 'package:musify_mu/core/ui/widgets/app_header.dart';
import 'package:musify_mu/core/ui/widgets/shell_bottom_spacer.dart';
import 'package:musify_mu/features/local_music/domain/entities/domain_track.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_bloc.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_state.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Offline library view -- shows local music files in a library layout.
/// Displayed when the app is in offline mode on the Library tab.
class OfflineLibraryView extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onToggleMode;
  final PlaybackController? playbackController;

  const OfflineLibraryView({
    super.key,
    this.onMenuPressed,
    this.onToggleMode,
    this.playbackController,
  });

  @override
  State<OfflineLibraryView> createState() => _OfflineLibraryViewState();
}

class _OfflineLibraryViewState extends State<OfflineLibraryView> {
  String _searchQuery = '';

  List<DomainTrack> _filter(List<DomainTrack> tracks) {
    if (_searchQuery.isEmpty) return tracks;
    final q = _searchQuery.toLowerCase();
    return tracks
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q) ||
            (t.album?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
// ... [remaining code in source file] ...
```
