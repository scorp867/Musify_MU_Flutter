---
title: "preview_card.dart"
path: "lib/features/home_feed/presentation/widgets/cards/preview_card.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 288
incoming_dependencies: 2
outgoing_dependencies: 3
---

# preview_card.dart

> Source File: `[lib/features/home_feed/presentation/widgets/cards/preview_card.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/cards/preview_card.dart)`
> Layer: `lib/features/home_feed/presentation/widgets/cards`

## Executive Summary
`preview_card.dart` is an essential file in `lib/features/home_feed/presentation/widgets/cards` providing definitions for `PreviewCard`, `_PreviewCardState`.
**Primary Architecture Role**: Widget State Lifecycle Handler, Stateful Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `color_extraction_service.dart` | `lib/core/color` | [[04-Reference/lib/core/color/color_extraction_service|color_extraction_service.dart]] |
| `app_network_image.dart` | `lib/core/widgets` | [[04-Reference/lib/core/widgets/app_network_image|app_network_image.dart]] |
| `spotify_entity.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/spotify_entity|spotify_entity.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `preview_carousel_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/preview_carousel_section|preview_carousel_section.dart]] |
| `preview_feed_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/preview_feed_section|preview_feed_section.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class PreviewCard`
- **Archetype**: Stateful Widget
- **Extends**: `StatefulWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `SpotifyEntity` |
| `trait` | `PreviewCardTrait` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `createState` | `State<PreviewCard>` | `(none)` |

#### `class _PreviewCardState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<PreviewCard>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_extractedColor` | `Color?` |
| `colorHex` | `final` |
| `url` | `final` |
| `service` | `ColorExtractionService?` |
| `cached` | `final` |
| `hsl` | `final` |
| `color` | `return` |
| `trait` | `final` |
| `bgColor` | `final` |
| `topColor` | `final` |
| `darkerColor` | `final` |
| `parts` | `final` |
| `colorHex` | `final` |
| `hex` | `final` |
| `argbHex` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `initState` | `void` | `(none)` |
| `didUpdateWidget` | `void` | `PreviewCard oldWidget` |
| `_resolveColor` | `void` | `(none)` |
| `then` | `dynamic` | `(color` |
| `setState` | `dynamic` | `(` |
| `_sanitizeColor` | `Color` | `Color color` |
| `build` | `Widget` | `BuildContext context` |
| `AppNetworkImage` | `dynamic` | `imageUrl: trait.imageUrl!, width: 88, height: 8...` |
| `_buildMiddleText` | `String` | `(none)` |
| `_parseBackgroundColor` | `Color` | `(none)` |

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
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/core/widgets/app_network_image.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Renders a full-width PreviewCardTrait exactly matching Spotify's layout:
///   ┌─────────────────────────────────────┐
///   │  [image]  Title                  ⋮  │
///   │           Subtitle                  │
///   │                                     │
///   │  75 songs · Artist1, Artist2, ...   │
///   │                                     │
///   │  [🔊 Preview playlist]    ⊕   ▶    │
///   └─────────────────────────────────────┘
class PreviewCard extends StatefulWidget {
  final SpotifyEntity item;
  final PreviewCardTrait trait;

  const PreviewCard({
    super.key,
    required this.item,
    required this.trait,
  });

  @override
  State<PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<PreviewCard> {
  Color? _extractedColor;

  @override
  void initState() {
    super.initState();
    _resolveColor();
  }

  @override
  void didUpdateWidget(PreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trait.imageUrl != widget.trait.imageUrl ||
        oldWidget.trait.backgroundColor != widget.trait.backgroundColor) {
      _resolveColor();
    }
// ... [remaining code in source file] ...
```
