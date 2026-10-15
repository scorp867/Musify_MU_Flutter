---
title: "artist_circle_card.dart"
path: "lib/features/home_feed/presentation/widgets/cards/artist_circle_card.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 81
incoming_dependencies: 1
outgoing_dependencies: 2
---

# artist_circle_card.dart

> Source File: `[lib/features/home_feed/presentation/widgets/cards/artist_circle_card.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/cards/artist_circle_card.dart)`
> Layer: `lib/features/home_feed/presentation/widgets/cards`

## Executive Summary
`artist_circle_card.dart` is an essential file in `lib/features/home_feed/presentation/widgets/cards` providing definitions for `ArtistCircleCard`.
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

## Declarations & API Breakdown

### Classes & Mixins
#### `class ArtistCircleCard`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `SpotifyEntity` |
| `size` | `double` |
| `title` | `final` |
| `imageUrl` | `final` |
| `pixelSize` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `ClipOval` | `dynamic` | `child: imageUrl != null ? AppNetworkImage( imag...` |

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

/// Reusable circle card for artists.
/// Shows: circle artwork + name + "Artist" label -- matches Spotify's layout.
class ArtistCircleCard extends StatelessWidget {
  final SpotifyEntity item;
  final double size;

  const ArtistCircleCard({
    super.key,
    required this.item,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    final title = item.cardTitle;
    final imageUrl = item.cardImageUrl;
    final pixelSize = (size * 2).toInt();

    return SizedBox(
      width: size,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            child: Container(
              width: size - 10,
              height: size - 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF282828),
              ),
              child: ClipOval(
                child: imageUrl != null
                    ? AppNetworkImage(
                        imageUrl: imageUrl,
                        width: size - 10,
                        height: size - 10,
                        fit: BoxFit.cover,
                        memCacheWidth: pixelSize,
// ... [remaining code in source file] ...
```
