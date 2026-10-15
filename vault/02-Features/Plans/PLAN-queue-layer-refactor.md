# Queue Layer Comprehensive Audit & Refactor Plan

## Overview
A full-stack architectural and bug-fix refactor of the Queue layer across Core Audio (`PlaybackQueueManager`, `AudioPlaybackService`, `AudioNotificationHandler`, `PlaybackController`), Domain (`PlayerQueue`, `ContextTrack`), Application (`QueueBloc`), and Presentation (`QueueSheetScreen`, `QueueTrackRow`, `QueueNowPlayingRow`, `PlayerScreen`). All 1:1 Spotify visual designs and 60/120fps animations are strictly preserved while eliminating functional bugs, split-brain state loss, race conditions, and Clean Architecture violations.

## Project Type
- **MOBILE** (Flutter Android/iOS)
- **Primary Agent**: `mobile-developer`
- **Core Skills**: `clean-code`, `architecture`, `mobile-design`, `testing-patterns`

---

## Complete Audit Findings (From Parallel Subagents)

### A. Critical Functional Bugs
1. **Unimplemented Shuffle & Repeat Modes Across the Entire Audio Stack**
   - `PlaybackController.setShuffleMode` and `setRepeatMode` (`lib/core/audio/playback_controller.dart:24-25`) are not overridden in `AudioNotificationHandler` (`lib/core/audio/audio_notification_handler.dart:13-15`), `AudioPlaybackService`, or `PlaybackQueueManager`. They hit `BaseAudioHandler`'s no-op stubs.
   - `AudioNotificationHandler._publishPlaybackState` (`audio_notification_handler.dart:40-68`) always emits the default `AudioServiceShuffleMode.none` and `AudioServiceRepeatMode.none`, which causes `QueueBloc._onPlaybackStatusChanged` (`queue_bloc.dart:134-150`) to immediately overwrite and revert any UI toggle back to `none`.
   - `PlayerScreen` (`lib/features/player/presentation/screens/player_screen.dart:100-101, 501-509`) uses local booleans `_shuffleEnabled` and `_repeatEnabled` that never listen to `playbackState`, and `_toggleRepeat` only supports 2 states (`one` / `none`) instead of 3 (`none -> all -> one`).
2. **`QueueSheetScreen` Close & Reopen Wipes `userQueue` State & Causes Duplicate `ValueKey` Crashes**
   - `QueueSheetScreen.show` (`lib/features/player/presentation/screens/queue_sheet_screen.dart:50-54`) creates a disposable `QueueBloc` per modal open. Closing the sheet resets `_userQueuedUids` (`queue_bloc.dart:57`) and `_uidSeed` (`queue_bloc.dart:59`) to `0`.
   - Re-adding a previously queued track after reopening the sheet generates `'${uri}_q_1'` again, colliding with the existing `'${uri}_q_1'` in `_fullTracks` and crashing `ReorderableListView` with a duplicate `ValueKey('track_${track.uid}')`.
   - Cross-section reordered tracks (`queue_bloc.dart:298-331`) revert to their old section on `_onDataChanged` or sheet reopen because `PlaybackQueueManager.reorderTrack` (`playback_queue_manager.dart:108-133`) never updates `MediaItem.extras['is_queued']` or `extras['provider']`.
3. **Natural Track Completion & Duplicate Track Bugs**
   - When a queued copy of a context track finishes playing, `_onDataChanged` (`queue_bloc.dart:567`) matches `availableExisting` by `t.uri == item.id` instead of instance `uid`, transferring `isQueued: true` and the queued `uid` onto the remaining context track instead of popping `userQueue`.
   - `AudioNotificationHandler._latestMediaItems` (`audio_notification_handler.dart:18, 78`) is keyed by `item.id` instead of instance `uid`, overwriting `extras` (`uid`, `is_queued`, `provider`) when a track appears in both `userQueue` and `contextTracks`.
   - Consecutive identical tracks (`[A, A]`) fail to emit `mediaItem` in `AudioNotificationHandler._publishPlaybackState` (`line 87: if (item.id != mediaItem.value?.id)`) and hit the buggy fast-path in `QueueBloc._onDataChanged` (`lines 511-540`), never removing the finished track from `nextTracks`.
   - `PlayerQueue.props` (`lib/features/player/domain/models/player_queue.dart:50-56`) only compares `currentTrack?.uid` and `revision`, suppressing state emissions when `currentTrack`'s artwork or metadata updates.
