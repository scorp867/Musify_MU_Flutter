---
title: "now_playing_scroll_event.dart"
path: "lib/features/player/application/scroll/now_playing_scroll_event.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 20
incoming_dependencies: 0
outgoing_dependencies: 0
---

# now_playing_scroll_event.dart

> Source File: `[lib/features/player/application/scroll/now_playing_scroll_event.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/application/scroll/now_playing_scroll_event.dart)`
> Layer: `lib/features/player/application/scroll`

## Executive Summary
`now_playing_scroll_event.dart` is an essential file in `lib/features/player/application/scroll` providing definitions for `NowPlayingScrollEvent`, `FetchNowPlayingScroll`.
**Primary Architecture Role**: Core Component, Domain Model / Entity

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class NowPlayingScrollEvent`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

#### `class FetchNowPlayingScroll`
- **Archetype**: Core Component
- **Extends**: `NowPlayingScrollEvent`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `MediaItem` |

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

/// Events for [NowPlayingScrollBloc].
sealed class NowPlayingScrollEvent extends Equatable {
  const NowPlayingScrollEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when the active now playing media item changes.
final class FetchNowPlayingScroll extends NowPlayingScrollEvent {
  final MediaItem item;

  const FetchNowPlayingScroll(this.item);

  @override
  List<Object?> get props => [item.id];
}
```
