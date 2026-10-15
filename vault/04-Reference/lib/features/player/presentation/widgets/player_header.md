---
title: "player_header.dart"
path: "lib/features/player/presentation/widgets/player_header.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 176
incoming_dependencies: 1
outgoing_dependencies: 0
---

# player_header.dart

> Source File: `[lib/features/player/presentation/widgets/player_header.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/presentation/widgets/player_header.dart)`
> Layer: `lib/features/player/presentation/widgets`

## Executive Summary
`player_header.dart` is an essential file in `lib/features/player/presentation/widgets` providing definitions for `PlayerHeader`, `PlayerCircleButton`, `PlayerEmptyState`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `player_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/player_screen|player_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class PlayerHeader`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `onClose` | `VoidCallback` |
| `onMore` | `VoidCallback` |
| `contextTitle` | `String?` |
| `contextSubtitle` | `String?` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |

#### `class PlayerCircleButton`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `icon` | `IconData` |
| `tooltip` | `String` |
| `onPressed` | `VoidCallback` |
| `iconColor` | `Color` |
| `backgroundColor` | `Color?` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |

#### `class PlayerEmptyState`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `onClose` | `VoidCallback` |
| `onMore` | `VoidCallback` |

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

import 'player_theme.dart';

class PlayerHeader extends StatelessWidget {
  const PlayerHeader({
    super.key,
    required this.onClose,
    required this.onMore,
    this.contextTitle,
    this.contextSubtitle,
  });

  final VoidCallback onClose;
  final VoidCallback onMore;
  final String? contextTitle;
  final String? contextSubtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 32,
            ),
            tooltip: 'Close player',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: onClose,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (contextTitle ?? 'NOW PLAYING').toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
// ... [remaining code in source file] ...
```
