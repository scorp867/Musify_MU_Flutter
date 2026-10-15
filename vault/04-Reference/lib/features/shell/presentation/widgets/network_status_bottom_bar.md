---
title: "network_status_bottom_bar.dart"
path: "lib/features/shell/presentation/widgets/network_status_bottom_bar.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, shell]
lines: 65
incoming_dependencies: 2
outgoing_dependencies: 2
---

# network_status_bottom_bar.dart

> Source File: `[lib/features/shell/presentation/widgets/network_status_bottom_bar.dart](file:///c:/Users/Admin/Musify_MU/lib/features/shell/presentation/widgets/network_status_bottom_bar.dart)`
> Layer: `lib/features/shell/presentation/widgets`

## Executive Summary
`network_status_bottom_bar.dart` is an essential file in `lib/features/shell/presentation/widgets` providing definitions for `NetworkStatusBottomBar`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `network_status_bloc.dart` | `lib/core/network/status/bloc` | [[04-Reference/lib/core/network/status/bloc/network_status_bloc|network_status_bloc.dart]] |
| `network_status.dart` | `lib/core/network/status` | [[04-Reference/lib/core/network/status/network_status|network_status.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `main_screen.dart` | `lib/features/shell/presentation` | [[04-Reference/lib/features/shell/presentation/main_screen|main_screen.dart]] |
| `network_status_bottom_bar_test.dart` | `test/features/shell` | [[04-Reference/test/features/shell/network_status_bottom_bar_test|network_status_bottom_bar_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class NetworkStatusBottomBar`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `isVisible` | `final` |
| `color` | `final` |
| `message` | `final` |
| `bottomInset` | `final` |
| `targetHeight` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `_getStatusColor` | `Color` | `NetworkStatus status` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/network/status/bloc/network_status_bloc.dart';
import 'package:musify_mu/core/network/status/network_status.dart';

/// An ultra-sleek, full-width ambient status bar displayed at the bottom-most
/// boundary of the shell. Lifts the screen content when active, accounts for
/// system navigation insets, and collapses to 0 when online.
class NetworkStatusBottomBar extends StatelessWidget {
  const NetworkStatusBottomBar({super.key});

  /// The visible content strip height above system navigation bars.
  static const double contentHeight = 16.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkStatusBloc, NetworkStatusState>(
      builder: (context, state) {
        final isVisible = state.isVisible;
        final color = isVisible ? _getStatusColor(state.status) : Colors.transparent;
        final message = state.message ?? '';
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        final targetHeight = isVisible ? (contentHeight + bottomInset) : 0.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: double.infinity,
          height: targetHeight,
          color: color,
          clipBehavior: Clip.hardEdge,
          child: isVisible
              ? Container(
                  height: contentHeight,
                  margin: EdgeInsets.only(bottom: bottomInset),
                  alignment: Alignment.center,
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: Colors.white,
                      height: 1.0,
                    ),
// ... [remaining code in source file] ...
```
