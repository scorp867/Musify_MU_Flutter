---
title: "about_artist_card.dart"
path: "lib/features/player/presentation/widgets/sections/about_artist_card.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 317
incoming_dependencies: 1
outgoing_dependencies: 5
---

# about_artist_card.dart

> Source File: `[lib/features/player/presentation/widgets/sections/about_artist_card.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/presentation/widgets/sections/about_artist_card.dart)`
> Layer: `lib/features/player/presentation/widgets/sections`

## Executive Summary
`about_artist_card.dart` is an essential file in `lib/features/player/presentation/widgets/sections` providing definitions for `PlayerAboutArtistSection`, `_PlayerAboutArtistSectionState`.
**Primary Architecture Role**: Widget State Lifecycle Handler, Stateful Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `data_pool.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool|data_pool.dart]] |
| `identity_trait.dart` | `lib/features/home_feed/domain/models/traits` | [[04-Reference/lib/features/home_feed/domain/models/traits/identity_trait|identity_trait.dart]] |
| `on_platform_reputation_trait.dart` | `lib/features/home_feed/domain/models/traits` | [[04-Reference/lib/features/home_feed/domain/models/traits/on_platform_reputation_trait|on_platform_reputation_trait.dart]] |
| `visual_identity_trait.dart` | `lib/features/home_feed/domain/models/traits` | [[04-Reference/lib/features/home_feed/domain/models/traits/visual_identity_trait|visual_identity_trait.dart]] |
| `player_artwork.dart` | `lib/features/player/presentation/widgets` | [[04-Reference/lib/features/player/presentation/widgets/player_artwork|player_artwork.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `debug_now_playing_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/debug_now_playing_screen|debug_now_playing_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class PlayerAboutArtistSection`
- **Archetype**: Stateful Widget
- **Extends**: `StatefulWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `MediaItem` |
| `dataPool` | `DataPool?` |
| `artistUri` | `String?` |
| `onFollow` | `VoidCallback?` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `createState` | `State<PlayerAboutArtistSection>` | `(none)` |

#### `class _PlayerAboutArtistSectionState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<PlayerAboutArtistSection>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_isFollowing` | `bool` |
| `_isBioExpanded` | `bool` |
| `artistName` | `final` |
| `artistUri` | `final` |
| `identity` | `final` |
| `visual` | `final` |
| `reputation` | `final` |
| `bannerUrl` | `final` |
| `isVerified` | `bool` |
| `listenersText` | `final` |
| `defaultBio` | `final` |
| `bioText` | `final` |
| `isLong` | `final` |
| `preview` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `_buildCard` | `Widget` | `{ required String artistName, int? monthlyListe...` |
| `network` | `dynamic` | `bannerImageUrl, fit: BoxFit.cover, width: doubl...` |
| `OutlinedButton` | `dynamic` | `onPressed: (` |
| `setState` | `dynamic` | `(` |
| `GestureDetector` | `dynamic` | `onTap: (` |
| `setState` | `dynamic` | `(` |
| `_buildBioText` | `Widget` | `String bio` |
| `_formatListeners` | `String` | `int count` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Synchronous setState() invoked without mounted check; can throw if widget is unmounted during async gaps.

## Implementation Highlight
```dart
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/identity_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/on_platform_reputation_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/visual_identity_trait.dart';

import '../player_artwork.dart';

/// Spotify-identical "About the Artist" card (`ScrollCardType.CREATOR_BIO` / `bio_card_view.xml`).
///
/// Features:
/// - 16dp rounded corners (`widgets_corner_radius`)
/// - Dark card background (#242424 / `dark_base_background_elevated_base`)
/// - Top artist banner with subtle gradient scrim (`bio_card_gradient`)
/// - "ABOUT THE ARTIST" category badge
/// - Monthly listeners / verified artist indicator
/// - "Follow" outline button
/// - Artist biography preview snippet with expandable "See more" behavior
/// - Dual-mode: Binds reactively to [DataPool] when available (online),
///   or falls back to [MediaItem] metadata (offline).
class PlayerAboutArtistSection extends StatefulWidget {
  const PlayerAboutArtistSection({
    super.key,
    required this.item,
    this.dataPool,
    this.artistUri,
    this.onFollow,
  });

  final MediaItem item;
  final DataPool? dataPool;
  final String? artistUri;
  final VoidCallback? onFollow;

  @override
  State<PlayerAboutArtistSection> createState() =>
      _PlayerAboutArtistSectionState();
}

class _PlayerAboutArtistSectionState extends State<PlayerAboutArtistSection> {
  bool _isFollowing = false;
  bool _isBioExpanded = false;

  @override
// ... [remaining code in source file] ...
```
