---
title: "showcase_section.dart"
path: "lib/features/home_feed/presentation/widgets/sections/showcase_section.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 128
incoming_dependencies: 1
outgoing_dependencies: 2
---

# showcase_section.dart

> Source File: `[lib/features/home_feed/presentation/widgets/sections/showcase_section.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/sections/showcase_section.dart)`
> Layer: `lib/features/home_feed/presentation/widgets/sections`

## Executive Summary
`showcase_section.dart` is an essential file in `lib/features/home_feed/presentation/widgets/sections` providing definitions for `ShowcaseSection`.
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
#### `class ShowcaseSection`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `title` | `String` |
| `items` | `List<SpotifyEntity>` |
| `item` | `final` |
| `imageUrl` | `final` |
| `itemTitle` | `final` |
| `subtitle` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `AppNetworkImage` | `dynamic` | `imageUrl: imageUrl, fit: BoxFit.cover, memCache...` |

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

/// Showcase / Immersive preview section -- full-width image with gradient overlay.
/// Maps to Casita Section body fields: 6 (ImmersivePreview), 17 (Showcase),
/// 36 (AudioSpotlight).
/// Spotify renders these as a large full-width card (~220px) with the artwork
/// filling the entire space and text overlaid at the bottom via gradient.
class ShowcaseSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const ShowcaseSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final item = items.first;
    final imageUrl = item.previewImageUrl;
    final itemTitle = item.previewTitle;
    final subtitle = item.getTrait<SimpleCardTrait>()?.subtitle ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
        Padding(
// ... [remaining code in source file] ...
```
