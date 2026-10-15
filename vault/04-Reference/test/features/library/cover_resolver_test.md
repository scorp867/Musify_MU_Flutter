---
title: "cover_resolver_test.dart"
path: "test/features/library/cover_resolver_test.dart"
type: "unit-test"
tags: [test, unit-test, flutter-test, verification]
lines: 139
---

# cover_resolver_test.dart

> Test File: `[test/features/library/cover_resolver_test.dart](file:///c:/Users/Admin/Musify_MU/test/features/library/cover_resolver_test.dart)`

## Test Suite Overview
This test suite verifies the functionality and regression resistance of components in Musify MU.

## Target Components Verified
- [[04-Reference/lib/features/library/domain/services/cover_resolver|cover_resolver.dart]] (`lib/features/library/domain/services/cover_resolver.dart`)

## Test Cases & Groups
**Test Groups:**
- `group('CoverResolver Spotify Behavior Tests')`

**Individual Test Cases:**
- `test('takes first track album art as single cover when fewer than 4 unique artworks are present')`
- `test('takes first track album art when playlist has 1 unique artwork')`
- `test('builds 2x2 mosaic when playlist has 4 or more unique artworks')`
- `test('CoverSet explicitly sets new custom cover and clears mosaic flag')`
- `test('resolveFromFull builds single cover from first track when < 4 artworks and no custom cover')`
- `test('resolveFromFull sets null cover when playlist has 0 tracks')`
- `test('resolveFromFull preserves custom cover unconditionally and ignores track arts')`
- `test('resolve preserves existing custom cover across diffs without coverChange')`
- `test('CoverRemoved reverts custom cover to 2x2 mosaic when >= 4 track arts exist')`

## Verification Strategy
- Follows the **AAA (Arrange, Act, Assert)** testing pattern.
- Uses `flutter_test` test harness with simulated events and streams.
