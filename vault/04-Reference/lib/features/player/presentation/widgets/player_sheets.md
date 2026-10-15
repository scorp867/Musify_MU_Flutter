---
title: "player_sheets.dart"
path: "lib/features/player/presentation/widgets/player_sheets.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 186
incoming_dependencies: 1
outgoing_dependencies: 1
---

# player_sheets.dart

> Source File: `[lib/features/player/presentation/widgets/player_sheets.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/presentation/widgets/player_sheets.dart)`
> Layer: `lib/features/player/presentation/widgets`

## Executive Summary
`player_sheets.dart` is an essential file in `lib/features/player/presentation/widgets` providing definitions for `PlayerOptionsSheet`, `PlayerTrackDetailsSheet`, `PlayerSheetHeader`, `PlayerSheetDetailRow`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `duration_formatter.dart` | `lib/core/ui/formatters` | [[04-Reference/lib/core/ui/formatters/duration_formatter|duration_formatter.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `player_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/player_screen|player_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class PlayerOptionsSheet`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `onShowDetails` | `VoidCallback` |
| `onShowQueue` | `VoidCallback` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |

#### `class PlayerTrackDetailsSheet`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `MediaItem` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |

#### `class PlayerSheetHeader`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `title` | `String` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `PlayerCircleButton` | `dynamic` | `icon: Icons.close_rounded, tooltip: 'Close', on...` |

#### `class PlayerSheetDetailRow`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `label` | `String` |
| `value` | `String` |

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
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';

import 'player_header.dart';
import 'player_theme.dart';

class PlayerOptionsSheet extends StatelessWidget {
  const PlayerOptionsSheet({
    super.key,
    required this.onShowDetails,
    required this.onShowQueue,
  });

  final VoidCallback onShowDetails;
  final VoidCallback onShowQueue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: const PlayerSheetHeader(title: 'Track options'),
          ),
          ListTile(
            leading: const Icon(
              Icons.info_outline_rounded,
              color: PlayerColors.accent,
            ),
            title: const Text(
              'Track details',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              onShowDetails();
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.queue_music_rounded,
              color: PlayerColors.accent,
// ... [remaining code in source file] ...
```
