---
title: "bottom_navigation.dart"
path: "lib/features/shell/presentation/widgets/bottom_navigation.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, shell]
lines: 176
incoming_dependencies: 1
outgoing_dependencies: 0
---

# bottom_navigation.dart

> Source File: `[lib/features/shell/presentation/widgets/bottom_navigation.dart](file:///c:/Users/Admin/Musify_MU/lib/features/shell/presentation/widgets/bottom_navigation.dart)`
> Layer: `lib/features/shell/presentation/widgets`

## Executive Summary
`bottom_navigation.dart` is an essential file in `lib/features/shell/presentation/widgets` providing definitions for `AppBottomNavigation`, `_SpotifyLibraryIcon`, `_SpotifyLibraryPainter`.
**Primary Architecture Role**: Core Component, Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `main_screen.dart` | `lib/features/shell/presentation` | [[04-Reference/lib/features/shell/presentation/main_screen|main_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class AppBottomNavigation`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `currentIndex` | `int` |
| `onTap` | `ValueChanged<int>` |
| `isNetworkBarVisible` | `bool` |
| `bottomInset` | `final` |
| `bottomPadding` | `final` |
| `isSelected` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `_buildNavItem` | `Widget` | `{ required int index, required String label, re...` |
| `Expanded` | `return` | `child: GestureDetector( behavior: HitTestBehavi...` |

#### `class _SpotifyLibraryIcon`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `color` | `Color` |
| `isFilled` | `bool` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |

#### `class _SpotifyLibraryPainter`
- **Archetype**: Core Component
- **Extends**: `CustomPainter`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `color` | `Color` |
| `isFilled` | `bool` |
| `paint` | `final` |
| `barWidth` | `const` |
| `barHeight` | `const` |
| `top` | `const` |
| `r1` | `final` |
| `r2` | `final` |
| `r3` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `paint` | `void` | `Canvas canvas, Size size` |
| `shouldRepaint` | `bool` | `covariant _SpotifyLibraryPainter oldDelegate` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';

/// A sleek Spotify-authentic navigation bar featuring a translucent gradient fade,
/// refined icons, and compact labels.
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isNetworkBarVisible;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isNetworkBarVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomPadding = isNetworkBarVisible ? 4.0 : (bottomInset + 4.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00000000), // Pure transparent top for smooth content bleed
            Color(0xCC000000), // 80% black mid
            Color(0xFF000000), // Solid black bottom
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.fromLTRB(16, 2, 16, bottomPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
              _buildNavItem(
                index: 0,
                label: 'Home',
                activeIcon: const Icon(Icons.home_filled, size: 24, color: Colors.white),
// ... [remaining code in source file] ...
```
