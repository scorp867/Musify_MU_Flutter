---
title: "spotify_encore_icons.dart"
path: "lib/core/ui/icons/spotify_encore_icons.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, ui]
lines: 587
incoming_dependencies: 4
outgoing_dependencies: 0
---

# spotify_encore_icons.dart

> Source File: `[lib/core/ui/icons/spotify_encore_icons.dart](file:///c:/Users/Admin/Musify_MU/lib/core/ui/icons/spotify_encore_icons.dart)`
> Layer: `lib/core/ui/icons`

## Executive Summary
`spotify_encore_icons.dart` is an essential file in `lib/core/ui/icons` providing definitions for `SpotifyEncoreIcons`, `SpotifyIcon`, `_SvgPathPainter`, `_SvgPathParser`.
**Primary Architecture Role**: Parser / Data Mapper, Core Component, Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `queue_sheet_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/queue_sheet_screen|queue_sheet_screen.dart]] |
| `queue_controls_layout.dart` | `lib/features/player/presentation/widgets` | [[04-Reference/lib/features/player/presentation/widgets/queue_controls_layout|queue_controls_layout.dart]] |
| `queue_now_playing_row.dart` | `lib/features/player/presentation/widgets` | [[04-Reference/lib/features/player/presentation/widgets/queue_now_playing_row|queue_now_playing_row.dart]] |
| `queue_track_row.dart` | `lib/features/player/presentation/widgets` | [[04-Reference/lib/features/player/presentation/widgets/queue_track_row|queue_track_row.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class SpotifyEncoreIcons`
- **Archetype**: Core Component

#### `class SpotifyIcon`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `paths` | `List<String>` |
| `color` | `Color` |
| `size` | `double` |
| `color` | `Color` |
| `size` | `double` |
| `color` | `Color` |
| `size` | `double` |
| `size` | `double` |
| `color` | `Color` |
| `scale` | `final` |
| `topLeft` | `final` |
| `paint` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `sort` | `dynamic` | `{Color color = Colors.white, double size = 24}` |
| `delete` | `dynamic` | `{Color color = Colors.white, double size = 24}` |
| `addToQueue` | `dynamic` | `{Color color = Colors.white, double size = 24}` |
| `shuffle` | `dynamic` | `{Color color = Colors.white, double size = 24}` |
| `repeat` | `dynamic` | `{Color color = Colors.white, double size = 24}` |
| `repeatOnce` | `dynamic` | `{Color color = Colors.white, double size = 24}` |
| `timer` | `dynamic` | `{Color color = Colors.white, double size = 24}` |
| `queueBadge` | `dynamic` | `{Color color = Colors.white, double size = 14}` |
| `pause` | `dynamic` | `{ Key? key, Color color = Colors.black, double ...` |
| `play` | `dynamic` | `{ Key? key, Color color = Colors.black, double ...` |
| `check` | `dynamic` | `{Color color = Colors.white, double size = 24}` |
| `cross` | `dynamic` | `{Color color = Colors.white, double size = 24}` |
| `chevronDown` | `dynamic` | `{Color color = Colors.white, double size = 24}` |
| `paintIcon` | `void` | `Canvas canvas, List<String> paths, { required O...` |
| `build` | `Widget` | `BuildContext context` |

#### `class _SvgPathPainter`
- **Archetype**: Core Component
- **Extends**: `CustomPainter`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `paths` | `List<String>` |
| `color` | `Color` |
| `scale` | `final` |
| `paint` | `final` |
| `path` | `final` |
| `path` | `final` |
| `path` | `return` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `paint` | `void` | `Canvas canvas, Size size` |
| `shouldRepaint` | `bool` | `covariant _SvgPathPainter oldDelegate` |
| `parseSvgPath` | `Path` | `String d` |

#### `class _SvgPathParser`
- **Archetype**: Parser / Data Mapper

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `d` | `String` |
| `_index` | `int` |
| `path` | `final` |
| `currentX` | `double` |
| `currentY` | `double` |
| `startX` | `double` |
| `startY` | `double` |
| `lastControlX` | `double` |
| `lastControlY` | `double` |
| `lastCmd` | `String` |
| `prevCmd` | `String` |
| `char` | `final` |
| `x` | `final` |
| `y` | `final` |
| `dx` | `final` |
| `dy` | `final` |
| `x` | `final` |
| `y` | `final` |
| `dx` | `final` |
| `dy` | `final` |
| `x` | `final` |
| `dx` | `final` |
| `y` | `final` |
| `dy` | `final` |
| `x1` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `parse` | `Path` | `(none)` |
| `_skipWhitespaceAndCommas` | `void` | `(none)` |
| `_isCommand` | `bool` | `String char` |
| `_readDouble` | `double` | `(none)` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';

/// Exact 1:1 Vector paths extracted from Spotify APK drawable resources:
/// - encore_icon_sort_24.xml
/// - encore_icon_delete_24.xml
/// - encore_icon_add_to_queue_24.xml
/// - encore_icon_shuffle_24.xml
/// - encore_icon_repeat_24.xml
/// - encore_icon_repeat_once_24.xml
/// - encore_icon_time_24.xml
/// - encore_icon_queue_badge_24.xml
/// - encore_icon_pause_24.xml
/// - encore_icon_play_24.xml
class SpotifyEncoreIcons {
  SpotifyEncoreIcons._();

  static const String sortPath =
      'M21,8L3,8L3,6h18zM21,18L3,18v-2h18zM3,13h18v-2L3,11z';

  static const String deletePath =
      'M8,4L8,3a3,3 0,0 1,3 -3h2a3,3 0,0 1,3 3v1h6v2h-0.956l-1.878,14.261'
      'A2,2 0,0 1,17.183 22L6.817,22a2,2 0,0 1,-1.983 -1.739L2.956,6L2,6L2,4z'
      'M10,3v1h4L14,3a1,1 0,0 0,-1 -1h-2a1,1 0,0 0,-1 1'
      'M4.974,6l1.843,14h10.366l1.843,-14z';

  static const String addToQueuePath1 =
      'M10.929,5C10.976,4.673 11,4.34 11,4C11,3.66 10.976,3.327 10.929,3H18.55'
      'C20.483,3 22.05,4.567 22.05,6.5C22.05,8.433 20.483,10 18.55,10H7.607'
      'C8.453,9.491 9.182,8.807 9.745,8H18.55C19.378,8 20.05,7.328 20.05,6.5'
      'C20.05,5.672 19.378,5 18.55,5H10.929Z';
  static const String addToQueuePath2 = 'M3,16H21V14H3V16Z';
  static const String addToQueuePath3 = 'M3,22H21V20H3V22Z';
  static const String addToQueuePath4 = 'M5,3H8V5H5V8H3V5H0L0,3H3V0L5,0V3Z';

  static const List<String> addToQueuePaths = [
    addToQueuePath1,
    addToQueuePath2,
    addToQueuePath3,
    addToQueuePath4,
  ];
  static const List<String> deletePaths = [deletePath];

  static const String shufflePath1 =
      'M18.788,3.702a1,1 0,0 1,1.414 -1.414L23.914,6l-3.712,3.712'
      'a1,1 0,1 1,-1.414 -1.414L20.086,7h-1.518a5,5 0,0 0,-3.826 1.78'
// ... [remaining code in source file] ...
```
