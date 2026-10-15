---
title: "network_traffic_controller.dart"
path: "lib/core/network/queue/network_traffic_controller.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, network, queue, offline-gating, traffic-controller]
lines: 241
incoming_dependencies: 1
outgoing_dependencies: 5
---

# network_traffic_controller.dart

> Source File: `[lib/core/network/queue/network_traffic_controller.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/queue/network_traffic_controller.dart)`
> Layer: `lib/core/network/queue` (Traffic Priority & Offline Scheduler)

## Executive Summary
`network_traffic_controller.dart` implements `NetworkTrafficController`, the central scheduler that manages outbound network operations based on device connectivity and priority levels. It provides offline request buffering (Outbox pattern), priority-ordered queue draining (`Playback (P0)` > `Interactive (P1)` > `Background (P2)`), tag-based request superseding, and concurrency throttling to prevent socket starvation.

**Primary Architecture Role**: Priority Traffic Scheduler & Offline Request Buffer

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `network_priority.dart` | `lib/core/network/priority` | [[04-Reference/lib/core/network/priority/network_priority|network_priority.dart]] |
| `queued_request.dart` | `lib/core/network/queue` | [[04-Reference/lib/core/network/queue/queued_request|queued_request.dart]] |
| `network_result.dart` | `lib/core/network/result` | [[04-Reference/lib/core/network/result/network_result|network_result.dart]] |
| `network_monitor_service.dart` | `lib/core/network/status` | [[04-Reference/lib/core/network/status/network_monitor_service|network_monitor_service.dart]] |
| `network_status.dart` | `lib/core/network/status` | [[04-Reference/lib/core/network/status/network_status|network_status.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `network_traffic_controller_test.dart` | `test/core/network/queue` | [[04-Reference/test/core/network/queue/network_traffic_controller_test|network_traffic_controller_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class NetworkTrafficController`

**Configuration & Fields:**
- `final NetworkMonitorService _monitorService`: Listens for connection transitions.
- `final int maxConcurrent`: Maximum concurrent in-flight requests during draining (default: 4).
- `final int maxQueueCapacity`: Maximum capacity of buffered offline queue (default: 64).
- `final List<QueuedRequest<dynamic>> _queue`: Priority-ordered buffered requests.
- `int _activeExecutions`: Number of currently executing network requests.
- `int _counter`: Monotonically incrementing request ID generator.

**Key Methods:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `dispatch<T>` | `Future<NetworkResult<T>>` | `execution, priority, tag, ttl, cancelToken, bufferIfOffline` | Submits an operation to the scheduler |
| `_drainQueue` | `void` | None | Asynchronously executes pending requests in priority order upon connection recovery |
| `_enqueue` | `void` | `QueuedRequest request` | Adds a request to the queue, enforcing tag-based superseding and capacity |
| `cancelTagged` | `void` | `String tag` | Cancels all queued requests matching a given tag |
| `clearQueue` | `void` | None | Cancels all queued requests |
| `dispose` | `void` | None | Cancels monitor subscription and aborts pending queue items |

## State & Data Flow Analysis
- **Offline Gating Policy**:
  - Read operations (`bufferIfOffline: false`): Bypass offline buffering to fail fast on socket disconnection so UI can display offline banners immediately.
  - Write mutations (`bufferIfOffline: true`): Enter `_queue` while offline. When connectivity transitions to `NetworkStatus.restored` or `NetworkStatus.online`, `_drainQueue()` flushes requests in priority order.
- **Tag-Based Superseding**:
  If a user rapidly taps different tracks or types search queries, older pending requests with the same tag are cancelled and replaced, preventing redundant bandwidth usage.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] TTL Expiration in Offline Outbox
> Stale requests waiting in `_queue` expire when their TTL elapses (`Playback: 10s`, `Interactive: 15s`, `Background: 60s`). Expired items fail with `NetworkFailureReason.timeout` without hitting the network adapter once online.

## Implementation Highlight
```dart
Future<NetworkResult<T>> dispatch<T>({
  required Future<NetworkResult<T>> Function() execution,
  NetworkPriority priority = NetworkPriority.interactive,
  String? tag,
  Duration? ttl,
  CancelToken? cancelToken,
  bool bufferIfOffline = false,
}) {
  if (_isDisposed) {
    return Future.value(
      const NetworkResult.failure(
        NetworkException(
          message: 'NetworkTrafficController is disposed',
          reason: NetworkFailureReason.cancelled,
        ),
      ),
    );
  }

  final effectiveTtl = ttl ?? _defaultTtlFor(priority);
  final request = QueuedRequest<T>(
    id: 'req_${++_counter}',
    tag: tag,
    priority: priority,
    ttl: effectiveTtl,
    execution: execution,
    cancelToken: cancelToken,
  );

  if (isOffline) {
    if (bufferIfOffline) {
      _enqueue(request);
      return request.completer.future;
    } else {
      _executeDirectly(request);
      return request.completer.future;
    }
  }

  _executeDirectly(request);
  return request.completer.future;
}
```
