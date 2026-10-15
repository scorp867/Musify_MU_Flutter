---
title: "playback_context.dart"
path: "lib/features/player/domain/models/playback_context.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player, playback-context, cosmos]
lines: 52
incoming_dependencies: 2
outgoing_dependencies: 2
---

# playback_context.dart

> Source File: `[lib/features/player/domain/models/playback_context.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/domain/models/playback_context.dart)`
> Layer: `lib/features/player/domain/models`

## Executive Summary
`playback_context.dart` models Spotify's `com.spotify.player.model.Context`. It represents an entire playing entity (such as a playlist, album, artist, or local collection) broken down into a series of `ContextPage` instances, with associated metadata, restrictions, and canonical URLs.

**Primary Architecture Role**: Domain Model / Aggregate Root

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `context_page.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/context_page|context_page.dart]] |
| `context_track.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/context_track|context_track.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `local_context_resolver.dart` | `lib/features/local_music/domain` | [[04-Reference/lib/features/local_music/domain/local_context_resolver|local_context_resolver.dart]] |
| `queue_replication_test.dart` | `test/features/player` | [[04-Reference/test/features/player/queue_replication_test|queue_replication_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class PlaybackContext extends Equatable`
- **Archetype**: Domain Model / Aggregate Root
- **Extends**: `Equatable`

**Key Fields & Properties:**
| Field Name | Type | Description |
|------------|------|-------------|
| `uri` | `String` | Canonical Spotify context URI (e.g., `spotify:context:local-music`) |
| `url` | `String` | Resolvable web or local schema URL |
| `metadata` | `Map<String, String>` | Context-level metadata attributes |
| `pages` | `List<ContextPage>` | Chunked page slices forming the full collection |
| `restrictions` | `Map<String, dynamic>` | Playback restriction flags |

**Methods & Handlers:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `fromTracks` | `PlaybackContext` | `String uri, List<ContextTrack> tracks` | Factory initializing single-page context |
| `copyWith` | `PlaybackContext` | `{String? uri, String? url, Map<String, String>? metadata, List<ContextPage>? pages, Map<String, dynamic>? restrictions}` | Immutability copy helper |

## State & Data Flow Analysis
- **Execution Context**: Invoked by offline resolvers (`LocalContextResolver`) and remote playback adapters.
- **Data Flow**: Acts as the root definition of a media session context, supplying chunked pages to the player engine.

## Gotchas, Edge Cases & Technical Debt
> [!NOTE] 1:1 Spotify Parity
> Direct equivalent of Android Spotify's `Context.fromTrackUris(uri, trackUris)`.

## Implementation Highlight
```dart
import 'package:equatable/equatable.dart';
import 'context_page.dart';
import 'context_track.dart';

/// 1:1 with Spotify's com.spotify.player.model.Context
class PlaybackContext extends Equatable {
  final String uri;
  final String url;
  final Map<String, String> metadata;
  final List<ContextPage> pages;
  final Map<String, dynamic> restrictions;

  const PlaybackContext({
    required this.uri,
    this.url = '',
    this.metadata = const {},
    this.pages = const [],
    this.restrictions = const {},
  });
// ...
```
