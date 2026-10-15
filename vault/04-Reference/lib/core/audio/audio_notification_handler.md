---
title: "audio_notification_handler.dart"
path: "lib/core/audio/audio_notification_handler.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, audio, notifications, media-session, lockscreen]
lines: 339
incoming_dependencies: 1
outgoing_dependencies: 3
---

# audio_notification_handler.dart

> Source File: `[lib/core/audio/audio_notification_handler.dart](file:///c:/Users/Admin/Musify_MU/lib/core/audio/audio_notification_handler.dart)`
> Layer: `lib/core/audio` (System MediaSession Bridge)

## Executive Summary
`audio_notification_handler.dart` implements `AudioNotificationHandler`, which bridges Musify MU's internal audio engine with the operating system's native MediaSession and notification center. It extends `BaseAudioHandler` with `SeekHandler` from `audio_service` and implements the `PlaybackController` interface. It manages lockscreen controls, Android notification channels, asynchronous artwork caching, and state synchronization across track transitions.

**Primary Architecture Role**: Operating System MediaSession, Lockscreen & Artwork Notification Controller

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `media_item_mapper.dart` | `lib/core/media` | [[04-Reference/lib/core/media/media_item_mapper|media_item_mapper.dart]] |
| `audio_playback_service.dart` | `lib/core/audio` | [[04-Reference/lib/core/audio/audio_playback_service|audio_playback_service.dart]] |
| `playback_controller.dart` | `lib/core/audio` | [[04-Reference/lib/core/audio/playback_controller|playback_controller.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|-------------|-------|-----------|
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class AudioNotificationHandler extends BaseAudioHandler with SeekHandler implements PlaybackController`

**Internal State & Caches:**
| Field Name | Type | Description |
|------------|------|-------------|
| `_playbackService` | `AudioPlaybackService` | Underlying player I/O service |
| `_audioQuery` | `OnAudioQuery` | Native device artwork scanner |
| `_latestMediaItems` | `Map<String, MediaItem>` | LRU metadata cache (max 500 items) keyed by instance UID to prevent metadata clobbering |
| `_artworkRequests` | `Map<String, Future<MediaItem>>` | In-flight request de-duplication map for artwork generation |
| `_cachedArtUris` | `Map<String, Uri>` | In-memory cache mapping track ID to disk URI |
| `_pendingQueueItemId`| `String?` | ID of track awaiting initialization in `playQueue` |
| `_lastPublishedQueueIndex`| `int?` | Tracks index shifts to support consecutive identical tracks |
| `_playbackSub` | `StreamSubscription` | Subscribes to `_playbackService.playbackEventStream` |

**Key Public Methods:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `playQueue` | `Future<void>` | `List<MediaItem> tracks, int initialIndex` | Fetches initial track art, seeds metadata, and launches playback |
| `setNextTracks` | `Future<void>` | `List<MediaItem> upcomingTracks` | Delegates to playback service and broadcasts updated fullTracks queue |
| `updateCurrentMediaItem` | `Future<void>` | `MediaItem item` | Forces metadata reload and notifies lockscreen with updated tags |
| `refreshArtwork` | `Future<void>` | None | Triggers asynchronous artwork refetch for active track |
| `enqueueUserTrack` | `Future<void>` | `MediaItem mediaItem` | Inserts user track and emits updated queue stream |
| `clearUserQueue` | `Future<void>` | None | Clears user queue and emits updated queue stream |
| `setShuffleMode` | `Future<void>` | `AudioServiceShuffleMode shuffleMode` | Toggles shuffle and notifies MediaSession |
| `setRepeatMode` | `Future<void>` | `AudioServiceRepeatMode repeatMode` | Toggles repeat and notifies MediaSession |
| `reorderQueueItem` | `Future<void>` | `int fromIndex, int toIndex` | Reorders track and publishes queue |
| `removeQueueItemAt` | `Future<void>` | `int index` | Removes track and publishes queue |
| `removeQueueRange` | `Future<void>` | `int startIndex, int endIndex` | Removes track range and publishes queue |
| `insertQueueItem` | `Future<void>` | `int index, MediaItem mediaItem` | Inserts track and publishes queue |

## State & Data Flow Analysis
- **Lockscreen State Synchronization (`_publishPlaybackState`)**:
  Maps `just_audio`'s `ProcessingState` to `AudioProcessingState` (`idle`, `loading`, `buffering`, `ready`, `completed`).
  Exposes system actions: `MediaAction.seek`, `seekForward`, `seekBackward`.
  Sets Android compact action indices `[0, 1, 2]` (`skipToPrevious`, `play/pause`, `skipToNext`).
- **Consecutive Identical Track Handling**:
  Spotify queues allow playing the same track consecutively (e.g., track A followed by track A). The handler checks `final bool indexChanged = _lastPublishedQueueIndex != currentAbsoluteIndex;`. If the track ID did not change but the absolute queue index changed, it re-emits `mediaItem`, ensuring UI scrubbers and title bars update appropriately.
- **Asynchronous Artwork Pipeline**:
  ```dart
  final bytes = await _audioQuery.queryArtwork(songId, ArtworkType.AUDIO, size: 400);
  final file = File('${tempDir.path}/art_$safeId.jpg');
  await file.writeAsBytes(bytes);
  ```
  Artwork is queried in the background and written to temporary files so the Android/iOS MediaSession notification can load it via `Uri.file`.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Memory Management in High-Volume Queues
> `_latestMediaItems` implements an eviction threshold:
> ```dart
> if (_latestMediaItems.length > 500) {
>   final keysToRemove = _latestMediaItems.keys.take(_latestMediaItems.length - 400).toList();
>   keysToRemove.forEach(_latestMediaItems.remove);
> }
> ```
> This prevents memory bloat during massive playlist traversals while retaining active queue metadata.

## Implementation Highlight
```dart
void _publishPlaybackState(PlaybackEvent event) {
  final player = _playbackService.player;
  final playing = player.playing;
  final currentAbsoluteIndex = event.currentIndex != null
      ? _playbackService.windowToAbsoluteIndex(event.currentIndex!)
      : null;

  playbackState.add(
    playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: currentAbsoluteIndex,
      shuffleMode: _playbackService.shuffleMode,
      repeatMode: _playbackService.repeatMode,
    ),
  );
}
```
