---
title: "queued_network_client.dart"
path: "lib/core/network/client/queued_network_client.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, network]
lines: 121
incoming_dependencies: 2
outgoing_dependencies: 5
---

# queued_network_client.dart

> Source File: `[lib/core/network/client/queued_network_client.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/client/queued_network_client.dart)`
> Layer: `lib/core/network/client`

## Executive Summary
`queued_network_client.dart` is an essential file in `lib/core/network/client` providing definitions for `QueuedNetworkClient`.
**Primary Architecture Role**: Data Source / Remote Client

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `network_client.dart` | `lib/core/network/client` | [[04-Reference/lib/core/network/client/network_client|network_client.dart]] |
| `network_priority.dart` | `lib/core/network/priority` | [[04-Reference/lib/core/network/priority/network_priority|network_priority.dart]] |
| `network_traffic_controller.dart` | `lib/core/network/queue` | [[04-Reference/lib/core/network/queue/network_traffic_controller|network_traffic_controller.dart]] |
| `network_result.dart` | `lib/core/network/result` | [[04-Reference/lib/core/network/result/network_result|network_result.dart]] |
| `network_monitor_service.dart` | `lib/core/network/status` | [[04-Reference/lib/core/network/status/network_monitor_service|network_monitor_service.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `network_traffic_controller_test.dart` | `test/core/network/queue` | [[04-Reference/test/core/network/queue/network_traffic_controller_test|network_traffic_controller_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class QueuedNetworkClient`
- **Archetype**: Data Source / Remote Client
- **Implements**: `NetworkClient`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_delegate` | `NetworkClient` |
| `_controller` | `NetworkTrafficController` |
| `priority` | `NetworkPriority` |
| `bufferIfOffline` | `bool` |
| `priority` | `NetworkPriority` |
| `contentType` | `String` |
| `bufferIfOffline` | `bool` |
| `bufferIfOffline` | `bool` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `get` | `Future<NetworkResult<Uint8List>>` | `Uri uri, { Map<String, String>? headers, Cancel...` |
| `post` | `Future<NetworkResult<Uint8List>>` | `Uri uri, Uint8List body, { Map<String, String>?...` |
| `head` | `List<String>>>>` | `Uri uri, { Map<String, String>? headers, Durati...` |
| `close` | `void` | `{bool force = false}` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:musify_mu/core/network/client/network_client.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/queue/network_traffic_controller.dart';
import 'package:musify_mu/core/network/result/network_result.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';

/// Decorator over [NetworkClient] that routes all outgoing HTTP requests
/// through a centralized [NetworkTrafficController].
///
/// Ensures all requests:
/// - Pause gracefully when offline rather than failing immediately.
/// - Prioritize playback (P0) over interactive (P1) and background (P2).
/// - Evict stale queries via TTL or superseding tags.
/// - Drain with controlled concurrency on network reconnection.
class QueuedNetworkClient implements NetworkClient {
  final NetworkClient _delegate;
  final NetworkTrafficController _controller;

  QueuedNetworkClient({
    required NetworkClient delegate,
    required NetworkMonitorService monitorService,
    NetworkTrafficController? controller,
  })  : _delegate = delegate,
        _controller = controller ??
            NetworkTrafficController(monitorService: monitorService);

  NetworkTrafficController get controller => _controller;
  NetworkClient get delegate => _delegate;

  @override
  Future<NetworkResult<Uint8List>> get(
    Uri uri, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
    NetworkPriority priority = NetworkPriority.interactive,
    Duration? timeout,
    String? tag,
    Duration? ttl,
    bool bufferIfOffline = false,
  }) {
    return _controller.dispatch<Uint8List>(
      priority: priority,
// ... [remaining code in source file] ...
```
