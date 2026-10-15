---
title: "network_telemetry_interceptor.dart"
path: "lib/core/network/interceptors/network_telemetry_interceptor.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, network]
lines: 44
incoming_dependencies: 1
outgoing_dependencies: 1
---

# network_telemetry_interceptor.dart

> Source File: `[lib/core/network/interceptors/network_telemetry_interceptor.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/interceptors/network_telemetry_interceptor.dart)`
> Layer: `lib/core/network/interceptors`

## Executive Summary
`network_telemetry_interceptor.dart` is an essential file in `lib/core/network/interceptors` providing definitions for `NetworkTelemetryInterceptor`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `network_monitor_service.dart` | `lib/core/network/status` | [[04-Reference/lib/core/network/status/network_monitor_service|network_monitor_service.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `dio_network_client.dart` | `lib/core/network/client` | [[04-Reference/lib/core/network/client/dio_network_client|dio_network_client.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class NetworkTelemetryInterceptor`
- **Archetype**: Core Component
- **Extends**: `Interceptor`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_monitorService` | `NetworkMonitorService` |
| `startEpoch` | `final` |
| `duration` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `onRequest` | `void` | `RequestOptions options, RequestInterceptorHandl...` |
| `onResponse` | `void` | `Response response, ResponseInterceptorHandler h...` |
| `onError` | `void` | `DioException err, ErrorInterceptorHandler handler` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';

/// Interceptor that measures HTTP request round-trip latency and timeouts
/// to update the NetworkMonitorService in real time.
class NetworkTelemetryInterceptor extends Interceptor {
  final NetworkMonitorService _monitorService;

  NetworkTelemetryInterceptor(this._monitorService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['_request_start_epoch'] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startEpoch = response.requestOptions.extra['_request_start_epoch'] as int?;
    if (startEpoch != null) {
      final duration = Duration(
        milliseconds: DateTime.now().millisecondsSinceEpoch - startEpoch,
      );
      _monitorService.recordLatency(duration);
    }
    _monitorService.recordSuccess();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      _monitorService.recordTimeout();
    } else if (err.type == DioExceptionType.connectionError ||
        err.error is SocketException) {
      _monitorService.recordConnectionError();
    }
    handler.next(err);
  }
}
```
