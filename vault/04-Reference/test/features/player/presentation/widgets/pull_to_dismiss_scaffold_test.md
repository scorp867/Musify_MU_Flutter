---
title: "pull_to_dismiss_scaffold_test.dart"
path: "test/features/player/presentation/widgets/pull_to_dismiss_scaffold_test.dart"
type: "unit-test"
tags: [test, unit-test, flutter-test, verification]
lines: 368
---

# pull_to_dismiss_scaffold_test.dart

> Test File: `[test/features/player/presentation/widgets/pull_to_dismiss_scaffold_test.dart](file:///c:/Users/Admin/Musify_MU/test/features/player/presentation/widgets/pull_to_dismiss_scaffold_test.dart)`

## Test Suite Overview
This test suite verifies the functionality and regression resistance of components in Musify MU.

## Target Components Verified
- [[04-Reference/lib/features/player/presentation/widgets/peek_scroll_view|peek_scroll_view.dart]] (`lib/features/player/presentation/widgets/peek_scroll_view.dart`)
- [[04-Reference/lib/features/player/presentation/widgets/pull_to_dismiss_scaffold|pull_to_dismiss_scaffold.dart]] (`lib/features/player/presentation/widgets/pull_to_dismiss_scaffold.dart`)

## Test Cases & Groups
**Test Groups:**
- `group('PullToDismissScaffold Scrim Interaction and Multi-pointer Tests')`

**Individual Test Cases:**
- `test('scrim is not exposed when dragOffsetY is 0')`
- `test('dragging exposed scrim continues dragging the player sheet')`
- `test('multi-pointer handoff from sheet to scrim keeps drag active without premature snap-back')`
- `test('tapping exposed scrim outside player sheet dismisses the route')`
- `test('only 1 pointer is active on the scrim at a time and movement is not doubled when multiple pointers move')`
- `test('dragging down deeply then reversing up by 10px expands to offset 0 instead of collapsing')`
- `test('dragging down and releasing with downward motion collapses the sheet')`
- `test('dragging down sheet then dragging back up near top settles cleanly to 0 without dipping down')`

## Verification Strategy
- Follows the **AAA (Arrange, Act, Assert)** testing pattern.
- Uses `flutter_test` test harness with simulated events and streams.
