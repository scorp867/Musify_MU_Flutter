---
title: "context_track.dart"
path: "lib/features/player/domain/models/context_track.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player, domain-model]
lines: 154
incoming_dependencies: 14
outgoing_dependencies: 0
---

# context_track.dart

> Source File: `[lib/features/player/domain/models/context_track.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/domain/models/context_track.dart)`
> Layer: `lib/features/player/domain/models`

## Executive Summary
`context_track.dart` implements `ContextTrack` 1:1 with Spotify Android's `com.spotify.player.model.ContextTrack`. It encapsulates track URI, unique session instance UID, provider tag (`'queue'` | `'context'` | `'autoplay'`), queued flag, boundary delimiter detection, and metadata map with bi-directional synchronization between `isQueued` boolean and `metadata['is_queued']`.

**Primary Architecture Role**: Domain Model / Entity

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- Leaf component: No internal project dependencies.

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `player_queue.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/player_queue|player_queue.dart]] |
| `context_page.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/context_page|context_page.dart]] |
| `playback_context.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/playback_context|playback_context.dart]] |
| `set_queue_command.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/set_queue_command|set_queue_command.dart]] |
| `queue_filter_helper.dart` | `lib/features/player/domain/queue` | [[04-Reference/lib/features/player/domain/queue/queue_filter_helper|queue_filter_helper.dart]] |
| `queue_mutator.dart` | `lib/features/player/domain/queue` | [[04-Reference/lib/features/player/domain/queue/queue_mutator|queue_mutator.dart]] |
| `local_context_resolver.dart` | `lib/features/local_music/domain` | [[04-Reference/lib/features/local_music/domain/local_context_resolver|local_context_resolver.dart]] |
| `queue_sheet_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/queue_sheet_screen|queue_sheet_screen.dart]] |
| `queue_now_playing_row.dart` | `lib/features/player/presentation/widgets` | [[04-Reference/lib/features/player/presentation/widgets/queue_now_playing_row|queue_now_playing_row.dart]] |
| `queue_track_row.dart` | `lib/features/player/presentation/widgets` | [[04-Reference/lib/features/player/presentation/widgets/queue_track_row|queue_track_row.dart]] |
| `queue_bloc.dart` | `lib/features/player/application/queue` | [[04-Reference/lib/features/player/application/queue/queue_bloc|queue_bloc.dart]] |
| `queue_event.dart` | `lib/features/player/application/queue` | [[04-Reference/lib/features/player/application/queue/queue_event|queue_event.dart]] |
| `queue_state.dart` | `lib/features/player/application/queue` | [[04-Reference/lib/features/player/application/queue/queue_state|queue_state.dart]] |
| `media_item_mapper.dart` | `lib/core/media` | [[04-Reference/lib/core/media/media_item_mapper|media_item_mapper.dart]] |
| `queue_replication_test.dart` | `test/features/player` | [[04-Reference/test/features/player/queue_replication_test|queue_replication_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class ContextTrack extends Equatable`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

**Delimiter Constants & Detection:**
- `static const List<String> delimiters = ['spotify:meta:delimiter', 'spotify:delimiter']`
- `bool get isDelimiter => delimiters.contains(uri)`: Identifies Cosmos pagination delimiters.

**Key Fields & Properties:**
| Field Name | Type | Description |
|------------|------|-------------|
| `uri` | `String` | Universal track URI |
| `uid` | `String` | Session-unique instance identifier |
| `provider` | `String` | Provider origin (`'queue'`, `'context'`, `'autoplay'`) |
| `isQueued` | `bool` | True if explicitly added to user queue |
| `metadata` | `Map<String, String>` | Stamped track metadata dictionary |

**Methods & Getters:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `title`, `artist`, `album`, `imageUrl`, `duration` | String/Duration | None | Typed convenience accessors into `metadata` |
| `fromMediaItem` | `ContextTrack` | `MediaItem item, {String? uid, bool? isQueued}` | Factory synchronizing MediaItem extras |
| `toMediaItem` | `MediaItem` | None | Converts domain track to audio service model |
| `copyWith` | `ContextTrack` | Parameter overrides | Immutability copy helper; automatically syncs `metadata['is_queued']` |
| `toJson` / `fromJson` | Map / Object | Serializer and deserializer |

## Implementation Highlight
```dart
import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';

/// 1:1 with Spotify's com.spotify.player.model.ContextTrack
class ContextTrack extends Equatable {
  static const List<String> delimiters = [
    'spotify:meta:delimiter',
    'spotify:delimiter',
  ];

  final String uri;
  final String uid; // Session-unique instance identifier
  final String provider; // 'queue' | 'context' | 'autoplay'
  final bool isQueued;
  final Map<String, String> metadata;

  bool get isDelimiter => delimiters.contains(uri);
// ...
```
