---
title: "promotion_banner_section.dart"
path: "lib/features/home_feed/presentation/widgets/sections/promotion_banner_section.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 194
incoming_dependencies: 1
outgoing_dependencies: 2
---

# promotion_banner_section.dart

> Source File: `[lib/features/home_feed/presentation/widgets/sections/promotion_banner_section.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/sections/promotion_banner_section.dart)`
> Layer: `lib/features/home_feed/presentation/widgets/sections`

## Executive Summary
`promotion_banner_section.dart` is an essential file in `lib/features/home_feed/presentation/widgets/sections` providing definitions for `PromotionBannerSection`.
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
#### `class PromotionBannerSection`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `title` | `String` |
| `items` | `List<SpotifyEntity>` |
| `preview` | `final` |
| `item` | `final` |
| `displayTitle` | `final` |
| `subtitle` | `final` |
| `imageUrl` | `final` |
| `typeLabel` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `_contentTypeLabel` | `String` | `SpotifyEntity item` |
| `build` | `Widget` | `BuildContext context` |
| `AspectRatio` | `dynamic` | `aspectRatio: 1, child: imageUrl != null && imag...` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:musify_mu/core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Promotion banner / "Picked for you" section matching Spotify's exact horizontal card layout:
///   ┌──────────────────────────────────────────────────┐
///   │  ┌─────────┐   Playlist                       ⋮  │
///   │  │ [Image] │   Deep Sleep                        │
///   │  │         │   Soothing, minimalist ambient...   │
///   │  └─────────┘   ⊕                              ▶  │
///   └──────────────────────────────────────────────────┘
class PromotionBannerSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const PromotionBannerSection({
    super.key,
    required this.title,
    required this.items,
  });

  String _contentTypeLabel(SpotifyEntity item) {
    final preview = item.getTrait<PreviewCardTrait>();
    if (preview != null && preview.contentTypeName.isNotEmpty) {
      return preview.contentTypeName;
    }
    return switch (item.type) {
      ContentType.playlist => 'Playlist',
      ContentType.album => 'Album',
      ContentType.podcast => 'Podcast',
      ContentType.episode => 'Episode',
      ContentType.artist => 'Artist',
      ContentType.track => 'Song',
      ContentType.unknown => 'Playlist',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final item = items.first;

    final displayTitle = item.cardTitle.isNotEmpty ? item.cardTitle : item.previewTitle;
    final subtitle = item.getTrait<SimpleCardTrait>()?.subtitle
        ?? item.getTrait<PreviewCardTrait>()?.description
// ... [remaining code in source file] ...
```
