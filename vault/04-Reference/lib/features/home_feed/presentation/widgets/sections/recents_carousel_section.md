---
title: "recents_carousel_section.dart"
path: "lib/features/home_feed/presentation/widgets/sections/recents_carousel_section.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 483
incoming_dependencies: 1
outgoing_dependencies: 4
---

# recents_carousel_section.dart

> Source File: `[lib/features/home_feed/presentation/widgets/sections/recents_carousel_section.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/sections/recents_carousel_section.dart)`
> Layer: `lib/features/home_feed/presentation/widgets/sections`

## Executive Summary
`recents_carousel_section.dart` is an essential file in `lib/features/home_feed/presentation/widgets/sections` providing definitions for `RecentsCarouselSection`, `_RecentsCarouselSectionState`, `_RecentsCard`.
**Primary Architecture Role**: Widget State Lifecycle Handler, Stateful Widget, Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `app_network_image.dart` | `lib/core/widgets` | [[04-Reference/lib/core/widgets/app_network_image|app_network_image.dart]] |
| `data_pool.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool|data_pool.dart]] |
| `image_link_card_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/image_link_card_data_element|image_link_card_data_element.dart]] |
| `spotify_entity.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/spotify_entity|spotify_entity.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `section_registry.dart` | `lib/features/home_feed/presentation` | [[04-Reference/lib/features/home_feed/presentation/section_registry|section_registry.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class RecentsCarouselSection`
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
| `createState` | `State<RecentsCarouselSection>` | `(none)` |

#### `class _RecentsCarouselSectionState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<RecentsCarouselSection>`
- **With Mixins**: `AutomaticKeepAliveClientMixin`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `null` | `return` |
| `pool` | `final` |
| `allUris` | `final` |
| `meta` | `final` |
| `pool` | `final` |
| `rawItem` | `final` |
| `currentTraits` | `final` |
| `entity` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `initState` | `void` | `(none)` |
| `didUpdateWidget` | `void` | `covariant RecentsCarouselSection oldWidget` |
| `_resolvePool` | `DataPool?` | `(none)` |
| `_loadSectionTraits` | `void` | `(none)` |
| `build` | `Widget` | `BuildContext context` |

#### `class _RecentsCard`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `SpotifyEntity` |
| `pool` | `DataPool` |
| `title` | `final` |
| `recentsMeta` | `final` |
| `isArtist` | `final` |
| `isEpisode` | `final` |
| `isLikedSongs` | `final` |
| `imageUrl` | `final` |
| `trackCovers` | `final` |
| `traits` | `final` |
| `simple` | `final` |
| `visual` | `final` |
| `img` | `final` |
| `frontCoverUrl` | `final` |
| `hasMultipleTracks` | `final` |
| `isEpisode` | `bool` |
| `showCheckmark` | `final` |
| `subtitleText` | `String` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `_buildArtistAvatar` | `Widget` | `(none)` |
| `AppNetworkImage` | `?` | `imageUrl: imageUrl, fit: BoxFit.cover, memCache...` |
| `_buildStackedArtworkWithBadge` | `Widget` | `bool isLikedSongs, bool isEpisode, RecentsMetad...` |
| `_artworkTile` | `Widget` | `String? imageUrl, double width, double height, ...` |
| `AppNetworkImage` | `dynamic` | `imageUrl: imageUrl, fit: BoxFit.cover, memCache...` |
| `_buildLikedSongsBadge` | `Widget` | `(none)` |
| `_buildPlaylistMiniBadge` | `Widget` | `List<String> trackCovers` |
| `AppNetworkImage` | `?` | `imageUrl: item.cardImageUrl!, fit: BoxFit.cover...` |
| `_buildSubtitleRow` | `Widget` | `RecentsMetadataTrait? meta` |
| `_placeholder` | `Widget` | `(none)` |

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
import 'package:musify_mu/features/home_feed/data/elements/image_link_card_data_element.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Recents carousel matching Spotify's 1:1 layout:
///   - 112dp card width, 97dp artwork size, 175dp carousel height
///   - Stacked artwork for multiple tracks (Layer 2 -> Layer 1 -> Layer 0)
///   - Anchored bottom-left badge (0.373 * 97 = 36dp):
///       * Liked Songs: #431337 badge with white heart
///       * Playlists: 2x2 miniature grid badge
///   - Inline green circle checkmark (#1DB954, Icons.check) before action subtitle
class RecentsCarouselSection extends StatefulWidget {
  final String title;
  final List<SpotifyEntity> items;

  const RecentsCarouselSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<RecentsCarouselSection> createState() => _RecentsCarouselSectionState();
}

class _RecentsCarouselSectionState extends State<RecentsCarouselSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSectionTraits();
  }

  @override
  void didUpdateWidget(covariant RecentsCarouselSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _loadSectionTraits();
    }
// ... [remaining code in source file] ...
```
