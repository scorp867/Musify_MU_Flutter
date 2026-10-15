---
title: "video_carousel_section.dart"
path: "lib/features/home_feed/presentation/widgets/sections/video_carousel_section.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 331
incoming_dependencies: 3
outgoing_dependencies: 4
---

# video_carousel_section.dart

> Source File: `[lib/features/home_feed/presentation/widgets/sections/video_carousel_section.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/sections/video_carousel_section.dart)`
> Layer: `lib/features/home_feed/presentation/widgets/sections`

## Executive Summary
`video_carousel_section.dart` is an essential file in `lib/features/home_feed/presentation/widgets/sections` providing definitions for `VideoCarouselSection`, `_VideoCarouselSectionState`, `VideoPreviewCard`.
**Primary Architecture Role**: Widget State Lifecycle Handler, Stateful Widget, Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `app_network_image.dart` | `lib/core/widgets` | [[04-Reference/lib/core/widgets/app_network_image|app_network_image.dart]] |
| `data_pool.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool|data_pool.dart]] |
| `preview_card_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/preview_card_data_element|preview_card_data_element.dart]] |
| `spotify_entity.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/spotify_entity|spotify_entity.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `section_registry.dart` | `lib/features/home_feed/presentation` | [[04-Reference/lib/features/home_feed/presentation/section_registry|section_registry.dart]] |
| `podcast_preview_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/podcast_preview_section|podcast_preview_section.dart]] |
| `preview_feed_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/preview_feed_section|preview_feed_section.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class VideoCarouselSection`
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
| `createState` | `State<VideoCarouselSection>` | `(none)` |

#### `class _VideoCarouselSectionState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<VideoCarouselSection>`
- **With Mixins**: `AutomaticKeepAliveClientMixin`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `null` | `return` |
| `pool` | `final` |
| `uris` | `final` |
| `pool` | `final` |
| `rawItem` | `final` |
| `currentTraits` | `final` |
| `item` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `initState` | `void` | `(none)` |
| `didUpdateWidget` | `void` | `covariant VideoCarouselSection oldWidget` |
| `_resolvePool` | `DataPool?` | `(none)` |
| `_loadSectionTraits` | `void` | `(none)` |
| `map` | `dynamic` | `(e` |
| `build` | `Widget` | `BuildContext context` |

#### `class VideoPreviewCard`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `entity` | `SpotifyEntity` |
| `simpleTrait` | `final` |
| `previewTrait` | `final` |
| `videoTrait` | `final` |
| `title` | `final` |
| `showName` | `final` |
| `videoThumbnail` | `final` |
| `showArtwork` | `final` |
| `durationStr` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `Stack` | `dynamic` | `children: [ AspectRatio( aspectRatio: 16 / 9, c...` |
| `AppNetworkImage` | `dynamic` | `imageUrl: showArtwork, width: 44, height: 44, f...` |
| `_overlayIcon` | `Widget` | `IconData icon` |

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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/home_feed/data/elements/preview_card_data_element.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Renders video episode sections matching Spotify's official layout.
///
/// Features:
///   - 16:9 video frame thumbnail with top-left duration badge (e.g. "09:22" or "25:26")
///   - Right-edge overlay controls: (+) add, mute, play button
///   - Square show artwork (44x44, 4px rounded corners) next to title and show info
///   - Horizontally pageable carousel matching Spotify's podcasts feed
class VideoCarouselSection extends StatefulWidget {
  final String title;
  final List<SpotifyEntity> items;

  const VideoCarouselSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<VideoCarouselSection> createState() => _VideoCarouselSectionState();
}

class _VideoCarouselSectionState extends State<VideoCarouselSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSectionTraits();
  }

  @override
  void didUpdateWidget(covariant VideoCarouselSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _loadSectionTraits();
    }
// ... [remaining code in source file] ...
```
