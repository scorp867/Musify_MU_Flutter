---
title: "app_header.dart"
path: "lib/core/ui/widgets/app_header.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, ui]
lines: 101
incoming_dependencies: 6
outgoing_dependencies: 0
---

# app_header.dart

> Source File: `[lib/core/ui/widgets/app_header.dart](file:///c:/Users/Admin/Musify_MU/lib/core/ui/widgets/app_header.dart)`
> Layer: `lib/core/ui/widgets`

## Executive Summary
`app_header.dart` is an essential file in `lib/core/ui/widgets` providing definitions for `AppHeader`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `main_screen.dart` | `lib/features/shell/presentation` | [[04-Reference/lib/features/shell/presentation/main_screen|main_screen.dart]] |
| `library_view.dart` | `lib/features/library/presentation` | [[04-Reference/lib/features/library/presentation/library_view|library_view.dart]] |
| `offline_library_view.dart` | `lib/features/library/presentation` | [[04-Reference/lib/features/library/presentation/offline_library_view|offline_library_view.dart]] |
| `home_header.dart` | `lib/features/home/presentation/widgets` | [[04-Reference/lib/features/home/presentation/widgets/home_header|home_header.dart]] |
| `browse_view.dart` | `lib/features/browse/presentation` | [[04-Reference/lib/features/browse/presentation/browse_view|browse_view.dart]] |
| `offline_browse_view.dart` | `lib/features/browse/presentation` | [[04-Reference/lib/features/browse/presentation/offline_browse_view|offline_browse_view.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class AppHeader`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `leading` | `Widget?` |
| `title` | `String` |
| `titleStyle` | `TextStyle?` |
| `trailing` | `List<Widget>` |
| `onLeadingTap` | `VoidCallback?` |
| `bottom` | `Widget?` |
| `padding` | `EdgeInsetsGeometry` |

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

/// Shared app header bar used across all main tabs.
///
/// Layout:
///   Row 1:  [leading] [title]                    [...trailing]
///   Row 2:  [bottom] (optional, e.g. filter chips)
///
/// Each screen customises via:
///   - `leading`: widget on the far left (app icon, avatar, etc.)
///   - `title`: the header text
///   - `trailing`: list of action widgets on the right
///   - `bottom`: optional widget below the title row (filter chips, etc.)
class AppHeader extends StatelessWidget {
  /// Widget on the far left (e.g. app icon, user avatar).
  final Widget? leading;

  /// Header title text.
  final String title;

  /// Style override for the title.
  final TextStyle? titleStyle;

  /// Action widgets on the right side.
  final List<Widget> trailing;

  /// Called when the leading widget is tapped.
  final VoidCallback? onLeadingTap;

  /// Optional widget below the title row (e.g. filter chips).
  final Widget? bottom;

  /// Horizontal padding for the title row.
  final EdgeInsetsGeometry padding;

  const AppHeader({
    super.key,
    this.leading,
    required this.title,
    this.titleStyle,
    this.trailing = const [],
    this.onLeadingTap,
    this.bottom,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });
// ... [remaining code in source file] ...
```
