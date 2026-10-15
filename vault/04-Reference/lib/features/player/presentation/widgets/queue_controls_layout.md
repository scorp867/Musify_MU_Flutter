---
title: "queue_controls_layout.dart"
path: "lib/features/player/presentation/widgets/queue_controls_layout.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 201
incoming_dependencies: 1
outgoing_dependencies: 1
---

# queue_controls_layout.dart

> Source File: `[lib/features/player/presentation/widgets/queue_controls_layout.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/presentation/widgets/queue_controls_layout.dart)`
> Layer: `lib/features/player/presentation/widgets`

## Executive Summary
`queue_controls_layout.dart` is an essential file in `lib/features/player/presentation/widgets` providing definitions for `QueueControlsLayout`, `_SessionModifierButton`, `_SessionModifierButtonState`.
**Primary Architecture Role**: Widget State Lifecycle Handler, Stateful Widget, Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `spotify_encore_icons.dart` | `lib/core/ui/icons` | [[04-Reference/lib/core/ui/icons/spotify_encore_icons|spotify_encore_icons.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `queue_sheet_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/queue_sheet_screen|queue_sheet_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class QueueControlsLayout`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `shuffleMode` | `AudioServiceShuffleMode` |
| `repeatMode` | `AudioServiceRepeatMode` |
| `onShuffleTapped` | `VoidCallback` |
| `onRepeatTapped` | `VoidCallback` |
| `onTimerTapped` | `VoidCallback` |
| `isTimerActive` | `bool` |
| `bottomSafe` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `Row` | `dynamic` | `children: [ Expanded( child: _SessionModifierBu...` |
| `Expanded` | `dynamic` | `child: _SessionModifierButton( label: 'Repeat',...` |
| `Expanded` | `dynamic` | `child: _SessionModifierButton( label: 'Timer', ...` |

#### `class _SessionModifierButton`
- **Archetype**: Stateful Widget
- **Extends**: `StatefulWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `label` | `String` |
| `isActive` | `bool` |
| `onTap` | `VoidCallback` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `createState` | `State<_SessionModifierButton>` | `(none)` |

#### `class _SessionModifierButtonState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<_SessionModifierButton>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_isPressed` | `bool` |
| `targetColor` | `final` |
| `resolvedColor` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `RepaintBoundary` | `return` | `child: GestureDetector( onTapDown: (_` |
| `setState` | `dynamic` | `(` |
| `setState` | `dynamic` | `(` |
| `setState` | `>` | `(` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Synchronous setState() invoked without mounted check; can throw if widget is unmounted during async gaps.

## Implementation Highlight
```dart
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/core/ui/icons/spotify_encore_icons.dart';

import 'player_theme.dart';

/// 1:1 with Spotify's layout_queue_controls.xml & screenshots:
///
///   DropShadowContainer (top gradient fade over scrolling list)
///   SessionModifierContainerView:
///     Three equal-width rounded cards (#242424) with icon + label:
///     [Shuffle]  [Repeat]  [Timer]
class QueueControlsLayout extends StatelessWidget {
  const QueueControlsLayout({
    super.key,
    required this.shuffleMode,
    required this.repeatMode,
    required this.onShuffleTapped,
    required this.onRepeatTapped,
    required this.onTimerTapped,
    this.isTimerActive = false,
  });

  final AudioServiceShuffleMode shuffleMode;
  final AudioServiceRepeatMode repeatMode;
  final VoidCallback onShuffleTapped;
  final VoidCallback onRepeatTapped;
  final VoidCallback onTimerTapped;
  final bool isTimerActive;

  bool get _isShuffling =>
      shuffleMode == AudioServiceShuffleMode.all ||
      shuffleMode == AudioServiceShuffleMode.group;

  bool get _isRepeating =>
      repeatMode == AudioServiceRepeatMode.all ||
      repeatMode == AudioServiceRepeatMode.one;

  bool get _isRepeatingOne => repeatMode == AudioServiceRepeatMode.one;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return RepaintBoundary(
// ... [remaining code in source file] ...
```
