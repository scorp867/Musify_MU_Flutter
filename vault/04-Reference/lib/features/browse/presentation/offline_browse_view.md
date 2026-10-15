---
title: "offline_browse_view.dart"
path: "lib/features/browse/presentation/offline_browse_view.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, browse]
lines: 473
incoming_dependencies: 1
outgoing_dependencies: 8
---

# offline_browse_view.dart

> Source File: `[lib/features/browse/presentation/offline_browse_view.dart](file:///c:/Users/Admin/Musify_MU/lib/features/browse/presentation/offline_browse_view.dart)`
> Layer: `lib/features/browse/presentation`

## Executive Summary
`offline_browse_view.dart` is an essential file in `lib/features/browse/presentation` providing definitions for `OfflineBrowseView`, `_OfflineBrowseViewState`, `_ArtistCard`, `_AlbumCard`.
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
#### `class OfflineBrowseView`
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
| `createState` | `State<OfflineBrowseView>` | `(none)` |

#### `class _OfflineBrowseViewState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<OfflineBrowseView>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_searchController` | `TextEditingController` |
| `_searchQuery` | `String` |
| `allTracks` | `final` |
| `artistMap` | `final` |
| `artists` | `final` |
| `albumMap` | `final` |
| `album` | `final` |
| `albums` | `final` |
| `artist` | `final` |
| `count` | `final` |
| `firstTrack` | `final` |
| `album` | `final` |
| `albumTracks` | `final` |
| `artist` | `final` |
| `firstTrack` | `final` |
| `q` | `final` |
| `filtered` | `final` |
| `track` | `final` |
| `playback` | `final` |
| `mediaItems` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `dispose` | `void` | `(none)` |
| `build` | `Widget` | `BuildContext context` |
| `SafeArea` | `dynamic` | `bottom: false, child: BlocBuilder<LocalMusicBlo...` |
| `TextField` | `dynamic` | `controller: _searchController, onChanged: (v` |
| `setState` | `dynamic` | `(` |
| `setState` | `dynamic` | `(` |
| `_buildBrowseGrid` | `Widget` | `List<DomainTrack> tracks` |
| `putIfAbsent` | `dynamic` | `t.artist, (` |
| `putIfAbsent` | `dynamic` | `album, (` |
| `_sectionHeader` | `Widget` | `String title, String count` |
| `_buildSearchResults` | `Widget` | `List<DomainTrack> tracks` |
| `where` | `dynamic` | `(t` |
| `builder` | `dynamic` | `itemCount: filtered.length + 1, itemBuilder: (c...` |
| `GestureDetector` | `return` | `onTap: (` |
| `_playTrack` | `void` | `List<DomainTrack> tracks, int index` |
| `map` | `dynamic` | `(t` |

#### `class _ArtistCard`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `name` | `String` |
| `trackCount` | `int` |
| `sampleTrack` | `DomainTrack` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |

#### `class _AlbumCard`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `name` | `String` |
| `artist` | `String` |
| `sampleTrack` | `DomainTrack` |

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

/// Offline browse view -- search and explore local music files by artist/album.
/// Displayed when the app is in offline mode on the Browse tab.
class OfflineBrowseView extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onToggleMode;
  final PlaybackController? playbackController;

  const OfflineBrowseView({
    super.key,
    this.onMenuPressed,
    this.onToggleMode,
    this.playbackController,
  });

  @override
  State<OfflineBrowseView> createState() => _OfflineBrowseViewState();
}

class _OfflineBrowseViewState extends State<OfflineBrowseView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: SafeArea(
// ... [remaining code in source file] ...
```
