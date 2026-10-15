---
title: "queue_track_row.dart"
path: "lib/features/player/presentation/widgets/queue_track_row.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 646
incoming_dependencies: 1
outgoing_dependencies: 3
---

# queue_track_row.dart

> Source File: `[lib/features/player/presentation/widgets/queue_track_row.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/presentation/widgets/queue_track_row.dart)`
> Layer: `lib/features/player/presentation/widgets`

## Executive Summary
`queue_track_row.dart` is an essential file in `lib/features/player/presentation/widgets` providing definitions for `QueueTrackRow`, `_QueueTrackRowState`, `_StrictHorizontalDragGestureRecognizer`, `_SpotifySwipeBackgroundPainter`.
**Primary Architecture Role**: Widget State Lifecycle Handler, Stateful Widget, Core Component

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
#### `class QueueTrackRow`
- **Archetype**: Stateful Widget
- **Extends**: `StatefulWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `track` | `ContextTrack` |
| `index` | `int` |
| `onTap` | `VoidCallback` |
| `onRemove` | `VoidCallback` |
| `onAddToQueue` | `VoidCallback` |
| `onCollapseStart` | `VoidCallback?` |
| `showDragHandle` | `bool` |
| `animateInsert` | `bool` |
| `animateSlideDown` | `bool` |
| `isClearing` | `bool` |
| `isTappedPlaying` | `bool` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `createState` | `State<QueueTrackRow>` | `(none)` |

#### `class _QueueTrackRowState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<QueueTrackRow>`
- **With Mixins**: `TickerProviderStateMixin`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_dragOffsetX` | `ValueNotifier<double>` |
| `_swipeAnimation` | `Animation<double>?` |
| `_rawDragX` | `double` |
| `_armedAddToQueue` | `bool` |
| `_isRemoving` | `bool` |
| `_isSlidingDown` | `bool` |
| `anim` | `final` |
| `startCollapsed` | `final` |
| `width` | `final` |
| `maxRight` | `final` |
| `clampedDx` | `final` |
| `width` | `final` |
| `currentDx` | `final` |
| `velocityX` | `final` |
| `triggerAddOnZero` | `final` |
| `fraction` | `final` |
| `shouldDelete` | `final` |
| `startDx` | `final` |
| `track` | `final` |
| `mediaItem` | `final` |
| `cachedRowLayer` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `initState` | `void` | `(none)` |
| `addListener` | `dynamic` | `(` |
| `didUpdateWidget` | `void` | `covariant QueueTrackRow oldWidget` |
| `dispose` | `void` | `(none)` |
| `_onHorizontalDragStart` | `void` | `DragStartDetails details` |
| `_onHorizontalDragUpdate` | `void` | `DragUpdateDetails details` |
| `_onHorizontalDragEnd` | `void` | `DragEndDetails details` |
| `_animateSwipeTo` | `dynamic` | `targetDx: 0.0, duration: _recoverDuration, curv...` |
| `_animateSwipeTo` | `250ms` | `targetDx: -width, duration: _swipeDismissDurati...` |
| `then` | `dynamic` | `(_` |
| `_onHorizontalDragCancel` | `void` | `(none)` |
| `_animateSwipeTo` | `void` | `{ required double targetDx, required Duration d...` |
| `then` | `dynamic` | `(_` |
| `build` | `Widget` | `BuildContext context` |
| `RepaintBoundary` | `dynamic` | `child: ColoredBox( color: PlayerColors.backgrou...` |
| `CustomPaint` | `dynamic` | `painter: _swipePainter, child: AnimatedBuilder(...` |

#### `class _StrictHorizontalDragGestureRecognizer`
- **Archetype**: Core Component
- **Extends**: `HorizontalDragGestureRecognizer`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_startPosition` | `Offset` |
| `_totalDx` | `double` |
| `_totalDy` | `double` |
| `_isAccepted` | `bool` |
| `minSlop` | `final` |
| `effectiveSlop` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `addAllowedPointer` | `void` | `PointerDownEvent event` |
| `handleEvent` | `void` | `PointerEvent event` |
| `hasSufficientGlobalDistanceToAccept` | `bool` | `PointerDeviceKind pointerDeviceKind, double? de...` |
| `acceptGesture` | `void` | `int pointer` |
| `rejectGesture` | `void` | `int pointer` |

#### `class _SpotifySwipeBackgroundPainter`
- **Archetype**: Core Component
- **Extends**: `CustomPainter`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `dragOffsetX` | `ValueNotifier<double>` |
| `_fillPaint` | `Paint` |
| `dx` | `final` |
| `rect` | `final` |
| `rect` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `paint` | `void` | `Canvas canvas, Size size` |
| `shouldRepaint` | `bool` | `covariant _SpotifySwipeBackgroundPainter oldDel...` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';
import 'package:musify_mu/core/ui/icons/spotify_encore_icons.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';

import 'player_artwork.dart';
import 'player_theme.dart';

/// 1:1 with Spotify's layout_default_track_row.xml & p/l1q0.java (ItemTouchHelper)
/// + p/z6y0.java (DefaultItemAnimator).
///
/// Structure & Physics (from XML & decompiled APK):
///   - Row height: 64dp
///   - ArtworkView: 48x48, 4dp radius, marginStart=16dp, marginEnd=12dp
///   - Title: BodyMedium, white
///   - Subtitle Row:
///       [QueuedBadgeView (13dp green queue badge, marginEnd=5dp) when track.isQueued]
///       ArtistName (BodySmall, #B3B3B3)
///   - DragHandle: encore_icon_sort, marginEnd=8dp
///   - Swipe Right (Add to Queue, l1q0.java):
///       * Clamped to 0.45 * rowWidth
///       * #1ED760 background rect [0..dX] with addToQueue icon dynamically
///         centered at dX/2 and clipped to [0..dX]
///       * Armed when dX/width > 0.25
///       * Smoothly recovers to 0.0 over 280ms (DecelerateInterpolator) and
///         invokes onAddToQueue() upon reaching dX == 0.0
///   - Swipe Left (Delete, l1q0.java + z6y0.java):
///       * #E22134 background rect [width+dX..width] with delete icon
///         dynamically centered at width + dX/2 and clipped to [width+dX..width]
///       * Slides out (240ms Decelerate) then collapses height over 250ms
///         (FastOutSlowInInterpolator) before invoking onRemove()
class QueueTrackRow extends StatefulWidget {
  const QueueTrackRow({
    super.key,
    required this.track,
    required this.index,
    required this.onTap,
    required this.onRemove,
    required this.onAddToQueue,
    this.onCollapseStart,
    this.showDragHandle = true,
    this.animateInsert = false,
    this.animateSlideDown = false,
    this.isClearing = false,
// ... [remaining code in source file] ...
```
