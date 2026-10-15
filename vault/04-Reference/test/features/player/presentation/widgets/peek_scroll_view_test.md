---
title: "peek_scroll_view_test.dart"
path: "test/features/player/presentation/widgets/peek_scroll_view_test.dart"
type: "unit-test"
tags: [test, unit-test, flutter-test, verification]
lines: 632
---

# peek_scroll_view_test.dart

> Test File: `[test/features/player/presentation/widgets/peek_scroll_view_test.dart](file:///c:/Users/Admin/Musify_MU/test/features/player/presentation/widgets/peek_scroll_view_test.dart)`

## Test Suite Overview
This test suite verifies the functionality and regression resistance of components in Musify MU.

## Target Components Verified
- [[04-Reference/lib/features/player/presentation/widgets/peek_scroll_view|peek_scroll_view.dart]] (`lib/features/player/presentation/widgets/peek_scroll_view.dart`)
- [[04-Reference/lib/features/player/presentation/widgets/pull_to_dismiss_scaffold|pull_to_dismiss_scaffold.dart]] (`lib/features/player/presentation/widgets/pull_to_dismiss_scaffold.dart`)
- [[04-Reference/lib/features/player/presentation/widgets/spotify_scroll_physics|spotify_scroll_physics.dart]] (`lib/features/player/presentation/widgets/spotify_scroll_physics.dart`)

## Test Cases & Groups
**Test Groups:**
- `group('AndroidEdgeEffect (AOSP Port Unit Tests)')`
- `group('SpotifyStretchController')`
- `group('PeekScrollView')`
- `group('SpotifyStretchOverscrollIndicator')`

**Individual Test Cases:**
- `test('onPullDistance advances and contracts proportionally')`
- `test('onRelease rebounds underdamped spring to zero without hanging or runaway')`
- `test('onAbsorb absorbs impact velocity and converges to zero')`
- `test('dampStretchVector computes correct logarithmic/exponential curve')`
- `test('computes bidirectional stretch correctly and rebounds to zero')`
- `test('mounts cleanly without null-check crashes during initial layout')`
- `test('handles vertical drag gestures without unhandled exceptions')`
- `test('overscroll at bottom rebounds to 0 after lifting finger in PeekScrollView')`
- `test('dragging in opposite direction contracts stretch without scrolling content until stretch reaches 0')`
- `test('scrolling slightly from offset 0 then dragging down in same gesture locks to offset 0 with overscroll without collapsing sheet')`
- `test('dragging down when resting at offset 0 drives pull to dismiss route without overscroll')`
- `test('records velocity on drag down then up near 0')`
- `test('multi-pointer overscroll handoff does not reset stretch when a pointer lifts while another remains')`
- `test('renders child and handles scroll notifications smoothly')`

## Verification Strategy
- Follows the **AAA (Arrange, Act, Assert)** testing pattern.
- Uses `flutter_test` test harness with simulated events and streams.
