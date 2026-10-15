---
title: "player_metadata.dart"
path: "lib/features/player/presentation/widgets/player_metadata.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 69
incoming_dependencies: 1
outgoing_dependencies: 0
---

# player_metadata.dart

> Source File: `[lib/features/player/presentation/widgets/player_metadata.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/presentation/widgets/player_metadata.dart)`
> Layer: `lib/features/player/presentation/widgets`

## Executive Summary
`player_metadata.dart` is an essential file in `lib/features/player/presentation/widgets` providing definitions for `PlayerMetadata`.
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
#### `class PlayerMetadata`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `MediaItem` |
| `isFavorite` | `bool` |
| `onFavoriteChanged` | `VoidCallback` |

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

class PlayerMetadata extends StatelessWidget {
  const PlayerMetadata({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onFavoriteChanged,
  });

  final MediaItem item;
  final bool isFavorite;
  final VoidCallback onFavoriteChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.title.isEmpty ? 'Unknown Track' : item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.artist?.isNotEmpty == true
                    ? item.artist!
                    : 'Unknown Artist',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
// ... [remaining code in source file] ...
```
