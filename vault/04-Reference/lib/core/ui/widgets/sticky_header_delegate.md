---
title: "sticky_header_delegate.dart"
path: "lib/core/ui/widgets/sticky_header_delegate.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, ui]
lines: 43
incoming_dependencies: 3
outgoing_dependencies: 0
---

# sticky_header_delegate.dart

> Source File: `[lib/core/ui/widgets/sticky_header_delegate.dart](file:///c:/Users/Admin/Musify_MU/lib/core/ui/widgets/sticky_header_delegate.dart)`
> Layer: `lib/core/ui/widgets`

## Executive Summary
`sticky_header_delegate.dart` is an essential file in `lib/core/ui/widgets` providing definitions for `StickyHeaderDelegate`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `library_view.dart` | `lib/features/library/presentation` | [[04-Reference/lib/features/library/presentation/library_view|library_view.dart]] |
| `home_feed_view.dart` | `lib/features/home_feed/presentation` | [[04-Reference/lib/features/home_feed/presentation/home_feed_view|home_feed_view.dart]] |
| `browse_view.dart` | `lib/features/browse/presentation` | [[04-Reference/lib/features/browse/presentation/browse_view|browse_view.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class StickyHeaderDelegate`
- **Archetype**: Core Component
- **Extends**: `SliverPersistentHeaderDelegate`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `child` | `Widget` |
| `height` | `double` |
| `backgroundColor` | `Color` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context, double shrinkOffset, bool...` |
| `shouldRebuild` | `bool` | `covariant StickyHeaderDelegate oldDelegate` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';

/// Delegate for a pinned sticky header in a [CustomScrollView].
///
/// Wraps any widget to make it stick at the top when scrolled past.
/// Used for filter chips (home) and search bar (browse).
class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final Color backgroundColor;

  StickyHeaderDelegate({
    required this.child,
    required this.height,
    this.backgroundColor = const Color(0xFF121212),
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: height,
      color: backgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant StickyHeaderDelegate oldDelegate) {
    return child != oldDelegate.child ||
        height != oldDelegate.height ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
```
