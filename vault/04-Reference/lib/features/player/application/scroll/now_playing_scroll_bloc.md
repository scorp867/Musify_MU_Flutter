---
title: "now_playing_scroll_bloc.dart"
path: "lib/features/player/application/scroll/now_playing_scroll_bloc.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 92
incoming_dependencies: 4
outgoing_dependencies: 4
---

# now_playing_scroll_bloc.dart

> Source File: `[lib/features/player/application/scroll/now_playing_scroll_bloc.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/application/scroll/now_playing_scroll_bloc.dart)`
> Layer: `lib/features/player/application/scroll`

## Executive Summary
`now_playing_scroll_bloc.dart` is an essential file in `lib/features/player/application/scroll` providing definitions for `NowPlayingScrollBloc`.
**Primary Architecture Role**: BLoC State Machine

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `media_item_mapper.dart` | `lib/core/media` | [[04-Reference/lib/core/media/media_item_mapper|media_item_mapper.dart]] |
| `scroll_card_descriptor.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/scroll_card_descriptor|scroll_card_descriptor.dart]] |
| `lyrics_repository.dart` | `lib/features/player/domain/repositories` | [[04-Reference/lib/features/player/domain/repositories/lyrics_repository|lyrics_repository.dart]] |
| `scrollsita_repository.dart` | `lib/features/player/domain/repositories` | [[04-Reference/lib/features/player/domain/repositories/scrollsita_repository|scrollsita_repository.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `debug_now_playing_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/debug_now_playing_screen|debug_now_playing_screen.dart]] |
| `player_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/player_screen|player_screen.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `now_playing_scroll_bloc_test.dart` | `test/features/player/application` | [[04-Reference/test/features/player/application/now_playing_scroll_bloc_test|now_playing_scroll_bloc_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class NowPlayingScrollBloc`
- **Archetype**: BLoC State Machine
- **Extends**: `Bloc<NowPlayingScrollEvent, NowPlayingScrollState>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_scrollSitaRepository` | `ScrollSitaRepository` |
| `_lyricsRepository` | `LyricsRepository` |
| `item` | `final` |
| `previousCards` | `List<ScrollCardDescriptor>` |
| `loaded` | `final` |
| `songId` | `final` |
| `trackId` | `final` |
| `hasSpotifyUri` | `final` |
| `results` | `final` |
| `cards` | `final` |
| `lyrics` | `final` |
| `fallbackCards` | `List<ScrollCardDescriptor>` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `_onFetchNowPlayingScroll` | `Future<void>` | `FetchNowPlayingScroll event, Emitter<NowPlaying...` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';
import 'package:musify_mu/features/player/domain/repositories/lyrics_repository.dart';
import 'package:musify_mu/features/player/domain/repositories/scrollsita_repository.dart';

import 'now_playing_scroll_event.dart';
import 'now_playing_scroll_state.dart';

export 'now_playing_scroll_event.dart';
export 'now_playing_scroll_state.dart';

/// BLoC coordinating the Now Playing scroll cards and color-synced lyrics pipeline.
///
/// Follows Spotify Android's SDUI orchestration:
/// 1. Dispatches parallel requests to [ScrollSitaRepository] and [LyricsRepository].
/// 2. Emits [NowPlayingScrollLoaded] with ordered descriptors and color lyrics payload.
class NowPlayingScrollBloc
    extends Bloc<NowPlayingScrollEvent, NowPlayingScrollState> {
  final ScrollSitaRepository _scrollSitaRepository;
  final LyricsRepository _lyricsRepository;

  NowPlayingScrollBloc({
    required ScrollSitaRepository scrollSitaRepository,
    required LyricsRepository lyricsRepository,
  })  : _scrollSitaRepository = scrollSitaRepository,
        _lyricsRepository = lyricsRepository,
        super(const NowPlayingScrollInitial()) {
    on<FetchNowPlayingScroll>(_onFetchNowPlayingScroll);
  }

  Future<void> _onFetchNowPlayingScroll(
    FetchNowPlayingScroll event,
    Emitter<NowPlayingScrollState> emit,
  ) async {
    final item = event.item;

    List<ScrollCardDescriptor> previousCards = const [];
    if (state is NowPlayingScrollLoaded) {
      final loaded = state as NowPlayingScrollLoaded;
      if (loaded.item.id == item.id) {
        return;
// ... [remaining code in source file] ...
```
