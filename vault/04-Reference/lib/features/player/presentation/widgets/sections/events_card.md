---
title: "events_card.dart"
path: "lib/features/player/presentation/widgets/sections/events_card.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 240
incoming_dependencies: 1
outgoing_dependencies: 2
---

# events_card.dart

> Source File: `[lib/features/player/presentation/widgets/sections/events_card.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/presentation/widgets/sections/events_card.dart)`
> Layer: `lib/features/player/presentation/widgets/sections`

## Executive Summary
`events_card.dart` is an essential file in `lib/features/player/presentation/widgets/sections` providing definitions for `PlayerEventsSection`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `data_pool.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool|data_pool.dart]] |
| `concert_trait.dart` | `lib/features/home_feed/domain/models/traits` | [[04-Reference/lib/features/home_feed/domain/models/traits/concert_trait|concert_trait.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `debug_now_playing_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/debug_now_playing_screen|debug_now_playing_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class PlayerEventsSection`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `artistName` | `String` |
| `bannerImageUrl` | `String?` |
| `dataPool` | `DataPool?` |
| `artistUri` | `String?` |
| `onFindTickets` | `VoidCallback?` |
| `onShowAll` | `VoidCallback?` |
| `concert` | `final` |
| `date` | `final` |
| `months` | `const` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `_buildCard` | `Widget` | `{ required String title, required String artist...` |
| `network` | `dynamic` | `bannerImageUrl!, fit: BoxFit.cover, errorBuilde...` |
| `_buildBannerPlaceholder` | `Widget` | `(none)` |
| `_formatEventDate` | `String` | `int timestamp` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/concert_trait.dart';

/// Spotify-identical On Tour / Live Events card
/// (`ScrollCardType.ON_TOUR` / `on_tour_event_card_layout.xml`).
///
/// Features:
/// - 16dp rounded corners (`widgets_corner_radius`)
/// - Elevated base background (#242424)
/// - Top 3:2 banner with gradient scrim (`on_tour_event_card_gradient`)
/// - "On Tour" header + "Show all" tertiary button
/// - Artist name, concert date/venue, and location details
/// - Outline "Find tickets" secondary button (`Encore.Button.Secondary.Small`)
/// - Dual-mode: Binds to [DataPool] [ConcertTrait] when available (online).
class PlayerEventsSection extends StatelessWidget {
  const PlayerEventsSection({
    super.key,
    required this.artistName,
    this.bannerImageUrl,
    this.dataPool,
    this.artistUri,
    this.onFindTickets,
    this.onShowAll,
  });

  final String artistName;
  final String? bannerImageUrl;
  final DataPool? dataPool;
  final String? artistUri;
  final VoidCallback? onFindTickets;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    if (dataPool != null && artistUri != null && artistUri!.isNotEmpty) {
      return StreamBuilder<Map<String, dynamic>>(
        stream: dataPool!.watchEntity(artistUri!),
        initialData: dataPool!.getTraits(artistUri!),
        builder: (context, snapshot) {
          final concert = dataPool!.getTrait<ConcertTrait>(artistUri!);
          return _buildCard(
            title: concert?.title.isNotEmpty == true
                ? concert!.title
                : 'Live Tour',
// ... [remaining code in source file] ...
```
