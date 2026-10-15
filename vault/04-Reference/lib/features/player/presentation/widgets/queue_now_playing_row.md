---
title: "queue_now_playing_row.dart"
path: "lib/features/player/presentation/widgets/queue_now_playing_row.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 404
incoming_dependencies: 1
outgoing_dependencies: 3
---

# queue_now_playing_row.dart

> Source File: `[lib/features/player/presentation/widgets/queue_now_playing_row.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/presentation/widgets/queue_now_playing_row.dart)`
> Layer: `lib/features/player/presentation/widgets`

## Executive Summary
`queue_now_playing_row.dart` is an essential file in `lib/features/player/presentation/widgets` providing definitions for `QueueNowPlayingRow`, `_EncoreCirclePlayPauseButton`, `_EncoreCirclePlayPauseButtonState`, `_PlayIndicator`, `_PlayIndicatorState`, `_EqualizerPainter`.
**Primary Architecture Role**: Core Component, Widget State Lifecycle Handler, Stateful Widget, Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `media_item_mapper.dart` | `lib/core/media` | [[04-Reference/lib/core/media/media_item_mapper|media_item_mapper.dart]] |
| `spotify_encore_icons.dart` | `lib/core/ui/icons` | [[04-Reference/lib/core/ui/icons/spotify_encore_icons|spotify_encore_icons.dart]] |
| `context_track.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/context_track|context_track.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `queue_sheet_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/queue_sheet_screen|queue_sheet_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class QueueNowPlayingRow`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `track` | `ContextTrack` |
| `isPlaying` | `bool` |
| `onTap` | `VoidCallback?` |
| `onPlayPause` | `VoidCallback?` |
| `mediaItem` | `final` |
| `trackKey` | `final` |
| `slideTween` | `final` |
| `slideTween` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `_slideStackLayoutBuilder` | `Widget` | `Widget? currentChild, List<Widget> previousChil...` |
| `build` | `Widget` | `BuildContext context` |
| `Row` | `dynamic` | `children: [ // 48x48 Artwork with 4dp corners +...` |
| `Expanded` | `dynamic` | `child: ClipRect( child: AnimatedSwitcher( durat...` |
| `ClipRect` | `dynamic` | `child: AnimatedSwitcher( duration: _trackSwitch...` |

#### `class _EncoreCirclePlayPauseButton`
- **Archetype**: Stateful Widget
- **Extends**: `StatefulWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `isPlaying` | `bool` |
| `onTap` | `VoidCallback?` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `createState` | `State<_EncoreCirclePlayPauseButton>` | `(none)` |

#### `class _EncoreCirclePlayPauseButtonState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<_EncoreCirclePlayPauseButton>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_isPressed` | `bool` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `GestureDetector` | `return` | `onTapDown: (_` |
| `setState` | `dynamic` | `(` |
| `setState` | `dynamic` | `(` |
| `setState` | `>` | `(` |
| `Center` | `dynamic` | `child: AnimatedSwitcher( duration: _encoreButto...` |

#### `class _PlayIndicator`
- **Archetype**: Stateful Widget
- **Extends**: `StatefulWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `isPlaying` | `bool` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `createState` | `State<_PlayIndicator>` | `(none)` |

#### `class _PlayIndicatorState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<_PlayIndicator>`
- **With Mixins**: `SingleTickerProviderStateMixin`

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `initState` | `void` | `(none)` |
| `didUpdateWidget` | `void` | `covariant _PlayIndicator oldWidget` |
| `dispose` | `void` | `(none)` |
| `build` | `Widget` | `BuildContext context` |

#### `class _EqualizerPainter`
- **Archetype**: Core Component
- **Extends**: `CustomPainter`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `animation` | `Animation<double>` |
| `isPlaying` | `bool` |
| `color` | `Color` |
| `_barPaint` | `Paint` |
| `barCount` | `const` |
| `barWidth` | `final` |
| `gap` | `final` |
| `maxHeight` | `final` |
| `progress` | `final` |
| `heightsWhenPaused` | `const` |
| `factor` | `double` |
| `phase` | `final` |
| `wave` | `final` |
| `barHeight` | `final` |
| `x` | `final` |
| `y` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `paint` | `void` | `Canvas canvas, Size size` |
| `shouldRepaint` | `bool` | `covariant _EqualizerPainter oldDelegate` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Synchronous setState() invoked without mounted check; can throw if widget is unmounted during async gaps.

> [!WARNING] Architectural Gotcha
> Background Isolate execution: arguments and return payloads must strictly cross isolate boundaries.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';
import 'package:musify_mu/core/ui/icons/spotify_encore_icons.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';

import 'player_artwork.dart';
import 'player_theme.dart';

/// 1:1 with Spotify's sticky current track row in the Queue Sheet.
///
/// Visual structure:
///   [48x48 Artwork] [Equalizer + Green Title / Gray Subtitle] [34x34 Solid White Pause/Play Circle]
class QueueNowPlayingRow extends StatelessWidget {
  const QueueNowPlayingRow({
    super.key,
    required this.track,
    this.isPlaying = true,
    this.onTap,
    this.onPlayPause,
  });

  final ContextTrack track;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onPlayPause;

  static const Cubic _trackSwitchCurve = Cubic(0.3, 0.0, 0.0, 1.0);
  static const Duration _trackSwitchDuration = Duration(milliseconds: 280);

  static final Tween<double> _artworkScaleTween =
      Tween<double>(begin: 0.90, end: 1.0);
  static final Tween<Offset> _slideInTween = Tween<Offset>(
    begin: const Offset(0.0, 0.35),
    end: Offset.zero,
  );
  static final Tween<Offset> _slideOutTween = Tween<Offset>(
    begin: const Offset(0.0, -0.35),
    end: Offset.zero,
  );

  static Widget _slideStackLayoutBuilder(
    Widget? currentChild,
    List<Widget> previousChildren,
  ) {
    return Stack(
// ... [remaining code in source file] ...
```
