---
title: "credits_card.dart"
path: "lib/features/player/presentation/widgets/sections/credits_card.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 244
incoming_dependencies: 1
outgoing_dependencies: 3
---

# credits_card.dart

> Source File: `[lib/features/player/presentation/widgets/sections/credits_card.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/presentation/widgets/sections/credits_card.dart)`
> Layer: `lib/features/player/presentation/widgets/sections`

## Executive Summary
`credits_card.dart` is an essential file in `lib/features/player/presentation/widgets/sections` providing definitions for `PlayerCreditsSection`, `_PlayerCreditsSectionState`, `_ContributorData`.
**Primary Architecture Role**: Widget State Lifecycle Handler, Stateful Widget, Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `data_pool.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool|data_pool.dart]] |
| `credits_trait.dart` | `lib/features/home_feed/domain/models/traits` | [[04-Reference/lib/features/home_feed/domain/models/traits/credits_trait|credits_trait.dart]] |
| `identity_trait.dart` | `lib/features/home_feed/domain/models/traits` | [[04-Reference/lib/features/home_feed/domain/models/traits/identity_trait|identity_trait.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `debug_now_playing_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/debug_now_playing_screen|debug_now_playing_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class PlayerCreditsSection`
- **Archetype**: Stateful Widget
- **Extends**: `StatefulWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `MediaItem` |
| `dataPool` | `DataPool?` |
| `trackUri` | `String?` |
| `contributorUris` | `List<String>` |
| `onShowAll` | `VoidCallback?` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `createState` | `State<PlayerCreditsSection>` | `(none)` |

#### `class _PlayerCreditsSectionState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<PlayerCreditsSection>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_followingContributors` | `Set<String>` |
| `contributors` | `final` |
| `isFollowing` | `final` |
| `list` | `final` |
| `credits` | `final` |
| `byName` | `final` |
| `uriByName` | `final` |
| `roles` | `final` |
| `identity` | `final` |
| `rawArtists` | `final` |
| `names` | `final` |
| `list` | `return` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `_buildContributorRow` | `Widget` | `_ContributorData contributor` |
| `OutlinedButton` | `dynamic` | `onPressed: (` |
| `setState` | `dynamic` | `(` |
| `_resolveContributors` | `List<_ContributorData>` | `(none)` |
| `putIfAbsent` | `dynamic` | `c.name, (` |
| `putIfAbsent` | `dynamic` | `c.name, (` |
| `map` | `dynamic` | `(n` |
| `where` | `dynamic` | `(n` |

#### `class _ContributorData`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `name` | `String` |
| `roles` | `String` |
| `uri` | `String?` |

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
import 'package:musify_mu/features/home_feed/domain/models/traits/credits_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/identity_trait.dart';

/// Spotify-identical Track Credits card (`ScrollCardType.TRACK_CREDITS`).
///
/// 1:1 replica of decompiled Spotify Android layout (`w5i.java` + `fhb1.java`).
///
/// Features:
/// - 16dp rounded corners
/// - Surface color #242424
/// - Header: "Credits" on left, "Show all" in Spotify Green (#1DB954) on right
/// - Contributor rows with artist name, combined roles ("Main Artist • Composer"),
///   and native "Follow" stadium button.
class PlayerCreditsSection extends StatefulWidget {
  const PlayerCreditsSection({
    super.key,
    required this.item,
    this.dataPool,
    this.trackUri,
    this.contributorUris = const [],
    this.onShowAll,
  });

  final MediaItem item;
  final DataPool? dataPool;
  final String? trackUri;
  final List<String> contributorUris;
  final VoidCallback? onShowAll;

  @override
  State<PlayerCreditsSection> createState() => _PlayerCreditsSectionState();
}

class _PlayerCreditsSectionState extends State<PlayerCreditsSection> {
  final Set<String> _followingContributors = {};

  @override
  Widget build(BuildContext context) {
    final contributors = _resolveContributors();

    return Container(
      padding: const EdgeInsets.all(16),
// ... [remaining code in source file] ...
```
