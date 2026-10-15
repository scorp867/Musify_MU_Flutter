---
title: "lyrics_card.dart"
path: "lib/features/player/presentation/widgets/sections/lyrics_card.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 227
incoming_dependencies: 1
outgoing_dependencies: 2
---

# lyrics_card.dart

> Source File: `[lib/features/player/presentation/widgets/sections/lyrics_card.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/presentation/widgets/sections/lyrics_card.dart)`
> Layer: `lib/features/player/presentation/widgets/sections`

## Executive Summary
`lyrics_card.dart` is an essential file in `lib/features/player/presentation/widgets/sections` providing definitions for `PlayerLyricsSection`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `data_pool.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool|data_pool.dart]] |
| `visual_identity_trait.dart` | `lib/features/home_feed/domain/models/traits` | [[04-Reference/lib/features/home_feed/domain/models/traits/visual_identity_trait|visual_identity_trait.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `debug_now_playing_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/debug_now_playing_screen|debug_now_playing_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class PlayerLyricsSection`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `onTapHeader` | `VoidCallback?` |
| `backgroundColor` | `Color?` |
| `lyricsLines` | `List<String>?` |
| `activeLineIndex` | `int` |
| `colorLyrics` | `ColorLyricsResponse?` |
| `dataPool` | `DataPool?` |
| `trackUri` | `String?` |
| `trackUri` | `return` |
| `uri` | `final` |
| `visual` | `final` |
| `palette` | `final` |
| `startBg` | `Color` |
| `endBg` | `Color` |
| `highlightColor` | `Color` |
| `inactiveColor` | `Color` |
| `bg` | `final` |
| `lines` | `final` |
| `previewLines` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `_buildCard` | `Widget` | `VisualIdentityTrait? visual` |
| `map` | `dynamic` | `(l` |
| `where` | `dynamic` | `(w` |
| `_buildLyricsPreview` | `List<Widget>` | `List<String> lines, Color highlightColor, Color...` |
| `_buildUnavailableMessage` | `Widget` | `(none)` |

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
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/visual_identity_trait.dart';

import 'lyrics_color_parser.dart';

/// Spotify-identical Lyrics preview card (`ScrollCardType.LYRICS`).
///
/// 1:1 replica of official Spotify Android layout (`lyricscard_spotify.jpeg`
/// and decompiled `p/io80.java`, `p/rm2.java`, `p/aw80.java`).
///
/// Palette hierarchy (exact replica of `p/aw80.java`):
/// 1. First-party [VisualIdentityTrait] (`higherContrast` -> `backgroundBase` + `backgroundTintedBase`)
///    extracted from album artwork via Kodiak DataPool.
/// 2. Third-party [ColorLyricsResponse] (`colors.background`) from Musixmatch.
/// 3. Offline constants from Spotify Encore (`p/mzs.java:5-9` -> `#353535` / `#565656`).
class PlayerLyricsSection extends StatelessWidget {
  const PlayerLyricsSection({
    super.key,
    this.onTapHeader,
    this.backgroundColor,
    this.lyricsLines,
    this.activeLineIndex = 0,
    this.colorLyrics,
    this.dataPool,
    this.trackUri,
  });

  final VoidCallback? onTapHeader;
  final Color? backgroundColor;
  final List<String>? lyricsLines;
  final int activeLineIndex;
  final ColorLyricsResponse? colorLyrics;
  final DataPool? dataPool;
  final String? trackUri;

  String? get _normalizedTrackUri {
    if (trackUri == null || trackUri!.isEmpty) return null;
    if (!trackUri!.startsWith('spotify:')) {
      return 'spotify:track:$trackUri';
    }
    return trackUri;
  }

// ... [remaining code in source file] ...
```