4. **Sliding Window Desynchronization & Concurrency Races in `PlaybackQueueManager`**
   - `removeTrack` (`playback_queue_manager.dart:135-148`), `removeTrackRange` (`lines 150-169`), `insertTrack` (`lines 171-183`), and `reorderTrack` (`lines 108-133`) corrupt `_windowStartIndex` and `_windowEndIndex` whenever mutations occur before `_windowStartIndex`, after `_windowEndIndex`, or across the 50-track window boundary.
   - `onIndexChanged` (`lines 200-232`) updates `_windowEndIndex` and `_windowStartIndex` *after* `await playlist.addAll` / `insertAll` without serialization, causing duplicate batch insertions and `+10` index offsets during `PlaybackEvent` emissions.
   - `QueueBloc` caps `upcomingItems` at `audioWindowEndIndex` (`queue_bloc.dart:130, 497-504`), hiding tracks 51+ in playlists larger than 50 tracks.
5. **Mid-Animation Interaction Deadlocks & Dropped Mutations**
   - **Clear + Tap Deadlock**: Tapping any track within `375ms` of tapping **Clear** (`queue_sheet_screen.dart:237-265`) increments `_tapAnimationGeneration`, causing `_handleClearQueue`'s delayed callback to return early at line 258 without resetting `_isClearingQueue = false` or dispatching `QueueCleared()`. The Clear button is permanently locked out for the rest of the session.
   - **Sheet Close Drops Audio Mutations**: Closing `QueueSheetScreen` within `375ms` of tapping, adding, clearing, or swiping-to-delete a track cancels the mutation (`if (!isClosed) await action();` at `queue_bloc.dart:71`, `if (!mounted) return;` at `queue_sheet_screen.dart:258` and `queue_track_row.dart:282`).
   - **Mid-Transition Reorder & Rapid Tap Corruption**: Reordering while `_tapTransitionTracks != null` (`queue_sheet_screen.dart:547, 565-567`) sends indices from the temporary transition list to `QueueBloc._onReordered`. Rapid taps within `375ms` corrupt `baseOffset = state.currentIndex + 1` (`queue_bloc.dart:187`) and execute unguarded `removeQueueRange` calls (`lines 224-233, 258-263`).
   - **Suppressed Stream Updates Never Flushed**: When `_pendingMutations` decrements to `0` (`queue_bloc.dart:74-76`), suppressed stream events and `_lastQueueIndex` are never flushed via `_emitQueueChange()`.
   - **Interrupted `isClearing` Leaves Dead Row**: `QueueTrackRow.didUpdateWidget` (`queue_track_row.dart:177-200`) does not handle `!widget.isClearing && oldWidget.isClearing`, leaving interrupted rows permanently invisible (`sizeFactor = 0.0`) and unresponsive.
   - **Cross-Section Drag False Insert Animation**: Dragging a context track into `userQueue` causes `_syncUserQueueAnimations` (`queue_sheet_screen.dart:157-173`) to treat the dragged UID as newly inserted, collapsing it to `0px` and re-running the 370ms insert animation.
   - **Scenario B Off-Screen Truncation Pop**: When `offScreenQueuedCount > 10` (`queue_sheet_screen.dart:352-358`), tracks `10..offScreenQueuedCount-1` are omitted during the `375ms` transition and pop back in at `t = 375ms`.
   - **Missing Double-Open Guard & Route Collision**: `QueueSheetScreen.show` (`queue_sheet_screen.dart:36-76`) lacks a single-top `_isOpen` guard, and `PlayerOptionsSheet` (`player_sheets.dart:51-54`) pops the bottom sheet and pushes `QueueSheetScreen` on the root navigator in the same synchronous frame.
   - **`stop()` Breaks Session Stream**: `AudioNotificationHandler.stop()` (`audio_notification_handler.dart:293-297`) cancels `_playbackSub`, permanently breaking `playbackState` updates for subsequent playback.

