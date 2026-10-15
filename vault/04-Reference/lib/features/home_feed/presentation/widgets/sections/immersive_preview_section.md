---
title: "immersive_preview_section.dart"
path: "lib/features/home_feed/presentation/widgets/sections/immersive_preview_section.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 127
incoming_dependencies: 0
outgoing_dependencies: 2
---

# immersive_preview_section.dart

> Source File: `[lib/features/home_feed/presentation/widgets/sections/immersive_preview_section.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/sections/immersive_preview_section.dart)`
> Layer: `lib/features/home_feed/presentation/widgets/sections`

## Executive Summary
`immersive_preview_section.dart` is an essential file in `lib/features/home_feed/presentation/widgets/sections` providing definitions for `ImmersivePreviewSection`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `app_network_image.dart` | `lib/core/widgets` | [[04-Reference/lib/core/widgets/app_network_image|app_network_image.dart]] |
| `spotify_entity.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/spotify_entity|spotify_entity.dart]] |

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class ImmersivePreviewSection`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `title` | `String` |
| `items` | `List<SpotifyEntity>` |
| `item` | `final` |
| `previewTrait` | `final` |
| `simpleTrait` | `final` |
| `displayTitle` | `final` |
| `subtitle` | `final` |
| `imageUrl` | `final` |
| `bgHex` | `final` |
| `bgColor` | `Color` |

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
import 'package:musify_mu/core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Full-bleed hero preview card for preview (tag 4) and immersivePreview (tag 6).
/// Large artwork filling width, gradient overlay, title/subtitle at bottom.
class ImmersivePreviewSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const ImmersivePreviewSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final item = items.first;
    final previewTrait = item.getTrait<PreviewCardTrait>();
    final simpleTrait = item.getTrait<SimpleCardTrait>();

    final displayTitle = previewTrait?.title ?? simpleTrait?.title ?? '';
    final subtitle = previewTrait?.description ?? simpleTrait?.subtitle ?? '';
    final imageUrl = previewTrait?.imageUrl ?? simpleTrait?.imageUrl;
    final bgHex = previewTrait?.backgroundColor;

    Color bgColor = const Color(0xFF1A1A1A);
    if (bgHex != null && bgHex.length >= 6) {
      try {
        bgColor = Color(int.parse('FF${bgHex.substring(0, 6)}', radix: 16));
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                title,
// ... [remaining code in source file] ...
```
