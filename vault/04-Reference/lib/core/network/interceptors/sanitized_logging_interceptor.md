---
title: "sanitized_logging_interceptor.dart"
path: "lib/core/network/interceptors/sanitized_logging_interceptor.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, network]
lines: 56
incoming_dependencies: 1
outgoing_dependencies: 0
---

# sanitized_logging_interceptor.dart

> Source File: `[lib/core/network/interceptors/sanitized_logging_interceptor.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/interceptors/sanitized_logging_interceptor.dart)`
> Layer: `lib/core/network/interceptors`

## Executive Summary
`sanitized_logging_interceptor.dart` is an essential file in `lib/core/network/interceptors` providing definitions for `SanitizedLoggingInterceptor`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `dio_network_client.dart` | `lib/core/network/client` | [[04-Reference/lib/core/network/client/dio_network_client|dio_network_client.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class SanitizedLoggingInterceptor`
- **Archetype**: Core Component
- **Extends**: `Interceptor`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `sw` | `final` |
| `bodySize` | `final` |
| `sw` | `final` |
| `elapsedMs` | `final` |
| `bytesLength` | `final` |
| `statusCode` | `final` |
| `ok` | `final` |
| `sw` | `final` |
| `elapsedMs` | `final` |
| `status` | `final` |

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
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Structured diagnostic logger for network traffic.
///
/// Filters sensitive headers (Authorization, Cookie, Client-Token) to prevent
/// credential leakage in logs while maintaining visibility in terminal:
/// `flutter run 2>&1 | Select-String "[NET]"`
class SanitizedLoggingInterceptor extends Interceptor {
  final Map<int, Stopwatch> _stopwatches = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final sw = Stopwatch()..start();
    _stopwatches[options.hashCode] = sw;

    final bodySize = options.data is List<int>
        ? ' (${(options.data as List<int>).length} B)'
        : '';
    debugPrint('[NET] --> ${options.method} ${options.uri.path}$bodySize');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final sw = _stopwatches.remove(response.requestOptions.hashCode);
    final elapsedMs = sw?.elapsedMilliseconds ?? 0;

    final bytesLength = response.data is List<int>
        ? (response.data as List<int>).length
        : 0;
    final statusCode = response.statusCode ?? 200;
    final ok = statusCode >= 200 && statusCode < 300 ? 'ok' : 'ERR';

    debugPrint(
      '[NET] <-- ${response.requestOptions.method} ${response.requestOptions.uri.path} '
      '[$ok $statusCode] ${elapsedMs}ms ${bytesLength}B',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sw = _stopwatches.remove(err.requestOptions.hashCode);
    final elapsedMs = sw?.elapsedMilliseconds ?? 0;
// ... [remaining code in source file] ...
```
