---
title: "player_theme.dart"
path: "lib/features/player/presentation/widgets/player_theme.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 26
incoming_dependencies: 2
outgoing_dependencies: 0
---

# player_theme.dart

> Source File: `[lib/features/player/presentation/widgets/player_theme.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/presentation/widgets/player_theme.dart)`
> Layer: `lib/features/player/presentation/widgets`

## Executive Summary
`player_theme.dart` is an essential file in `lib/features/player/presentation/widgets` providing definitions for `PlayerColors`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `player_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/player_screen|player_screen.dart]] |
| `queue_sheet_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/queue_sheet_screen|queue_sheet_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class PlayerColors`
- **Archetype**: Core Component

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';

/// Dark-minimal Spotify design tokens  -  #121212 background, #1ED760 green accent.
abstract final class PlayerColors {
  // Backgrounds
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF181818);
  static const surfaceHigh = Color(0xFF242424);

  // Accent (Authentic Spotify Green)
  static const accent = Color(0xFF1ED760);
  static const accentDim = Color(0xFF169C46);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB3B3B3);
  static const muted = Color(0xFF727272);

  // Misc
  static const divider = Color(0xFF282828);
  static const shimmer = Color(0xFF252525);
  static final BoxDecoration panelDecoration = BoxDecoration(
    color: surfaceHigh,
    borderRadius: BorderRadius.circular(16),
  );
}
```