### B. Architectural & Layering Violations
1. **Ephemeral Split-Brain Queue State**: `PlayerQueue` (`userQueue` vs `contextTracks`) is reconstructed heuristically inside a disposable UI BLoC (`QueueBloc`) instead of being managed by a session-scoped queue engine in `PlaybackQueueManager`. External screens cannot add tracks to `userQueue`.
2. **Domain Layer Coupled to `audio_service`**: `ContextTrack` (`lib/features/player/domain/models/context_track.dart:1`) imports `package:audio_service/audio_service.dart` directly, and presentation widgets (`QueueNowPlayingRow`, `QueueTrackRow`) reconstruct `MediaItem` inside `build()`.
3. **Hardware Pagination Leaked to Application Layer**: `PlaybackController.audioWindowEndIndex` leaks `just_audio`'s internal 50-track `ConcatenatingAudioSource` window into `QueueBloc`.
4. **Shadow State Machine in Presentation**: `_QueueSheetBodyState` (`queue_sheet_screen.dart`, 864 lines) holds 9 mutable state-tracking fields and duplicates `375ms` timers alongside `QueueBloc`.
5. **Synchronous `setState` & `Bloc.add` Inside `PlayerScreen.build`**: `_buildPlayer` (`player_screen.dart:334`) calls `_updateScheme(item)` synchronously during `build()`.

### C. Structural, Dead Code & Maintenance Issues
1. **Dead Files & Unused Classes**:
   - `lib/features/player/presentation/widgets/queue_now_playing_card.dart` (177 lines, 0 callers)
   - `lib/features/player/presentation/widgets/queue_track_tile.dart` (107 lines, 0 callers)
   - `PlayerSecondaryControls` in `lib/features/player/presentation/widgets/player_controls.dart:327-423` (0 callers)
   - `AudioNotificationHandler.playTrack` (`audio_notification_handler.dart:107-115`) & `AudioPlaybackService.setAudioSource(String)` (`audio_playback_service.dart:29-35`) (0 callers)
2. **God Files & Duplicated Widgets/Constants**:
   - `queue_sheet_screen.dart` (864 lines) and `queue_track_row.dart` (646 lines) bundle multiple responsibilities.
   - Press-scale button logic is triplicated across `queue_sheet_screen.dart`, `queue_now_playing_row.dart`, and `queue_controls_layout.dart`.
   - Magic numbers (`64.0` row height, `370ms`/`375ms` animator durations, `Cubic(0.3, 0.0, 0.0, 1.0)` curve) and hex colors are scattered across 6+ files.
3. **Zero `QueueBloc` Unit Test Coverage**: `test/features/player/queue_replication_test.dart` only tests inline list literals without testing `QueueBloc` or `PlaybackQueueManager`.

---

## Success Criteria
- [ ] Single authoritative session-scoped queue state (`userQueue`, `contextTracks`, `currentTrack`, monotonic `uid` generator, and unshuffled backup) persists across `QueueSheetScreen` open/close cycles and supports adding tracks to the queue from anywhere in the app.
- [ ] Shuffle (`contextTracks` only, keeping `userQueue` FIFO) and Repeat (`none -> all -> one`) work end-to-end across `PlaybackQueueManager`, `AudioNotificationHandler`, `QueueSheetScreen`, and `PlayerScreen`.
- [ ] All sliding-window index bugs, async race conditions, and mid-animation deadlocks (`Clear` + `Tap`, rapid taps, sheet close during `375ms` window, cross-section drag animations) are eliminated while keeping 60/120fps animations intact.
- [ ] Domain models (`ContextTrack`, `PlayerQueue`) have zero dependency on `package:audio_service/audio_service.dart`.
- [ ] Dead queue files removed, oversized presentation files modularized, and unit/bloc tests added for `PlaybackQueueManager` and `QueueBloc`.
- [ ] `dart analyze` and `flutter test` pass with 0 issues.

---

## Proposed File Structure
```text
lib/
├── core/
│   ├── audio/
│   │   ├── playback_controller.dart          # Clean session queue & playback contract
│   │   ├── playback_queue_manager.dart       # Authoritative session queue + serialized sliding window
│   │   ├── audio_playback_service.dart       # Loops/shuffle & queue delegation
│   │   └── audio_notification_handler.dart   # MediaSession sync, repeat/shuffle state, instance-safe cache
│   └── media/
│       └── media_item_mapper.dart            # All ContextTrack <-> MediaItem & Track <-> MediaItem mapping
└── features/
    └── player/
        ├── domain/
        │   └── models/
        │       ├── context_track.dart        # Pure domain model (no audio_service import)
        │       └── player_queue.dart         # Pure domain queue value object with full equality
        ├── application/
        │   └── queue/
        │       ├── queue_bloc.dart           # Thin reactive BLoC registered in DI
        │       ├── queue_event.dart          # Queue events with complete Equatable props
        │       └── queue_state.dart          # Queue state
        └── presentation/
            ├── screens/
            │   ├── player_screen.dart        # Synced shuffle/repeat & build-safe scheme updates
            │   └── queue_sheet_screen.dart   # Modularized Queue Sheet screen (<450 lines)
            └── widgets/
                ├── queue_header_bar.dart     # Extracted Grapple, Queue Header & Clear button
                ├── queue_now_playing_row.dart# UID-keyed sticky row & shared press-scale button
                ├── queue_track_row.dart      # Row widget with reversible item animator (<400 lines)
                ├── queue_swipe_background.dart # Extracted swipe background painter & gesture recognizer
                ├── queue_controls_layout.dart# Bottom controls dock
                └── queued_badge_view.dart    # Dedicated Queued badge widget
```

