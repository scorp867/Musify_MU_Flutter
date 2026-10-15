---
title: "queue_now_playing_card.dart"
path: "lib/features/player/presentation/widgets/queue_now_playing_card.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 176
incoming_dependencies: 0
outgoing_dependencies: 1
---

# queue_now_playing_card.dart

> Source File: `[lib/features/player/presentation/widgets/queue_now_playing_card.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/presentation/widgets/queue_now_playing_card.dart)`
> Layer: `lib/features/player/presentation/widgets`

## Executive Summary
`queue_now_playing_card.dart` is an essential file in `lib/features/player/presentation/widgets` providing definitions for `QueueNowPlayingCard`, `_NowPlayingIndicator`, `_NowPlayingIndicatorState`.
**Primary Architecture Role**: Widget State Lifecycle Handler, Stateful Widget, Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `playback_controller.dart` | `lib/core/audio` | [[04-Reference/lib/core/audio/playback_controller|playback_controller.dart]] |

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class QueueNowPlayingCard`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `MediaItem` |
| `playbackController` | `PlaybackController` |
| `playing` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |

#### `class _NowPlayingIndicator`
- **Archetype**: Stateful Widget
- **Extends**: `StatefulWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `isPlaying` | `bool` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `createState` | `State<_NowPlayingIndicator>` | `(none)` |

#### `class _NowPlayingIndicatorState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<_NowPlayingIndicator>`
- **With Mixins**: `TickerProviderStateMixin`

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `initState` | `void` | `(none)` |
| `generate` | `dynamic` | `_barCount, (i` |
| `generate` | `dynamic` | `_barCount, (i` |
| `didUpdateWidget` | `void` | `_NowPlayingIndicator oldWidget` |
| `_syncAnimations` | `void` | `(none)` |
| `dispose` | `void` | `(none)` |
| `build` | `Widget` | `BuildContext context` |
| `SizedBox` | `return` | `width: 24, height: 24, child: Row( mainAxisAlig...` |
| `AnimatedBuilder` | `return` | `animation: _controllers[i], builder: (context, ...` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';

import 'player_artwork.dart';
import 'player_theme.dart';

class QueueNowPlayingCard extends StatelessWidget {
  const QueueNowPlayingCard({
    super.key,
    required this.item,
    required this.playbackController,
  });

  final MediaItem item;
  final PlaybackController playbackController;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PlayerColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PlayerColors.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: PlayerArtworkImage(
                item: item,
                artworkWidth: 52,
                artworkHeight: 52,
                placeholderIconSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
// ... [remaining code in source file] ...
```
