---
title: "local_music_playback_synchronizer.dart"
path: "lib/features/local_music/application/local_music_playback_synchronizer.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, local-music, sync, playback, boundary]
lines: 66
incoming_dependencies: 2
outgoing_dependencies: 3
---

# local_music_playback_synchronizer.dart

> Source File: `[lib/features/local_music/application/local_music_playback_synchronizer.dart](file:///c:/Users/Admin/Musify_MU/lib/features/local_music/application/local_music_playback_synchronizer.dart)`
> Layer: `lib/features/local_music/application` (Metadata Synchronization Boundary)

## Executive Summary
`local_music_playback_synchronizer.dart` implements `LocalMusicPlaybackSynchronizer`, the application boundary component that synchronizes the active `MediaItem` in system notifications with local library metadata changes. It serializes burst updates during device media scanning and performs deep field comparison to prevent redundant artwork queries when audio tags remain identical.

**Primary Architecture Role**: Active Playback Notification Synchronization Boundary

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `playback_controller.dart` | `lib/core/audio` | [[04-Reference/lib/core/audio/playback_controller|playback_controller.dart]] |
| `media_item_mapper.dart` | `lib/core/media` | [[04-Reference/lib/core/media/media_item_mapper|media_item_mapper.dart]] |
| `domain_track.dart` | `lib/features/local_music/domain/entities` | [[04-Reference/lib/features/local_music/domain/entities/domain_track|domain_track.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `local_music_playback_synchronizer_test.dart` | `test/features/local_music/application` | [[04-Reference/test/features/local_music/application/local_music_playback_synchronizer_test|local_music_playback_synchronizer_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class LocalMusicPlaybackSynchronizer`

**Fields & State:**
- `final PlaybackController _playbackController`: Injected playback controller interface.
- `Future<void> _pendingUpdate`: Future chain serializing concurrent library scan bursts.

**Methods:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `synchronize` | `Future<void>` | `List<DomainTrack> tracks` | Submits a list of scanned domain tracks for active playback verification |
| `_synchronizeCurrentTrack` | `Future<void>` | `List<DomainTrack> tracks` | Matches currently playing item against domain tracks and updates controller |
| `_hasMetadataChanged` | `bool` | `MediaItem current, MediaItem updated` | Deep comparison of title, artist, album, duration, and extras (`songId`, `dataPath`, `dateModified`) |

## State & Data Flow Analysis
- **Concurrency Serialization**:
  ```dart
  Future<void> synchronize(List<DomainTrack> tracks) {
    _pendingUpdate = _pendingUpdate.then((_) async {
      try {
        await _synchronizeCurrentTrack(tracks);
      } catch (error) {
        debugPrint('Unable to synchronize active media metadata: $error');
      }
    });
    return _pendingUpdate;
  }
  ```
  During library scanning, multiple batches of updated tracks can arrive in rapid succession. Chaining via `_pendingUpdate.then(...)` guarantees that artwork and notification updates are applied sequentially without race conditions.
- **Change Deduplication**:
  `_hasMetadataChanged` inspects both top-level metadata and internal extras (`songIdKey`, `dataPathKey`, `dateModifiedKey`). If a background sync completes but tags have not changed, `updateCurrentMediaItem` is skipped, avoiding unnecessary lockscreen flashing.

## Implementation Highlight
```dart
class LocalMusicPlaybackSynchronizer {
  final PlaybackController _playbackController;
  Future<void> _pendingUpdate = Future<void>.value();

  LocalMusicPlaybackSynchronizer(this._playbackController);

  Future<void> synchronize(List<DomainTrack> tracks) {
    _pendingUpdate = _pendingUpdate.then((_) async {
      try {
        await _synchronizeCurrentTrack(tracks);
      } catch (error) {
        debugPrint('Unable to synchronize active media metadata: $error');
      }
    });
    return _pendingUpdate;
  }
}
```