---

## Task Breakdown

### Task 1: Decouple Domain Models & Centralize `MediaItemMapper`
- **Agent**: `mobile-developer` | **Skills**: `clean-code`, `architecture` | **Priority**: P0 | **Dependencies**: None
- **INPUT**: `lib/features/player/domain/models/context_track.dart`, `lib/features/player/domain/models/player_queue.dart`, `lib/core/media/media_item_mapper.dart`
- **OUTPUT**:
  - Remove `package:audio_service/audio_service.dart` from `ContextTrack`; move `fromMediaItem` / `toMediaItem` (with `Expando<MediaItem>` cache and non-destructive extras preservation) into `MediaItemMapper`.
  - Fix `PlayerQueue.props` to compare `currentTrack`, `userQueue`, `contextTracks`, and `revision` accurately so artwork/metadata updates emit properly, and remove unused `prevTracks`.
- **VERIFY**: `dart analyze lib/features/player/domain/ lib/core/media/` reports 0 issues and 0 `audio_service` imports in `domain/`.

### Task 2: Refactor `PlaybackQueueManager` as the Authoritative Session Queue Engine
- **Agent**: `mobile-developer` | **Skills**: `clean-code`, `architecture` | **Priority**: P0 | **Dependencies**: Task 1
- **INPUT**: `lib/core/audio/playback_queue_manager.dart`, `lib/core/audio/audio_playback_service.dart`, `lib/core/audio/audio_notification_handler.dart`, `lib/core/audio/playback_controller.dart`
- **OUTPUT**:
  - Serialize all `PlaybackQueueManager` async operations (`setQueue`, `insertTrack`, `removeTrack`, `removeTrackRange`, `reorderTrack`, `onIndexChanged`) through an internal async operation queue so `ConcatenatingAudioSource` and `_windowStartIndex` / `_windowEndIndex` never race or desync.
  - Fix sliding-window boundary math in `removeTrack`, `removeTrackRange`, `insertTrack`, and `reorderTrack` (handling indices `< _windowStartIndex`, `>= _windowEndIndex`, and cross-window moves).
  - Track `userQueue` vs `contextTracks` (and unshuffled `contextTracks` backup + monotonic `_uidSeed`) directly inside `PlaybackQueueManager` so `userQueue` survives `QueueSheetScreen` close/reopen, pops consumed queued tracks on natural advance, and supports `enqueueUserTrack(MediaItem)` from anywhere in the app.
  - Implement `setShuffleMode` (shuffling only `contextTracks` while keeping `userQueue` in FIFO order right after `currentTrack`) and `setRepeatMode` (`none -> all -> one` mapped to `LoopMode.off`, `LoopMode.all`, `LoopMode.one`).
  - Fix `AudioNotificationHandler`: key `_latestMediaItems` by instance `uid` (fallback `id`), emit `mediaItem` on consecutive duplicate tracks when `queueIndex` changes, sanitize temp artwork filenames, keep `_playbackSub` alive across `stop()`, and remove `audioWindowEndIndex` truncation from full-queue consumers.
- **VERIFY**: `dart analyze lib/core/audio/` passes with 0 errors/warnings.

