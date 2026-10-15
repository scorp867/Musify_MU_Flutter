---
title: "queue_replication_test.dart"
path: "test/features/player/queue_replication_test.dart"
type: "unit-test"
tags: [test, unit-test, flutter-test, verification, player, queue, operational-transformation, cosmos, prefetch]
lines: 829
---

# queue_replication_test.dart

> Test File: `[test/features/player/queue_replication_test.dart](file:///c:/Users/Admin/Musify_MU/test/features/player/queue_replication_test.dart)`
> Target Component: `[queue_bloc.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/application/queue/queue_bloc.dart)`, `[playback_queue_manager.dart](file:///c:/Users/Admin/Musify_MU/lib/core/audio/playback_queue_manager.dart)`, `[queue_mutator.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/domain/queue/queue_mutator.dart)`, `[queue_filter_helper.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/domain/queue/queue_filter_helper.dart)`, `[local_context_resolver.dart](file:///c:/Users/Admin/Musify_MU/lib/features/local_music/domain/local_context_resolver.dart)`

## Test Suite Overview
`queue_replication_test.dart` is an 829-line comprehensive unit and BLoC test suite (30 test cases) verifying exact 1:1 behavioral parity between Musify MU's playback queue architecture and Spotify Android's queue model (`com.spotify.player.model`, `p.zfy`, `p.lwp0`, `p.gxl0`, `p.hxl0`, `p.s5j`, Cosmos `ContextResolver`, and `EsMediaPrefetch`).

## Target Components Verified
- [[04-Reference/lib/features/player/application/queue/queue_bloc|queue_bloc.dart]] (`lib/features/player/application/queue/queue_bloc.dart`)
- [[04-Reference/lib/core/audio/playback_queue_manager|playback_queue_manager.dart]] (`lib/core/audio/playback_queue_manager.dart`)
- [[04-Reference/lib/features/player/domain/models/context_track|context_track.dart]] (`lib/features/player/domain/models/context_track.dart`)
- [[04-Reference/lib/features/player/domain/models/player_queue|player_queue.dart]] (`lib/features/player/domain/models/player_queue.dart`)
- [[04-Reference/lib/features/player/domain/queue/queue_filter_helper|queue_filter_helper.dart]] (`lib/features/player/domain/queue/queue_filter_helper.dart`)
- [[04-Reference/lib/features/player/domain/queue/queue_mutator|queue_mutator.dart]] (`lib/features/player/domain/queue/queue_mutator.dart`)
- [[04-Reference/lib/features/local_music/domain/local_context_resolver|local_context_resolver.dart]] (`lib/features/local_music/domain/local_context_resolver.dart`)
- [[04-Reference/lib/features/player/domain/models/prefetch_level|prefetch_level.dart]] (`lib/features/player/domain/models/prefetch_level.dart`)
- [[04-Reference/lib/features/player/domain/models/prepare_play_options|prepare_play_options.dart]] (`lib/features/player/domain/models/prepare_play_options.dart`)
- [[04-Reference/lib/features/player/domain/models/set_queue_command|set_queue_command.dart]] (`lib/features/player/domain/models/set_queue_command.dart`)
- [[04-Reference/lib/features/player/domain/models/update_page_command|update_page_command.dart]] (`lib/features/player/domain/models/update_page_command.dart`)

## Test Cases & Verification Scenarios

### 1. Domain Models & Parity
- **`ContextTrack models 1:1 properties from com.spotify.player.model`**: Verifies exact field serialization, instance UID, provider tag, and `isQueued` mapping.
- **`PlayerQueue nextTracks combines userQueue and contextTracks in order`**: Validates linear `nextTracks` ordering with prioritized user-queued items ahead of context tracks.
- **`Cross-section reordering converts context track to user-queued track`**: Checks metadata and `isQueued` state flip.
- **`Cross-section reordering converts user-queued track to context track`**: Verifies removal from user queue partition.
- **`Track removal deletes from contextTracks or userQueue by uid`**: Validates targeted removal by instance UID without index leakage.

### 2. QueueFilterHelper (hxl0.java & s5j.java)
- **`getUserQueue returns only isQueued tracks`**: Filters tracks where `isQueued == true`.
- **`getContextQueue returns non-queued tracks`**: Filters tracks where `!isQueued`.
- **`setIsQueued synchronizes both boolean and metadata map`**: Stamped `metadata['is_queued']` and provider tags match boolean state.

### 3. QueueMutator Operational Transformations (zfy.java, lwp0.java, pml0.java, gxl0.java)
- **`addToQueue appends to user queue, deduplicates, and increments revision`**: FIFO queuing with monotonic revision update.
- **`addToQueue creates user-queued track while preserving context queue (uvn.java:58)`**: Preserves upcoming context without clobbering delimiters.
- **`playAsNext prepends to front of queue with isQueued = true`**: Immediate next-play priority.
- **`reorder stamps items according to partition placement`**: Moves tracks across boundary lines.
- **`removeTrack removes track by uid and increments revision`**: Safe deletion across linear nextTracks.
- **`clearUserQueue purges user queue while keeping context tracks`**: Wipes user partition while keeping context tracks intact.
- **`advancePlayhead promotes next track and moves current to history`**: Advances track and prepends to `prevTracks`.

### 4. PrefetchLevel & PreparePlayOptions
- **`PrefetchLevel enum contains none and media`**: Verifies enum values for audio feeding.
- **`PreparePlayOptions defaults and properties`**: Validates defaults, skip targets, seek position, and overrides.

### 5. Precise Upward & Downward Drag Reordering
- **`Dragging downward from index 0 to index 3 places track exactly at index 3`**: Exact slot verification.
- **`Dragging upward from index 3 to index 0 places track exactly at index 0`**: Exact slot verification.
- **`QueueMutator.reorderTrack 1:1 with gxl0.java: downward drag across partition`**: Reorder into context partition resets `isQueued = false`.
- **`QueueMutator.reorderTrack 1:1 with gxl0.java: upward drag across partition`**: Reorder into user queue sets `isQueued = true`.

### 6. UpdatePageCommand & Cosmos Pagination
- **`QueueMutator.updatePage cleanly appends page tracks without delimiter`**: Dynamic page integration into active queue.
- **`LocalContextResolver chunks offline tracks without delimiter pseudo-tracks`**: Validates 50-track chunking with next-page URLs.
- **`LocalContextResolver.buildContextFromDomainTracks chunks DomainTracks into 50-track pages`**: Validates domain entity pagination.
- **`SetQueueCommand and CommandOptions 1:1 modeling`**: Tests builder pattern and JSON serialization.
- **`LocalContextResolver.playDomainTracks loads only 50-track page chunk into player`**: Verifies that initial playback feeds only the active 50-track chunk.

### 7. QueueBloc BLoC Integration
- **`cross-partition dragging removes isQueued without badge reappearing on sync`**: Validates that cross-partition drags persist when audio engine emits updated stream.
- **`QueueBloc handles QueueNextPageRequested and updates queue with next page`**: Appends next page and updates `PlaybackController`.
- **`fast-path preserves revision when syncing with audio engine`**: Prevents `ReorderableListView` flickering when queue stream updates with identical tracks.
- **`QueueTrackAdded updates state immediately and does not get reset by backend setNextTracks response`**: Validates optimistic addition and persistence across controller sync.

## Verification Strategy
- **_FakePlaybackController**: Simulates full `PlaybackController` stream events, `setNextTracks` delegation, and queue state broadcasting.
- **AAA Pattern**: All 30 tests follow Arrange-Act-Assert structure and run cleanly in CI (`flutter test test/features/player/queue_replication_test.dart`).
