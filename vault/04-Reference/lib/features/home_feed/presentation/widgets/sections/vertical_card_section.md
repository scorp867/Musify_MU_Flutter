---
title: "vertical_card_section.dart"
path: "lib/features/home_feed/presentation/widgets/sections/vertical_card_section.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 93
incoming_dependencies: 1
outgoing_dependencies: 2
---

# vertical_card_section.dart

> Source File: `[lib/features/home_feed/presentation/widgets/sections/vertical_card_section.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/sections/vertical_card_section.dart)`
> Layer: `lib/features/home_feed/presentation/widgets/sections`

## Executive Summary
`vertical_card_section.dart` is an essential file in `lib/features/home_feed/presentation/widgets/sections` providing definitions for `VerticalCardSection`.
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
#### `class VerticalCardSection`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `title` | `String` |
| `items` | `List<SpotifyEntity>` |
| `item` | `final` |
| `simpleTrait` | `final` |
| `previewTrait` | `final` |
| `displayTitle` | `final` |
| `subtitle` | `final` |
| `imageUrl` | `final` |

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

/// Single large vertical card layout.
/// Used for verticalSingleEntry (tag 24).
/// Full-width artwork on top with title/subtitle below.
class VerticalCardSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const VerticalCardSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final item = items.first;
    final simpleTrait = item.getTrait<SimpleCardTrait>();
    final previewTrait = item.getTrait<PreviewCardTrait>();

    final displayTitle = simpleTrait?.title ?? previewTrait?.title ?? '';
    final subtitle = simpleTrait?.subtitle ?? previewTrait?.description ?? '';
    final imageUrl = simpleTrait?.imageUrl ?? previewTrait?.imageUrl;

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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
// ... [remaining code in source file] ...
```
