---
title: "podcast_preview_section.dart"
path: "lib/features/home_feed/presentation/widgets/sections/podcast_preview_section.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 130
incoming_dependencies: 2
outgoing_dependencies: 6
---

# podcast_preview_section.dart

> Source File: `[lib/features/home_feed/presentation/widgets/sections/podcast_preview_section.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/sections/podcast_preview_section.dart)`
> Layer: `lib/features/home_feed/presentation/widgets/sections`

## Executive Summary
`podcast_preview_section.dart` is an essential file in `lib/features/home_feed/presentation/widgets/sections` providing definitions for `PodcastPreviewSection`, `_PodcastPreviewSectionState`.
**Primary Architecture Role**: Widget State Lifecycle Handler, Stateful Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `data_pool.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool|data_pool.dart]] |
| `podcast_preview_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/podcast_preview_data_element|podcast_preview_data_element.dart]] |
| `spotify_entity.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/spotify_entity|spotify_entity.dart]] |
| `episode_preview_card.dart` | `lib/features/home_feed/presentation/widgets/cards` | [[04-Reference/lib/features/home_feed/presentation/widgets/cards/episode_preview_card|episode_preview_card.dart]] |
| `show_preview_card.dart` | `lib/features/home_feed/presentation/widgets/cards` | [[04-Reference/lib/features/home_feed/presentation/widgets/cards/show_preview_card|show_preview_card.dart]] |
| `video_carousel_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/video_carousel_section|video_carousel_section.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `section_registry.dart` | `lib/features/home_feed/presentation` | [[04-Reference/lib/features/home_feed/presentation/section_registry|section_registry.dart]] |
| `kodiak_data_layer_test.dart` | `test/features/home_feed` | [[04-Reference/test/features/home_feed/kodiak_data_layer_test|kodiak_data_layer_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class PodcastPreviewSection`
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
| `createState` | `State<PodcastPreviewSection>` | `(none)` |

#### `class _PodcastPreviewSectionState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<PodcastPreviewSection>`
- **With Mixins**: `AutomaticKeepAliveClientMixin`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `null` | `return` |
| `pool` | `final` |
| `uris` | `final` |
| `pool` | `final` |
| `isVideoSection` | `final` |
| `currentTraits` | `final` |
| `item` | `final` |
| `isVideo` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `initState` | `void` | `(none)` |
| `didUpdateWidget` | `void` | `covariant PodcastPreviewSection oldWidget` |
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
import 'package:musify_mu/features/home_feed/data/elements/podcast_preview_data_element.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/cards/episode_preview_card.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/cards/show_preview_card.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/video_carousel_section.dart';

/// Direct equivalent to Spotify Android's `p.tkn0` / `xab0` section renderer.
/// Handles Casita Tag 4 (`preview`):
/// - Video episodes / video sections: renders 16:9 [VideoPreviewCard].
/// - Audio episodes: renders 1:1 [EpisodePreviewCard].
/// - Shows: renders [ShowPreviewCard].
class PodcastPreviewSection extends StatefulWidget {
  final String title;
  final List<SpotifyEntity> items;

  const PodcastPreviewSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<PodcastPreviewSection> createState() => _PodcastPreviewSectionState();
}

class _PodcastPreviewSectionState extends State<PodcastPreviewSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSectionTraits();
  }

  @override
  void didUpdateWidget(covariant PodcastPreviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _loadSectionTraits();
    }
// ... [remaining code in source file] ...
```
