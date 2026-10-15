---
title: "platform_adapter.dart"
path: "lib/core/network/client/platform_adapter.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, network]
lines: 38
incoming_dependencies: 1
outgoing_dependencies: 0
---

# platform_adapter.dart

> Source File: `[lib/core/network/client/platform_adapter.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/client/platform_adapter.dart)`
> Layer: `lib/core/network/client`

## Executive Summary
`platform_adapter.dart` is an essential file in `lib/core/network/client` providing definitions for Top-level functions/constants.

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `dio_network_client.dart` | `lib/core/network/client` | [[04-Reference/lib/core/network/client/dio_network_client|dio_network_client.dart]] |

## Declarations & API Breakdown

This file contains top-level functions or standalone variables.

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
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';

/// Creates the lowest-latency, platform-native HTTP client adapter.
///
/// - Android: Google Cronet (Chromium network stack with HTTP/3, QUIC 0-RTT, and Brotli)
/// - iOS / macOS: Apple NSURLSession (Native connection pooling, background URLSession)
/// - Windows / Linux: Persistent IOHttpClientAdapter with TCP Keep-Alive and connection reuse
HttpClientAdapter createPlatformAdapter() {
  if (kIsWeb) {
    return HttpClientAdapter();
  }

  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    try {
      return NativeAdapter();
    } catch (e) {
      debugPrint('[NET] NativeAdapter unavailable ($e), falling back to IOHttpClientAdapter');
    }
  }

  // Windows Desktop / Linux / Fallback:
  final adapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.idleTimeout = const Duration(seconds: 30);
      client.connectionTimeout = const Duration(seconds: 15);
      client.maxConnectionsPerHost = 12;
      return client;
    },
  );

  return adapter;
}
```