### Task 3: Refactor `QueueBloc` & Register Session Queue State in DI
- **Agent**: `mobile-developer` | **Skills**: `clean-code`, `architecture` | **Priority**: P1 | **Dependencies**: Task 2
- **INPUT**: `lib/features/player/application/queue/queue_bloc.dart`, `queue_event.dart`, `queue_state.dart`, `lib/app/di/injection.dart`
- **OUTPUT**:
  - Register `QueueBloc` in `injection.dart` and make `PlaybackController` / `PlaybackQueueManager` execute deferred mutations independently of `QueueSheetScreen` route disposal (so closing the sheet within `375ms` never drops a tap, clear, add, or remove).
  - Fix `_enqueueMutation` so all queued mutations (`removeQueueRange`, `reorderQueueItem`, `skipToQueueItem`, `play`) check `_latestTapGeneration == tapGen`, compute `baseOffset` from authoritative engine state rather than chained optimistic increments, and flush any suppressed stream updates (`_emitQueueChange()`) when `_pendingMutations` reaches `0`.
  - Fix `_onStarted` subscription initialization so `_lastQueueIndex` is populated synchronously from `playbackState` before `_onDataChanged` runs.
  - Fix cross-section reorder boundary (`userQueue` <-> `contextTracks`) so `isQueued` and `provider` are persisted in `PlaybackQueueManager`.
- **VERIFY**: `dart analyze lib/features/player/application/queue/ lib/app/di/` passes with 0 issues.

### Task 4: Fix Presentation Bugs, Modularize Queue Widgets & Clean Dead Code
- **Agent**: `mobile-developer` | **Skills**: `clean-code`, `mobile-design` | **Priority**: P1 | **Dependencies**: Task 3
- **INPUT**: `lib/features/player/presentation/screens/queue_sheet_screen.dart`, `lib/features/player/presentation/widgets/queue_track_row.dart`, `queue_now_playing_row.dart`, `queue_controls_layout.dart`, `player_screen.dart`, `player_sheets.dart`
- **OUTPUT**:
  - Fix the `_handleClearQueue` + `_handleTrackTapped` deadlock so interrupting a clear animation always resets `_isClearingQueue = false` and reconciles cleared tracks.
  - Guard `onReorderItem` and rapid taps during the `375ms` `_tapTransitionTracks` window; remove the `10`-item truncation cap on `offScreenQueuedCount` in Scenario B so off-screen queued tracks never pop at `t = 375ms`.
  - Fix `_syncUserQueueAnimations` so dragging a context track into `userQueue` does not trigger a false `370ms` collapse/insert animation.
  - Fix `QueueTrackRow.didUpdateWidget` to recover cleanly when `isClearing` or `animateSlideDown` changes, and disable `onTap` / `ReorderableDragStartListener` while `_isRemoving` is `true`.
  - Key `QueueNowPlayingRow`'s `AnimatedSwitcher` by `track.uid` instead of `track.uri`.
  - Add a single-top `_isOpen` guard to `QueueSheetScreen.show`, fix `PlayerOptionsSheet`'s simultaneous `Navigator.pop` + `QueueSheetScreen.show`, move `_updateScheme` out of `PlayerScreen.build`, and sync `PlayerScreen`'s shuffle/repeat controls with `_playbackController.playbackState` (supporting all 3 repeat modes).
  - Extract `queue_header_bar.dart`, `queue_swipe_background.dart`, and `queued_badge_view.dart`, share common animation constants in `player_theme.dart`, and delete dead files (`queue_now_playing_card.dart`, `queue_track_tile.dart`, `PlayerSecondaryControls`, `playTrack`).
- **VERIFY**: `dart analyze lib/features/player/presentation/` passes with 0 issues.

### Task 5: Comprehensive Unit & BLoC Test Suite for the Queue Layer
- **Agent**: `mobile-developer` | **Skills**: `testing-patterns`, `clean-code` | **Priority**: P2 | **Dependencies**: Tasks 1-4
- **INPUT**: `test/features/player/queue_replication_test.dart`
- **OUTPUT**:
  - Replace inline list tests in `test/features/player/queue_replication_test.dart` with real unit/BLoC tests covering `PlaybackQueueManager` (sliding window add/remove/range/reorder, `userQueue` FIFO preservation, shuffle/unshuffle of `contextTracks`, repeat modes, natural track advance popping `userQueue`) and `QueueBloc` (tap-to-play Scenario A & B, rapid multi-tap coalescing, cross-section reorder persistence across close/reopen, clear queue, swipe-to-add duplicate UID safety).
- **VERIFY**: `flutter test test/features/player/queue_replication_test.dart` passes 100%.

---

## Phase X: Final Verification Checklist
- [ ] `dart analyze` across the entire repository reports `No issues found!`
- [ ] `flutter test` passes all unit and BLoC tests
- [ ] Python verification script check: `python .agent/skills/mobile-design/scripts/mobile_audit.py .`
- [ ] Manual/Profile check: 60/120fps animations in `QueueSheetScreen` remain completely smooth with zero regressions
