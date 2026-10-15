---
title: "preview_carousel_section.dart"
path: "lib/features/home_feed/presentation/widgets/sections/preview_carousel_section.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 122
incoming_dependencies: 1
outgoing_dependencies: 5
---

# preview_carousel_section.dart

> Source File: `[lib/features/home_feed/presentation/widgets/sections/preview_carousel_section.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/sections/preview_carousel_section.dart)`
> Layer: `lib/features/home_feed/presentation/widgets/sections`

## Executive Summary
`preview_carousel_section.dart` is an essential file in `lib/features/home_feed/presentation/widgets/sections` providing definitions for `PreviewCarouselSection`, `_PreviewCarouselSectionState`.
**Primary Architecture Role**: Widget State Lifecycle Handler, Stateful Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `data_pool.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool|data_pool.dart]] |
| `preview_card_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/preview_card_data_element|preview_card_data_element.dart]] |
| `spotify_entity.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/spotify_entity|spotify_entity.dart]] |
| `preview_card.dart` | `lib/features/home_feed/presentation/widgets/cards` | [[04-Reference/lib/features/home_feed/presentation/widgets/cards/preview_card|preview_card.dart]] |
| `square_card.dart` | `lib/features/home_feed/presentation/widgets/cards` | [[04-Reference/lib/features/home_feed/presentation/widgets/cards/square_card|square_card.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `section_registry.dart` | `lib/features/home_feed/presentation` | [[04-Reference/lib/features/home_feed/presentation/section_registry|section_registry.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class PreviewCarouselSection`
- **Archetype**: Stateful Widget
- **Extends**: `StatefulWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `title` | `String` |
| `items` | `List<SpotifyEntity>` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `createState` | `State<PreviewCarouselSection>` | `(none)` |

#### `class _PreviewCarouselSectionState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<PreviewCarouselSection>`
- **With Mixins**: `AutomaticKeepAliveClientMixin`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `null` | `return` |
| `pool` | `final` |
| `uris` | `final` |
| `pool` | `final` |
| `rawItem` | `final` |
| `currentTraits` | `final` |
| `item` | `final` |
| `previewTrait` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `initState` | `void` | `(none)` |
| `didUpdateWidget` | `void` | `covariant PreviewCarouselSection oldWidget` |
| `_resolvePool` | `DataPool?` | `(none)` |
| `_loadSectionTraits` | `void` | `(none)` |
| `map` | `dynamic` | `(e` |
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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/home_feed/data/elements/preview_card_data_element.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/cards/preview_card.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/cards/square_card.dart';

/// Preview carousel section -- horizontal scroll of preview cards.
/// Maps to Casita Section body field 37 (PreviewCarousel).
/// Spotify shows these as wide cards (~310px) in a horizontal list.
class PreviewCarouselSection extends StatefulWidget {
  final String title;
  final List<SpotifyEntity> items;

  const PreviewCarouselSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<PreviewCarouselSection> createState() => _PreviewCarouselSectionState();
}

class _PreviewCarouselSectionState extends State<PreviewCarouselSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSectionTraits();
  }

  @override
  void didUpdateWidget(covariant PreviewCarouselSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _loadSectionTraits();
    }
  }

  DataPool? _resolvePool() {
// ... [remaining code in source file] ...
```
