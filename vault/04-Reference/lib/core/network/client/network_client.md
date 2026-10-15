---
title: "network_client.dart"
path: "lib/core/network/client/network_client.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, network]
lines: 48
incoming_dependencies: 5
outgoing_dependencies: 2
---

# network_client.dart

> Source File: `[lib/core/network/client/network_client.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/client/network_client.dart)`
> Layer: `lib/core/network/client`

## Executive Summary
`network_client.dart` is an essential file in `lib/core/network/client` providing definitions for `NetworkClient`.
**Primary Architecture Role**: Data Source / Remote Client

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `network_priority.dart` | `lib/core/network/priority` | [[04-Reference/lib/core/network/priority/network_priority|network_priority.dart]] |
| `network_result.dart` | `lib/core/network/result` | [[04-Reference/lib/core/network/result/network_result|network_result.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `dio_network_client.dart` | `lib/core/network/client` | [[04-Reference/lib/core/network/client/dio_network_client|dio_network_client.dart]] |
| `queued_network_client.dart` | `lib/core/network/client` | [[04-Reference/lib/core/network/client/queued_network_client|queued_network_client.dart]] |
| `base_spotify_transport.dart` | `lib/core/network/spotify/transport` | [[04-Reference/lib/core/network/spotify/transport/base_spotify_transport|base_spotify_transport.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `network_traffic_controller_test.dart` | `test/core/network/queue` | [[04-Reference/test/core/network/queue/network_traffic_controller_test|network_traffic_controller_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class NetworkClient`
- **Archetype**: Data Source / Remote Client

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `priority` | `NetworkPriority` |
| `bufferIfOffline` | `bool` |
| `priority` | `NetworkPriority` |
| `contentType` | `String` |
| `bufferIfOffline` | `bool` |
| `bufferIfOffline` | `bool` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Cronet HTTP/3 engine: verify fallback to platform standard sockets if native Cronet provider fails initialization.

## Implementation Highlight
```dart
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/result/network_result.dart';

/// Central HTTP Client abstraction for Musify_MU.
///
/// Decouples features and transports from specific HTTP drivers (Dio, Cronet, etc.),
/// exposes priority scheduling, request cancellation, and typed [NetworkResult] returns.
abstract interface class NetworkClient {
  /// Dispatches an HTTP GET request.
  Future<NetworkResult<Uint8List>> get(
    Uri uri, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
    NetworkPriority priority = NetworkPriority.interactive,
    Duration? timeout,
    String? tag,
    Duration? ttl,
    bool bufferIfOffline = false,
  });

  /// Dispatches an HTTP POST request.
  Future<NetworkResult<Uint8List>> post(
    Uri uri,
    Uint8List body, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
    NetworkPriority priority = NetworkPriority.interactive,
    String contentType = 'application/x-protobuf',
    Duration? timeout,
    String? tag,
    Duration? ttl,
    bool bufferIfOffline = false,
  });

  /// Dispatches an HTTP HEAD request.
  Future<NetworkResult<Map<String, List<String>>>> head(
    Uri uri, {
    Map<String, String>? headers,
    Duration? timeout,
    bool bufferIfOffline = false,
  });

// ... [remaining code in source file] ...
```
