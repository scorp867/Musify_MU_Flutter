---
title: "local_context_resolver.dart"
path: "lib/features/local_music/domain/local_context_resolver.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, local-music, context-resolver, pagination, cosmos]
lines: 253
incoming_dependencies: 5
outgoing_dependencies: 5
---

# local_context_resolver.dart

> Source File: `[lib/features/local_music/domain/local_context_resolver.dart](file:///c:/Users/Admin/Musify_MU/lib/features/local_music/domain/local_context_resolver.dart)`
> Layer: `lib/features/local_music/domain`

## Executive Summary
`local_context_resolver.dart` implements Spotify's Cosmos ContextResolver architecture for local and offline audio playback. It chunks device songs into discrete `ContextPage` instances with page URLs and pagination links, manages an active context cache, and orchestrates offline queue initialization and playback through `PlaybackController`.

**Primary Architecture Role**: Domain Context Resolver / Offline Pagination Engine

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `playback_controller.dart` | `lib/core/audio` | [[04-Reference/lib/core/audio/playback_controller|playback_controller.dart]] |
| `domain_track.dart` | `lib/features/local_music/domain/entities` | [[04-Reference/lib/features/local_music/domain/entities/domain_track|domain_track.dart]] |
| `context_page.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/context_page|context_page.dart]] |
| `context_track.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/context_track|context_track.dart]] |
| `playback_context.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/playback_context|playback_context.dart]] |
| `player_queue.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/player_queue|player_queue.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `playback_queue_manager.dart` | `lib/core/audio` | [[04-Reference/lib/core/audio/playback_queue_manager|playback_queue_manager.dart]] |
| `local_music_screen.dart` | `lib/features/local_music/presentation/screens` | [[04-Reference/lib/features/local_music/presentation/screens/local_music_screen|local_music_screen.dart]] |
| `offline_browse_view.dart` | `lib/features/browse/presentation` | [[04-Reference/lib/features/browse/presentation/offline_browse_view|offline_browse_view.dart]] |
| `offline_library_view.dart` | `lib/features/library/presentation` | [[04-Reference/lib/features/library/presentation/offline_library_view|offline_library_view.dart]] |
| `queue_replication_test.dart` | `test/features/player` | [[04-Reference/test/features/player/queue_replication_test|queue_replication_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class LocalContextResolver`
- **Archetype**: Domain Service / Context Resolver

**Key Fields & Constants:**
- `static const int defaultPageSize = 50`: Default chunk size for Cosmos pages.
- `static final Map<String, PlaybackContext> _activeContexts`: In-memory registry mapping context URI/URL to `PlaybackContext`.

**Public Methods:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `registerContext` | `void` | `PlaybackContext context` | Indexes a context by URI and URL |
| `resolvePage` | `ContextPage?` | `String pageUrl` | Looks up a specific page across registered active contexts |
| `buildContext` | `PlaybackContext` | `{required List<Map<String, dynamic>> rawTracks, ...}` | Chunks raw track maps into discrete pages with next-page links |
| `buildContextFromDomainTracks` | `PlaybackContext` | `{required List<DomainTrack> tracks, ...}` | Chunks typed `DomainTrack` entities into `ContextPage` instances |
| `createInitialQueue` | `PlayerQueue` | `{required PlaybackContext context, required int initialTrackIndex, ...}` | Builds initial `PlayerQueue` starting at selected track |
| `playDomainTracks` | `Future<void>` | `{required PlaybackController playback, required List<DomainTrack> tracks, required int initialTrackIndex, ...}` | High-level coordinator that chunks tracks and feeds only the active 50-track page to the player |

## State & Data Flow Analysis
- Bridges offline device storage (`DomainTrack` entities) with Spotify's Cosmos pagination format.
- Rather than passing thousands of offline files to the player at once, it presents 50-track windowed pages and transparently streams subsequent chunks on demand.

## Implementation Highlight
```dart
/// 1:1 with Spotify's Cosmos ContextResolver for local & offline music.
class LocalContextResolver {
  static const int defaultPageSize = 50;
  static final Map<String, PlaybackContext> _activeContexts = {};

  static void registerContext(PlaybackContext context) {
    _activeContexts[context.url] = context;
    _activeContexts[context.uri] = context;
  }

  static ContextPage? resolvePage(String pageUrl) {
    for (final ctx in _activeContexts.values) {
      for (final page in ctx.pages) {
        if (page.pageUrl == pageUrl) return page;
      }
    }
    return null;
  }
// ...
```
