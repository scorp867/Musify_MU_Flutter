---
title: "queued_request.dart"
path: "lib/core/network/queue/queued_request.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, network]
lines: 96
incoming_dependencies: 1
outgoing_dependencies: 2
---

# queued_request.dart

> Source File: `[lib/core/network/queue/queued_request.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/queue/queued_request.dart)`
> Layer: `lib/core/network/queue`

## Executive Summary
`queued_request.dart` is an essential file in `lib/core/network/queue` providing definitions for `QueuedRequest`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `network_priority.dart` | `lib/core/network/priority` | [[04-Reference/lib/core/network/priority/network_priority|network_priority.dart]] |
| `network_result.dart` | `lib/core/network/result` | [[04-Reference/lib/core/network/result/network_result|network_result.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `network_traffic_controller.dart` | `lib/core/network/queue` | [[04-Reference/lib/core/network/queue/network_traffic_controller|network_traffic_controller.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class QueuedRequest`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `id` | `String` |
| `tag` | `String?` |
| `priority` | `NetworkPriority` |
| `ttl` | `Duration` |
| `createdAt` | `DateTime` |
| `cancelToken` | `CancelToken?` |
| `completer` | `Completer<NetworkResult<T>>` |
| `_ttlTimer` | `Timer?` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `Timer` | `dynamic` | `ttl, (` |
| `then` | `dynamic` | `(_` |
| `complete` | `void` | `NetworkResult<T> result` |
| `expire` | `void` | `(none)` |
| `cancel` | `void` | `[String message = 'Request was superseded or ca...` |
| `_clean` | `void` | `(none)` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/result/network_result.dart';

/// Represents an item buffered or managed in the [NetworkTrafficController].
class QueuedRequest<T> {
  final String id;
  final String? tag;
  final NetworkPriority priority;
  final Duration ttl;
  final DateTime createdAt;
  final CancelToken? cancelToken;
  final Future<NetworkResult<T>> Function() execution;
  final Completer<NetworkResult<T>> completer = Completer<NetworkResult<T>>();

  Timer? _ttlTimer;

  QueuedRequest({
    required this.id,
    this.tag,
    required this.priority,
    required this.ttl,
    required this.execution,
    this.cancelToken,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCompleted => completer.isCompleted;

  void startTtlTimer(
    void Function(QueuedRequest<T> request) onExpired, {
    void Function(QueuedRequest<T> request)? onCancelled,
  }) {
    _ttlTimer?.cancel();
    _ttlTimer = Timer(ttl, () {
      if (!isCompleted) {
        onExpired(this);
      }
    });

    if (cancelToken != null) {
      if (cancelToken!.isCancelled) {
        cancel('Request cancelled via CancelToken');
        onCancelled?.call(this);
// ... [remaining code in source file] ...
```
