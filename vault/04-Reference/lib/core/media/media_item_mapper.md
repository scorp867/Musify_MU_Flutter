---
title: "media_item_mapper.dart"
path: "lib/core/media/media_item_mapper.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, media, mapper, expando, audio-service]
lines: 180
incoming_dependencies: 6
outgoing_dependencies: 1
---

# media_item_mapper.dart

> Source File: `[lib/core/media/media_item_mapper.dart](file:///c:/Users/Admin/Musify_MU/lib/core/media/media_item_mapper.dart)`
> Layer: `lib/core/media` (Domain Model & AudioService Translation)

## Executive Summary
`media_item_mapper.dart` defines `MediaItemMapper`, a bidirectional translation layer between Flutter `audio_service`'s `MediaItem` and Musify MU's clean domain models (`ContextTrack`). It isolates audio service imports from the domain layer and uses an `Expando<MediaItem>` cache to avoid re-allocating `MediaItem` instances across UI frames.

**Primary Architecture Role**: AudioService Boundary Mapper & Weak-Reference Instance Cache

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `context_track.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/context_track|context_track.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `audio_notification_handler.dart` | `lib/core/audio` | [[04-Reference/lib/core/audio/audio_notification_handler|audio_notification_handler.dart]] |
| `playback_queue_manager.dart` | `lib/core/audio` | [[04-Reference/lib/core/audio/playback_queue_manager|playback_queue_manager.dart]] |
| `local_music_playback_synchronizer.dart` | `lib/features/local_music/application` | [[04-Reference/lib/features/local_music/application/local_music_playback_synchronizer|local_music_playback_synchronizer.dart]] |
| `queue_bloc.dart` | `lib/features/player/application/queue` | [[04-Reference/lib/features/player/application/queue/queue_bloc|queue_bloc.dart]] |
| `queue_track_row.dart` | `lib/features/player/presentation/widgets` | [[04-Reference/lib/features/player/presentation/widgets/queue_track_row|queue_track_row.dart]] |
| `player_artwork.dart` | `lib/features/player/presentation/widgets` | [[04-Reference/lib/features/player/presentation/widgets/player_artwork|player_artwork.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `abstract final class MediaItemMapper`

**Standard Extras Key Constants:**
- `static const songIdKey = 'songId'`
- `static const dataPathKey = 'dataPath'`
- `static const dateModifiedKey = 'dateModified'`
- `static const artworkVersionKey = 'artworkVersion'`
- `static const uidKey = 'uid'`
- `static const isQueuedKey = 'is_queued'`
- `static const providerKey = 'provider'`

**Public Helper Methods:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `fromTrack` | `MediaItem` | `{id, title, artist, album, durationMilliseconds, songId, dataPath, dateModified}` | Constructs a `MediaItem` with typed extras |
| `songId` | `int?` | `MediaItem item` | Extracts numeric song ID from extras or parses from ID string |
| `dataPath` | `String?` | `MediaItem item` | Extracts local audio file path |
| `uid` | `String?` | `MediaItem item` | Extracts unique instance identifier |
| `isQueued` | `bool` | `MediaItem item` | Returns true if track belongs to manual user queue |
| `provider` | `String` | `MediaItem item` | Returns `'queue'` or `'context'` |
| `contextTrackFromMediaItem` | `ContextTrack` | `MediaItem item, {uid, isQueued, provider}` | Converts a `MediaItem` into a pure domain `ContextTrack` |
| `mediaItemFromContextTrack` | `MediaItem` | `ContextTrack track` | Converts a domain `ContextTrack` to `MediaItem`, leveraging `_contextTrackMediaItemCache` |

## State & Data Flow Analysis
- **Expando Weak-Reference Caching**:
  ```dart
  static final Expando<MediaItem> _contextTrackMediaItemCache = Expando<MediaItem>('ContextTrackMediaItem');
  ```
  `Expando` associates `MediaItem` instances with `ContextTrack` domain objects without creating strong references that prevent garbage collection. Re-mapping unchanged domain tracks reuses existing `MediaItem` objects, preventing allocation churn in queue lists.

## Implementation Highlight
```dart
static ContextTrack contextTrackFromMediaItem(
  MediaItem item, {
  String? uid,
  bool? isQueued,
  String? provider,
}) {
  final effectiveUid = uid ?? item.extras?[uidKey]?.toString() ?? item.id;
  final effectiveIsQueued = isQueued ??
      (item.extras?[isQueuedKey] == true || item.extras?[isQueuedKey] == 'true');
  final effectiveProvider = provider ??
      item.extras?[providerKey]?.toString() ??
      (effectiveIsQueued ? 'queue' : 'context');

  final meta = <String, String>{
    'title': item.title,
    'artist_name': item.artist ?? '',
    'album_title': item.album ?? '',
    if (item.artUri != null) 'image_url': item.artUri.toString(),
    if (item.duration != null)
      'duration_ms': item.duration!.inMilliseconds.toString(),
  };

  if (item.extras != null) {
    item.extras!.forEach((k, v) {
      if (v != null) meta[k] = v.toString();
    });
  }

  return ContextTrack(
    uri: item.id,
    uid: effectiveUid,
    metadata: meta,
    isQueued: effectiveIsQueued,
    provider: effectiveProvider,
  );
}
```
