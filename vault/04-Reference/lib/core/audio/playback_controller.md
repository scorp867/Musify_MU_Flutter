---
title: "playback_controller.dart"
path: "lib/core/audio/playback_controller.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, audio, interface, contract]
lines: 29
incoming_dependencies: 16
outgoing_dependencies: 0
---

# playback_controller.dart

> Source File: `[lib/core/audio/playback_controller.dart](file:///c:/Users/Admin/Musify_MU/lib/core/audio/playback_controller.dart)`
> Layer: `lib/core/audio` (Playback Contract Boundary)

## Executive Summary
`playback_controller.dart` defines `PlaybackController`, the abstract interface class that acts as the decoupled contract between the Flutter UI presentation layer (and BLoCs) and the underlying audio engine. Presentation widgets receive this contract explicitly, preventing UI components from directly coupling to low-level `just_audio` player instances or `BaseAudioHandler` implementations.

**Primary Architecture Role**: Audio & Queue Boundary Interface Contract

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- `package:audio_service/audio_service.dart`: For `MediaItem`, `PlaybackState`, `AudioServiceShuffleMode`, and `AudioServiceRepeatMode`.
- No internal project dependencies (pure boundary contract).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `app.dart` | `lib/app` | [[04-Reference/lib/app/app|app.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `audio_notification_handler.dart` | `lib/core/audio` | [[04-Reference/lib/core/audio/audio_notification_handler|audio_notification_handler.dart]] |
| `queue_bloc.dart` | `lib/features/player/application/queue` | [[04-Reference/lib/features/player/application/queue/queue_bloc|queue_bloc.dart]] |
| `player_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/player_screen|player_screen.dart]] |
| `queue_sheet_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/queue_sheet_screen|queue_sheet_screen.dart]] |
| `mini_player.dart` | `lib/features/player/presentation/widgets` | [[04-Reference/lib/features/player/presentation/widgets/mini_player|mini_player.dart]] |
| `player_controls.dart` | `lib/features/player/presentation/widgets` | [[04-Reference/lib/features/player/presentation/widgets/player_controls|player_controls.dart]] |
| `queue_now_playing_card.dart` | `lib/features/player/presentation/widgets` | [[04-Reference/lib/features/player/presentation/widgets/queue_now_playing_card|queue_now_playing_card.dart]] |
| `hidden_drawer_scaffold.dart` | `lib/features/shell/presentation` | [[04-Reference/lib/features/shell/presentation/hidden_drawer_scaffold|hidden_drawer_scaffold.dart]] |
| `main_screen.dart` | `lib/features/shell/presentation` | [[04-Reference/lib/features/shell/presentation/main_screen|main_screen.dart]] |
| `local_music_playback_synchronizer.dart` | `lib/features/local_music/application` | [[04-Reference/lib/features/local_music/application/local_music_playback_synchronizer|local_music_playback_synchronizer.dart]] |
| `local_music_screen.dart` | `lib/features/local_music/presentation/screens` | [[04-Reference/lib/features/local_music/presentation/screens/local_music_screen|local_music_screen.dart]] |
| `offline_library_view.dart` | `lib/features/library/presentation` | [[04-Reference/lib/features/library/presentation/offline_library_view|offline_library_view.dart]] |
| `home_tab.dart` | `lib/features/home/presentation` | [[04-Reference/lib/features/home/presentation/home_tab|home_tab.dart]] |
| `offline_browse_view.dart` | `lib/features/browse/presentation` | [[04-Reference/lib/features/browse/presentation/offline_browse_view|offline_browse_view.dart]] |
| `local_context_resolver.dart` | `lib/features/local_music/domain` | [[04-Reference/lib/features/local_music/domain/local_context_resolver|local_context_resolver.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `abstract interface class PlaybackController`

**Reactive Getters & Streams:**
| Getter | Return Type | Description |
|--------|-------------|-------------|
| `mediaItem` | `Stream<MediaItem?>` | Broadcast stream of the currently active media track metadata |
| `playbackState` | `Stream<PlaybackState>` | Broadcast stream of transport states (playing, buffering, position, controls) |
| `queue` | `Stream<List<MediaItem>>` | Broadcast stream of current sliding-window tracks |
| `currentMediaItem` | `MediaItem?` | Synchronous snapshot of the currently active media track |
| `audioWindowEndIndex` | `int` | Upper boundary index of the active hardware window in the playback engine |

**Queue Management Methods:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `playQueue` | `Future<void>` | `List<MediaItem> tracks, int initialIndex` | Replaces current context queue and starts playback at initial index |
| `setNextTracks` | `Future<void>` | `List<MediaItem> upcomingTracks` | Atomically replaces tracks after current index in engine metadata |
| `enqueueUserTrack` | `Future<void>` | `MediaItem mediaItem` | Inserts a track into the user-specified FIFO priority queue |
| `clearUserQueue` | `Future<void>` | None | Clears all user-queued items, reverting to raw context queue |
| `reorderQueueItem` | `Future<void>` | `int fromIndex, int toIndex` | Moves a track within or across queue sections |
| `removeQueueItemAt` | `Future<void>` | `int index` | Deletes a specific track by its absolute queue index |
| `removeQueueRange` | `Future<void>` | `int startIndex, int endIndex` | Removes a range of tracks (e.g. clearing upcoming context) |
| `insertQueueItem` | `Future<void>` | `int index, MediaItem mediaItem` | Inserts a track at a specific absolute position |
| `updateCurrentMediaItem`| `Future<void>` | `MediaItem item` | Updates metadata for currently playing track (e.g. after color resolution) |
| `refreshArtwork` | `Future<void>` | None | Requests background notification artwork reload |

**Transport Control Methods:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `play` | `Future<void>` | None | Resumes audio playback |
| `pause` | `Future<void>` | None | Pauses audio playback |
| `seek` | `Future<void>` | `Duration position` | Seeks playback head to position |
| `stop` | `Future<void>` | None | Stops playback and releases audio focus |
| `skipToNext` | `Future<void>` | None | Advances to next track |
| `skipToPrevious`| `Future<void>` | None | Rewinds or skips to previous track |
| `skipToQueueItem`| `Future<void>` | `int index` | Jumps playback to specific queue index |
| `setShuffleMode`| `Future<void>` | `AudioServiceShuffleMode shuffleMode` | Toggles shuffle (none vs all) |
| `setRepeatMode` | `Future<void>` | `AudioServiceRepeatMode repeatMode` | Toggles repeat (none -> all -> one) |

## State & Data Flow Analysis
- **Interface Segregation**: By implementing this contract in `AudioNotificationHandler`, UI elements only interact with high-level media operations.
- **Stream Inversion**: The UI listens to `mediaItem` and `playbackState` streams to update progress bars, play/pause buttons, and artwork without polling.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] audioWindowEndIndex Leakage
> `audioWindowEndIndex` exposes the internal sliding-window boundary of `PlaybackQueueManager` (50 tracks) to callers like `QueueBloc`. Callers must ensure they query the total list length from `fullTracks` or `queue` rather than assuming `audioWindowEndIndex` represents the total playlist length.

## Implementation Highlight
```dart
abstract interface class PlaybackController {
  Stream<MediaItem?> get mediaItem;
  Stream<PlaybackState> get playbackState;
  Stream<List<MediaItem>> get queue;
  MediaItem? get currentMediaItem;
  int get audioWindowEndIndex;

  Future<void> playQueue(List<MediaItem> tracks, int initialIndex);
  Future<void> enqueueUserTrack(MediaItem mediaItem);
  Future<void> clearUserQueue();
  Future<void> reorderQueueItem(int fromIndex, int toIndex);
  Future<void> removeQueueItemAt(int index);
  Future<void> removeQueueRange(int startIndex, int endIndex);
  Future<void> insertQueueItem(int index, MediaItem mediaItem);
  Future<void> updateCurrentMediaItem(MediaItem item);
  Future<void> refreshArtwork();
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> skipToQueueItem(int index);
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode);
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode);
}
```
