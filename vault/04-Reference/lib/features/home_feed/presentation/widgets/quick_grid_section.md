---
title: "quick_grid_section.dart"
path: "lib/features/home_feed/presentation/widgets/quick_grid_section.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 116
incoming_dependencies: 1
outgoing_dependencies: 2
---

# quick_grid_section.dart

> Source File: `[lib/features/home_feed/presentation/widgets/quick_grid_section.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/quick_grid_section.dart)`
> Layer: `lib/features/home_feed/presentation/widgets`

## Executive Summary
`quick_grid_section.dart` is an essential file in `lib/features/home_feed/presentation/widgets` providing definitions for `QuickGridSection`, `_QuickGridTile`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `app_network_image.dart` | `lib/core/widgets` | [[04-Reference/lib/core/widgets/app_network_image|app_network_image.dart]] |
| `spotify_entity.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/spotify_entity|spotify_entity.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `section_registry.dart` | `lib/features/home_feed/presentation` | [[04-Reference/lib/features/home_feed/presentation/section_registry|section_registry.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class QuickGridSection`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `title` | `String` |
| `items` | `List<SpotifyEntity>` |
| `gridItems` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `ExcludeSemantics` | `dynamic` | `child: Wrap( spacing: 8, runSpacing: 8, childre...` |

#### `class _QuickGridTile`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `SpotifyEntity` |
| `width` | `final` |
| `title` | `final` |
| `imageUrl` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `GestureDetector` | `return` | `onTap: (` |
| `Row` | `dynamic` | `children: [ // Thumbnail SizedBox( width: 56, h...` |
| `_placeholder` | `Widget` | `(none)` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';
import 'package:musify_mu/core/widgets/app_network_image.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// 2-column compact grid  -  used for shortcuts (recently played quick access).
/// Mimics Spotify's top quick-access grid with small rectangular cards.
class QuickGridSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const QuickGridSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final gridItems = items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ExcludeSemantics(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: gridItems.map((item) => _QuickGridTile(item: item)).toList(),
            ),
// ... [remaining code in source file] ...
```
