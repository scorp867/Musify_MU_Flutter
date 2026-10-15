---
title: "shell_bottom_spacer.dart"
path: "lib/core/ui/widgets/shell_bottom_spacer.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, ui]
lines: 59
incoming_dependencies: 6
outgoing_dependencies: 0
---

# shell_bottom_spacer.dart

> Source File: `[lib/core/ui/widgets/shell_bottom_spacer.dart](file:///c:/Users/Admin/Musify_MU/lib/core/ui/widgets/shell_bottom_spacer.dart)`
> Layer: `lib/core/ui/widgets`

## Executive Summary
`shell_bottom_spacer.dart` is an essential file in `lib/core/ui/widgets` providing definitions for `ShellBottomSpacer`, `SliverShellBottomSpacer`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `local_music_screen.dart` | `lib/features/local_music/presentation/screens` | [[04-Reference/lib/features/local_music/presentation/screens/local_music_screen|local_music_screen.dart]] |
| `library_view.dart` | `lib/features/library/presentation` | [[04-Reference/lib/features/library/presentation/library_view|library_view.dart]] |
| `offline_library_view.dart` | `lib/features/library/presentation` | [[04-Reference/lib/features/library/presentation/offline_library_view|offline_library_view.dart]] |
| `home_feed_view.dart` | `lib/features/home_feed/presentation` | [[04-Reference/lib/features/home_feed/presentation/home_feed_view|home_feed_view.dart]] |
| `browse_view.dart` | `lib/features/browse/presentation` | [[04-Reference/lib/features/browse/presentation/browse_view|browse_view.dart]] |
| `offline_browse_view.dart` | `lib/features/browse/presentation` | [[04-Reference/lib/features/browse/presentation/offline_browse_view|offline_browse_view.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class ShellBottomSpacer`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `hasBottomNav` | `bool` |
| `additionalHeight` | `double` |
| `bottomPadding` | `final` |
| `targetHeight` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |

#### `class SliverShellBottomSpacer`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `hasBottomNav` | `bool` |
| `additionalHeight` | `double` |

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

/// A dynamic shell spacer that provides bottom clearance for scrollable views
/// rendered inside an edge-to-edge [Scaffold] with [Scaffold.extendBody] set to true.
///
/// In Flutter, when [Scaffold.extendBody] is true, the scaffold automatically calculates
/// the combined height of all active bottom widgets (e.g., MiniPlayer, AppBottomNavigation,
/// and NetworkStatusBottomBar) plus system navigation insets, and exposes it in
/// [MediaQuery.paddingOf(context).bottom].
///
/// This spacer relies on Flutter's built-in calculation as the single source of truth,
/// adding [additionalHeight] (default: 16.0dp) for aesthetic breathing space.
class ShellBottomSpacer extends StatelessWidget {
  final bool hasBottomNav;
  final double additionalHeight;

  const ShellBottomSpacer({
    super.key,
    this.hasBottomNav = true,
    this.additionalHeight = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = hasBottomNav
        ? MediaQuery.paddingOf(context).bottom
        : MediaQuery.viewPaddingOf(context).bottom;

    final targetHeight = bottomPadding + additionalHeight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: targetHeight,
    );
  }
}

/// Sliver variant of [ShellBottomSpacer] for use inside [CustomScrollView.slivers].
class SliverShellBottomSpacer extends StatelessWidget {
  final bool hasBottomNav;
  final double additionalHeight;

  const SliverShellBottomSpacer({
    super.key,
// ... [remaining code in source file] ...
```
