---
title: "queue_track_tile.dart"
path: "lib/features/player/presentation/widgets/queue_track_tile.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 106
incoming_dependencies: 0
outgoing_dependencies: 1
---

# queue_track_tile.dart

> Source File: `[lib/features/player/presentation/widgets/queue_track_tile.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/presentation/widgets/queue_track_tile.dart)`
> Layer: `lib/features/player/presentation/widgets`

## Executive Summary
`queue_track_tile.dart` is an essential file in `lib/features/player/presentation/widgets` providing definitions for `QueueTrackTile`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `duration_formatter.dart` | `lib/core/ui/formatters` | [[04-Reference/lib/core/ui/formatters/duration_formatter|duration_formatter.dart]] |

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class QueueTrackTile`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `MediaItem` |
| `index` | `int` |
| `onTap` | `VoidCallback` |

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

import 'player_artwork.dart';
import 'player_theme.dart';

class QueueTrackTile extends StatelessWidget {
  const QueueTrackTile({
    super.key,
    required this.item,
    required this.index,
    required this.onTap,
  });

  final MediaItem item;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: PlayerColors.accent.withValues(alpha: 0.06),
          highlightColor: PlayerColors.accent.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: PlayerArtworkImage(
                      item: item,
                      artworkWidth: 44,
                      artworkHeight: 44,
                      placeholderIconSize: 18,
                    ),
                  ),
                ),
// ... [remaining code in source file] ...
```
