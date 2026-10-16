---
title: "playback_queue_manager.dart"
path: "lib/core/audio/playback_queue_manager.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, audio, queue, prefetch, 2-slot-pipeline, gapless]
lines: 294
incoming_dependencies: 1
outgoing_dependencies: 4
---

# playback_queue_manager.dart

> Source File: `[lib/core/audio/playback_queue_manager.dart](file:///c:/Users/Admin/Musify_MU/lib/core/audio/playback_queue_manager.dart)`
> Layer: `lib/core/audio` (Audio Engine Core)

## Executive Summary
`playback_queue_manager.dart` implements `PlaybackQueueManager` 1:1 with Spotify's C++ `ContextPlayer` & `EsMediaPrefetch` audio feeding architecture. Instead of complex sliding-window math over large playlists, it maintains:
1. A master linear track list (`_fullTracks`) as pure metadata.
2. A 2-slot gapless audio source pipeline in `just_audio`:
   - **Slot 0**: Active playing track.
   - **Slot 1**: Next upcoming track (prefetched via `PrefetchLevel.media`).

When Slot 0 finishes, `just_audio` transitions into Slot 1 gaplessly (0ms delay). The manager shifts Slot 1 to Slot 0 and buffers the new next track into Slot 1. Furthermore, it automatically loads and appends the next Cosmos page via `LocalContextResolver.resolvePage(nextPageUrl)` when remaining tracks fall below threshold (`<= 8`).

**Primary Architecture Role**: Audio Source Queue Engine & 2-Slot Gapless Prefetch Pipeline

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `media_item_mapper.dart` | `lib/core/media` | [[04-Reference/lib/core/media/media_item_mapper|media_item_mapper.dart]] |
| `local_context_resolver.dart` | `lib/features/local_music/domain` | [[04-Reference/lib/features/local_music/domain/local_context_resolver|local_context_resolver.dart]] |
| `prefetch_level.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/prefetch_level|prefetch_level.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `audio_playback_service.dart` | `lib/core/audio` | [[04-Reference/lib/core/audio/audio_playback_service|audio_playback_service.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class PlaybackQueueManager`

**Core State Fields:**
| Field Name | Type | Description |
|------------|------|-------------|
| `_player` | `AudioPlayer` | Hardware player instance from `just_audio` |
| `_playlist` | `ConcatenatingAudioSource?` | Native 2-slot gapless audio source pipeline |
| `_fullTracks` | `List<MediaItem>` | Master linear track list of active playback context |
| `_currentIndex` | `int` | Absolute index of currently active track in `_fullTracks` |
| `_isTransitioning` | `bool` | Lock guarding against concurrent prefetch pipeline transitions |
| `_prefetchLevel` | `PrefetchLevel` | Buffering strategy (`none` vs `media`) |
| `onQueueChanged` | `void Function(List<MediaItem>)?` | Callback notified when queue metadata updates |

**Public API Methods:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `setQueue` | `Future<void>` | `List<MediaItem> tracks, int initialIndex` | Replaces active queue, loads Slot 0, prefetches Slot 1 |
| `setNextTracks` | `Future<void>` | `List<MediaItem> upcomingTracks` | Atomically replaces tracks after current index and updates prefetch slot |
| `seekToAbsoluteIndex` | `Future<void>` | `int absoluteIndex` | Seeks playback to target index and refreshes prefetch slot |
| `onIndexChanged` | `Future<void>` | `int? index` | Handles native transition into Slot 1, shifts slots, and preloads new next track |
| `reorderTrack` | `Future<void>` | `int fromAbsolute, int toAbsolute` | Moves tracks within metadata queue and realigns current index |
| `removeTrack` | `Future<void>` | `int absoluteIndex` | Delegates directly to `removeTrackRange(absoluteIndex, absoluteIndex + 1)` |
| `removeTrackRange` | `Future<void>` | `int startAbsolute, int endAbsolute` | Removes track range, updates playback or halts player when empty, realigns current index, and refreshes prefetch slot and queue listeners |
| `insertTrack` | `Future<void>` | `int absoluteIndex, MediaItem track` | Inserts track into metadata list |

## State & Data Flow Analysis
- **2-Slot Prefetch Pipeline**:
  - `Slot 0`: Immediately audible track.
  - `Slot 1`: Prefetched upcoming track source.
  When `just_audio` completes Slot 0, it gaplessly plays Slot 1. `onIndexChanged` intercepts the event:
  1. `await playlist.removeAt(0)`
  2. If `_prefetchLevel == PrefetchLevel.media`, adds the new upcoming track into Slot 1 (`await playlist.add(nextSource)`).
- **Track Removal & Depletion Handling**:
  `removeTrack(absoluteIndex)` delegates to `removeTrackRange(absoluteIndex, absoluteIndex + 1)`. Clamping prevents out-of-bounds removal.
  - If the active playing track falls within `[start, end)`:
    - If tracks remain, `setQueue` repositions playback to `start.clamp(0, _fullTracks.length - 1)`.
    - If the entire queue is depleted, `_currentIndex` resets to `0`, `_playlist` is cleared to `null`, hardware playback halts via `_player.stop()`, and `onQueueChanged` is notified.
  - If removing tracks positioned before the active playing index (`end <= _currentIndex`), `_currentIndex` is shifted by `-(end - start)`.
  - For all mutations, `_refreshPrefetchSlot()` resynchronizes Slot 1 to reflect the active next track, and `onQueueChanged` notifies listeners with `List.unmodifiable(_fullTracks)`.
- **Cosmos Page Auto-Loading**:
  In `_checkAndLoadNextPage()`, if `_fullTracks.length - (_currentIndex + 1) <= 8`, it extracts `next_page_url` from the last track and queries `LocalContextResolver.resolvePage(nextPageUrl)`. The resolved page tracks are automatically mapped and appended to `_fullTracks`, notifying `onQueueChanged`.

## Gotchas, Edge Cases & Technical Debt
> [!NOTE] Elimination of Sliding Window Bugs
> The 2-slot prefetch pipeline completely removes index-drift bugs, 50-track window boundary arithmetic errors, and native memory bloat.

## Implementation Highlight
```dart
/// 1:1 with Spotify's C++ ContextPlayer & EsMediaPrefetch audio feeding architecture.
class PlaybackQueueManager {
  final AudioPlayer _player;

  ConcatenatingAudioSource? _playlist;
  List<MediaItem> _fullTracks = const [];
  int _currentIndex = 0;
  bool _isTransitioning = false;
  PrefetchLevel _prefetchLevel = PrefetchLevel.media;
  void Function(List<MediaItem> tracks)? onQueueChanged;
// ...
```
