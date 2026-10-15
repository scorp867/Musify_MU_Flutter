# Architecture Plan: System-Wide Network Traffic Controller & Priority Request Queue

**Task Slug:** `network-traffic-controller`  
**Primary Agent:** `mobile-developer`  
**Key Skills:** `clean-code`, `mobile-design`, `plan-writing`, `architecture`  
**Project Type:** MOBILE (Flutter / Android)  
**Status:** DRAFT (Awaiting User Review)  

---

## 1. Problem Statement & Motivation

Currently, Musify_MU retries individual metadata queries and image loads, but the **underlying transport layer has no unified traffic control**:
1. **Blind Offline Dispatching**: When network connectivity drops, any service making an HTTP call immediately hits the socket adapter, hangs for connection timeouts, or fails abruptly with raw socket errors.
2. **Offline Request Starvation vs. Memory Leaks**: When offline, requests either fail immediately (forcing user to retry manually) or retry blindly in rapid succession.
3. **Thundering Herd on Reconnect**: When connectivity restores, dozens of pending operations across different features (home feed, library, search, browse) all fire simultaneously, saturating mobile bandwidth and socket pools.
4. **No System-Wide Priority or Preemption**: Background card metadata and sync jobs compete equally for bandwidth with critical audio playback tokens and decryption keys.
5. **No Superseding / Stale Eviction**: If a user performs a search while connection flickers and types a new search, both requests execute when back online, wasting data on obsolete results.

---

## 2. Proposed Architecture: `QueuedNetworkClient` & `NetworkTrafficController`

A transparent decorator over [`NetworkClient`](file:///c:/Users/Admin/Musify_MU/lib/core/network/client/network_client.dart) powered by an internal priority-scheduled, offline-gating queue.

```
                           All Outbound Calls
               (AndroidTransport, WebPlayerTransport, Repositories)
                                    │
                                    ▼
                ┌───────────────────────────────────────┐
                │          QueuedNetworkClient          │
                │      (implements NetworkClient)       │
                └───────────────────┬───────────────────┘
                                    │
                                    ▼
                ┌───────────────────────────────────────┐
                │       NetworkTrafficController        │
                │   Monitors NetworkMonitorService      │
                │   State: Online | Paused | Draining   │
                └───────────────────┬───────────────────┘
                                    │
       ┌────────────────────────────┴────────────────────────────┐
       ▼                                                         ▼
[Device is Online]                                    [Device is Offline]
       │                                                         │
Direct Dispatch with Concurrency Pool                 Buffer into PriorityQueue:
(Playback runs unthrottled,                           ├─ P0 (Playback): 10s TTL
 Background capped at 4 concurrent)                   ├─ P1 (Interactive): 15s TTL, supersedable
                                                      └─ P2 (Background): 60s TTL, max 64 queue
                                                                 │
                                                       Network Restores:
                                                                 │
                                                                 ▼
                                                      Orderly Draining Pipeline:
                                                      (P0 > P1 > P2, max 4 parallel slots)
```

---

## 3. Detailed Component Design

### 3.1 `QueuedRequest<T>`
Encapsulates each in-flight or buffered request:
- `id`: Unique identifier (UUID).
- `tag`: Optional superseding key (e.g., `'search_query'`, `'home_feed_root'`). If a new request arrives with the same `tag`, any existing pending request with that tag is superseded and cancelled.
- `priority`: `NetworkPriority.playback` (0), `interactive` (1), `background` (2).
- `ttl`: Time-To-Live duration:
  - `playback`: 10s default.
  - `interactive`: 15s default.
  - `background`: 60s default.
- `createdAt`: Timestamp to measure expiration.
- `completer`: `Completer<NetworkResult<T>>` to resolve to the original caller.
- `cancelToken`: Dio `CancelToken` — if caller cancels, the request is evicted from the queue immediately.

### 3.2 Offline Eviction & Discarding Rules
1. **TTL Expiration**: While paused offline, each queued request runs a timer equal to its TTL. If the timer expires before connectivity is restored, the request completes with `NetworkFailure(reason: NetworkFailureReason.offline, message: 'Request expired in offline queue')`.
2. **Tag Superseding**: When `enqueue()` is called with `tag != null`, any pending request in the queue with the exact same tag is cancelled (`NetworkFailureReason.canceled`) and evicted.
3. **Queue Capacity**: Background queue is capped at `maxQueueCapacity = 64`. If exceeded, the oldest background items are dropped.

### 3.3 Controlled Draining on Reconnection
1. Upon `NetworkStatus.restored` or `NetworkStatus.online`, the controller transitions to `draining`.
2. Sorts queued requests:
   - Priority 0 (`playback`) -> Priority 1 (`interactive`) -> Priority 2 (`background`).
   - Ties broken by FIFO (`createdAt`).
3. Drains through a concurrency-limited pool of **max 4 concurrent requests** (except playback which can execute unthrottled).

---

## 4. Implementation Steps

1. **[NEW]** `../../lib/core/network/queue/queued_request.dart`:
   - Data class for queue items with TTL, tags, cancel token listeners, and priority ordering.
2. **[NEW]** `../../lib/core/network/queue/network_traffic_controller.dart`:
   - Core traffic manager with pause/resume, priority queue, tag superseding, TTL eviction, and draining loop.
3. **[NEW]** `../../lib/core/network/client/queued_network_client.dart`:
   - Implements `NetworkClient`, delegates to `DioNetworkClient` while routing calls through `NetworkTrafficController`.
4. **[MODIFIED]** `../../lib/app/di/injection.dart`:
   - Register `QueuedNetworkClient` as the singleton implementation of `NetworkClient`, passing `DioNetworkClient` as delegate.
5. **[NEW]** `../../test/core/network/queue/network_traffic_controller_test.dart`:
   - Unit tests covering:
     * Direct dispatch when online.
     * Buffering when offline.
     * Orderly draining in priority order (`playback` before `background`).
     * Tag-based superseding (new search cancels older search).
     * TTL expiration while offline.
     * Caller cancellation via `CancelToken`.

---

## 5. Verification Plan

- Run `flutter test test/core/network/queue/network_traffic_controller_test.dart`
- Run all existing network and Kodiak test suites (`token_refresh_mutex_test.dart`, `kodiak_data_layer_test.dart`, etc.)
- Run `flutter analyze` across the entire codebase to guarantee 0 errors and 0 warnings.
