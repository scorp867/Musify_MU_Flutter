---
title: "queue_bloc.dart"
path: "lib/features/player/application/queue/queue_bloc.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player, queue, bloc, state-machine]
lines: 492
incoming_dependencies: 2
outgoing_dependencies: 6
---

# queue_bloc.dart

> Source File: `[lib/features/player/application/queue/queue_bloc.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/application/queue/queue_bloc.dart)`
> Layer: `lib/features/player/application/queue` (Player Queue State Machine)

## Executive Summary
`queue_bloc.dart` implements `QueueBloc`, the reactive BLoC that powers Spotify's Now Playing Queue sheet (`QueueSheetScreen`). It subscribes to `PlaybackController` streams, synchronizes UI reordering, additions, removals, and clearing with hardware playback states, manages animation cooldowns to prevent UI jank, and reconstructs the domain `PlayerQueue` (`currentTrack`, `userQueue`, and upcoming `contextTracks`).

**Primary Architecture Role**: Player Queue Presentation State Machine

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `playback_controller.dart` | `lib/core/audio` | [[04-Reference/lib/core/audio/playback_controller|playback_controller.dart]] |
| `media_item_mapper.dart` | `lib/core/media` | [[04-Reference/lib/core/media/media_item_mapper|media_item_mapper.dart]] |
| `context_track.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/context_track|context_track.dart]] |
| `player_queue.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/player_queue|player_queue.dart]] |
| `queue_event.dart` | `lib/features/player/application/queue` | [[04-Reference/lib/features/player/application/queue/queue_event|queue_event.dart]] |
| `queue_state.dart` | `lib/features/player/application/queue` | [[04-Reference/lib/features/player/application/queue/queue_state|queue_state.dart]] |
| `queue_mutator.dart` | `lib/features/player/domain/queue` | [[04-Reference/lib/features/player/domain/queue/queue_mutator|queue_mutator.dart]] |
| `queue_filter_helper.dart` | `lib/features/player/domain/queue` | [[04-Reference/lib/features/player/domain/queue/queue_filter_helper|queue_filter_helper.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `queue_sheet_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/queue_sheet_screen|queue_sheet_screen.dart]] |
| `queue_replication_test.dart` | `test/features/player` | [[04-Reference/test/features/player/queue_replication_test|queue_replication_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class QueueBloc extends Bloc<QueueEvent, QueueState>`

**Internal State & Animation Synchronization:**
- `final PlaybackController _playbackController`: Injected playback controller interface.
- `StreamSubscription<List<MediaItem>>? _queueSub`: Subscribes to sliding-window tracks.
- `StreamSubscription<MediaItem?>? _mediaItemSub`: Subscribes to active track changes.
- `StreamSubscription<PlaybackState>? _playbackStateSub`: Subscribes to transport states.
- `int _pendingMutations`: Counter tracking active asynchronous operations.
- `DateTime? _animationEndTime`: Cooldown timestamp ensuring 375ms row collapse animations complete before queue re-emissions.
- `Future<void> _mutationChain`: Serialized execution chain for UI tap events.

**Event Handlers Registered:**
- `on<QueueStarted>(_onStarted)`: Attaches controller stream listeners.
- `on<QueueTrackTapped>(_onTrackTapped)`: Jumps playback head to tapped queue index.
- `on<QueueReordered>(_onReordered)`: Dispatches cross-section item reordering.
- `on<QueueTrackRemoved>(_onTrackRemoved)`: Removes track from user queue or context.
- `on<QueueTrackAdded>(_onTrackAdded)`: Appends track to user queue.
- `on<QueueCleared>(_onCleared)`: Flushes all user-queued tracks.
- `on<QueueShuffleToggled>(_onShuffleToggled)`: Toggles shuffle policy.
- `on<QueueRepeatToggled>(_onRepeatToggled)`: Toggles repeat mode (`none` -> `all` -> `one`).
- `on<QueuePlayPauseToggled>(_onPlayPauseToggled)`: Toggles play/pause transport.
- `on<QueueNextPageRequested>(_onNextPageRequested)`: Loads and appends subsequent 50-track page via LocalContextResolver / updatePage.
- `on<_QueueDataChanged>(_onDataChanged)`: Reconstructs `PlayerQueue` and emits state.
- `on<_PlaybackStatusChanged>(_onPlaybackStatusChanged)`: Emits transport updates.

## State & Data Flow Analysis
- **Animation Cooldown Synchronization (`_enqueueMutation`)**:
  ```dart
  void _enqueueMutation(Future<void> Function() action) {
    _pendingMutations++;
    _mutationChain = _mutationChain.then((_) async {
      final endTime = _animationEndTime;
      if (endTime != null) {
        final remaining = endTime.difference(DateTime.now());
        if (remaining > Duration.zero) {
          await Future<void>.delayed(remaining);
        }
      }
      await action();
    }).whenComplete(() {
      _pendingMutations--;
      if (_pendingMutations == 0) {
        _emitQueueChange();
      }
    });
  }
  ```
  When a user clears the queue or swipes to delete, the row plays a 375ms collapse animation. Re-emitting the queue state mid-animation would instantly remove the widget from the tree, causing jarring visual popping. `_enqueueMutation` waits for `_animationEndTime` before committing the audio layer mutation and updating the UI state.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Hardware Window vs. Total Playlist Size
> `PlaybackController.audioWindowEndIndex` only represents the upper limit of the currently loaded hardware window (50 tracks). `QueueBloc._onDataChanged` must inspect total context track length rather than truncating upcoming items at `audioWindowEndIndex`.

## Implementation Highlight
```dart
class QueueBloc extends Bloc<QueueEvent, QueueState> {
  final PlaybackController _playbackController;

  QueueBloc({required PlaybackController playbackController})
      : _playbackController = playbackController,
        super(const QueueState()) {
    on<QueueStarted>(_onStarted);
    on<QueueTrackTapped>(_onTrackTapped);
    on<QueueReordered>(_onReordered);
    on<QueueTrackRemoved>(_onTrackRemoved);
    on<QueueTrackAdded>(_onTrackAdded);
    on<QueueCleared>(_onCleared);
    on<QueueShuffleToggled>(_onShuffleToggled);
    on<QueueRepeatToggled>(_onRepeatToggled);
    on<QueuePlayPauseToggled>(_onPlayPauseToggled);
    on<_QueueDataChanged>(_onDataChanged);
    on<_PlaybackStatusChanged>(_onPlaybackStatusChanged);
  }
}
```
