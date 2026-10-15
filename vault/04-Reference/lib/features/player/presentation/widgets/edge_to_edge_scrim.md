---
title: "edge_to_edge_scrim.dart"
path: "lib/features/player/presentation/widgets/edge_to_edge_scrim.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 78
incoming_dependencies: 0
outgoing_dependencies: 0
---

# edge_to_edge_scrim.dart

> Source File: `[lib/features/player/presentation/widgets/edge_to_edge_scrim.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/presentation/widgets/edge_to_edge_scrim.dart)`
> Layer: `lib/features/player/presentation/widgets`

## Executive Summary
`edge_to_edge_scrim.dart` is an essential file in `lib/features/player/presentation/widgets` providing definitions for `EdgeToEdgeScrim`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class EdgeToEdgeScrim`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `child` | `Widget` |
| `topScrimColor` | `Color?` |
| `bottomScrimColor` | `Color?` |
| `showTopScrim` | `bool` |
| `showBottomScrim` | `bool` |
| `mediaQuery` | `final` |
| `topPadding` | `final` |
| `bottomPadding` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';

/// Reusable overlay that draws subtle protection scrims over the status bar
/// and navigation bar insets while allowing edge-to-edge content to render underneath.
class EdgeToEdgeScrim extends StatelessWidget {
  const EdgeToEdgeScrim({
    super.key,
    required this.child,
    this.topScrimColor,
    this.bottomScrimColor,
    this.showTopScrim = true,
    this.showBottomScrim = true,
  });

  final Widget child;
  final Color? topScrimColor;
  final Color? bottomScrimColor;
  final bool showTopScrim;
  final bool showBottomScrim;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (showTopScrim && topPadding > 0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPadding + 16,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      topScrimColor ?? Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
// ... [remaining code in source file] ...
```
