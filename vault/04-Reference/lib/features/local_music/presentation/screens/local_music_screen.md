---
title: "local_music_screen.dart"
path: "lib/features/local_music/presentation/screens/local_music_screen.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, local_music]
lines: 198
incoming_dependencies: 1
outgoing_dependencies: 6
---

# local_music_screen.dart

> Source File: `[lib/features/local_music/presentation/screens/local_music_screen.dart](file:///c:/Users/Admin/Musify_MU/lib/features/local_music/presentation/screens/local_music_screen.dart)`
> Layer: `lib/features/local_music/presentation/screens`

## Executive Summary
`local_music_screen.dart` is an essential file in `lib/features/local_music/presentation/screens` providing definitions for `LocalMusicScreen`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `playback_controller.dart` | `lib/core/audio` | [[04-Reference/lib/core/audio/playback_controller|playback_controller.dart]] |
| `local_context_resolver.dart` | `lib/features/local_music/domain` | [[04-Reference/lib/features/local_music/domain/local_context_resolver|local_context_resolver.dart]] |
| `duration_formatter.dart` | `lib/core/ui/formatters` | [[04-Reference/lib/core/ui/formatters/duration_formatter|duration_formatter.dart]] |
| `shell_bottom_spacer.dart` | `lib/core/ui/widgets` | [[04-Reference/lib/core/ui/widgets/shell_bottom_spacer|shell_bottom_spacer.dart]] |
| `local_music_bloc.dart` | `lib/features/local_music/presentation/bloc` | [[04-Reference/lib/features/local_music/presentation/bloc/local_music_bloc|local_music_bloc.dart]] |
| `local_music_state.dart` | `lib/features/local_music/presentation/bloc` | [[04-Reference/lib/features/local_music/presentation/bloc/local_music_state|local_music_state.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `home_tab.dart` | `lib/features/home/presentation` | [[04-Reference/lib/features/home/presentation/home_tab|home_tab.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class LocalMusicScreen`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `playbackController` | `PlaybackController?` |
| `tracks` | `final` |
| `track` | `final` |
| `playback` | `final` |
| `mediaItems` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `_buildSectionTitle` | `Widget` | `String title` |
| `_buildLocalLibrarySliver` | `Widget` | `(none)` |
| `SliverList` | `dynamic` | `delegate: SliverChildBuilderDelegate((context, ...` |
| `GestureDetector` | `dynamic` | `onTap: (` |
| `map` | `dynamic` | `(track` |
| `_formatDuration` | `String` | `int milliseconds` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';
import 'package:musify_mu/core/ui/widgets/shell_bottom_spacer.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_bloc.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_state.dart';
import 'package:on_audio_query/on_audio_query.dart';

class LocalMusicScreen extends StatelessWidget {
  final PlaybackController? playbackController;

  const LocalMusicScreen({super.key, this.playbackController});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildSectionTitle('Local Files (Offline)'),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            _buildLocalLibrarySliver(),
            const SliverShellBottomSpacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
// ... [remaining code in source file] ...
```
