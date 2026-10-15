---
title: "episode_list_section.dart"
path: "lib/features/home_feed/presentation/widgets/sections/episode_list_section.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 276
incoming_dependencies: 1
outgoing_dependencies: 4
---

# episode_list_section.dart

> Source File: `[lib/features/home_feed/presentation/widgets/sections/episode_list_section.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/sections/episode_list_section.dart)`
> Layer: `lib/features/home_feed/presentation/widgets/sections`

## Executive Summary
`episode_list_section.dart` is an essential file in `lib/features/home_feed/presentation/widgets/sections` providing definitions for `EpisodeListSection`, `_EpisodeListSectionState`, `_EpisodeCard`.
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

## Declarations & API Breakdown

### Classes & Mixins
#### `class EpisodeListSection`
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
| `createState` | `State<EpisodeListSection>` | `(none)` |

#### `class _EpisodeListSectionState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<EpisodeListSection>`
- **With Mixins**: `AutomaticKeepAliveClientMixin`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `null` | `return` |
| `pool` | `final` |
| `uris` | `final` |
| `pool` | `final` |
| `currentTraits` | `final` |
| `entity` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `initState` | `void` | `(none)` |
| `didUpdateWidget` | `void` | `covariant EpisodeListSection oldWidget` |
| `_resolvePool` | `DataPool?` | `(none)` |
| `_loadSectionTraits` | `void` | `(none)` |
| `map` | `dynamic` | `(e` |
| `build` | `Widget` | `BuildContext context` |
| `map` | `dynamic` | `(item` |

#### `class _EpisodeCard`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `entity` | `SpotifyEntity` |
| `simpleTrait` | `final` |
| `previewTrait` | `final` |
| `title` | `final` |
| `subtitle` | `final` |
| `imageUrl` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `SizedBox` | `dynamic` | `width: 56, height: 56, child: imageUrl != null ...` |

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

/// Renders episodes in a vertical list matching Spotify's "Episodes you might like".
///
/// Each episode card has:
///   - Square artwork on the left
///   - Title, show name, date, duration on the right
///   - "Preview episode" action bar at the bottom
///
/// This matches contentEvaluationList sections that contain episode URIs.
class EpisodeListSection extends StatefulWidget {
  final String title;
  final List<SpotifyEntity> items;

  const EpisodeListSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<EpisodeListSection> createState() => _EpisodeListSectionState();
}

class _EpisodeListSectionState extends State<EpisodeListSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSectionTraits();
  }

  @override
  void didUpdateWidget(covariant EpisodeListSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _loadSectionTraits();
// ... [remaining code in source file] ...
```
