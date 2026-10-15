---
title: "retry_interceptor.dart"
path: "lib/core/network/interceptors/retry_interceptor.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, network]
lines: 97
incoming_dependencies: 1
outgoing_dependencies: 0
---

# retry_interceptor.dart

> Source File: `[lib/core/network/interceptors/retry_interceptor.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/interceptors/retry_interceptor.dart)`
> Layer: `lib/core/network/interceptors`

## Executive Summary
`retry_interceptor.dart` is an essential file in `lib/core/network/interceptors` providing definitions for `RetryInterceptor`.
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
#### `class RetryInterceptor`
- **Archetype**: Core Component
- **Extends**: `Interceptor`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `dio` | `Dio` |
| `maxRetries` | `int` |
| `baseDelay` | `Duration` |
| `requestOptions` | `final` |
| `method` | `final` |
| `currentAttempt` | `final` |
| `shouldRetry` | `final` |
| `nextAttempt` | `final` |
| `delay` | `final` |
| `response` | `final` |
| `true` | `return` |
| `statusCode` | `final` |
| `true` | `return` |
| `true` | `return` |
| `false` | `return` |
| `jitter` | `final` |
| `delayMs` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `onError` | `Future<void>` | `DioException err, ErrorInterceptorHandler handler` |
| `_isTransientError` | `bool` | `DioException err` |
| `_calculateBackoff` | `Duration` | `int attempt` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Transparent exponential backoff retry for idempotent HTTP requests.
///
/// Only retries GET/HEAD requests when encountering transient connection
/// resets, timeouts, or 503/504 gateway errors.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 250),
  });

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final method = requestOptions.method.toUpperCase();

    // Only retry idempotent methods.
    if (method != 'GET' && method != 'HEAD') {
      return handler.next(err);
    }

    // Do not retry if request was explicitly cancelled.
    if (err.type == DioExceptionType.cancel) {
      return handler.next(err);
    }

    final currentAttempt =
        (requestOptions.extra['retry_attempt'] as int?) ?? 0;
    if (currentAttempt >= maxRetries) {
      return handler.next(err);
    }

    final shouldRetry = _isTransientError(err);
// ... [remaining code in source file] ...
```
