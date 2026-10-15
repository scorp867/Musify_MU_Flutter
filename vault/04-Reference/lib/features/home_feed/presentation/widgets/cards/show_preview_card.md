---
title: "show_preview_card.dart"
path: "lib/features/home_feed/presentation/widgets/cards/show_preview_card.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 298
incoming_dependencies: 1
outgoing_dependencies: 3
---

# show_preview_card.dart

> Source File: `[lib/features/home_feed/presentation/widgets/cards/show_preview_card.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/cards/show_preview_card.dart)`
> Layer: `lib/features/home_feed/presentation/widgets/cards`

## Executive Summary
`show_preview_card.dart` is an essential file in `lib/features/home_feed/presentation/widgets/cards` providing definitions for `ShowPreviewCard`, `_ShowPreviewCardState`.
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
| `podcast_preview_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/podcast_preview_section|podcast_preview_section.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class ShowPreviewCard`
- **Archetype**: Stateful Widget
- **Extends**: `StatefulWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `SpotifyEntity` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `createState` | `State<ShowPreviewCard>` | `(none)` |

#### `class _ShowPreviewCardState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<ShowPreviewCard>`

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
| `hex` | `final` |
| `argbHex` | `String` |
| `base` | `final` |
| `item` | `final` |
| `previewTrait` | `final` |
| `simpleTrait` | `final` |
| `title` | `final` |
| `publisher` | `final` |
| `description` | `final` |
| `artworkUrl` | `final` |
| `bgColor` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `initState` | `void` | `(none)` |
| `didUpdateWidget` | `void` | `ShowPreviewCard oldWidget` |
| `_resolveColor` | `void` | `(none)` |
| `then` | `dynamic` | `(color` |
| `setState` | `dynamic` | `(` |
| `_sanitizeColor` | `Color` | `Color color` |
| `_cardBackgroundColor` | `Color` | `(none)` |
| `build` | `Widget` | `BuildContext context` |
| `SizedBox` | `dynamic` | `width: 88, height: 88, child: artworkUrl != nul...` |

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

/// Renders a podcast show preview card matching Spotify Android layout:
///   ┌────────────────────────────────────────────────────────┐
///   │ [88x88 Art]  Show Title (max 2 lines)                ⋮ │
///   │              Publisher / Host                          │
///   │                                                        │
///   │ Show description preview (optional)                    │
///   │                                                        │
///   │ [🔊 Preview show]                              ⊕   ▶   │
///   └────────────────────────────────────────────────────────┘
class ShowPreviewCard extends StatefulWidget {
  final SpotifyEntity item;

  const ShowPreviewCard({super.key, required this.item});

  @override
  State<ShowPreviewCard> createState() => _ShowPreviewCardState();
}

class _ShowPreviewCardState extends State<ShowPreviewCard> {
  Color? _extractedColor;

  @override
  void initState() {
    super.initState();
    _resolveColor();
  }

  @override
  void didUpdateWidget(ShowPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.cardImageUrl != widget.item.cardImageUrl ||
        oldWidget.item.backgroundColorHex != widget.item.backgroundColorHex) {
      _resolveColor();
    }
  }

  void _resolveColor() {
    final colorHex = widget.item.backgroundColorHex;
    if (colorHex != null && colorHex.isNotEmpty) return;
// ... [remaining code in source file] ...
```
