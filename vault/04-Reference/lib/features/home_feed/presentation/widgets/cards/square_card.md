---
title: "square_card.dart"
path: "lib/features/home_feed/presentation/widgets/cards/square_card.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 89
incoming_dependencies: 2
outgoing_dependencies: 2
---

# square_card.dart

> Source File: `[lib/features/home_feed/presentation/widgets/cards/square_card.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/cards/square_card.dart)`
> Layer: `lib/features/home_feed/presentation/widgets/cards`

## Executive Summary
`square_card.dart` is an essential file in `lib/features/home_feed/presentation/widgets/cards` providing definitions for `SquareCard`.
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
| `content_carousel_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/content_carousel_section|content_carousel_section.dart]] |
| `preview_carousel_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/preview_carousel_section|preview_carousel_section.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class SquareCard`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `SpotifyEntity` |
| `size` | `double` |
| `title` | `final` |
| `subtitle` | `final` |
| `imageUrl` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
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

/// Reusable square card for albums, playlists, podcasts.
/// Renders: artwork + title + subtitle (no type labels -- Spotify doesn't show those).
/// Used in ContentCarouselSection.
class SquareCard extends StatelessWidget {
  final SpotifyEntity item;
  final double size;

  const SquareCard({
    super.key,
    required this.item,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    final title = item.cardTitle;
    final subtitle = item.getTrait<SimpleCardTrait>()?.subtitle ?? '';
    final imageUrl = item.cardImageUrl;

    return SizedBox(
      width: size,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: size,
              height: size,
              color: const Color(0xFF282828),
              child: imageUrl != null
                  ? AppNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: (size * 2).toInt(),
                      memCacheHeight: (size * 2).toInt(),
                      errorWidget: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
// ... [remaining code in source file] ...
```
