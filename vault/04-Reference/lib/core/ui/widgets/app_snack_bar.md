---
title: "app_snack_bar.dart"
path: "lib/core/ui/widgets/app_snack_bar.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, ui]
lines: 53
incoming_dependencies: 4
outgoing_dependencies: 0
---

# app_snack_bar.dart

> Source File: `[lib/core/ui/widgets/app_snack_bar.dart](file:///c:/Users/Admin/Musify_MU/lib/core/ui/widgets/app_snack_bar.dart)`
> Layer: `lib/core/ui/widgets`

## Executive Summary
`app_snack_bar.dart` is an essential file in `lib/core/ui/widgets` providing definitions for `AppSnackBar`.
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
| `app_snack_bar_test.dart` | `test/core/ui` | [[04-Reference/test/core/ui/app_snack_bar_test|app_snack_bar_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class AppSnackBar`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `duration` | `Duration` |
| `messenger` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `clear` | `void` | `BuildContext context` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';

/// Centralized SnackBar utility for consistent, unobtrusive in-app notifications.
///
/// Design attributes:
/// - Floats above the bottom navigation bar with balanced margin spacing.
/// - Sleek, compact height with subtle 8px border radius.
/// - Clean dark theme (#282828 background, pure white text).
/// - Strict 3-second auto-dismiss with horizontal swipe-to-dismiss.
/// - No retry action (content refreshes automatically upon reconnection).
/// - Clears any pending/queued notifications before displaying.
abstract final class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
          ),
        ),
        backgroundColor: const Color(0xFF282828),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 12,
        ),
      ),
// ... [remaining code in source file] ...
```
