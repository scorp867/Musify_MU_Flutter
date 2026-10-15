---
title: "audio_spotlight_section.dart"
path: "lib/features/home_feed/presentation/widgets/sections/audio_spotlight_section.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 148
incoming_dependencies: 1
outgoing_dependencies: 2
---

# audio_spotlight_section.dart

> Source File: `[lib/features/home_feed/presentation/widgets/sections/audio_spotlight_section.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/sections/audio_spotlight_section.dart)`
> Layer: `lib/features/home_feed/presentation/widgets/sections`

## Executive Summary
`audio_spotlight_section.dart` is an essential file in `lib/features/home_feed/presentation/widgets/sections` providing definitions for `AudioSpotlightSection`.
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
#### `class AudioSpotlightSection`
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
| `contentType` | `final` |
| `creator` | `final` |
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

/// Audio spotlight card with artwork and preview info.
/// Used for audioSpotlight (tag 36) and audioPromo (tag 33).
class AudioSpotlightSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const AudioSpotlightSection({
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
    final contentType = previewTrait?.contentTypeName ?? '';
    final creator = previewTrait?.creatorName ?? '';

    final bgHex = previewTrait?.backgroundColor;
    Color bgColor = const Color(0xFF2A2A2A);
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
// ... [remaining code in source file] ...
```
