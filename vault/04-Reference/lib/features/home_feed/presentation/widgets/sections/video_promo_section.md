---
title: "video_promo_section.dart"
path: "lib/features/home_feed/presentation/widgets/sections/video_promo_section.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 175
incoming_dependencies: 1
outgoing_dependencies: 2
---

# video_promo_section.dart

> Source File: `[lib/features/home_feed/presentation/widgets/sections/video_promo_section.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/sections/video_promo_section.dart)`
> Layer: `lib/features/home_feed/presentation/widgets/sections`

## Executive Summary
`video_promo_section.dart` is an essential file in `lib/features/home_feed/presentation/widgets/sections` providing definitions for `VideoPromoSection`.
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
#### `class VideoPromoSection`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `title` | `String` |
| `items` | `List<SpotifyEntity>` |
| `item` | `final` |
| `videoTrait` | `final` |
| `simpleTrait` | `final` |
| `previewTrait` | `final` |
| `displayTitle` | `final` |
| `subtitle` | `final` |
| `overline` | `final` |
| `videoThumbnail` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `AppNetworkImage` | `dynamic` | `imageUrl: videoThumbnail, fit: BoxFit.cover, me...` |

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

/// Single-item promotional video card section (matches Spotify Android's vbb0 / VideoPromo).
/// Renders a prominent 16:9 video promo banner with playback affordance.
class VideoPromoSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const VideoPromoSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final item = items.first;
    final videoTrait = item.getTrait<VideoCardTrait>();
    final simpleTrait = item.getTrait<SimpleCardTrait>();
    final previewTrait = item.getTrait<PreviewCardTrait>();

    final displayTitle = videoTrait?.title.isNotEmpty == true
        ? videoTrait!.title
        : (simpleTrait?.title ?? previewTrait?.title ?? '');
    final subtitle = videoTrait?.subtitle.isNotEmpty == true
        ? videoTrait!.subtitle
        : (simpleTrait?.subtitle ?? previewTrait?.description ?? '');
    final overline = videoTrait?.overline ?? '';

    final videoThumbnail = item.videoThumbnailUrl ??
        videoTrait?.videoThumbnailUrl ??
        item.cardImageUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
// ... [remaining code in source file] ...
```
