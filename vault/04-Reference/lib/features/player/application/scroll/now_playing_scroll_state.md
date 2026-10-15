---
title: "now_playing_scroll_state.dart"
path: "lib/features/player/application/scroll/now_playing_scroll_state.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 67
incoming_dependencies: 0
outgoing_dependencies: 1
---

# now_playing_scroll_state.dart

> Source File: `[lib/features/player/application/scroll/now_playing_scroll_state.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/application/scroll/now_playing_scroll_state.dart)`
> Layer: `lib/features/player/application/scroll`

## Executive Summary
`now_playing_scroll_state.dart` is an essential file in `lib/features/player/application/scroll` providing definitions for `NowPlayingScrollState`, `NowPlayingScrollInitial`, `NowPlayingScrollLoading`, `NowPlayingScrollLoaded`, `NowPlayingScrollFailure`.
**Primary Architecture Role**: Core Component, Domain Model / Entity

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `scroll_card_descriptor.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/scroll_card_descriptor|scroll_card_descriptor.dart]] |

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class NowPlayingScrollState`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

#### `class NowPlayingScrollInitial`
- **Archetype**: Core Component
- **Extends**: `NowPlayingScrollState`

#### `class NowPlayingScrollLoading`
- **Archetype**: Core Component
- **Extends**: `NowPlayingScrollState`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `MediaItem` |
| `currentCards` | `List<ScrollCardDescriptor>` |
| `currentLyrics` | `ColorLyricsResponse?` |

#### `class NowPlayingScrollLoaded`
- **Archetype**: Core Component
- **Extends**: `NowPlayingScrollState`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `MediaItem` |
| `cards` | `List<ScrollCardDescriptor>` |
| `lyrics` | `ColorLyricsResponse?` |

#### `class NowPlayingScrollFailure`
- **Archetype**: Core Component
- **Extends**: `NowPlayingScrollState`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `MediaItem` |
| `message` | `String` |
| `fallbackCards` | `List<ScrollCardDescriptor>` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';

/// States for [NowPlayingScrollBloc].
sealed class NowPlayingScrollState extends Equatable {
  const NowPlayingScrollState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any media item is resolved.
final class NowPlayingScrollInitial extends NowPlayingScrollState {
  const NowPlayingScrollInitial();
}

/// State emitted while loading cards or lyrics for a media item.
final class NowPlayingScrollLoading extends NowPlayingScrollState {
  final MediaItem item;
  final List<ScrollCardDescriptor> currentCards;
  final ColorLyricsResponse? currentLyrics;

  const NowPlayingScrollLoading({
    required this.item,
    this.currentCards = const [],
    this.currentLyrics,
  });

  @override
  List<Object?> get props => [item.id, currentCards, currentLyrics];
}

/// State emitted when card descriptors and lyrics have been fetched.
final class NowPlayingScrollLoaded extends NowPlayingScrollState {
  final MediaItem item;
  final List<ScrollCardDescriptor> cards;
  final ColorLyricsResponse? lyrics;

  const NowPlayingScrollLoaded({
    required this.item,
    required this.cards,
    this.lyrics,
  });
// ... [remaining code in source file] ...
```
