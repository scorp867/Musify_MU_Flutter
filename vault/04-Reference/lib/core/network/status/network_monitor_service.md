---
title: "network_monitor_service.dart"
path: "lib/core/network/status/network_monitor_service.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, network]
lines: 125
incoming_dependencies: 20
outgoing_dependencies: 1
---

# network_monitor_service.dart

> Source File: `[lib/core/network/status/network_monitor_service.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/status/network_monitor_service.dart)`
> Layer: `lib/core/network/status`

## Executive Summary
`network_monitor_service.dart` is an essential file in `lib/core/network/status` providing definitions for `NetworkMonitorService`, `NetworkMonitorServiceImpl`.
**Primary Architecture Role**: Service / Controller

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `network_status.dart` | `lib/core/network/status` | [[04-Reference/lib/core/network/status/network_status|network_status.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `library_bloc.dart` | `lib/features/library/application` | [[04-Reference/lib/features/library/application/library_bloc|library_bloc.dart]] |
| `home_feed_bloc.dart` | `lib/features/home_feed/application` | [[04-Reference/lib/features/home_feed/application/home_feed_bloc|home_feed_bloc.dart]] |
| `browse_bloc.dart` | `lib/features/browse/application` | [[04-Reference/lib/features/browse/application/browse_bloc|browse_bloc.dart]] |
| `auth_bloc.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_bloc|auth_bloc.dart]] |
| `dio_network_client.dart` | `lib/core/network/client` | [[04-Reference/lib/core/network/client/dio_network_client|dio_network_client.dart]] |
| `queued_network_client.dart` | `lib/core/network/client` | [[04-Reference/lib/core/network/client/queued_network_client|queued_network_client.dart]] |
| `network_telemetry_interceptor.dart` | `lib/core/network/interceptors` | [[04-Reference/lib/core/network/interceptors/network_telemetry_interceptor|network_telemetry_interceptor.dart]] |
| `network_traffic_controller.dart` | `lib/core/network/queue` | [[04-Reference/lib/core/network/queue/network_traffic_controller|network_traffic_controller.dart]] |
| `network_status_bloc.dart` | `lib/core/network/status/bloc` | [[04-Reference/lib/core/network/status/bloc/network_status_bloc|network_status_bloc.dart]] |
| `data_pool_impl.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool_impl|data_pool_impl.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `auth_bloc_test.dart` | `test/features/auth` | [[04-Reference/test/features/auth/auth_bloc_test|auth_bloc_test.dart]] |
| `browse_bloc_test.dart` | `test/features/browse` | [[04-Reference/test/features/browse/browse_bloc_test|browse_bloc_test.dart]] |
| `home_feed_bloc_test.dart` | `test/features/home_feed` | [[04-Reference/test/features/home_feed/home_feed_bloc_test|home_feed_bloc_test.dart]] |
| `library_bloc_test.dart` | `test/features/library` | [[04-Reference/test/features/library/library_bloc_test|library_bloc_test.dart]] |
| `network_status_bottom_bar_test.dart` | `test/features/shell` | [[04-Reference/test/features/shell/network_status_bottom_bar_test|network_status_bottom_bar_test.dart]] |
| `network_reconnect_retry_test.dart` | `test/core/kodiak` | [[04-Reference/test/core/kodiak/network_reconnect_retry_test|network_reconnect_retry_test.dart]] |
| `network_traffic_controller_test.dart` | `test/core/network/queue` | [[04-Reference/test/core/network/queue/network_traffic_controller_test|network_traffic_controller_test.dart]] |
| `network_monitor_service_test.dart` | `test/core/network/status` | [[04-Reference/test/core/network/status/network_monitor_service_test|network_monitor_service_test.dart]] |
| `network_status_bloc_test.dart` | `test/core/network/status` | [[04-Reference/test/core/network/status/network_status_bloc_test|network_status_bloc_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class NetworkMonitorService`
- **Archetype**: Service / Controller

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `recordConnectionError` | `void` | `(none)` |

#### `class NetworkMonitorServiceImpl`
- **Archetype**: Service / Controller
- **Implements**: `NetworkMonitorService`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_connectivity` | `Connectivity` |
| `_statusController` | `final` |
| `_connectivitySubscription` | `StreamSubscription<List<ConnectivityResult>>?` |
| `_currentStatus` | `NetworkStatus` |
| `_recentLatenciesMs` | `List<int>` |
| `_consecutiveTimeouts` | `int` |
| `isNone` | `final` |
| `ms` | `final` |
| `averageMs` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `Connectivity` | `??` | `(none)` |
| `_init` | `void` | `(none)` |
| `_handleConnectivityChanged` | `void` | `List<ConnectivityResult> results` |
| `every` | `dynamic` | `(r` |
| `recordLatency` | `void` | `Duration latency` |
| `reduce` | `dynamic` | `(a, b` |
| `recordTimeout` | `void` | `(none)` |
| `recordConnectionError` | `void` | `(none)` |
| `recordSuccess` | `void` | `(none)` |
| `_updateStatus` | `void` | `NetworkStatus newStatus` |
| `dispose` | `void` | `(none)` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:musify_mu/core/network/status/network_status.dart';

abstract class NetworkMonitorService {
  NetworkStatus get currentStatus;
  Stream<NetworkStatus> get statusStream;

  void recordLatency(Duration latency);
  void recordTimeout();
  void recordConnectionError() {}
  void recordSuccess();
  void dispose();
}

class NetworkMonitorServiceImpl implements NetworkMonitorService {
  final Connectivity _connectivity;
  final _statusController = StreamController<NetworkStatus>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  NetworkStatus _currentStatus = NetworkStatus.online;

  final List<int> _recentLatenciesMs = [];
  int _consecutiveTimeouts = 0;
  static const int _maxRecentSamples = 5;
  static const int _slowLatencyThresholdMs = 2500;
  static const int _fastLatencyThresholdMs = 1200;

  NetworkMonitorServiceImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  void _init() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChanged,
    );
    // Initial check
    _connectivity.checkConnectivity().then(_handleConnectivityChanged);
  }

  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    final isNone = results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);

// ... [remaining code in source file] ...
```
