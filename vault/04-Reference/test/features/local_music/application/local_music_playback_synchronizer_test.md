---
title: "local_music_playback_synchronizer_test.dart"
path: "test/features/local_music/application/local_music_playback_synchronizer_test.dart"
type: "unit-test"
tags: [test, unit-test, flutter-test, verification, local-music, synchronization]
lines: 154
---

# local_music_playback_synchronizer_test.dart

> Test File: `[test/features/local_music/application/local_music_playback_synchronizer_test.dart](file:///c:/Users/Admin/Musify_MU/test/features/local_music/application/local_music_playback_synchronizer_test.dart)`
> Target Component: `[local_music_playback_synchronizer.dart](file:///c:/Users/Admin/Musify_MU/lib/features/local_music/application/local_music_playback_synchronizer.dart)`

## Test Suite Overview
`local_music_playback_synchronizer_test.dart` verifies that background local library resyncs correctly update the actively playing `MediaItem` in `PlaybackController` when ID3 tags or filesystem timestamps change, without restarting audio playback or introducing audible hiccups.

## Target Components Verified
- [[04-Reference/lib/features/local_music/application/local_music_playback_synchronizer|local_music_playback_synchronizer.dart]] (`lib/features/local_music/application/local_music_playback_synchronizer.dart`)
- [[04-Reference/lib/core/audio/playback_controller|playback_controller.dart]] (`lib/core/audio/playback_controller.dart`)

## Test Cases & Verification Scenarios

### 1. `test('updates the active media item when local metadata changes')`
- **Scenario**: Local scanner detects an updated title or new `dateModified` timestamp for the song currently playing.
- **Assertion**:
  - `controller.updatedItems` contains exactly 1 updated item.
  - The new title and updated `dateModified` integer are propagated seamlessly to Android system notifications and lock screens.

### 2. `test('does not update playback when the active track is unchanged')`
- **Scenario**: Re-scan completes with identical track metadata.
- **Assertion**:
  - `controller.updatedItems` remains empty, avoiding redundant MethodChannel broadcasts to Android MediaSession.

## Architectural Value
Prevents audio stutter and notification flickers during periodic background filesystem rescans by gating updates on exact field differences.
