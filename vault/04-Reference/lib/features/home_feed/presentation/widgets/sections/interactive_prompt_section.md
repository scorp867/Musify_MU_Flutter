---
title: "interactive_prompt_section.dart"
path: "lib/features/home_feed/presentation/widgets/sections/interactive_prompt_section.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 84
incoming_dependencies: 1
outgoing_dependencies: 1
---

# interactive_prompt_section.dart

> Source File: `[lib/features/home_feed/presentation/widgets/sections/interactive_prompt_section.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/sections/interactive_prompt_section.dart)`
> Layer: `lib/features/home_feed/presentation/widgets/sections`

## Executive Summary
`interactive_prompt_section.dart` is an essential file in `lib/features/home_feed/presentation/widgets/sections` providing definitions for `InteractivePromptSection`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `spotify_entity.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/spotify_entity|spotify_entity.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `section_registry.dart` | `lib/features/home_feed/presentation` | [[04-Reference/lib/features/home_feed/presentation/section_registry|section_registry.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class InteractivePromptSection`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `title` | `String` |
| `items` | `List<SpotifyEntity>` |
| `promptText` | `String` |
| `simple` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `GestureDetector` | `dynamic` | `onTap: (` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Interactive search/prompt field section.
/// Used for interactiveEntrypoint (tag 30).
/// Renders as a tappable search-style input, NOT a card.
class InteractivePromptSection extends StatelessWidget {
  final String title;
  final List<SpotifyEntity> items;

  const InteractivePromptSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    // Try to extract prompt text from the section's first item
    String promptText = '';
    if (items.isNotEmpty) {
      final simple = items.first.getTrait<SimpleCardTrait>();
      promptText = simple?.title ?? '';
    }
    if (promptText.isEmpty) {
      promptText = title.isNotEmpty ? title : 'Search for songs, artists, podcasts...';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty && title != promptText)
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
