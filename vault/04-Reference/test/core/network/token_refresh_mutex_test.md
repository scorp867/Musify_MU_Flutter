---
title: "token_refresh_mutex_test.dart"
path: "test/core/network/token_refresh_mutex_test.dart"
type: "unit-test"
tags: [test, unit-test, flutter-test, verification, network, mutex, auth]
lines: 49
---

# token_refresh_mutex_test.dart

> Test File: `[test/core/network/token_refresh_mutex_test.dart](file:///c:/Users/Admin/Musify_MU/test/core/network/token_refresh_mutex_test.dart)`
> Target Component: `[token_refresh_mutex.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/auth/token_refresh_mutex.dart)`

## Test Suite Overview
`token_refresh_mutex_test.dart` verifies the asynchronous locking behavior of `TokenRefreshMutex`. It ensures that when multiple concurrent requests encounter 401 Unauthorized responses simultaneously, only a single token refresh request is dispatched to Spotify's `/api/token` endpoint, while all callers receive the newly refreshed token.

## Target Components Verified
- [[04-Reference/lib/core/network/auth/token_refresh_mutex|token_refresh_mutex.dart]] (`lib/core/network/auth/token_refresh_mutex.dart`)

## Test Cases & Verification Scenarios

### 1. `test('concurrent callers only invoke refresh action once')`
- **Setup**: Fires 10 concurrent requests (`Future.wait(List.generate(10, (_) => mutex.lock(simulateRefresh)))`).
- **Simulation**: Simulates an asynchronous refresh with a 50ms artificial latency returning `'fresh_token_123'`.
- **Assertions**:
  - All 10 callers resolve to `'fresh_token_123'`.
  - Underlying refresh action invocation count equals EXACTLY 1.

### 2. `test('subsequent calls after refresh completion can run again')`
- **Setup**: Executes a primary refresh, awaits its completion, then issues a secondary refresh.
- **Assertions**:
  - The first call resolves to `'token_1'` with invocation count 1.
  - The second call executes independently, resolving to `'token_2'` with invocation count 2, confirming that the `Completer` cleanly releases its lock upon completion.

## Architectural Value
Prevents Spotify OAuth rate limiting (HTTP 429) and race conditions where multiple requests attempt to exchange the same single-use refresh token simultaneously.
