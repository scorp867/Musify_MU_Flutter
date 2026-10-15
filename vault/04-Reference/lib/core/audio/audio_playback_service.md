---
title: "audio_playback_service.dart"
path: "lib/core/audio/audio_playback_service.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, audio, player-io, just-audio]
lines: 92
incoming_dependencies: 2
outgoing_dependencies: 1
---

# audio_playback_service.dart

> Source File: `[lib/core/audio/audio_playback_service.dart](file:///c:/Users/Admin/Musify_MU/lib/core/audio/audio_playback_service.dart)`
> Layer: `lib/core/audio` (Player Hardware Bridge)

## Executive Summary
`audio_playback_service.dart` defines `AudioPlaybackService`, which owns the hardware `AudioPlayer` from `just_audio` and binds its native playback stream to `PlaybackQueueManager`. It provides low-level audio I/O commands (`play`, `pause`, `seek`, `stop`) while delegating all queue policy, track sequencing, and window math to `PlaybackQueueManager`.

**Primary Architecture Role**: Player Hardware I/O & Queue Delegation Bridge

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `playback_queue_manager.dart` | `lib/core/audio` | [[04-Reference/lib/core/audio/playback_queue_manager|playback_queue_manager.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|-------------|-------|-----------|
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `audio_notification_handler.dart` | `lib/core/audio` | [[04-Reference/lib/core/audio/audio_notification_handler|audio_notification_handler.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class AudioPlaybackService`

**Fields & Lifecycle:**
- `final AudioPlayer _player = AudioPlayer()`: Hardware audio playback instance.
- `late final PlaybackQueueManager _queueManager`: Delegates queue state management.
- `late final StreamSubscription<int?> _indexSubscription`: Subscribes to `_player.currentIndexStream` to notify `_queueManager.onIndexChanged`.

**Lifecycle Methods:**
- `AudioPlaybackService()`: Constructor initializes `_queueManager` with `_player` and sets up the index change listener.
- `Future<void> dispose()`: Cancels the index subscription and disposes the native `AudioPlayer`.

**Player Transport Controls:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `play` | `Future<void>` | None | Starts or resumes audio playback |
| `pause` | `Future<void>` | None | Pauses playback |
| `seek` | `Future<void>` | `Duration position` | Seeks within current track |
| `stop` | `Future<void>` | None | Halts playback |
| `seekToNext` | `Future<void>` | None | Native just_audio seek to next item in current sequence |
| `seekToPrevious` | `Future<void>` | None | Native just_audio seek to previous item in current sequence |
| `seekToAbsoluteIndex` | `Future<void>` | `int absoluteIndex` | Delegates to queue manager to seek across window boundaries |

**Queue Delegations:**
| Method / Getter | Return Type | Description |
|-----------------|-------------|-------------|
| `setQueue` | `Future<void>` | Delegates to `_queueManager.setQueue(tracks, initialIndex)` |
| `setNextTracks` | `Future<void>` | Delegates to `_queueManager.setNextTracks(upcomingTracks)` |
| `enqueueUserTrack` | `Future<void>` | Delegates to `_queueManager.enqueueUserTrack(track)` |
| `clearUserQueue` | `Future<void>` | Delegates to `_queueManager.clearUserQueue()` |
| `reorderTrack` | `Future<void>` | Delegates to `_queueManager.reorderTrack(from, to)` |
| `removeTrack` | `Future<void>` | Delegates to `_queueManager.removeTrack(index)` |
| `removeTrackRange`| `Future<void>` | Delegates to `_queueManager.removeTrackRange(start, end)` |
| `insertTrack` | `Future<void>` | Delegates to `_queueManager.insertTrack(index, track)` |
| `setShuffleMode` | `Future<void>` | Delegates to `_queueManager.setShuffleMode(mode)` |
| `setRepeatMode` | `Future<void>` | Delegates to `_queueManager.setRepeatMode(mode)` |
| `onQueueChanged` | `void Function(List<MediaItem>)?` | Relays queue change notifications from queue manager |
| `playbackEventStream` | `Stream<PlaybackEvent>` | Direct stream from `_player.playbackEventStream` |

## State & Data Flow Analysis
- **Single Responsibility Principle**: By extracting all queue math and sliding-window logic into `PlaybackQueueManager`, `AudioPlaybackService` has zero lines of list manipulation or index offsetting.
- **Hardware Event Pipeline**:
  `_player.playbackEventStream` -> Exposed directly to `AudioNotificationHandler` to sync system media notifications with hardware position updates.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Disposal Order
> `dispose()` must cancel `_indexSubscription` prior to calling `_player.dispose()`; otherwise, index events dispatched during teardown may attempt to invoke callbacks on an inoperative queue manager.

## Implementation Highlight
```dart
class AudioPlaybackService {
  final AudioPlayer _player = AudioPlayer();
  late final PlaybackQueueManager _queueManager;
  late final StreamSubscription<int?> _indexSubscription;

  AudioPlaybackService() {
    _queueManager = PlaybackQueueManager(_player);
    _indexSubscription =
        _player.currentIndexStream.listen(_queueManager.onIndexChanged);
  }

  Future<void> dispose() async {
    await _indexSubscription.cancel();
    await _player.dispose();
  }

  AudioPlayer get player => _player;
  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;
}
```
