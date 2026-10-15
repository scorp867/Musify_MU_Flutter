---
title: "network_status.dart"
path: "lib/core/network/status/network_status.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, network]
lines: 13
incoming_dependencies: 19
outgoing_dependencies: 0
---

# network_status.dart

> Source File: `[lib/core/network/status/network_status.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/status/network_status.dart)`
> Layer: `lib/core/network/status`

## Executive Summary
`network_status.dart` is an essential file in `lib/core/network/status` providing definitions for Top-level functions/constants.

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `network_status_bottom_bar.dart` | `lib/features/shell/presentation/widgets` | [[04-Reference/lib/features/shell/presentation/widgets/network_status_bottom_bar|network_status_bottom_bar.dart]] |
| `library_bloc.dart` | `lib/features/library/application` | [[04-Reference/lib/features/library/application/library_bloc|library_bloc.dart]] |
| `home_feed_bloc.dart` | `lib/features/home_feed/application` | [[04-Reference/lib/features/home_feed/application/home_feed_bloc|home_feed_bloc.dart]] |
| `browse_bloc.dart` | `lib/features/browse/application` | [[04-Reference/lib/features/browse/application/browse_bloc|browse_bloc.dart]] |
| `auth_bloc.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_bloc|auth_bloc.dart]] |
| `app_network_image.dart` | `lib/core/widgets` | [[04-Reference/lib/core/widgets/app_network_image|app_network_image.dart]] |
| `network_traffic_controller.dart` | `lib/core/network/queue` | [[04-Reference/lib/core/network/queue/network_traffic_controller|network_traffic_controller.dart]] |
| `network_monitor_service.dart` | `lib/core/network/status` | [[04-Reference/lib/core/network/status/network_monitor_service|network_monitor_service.dart]] |
| `network_status_bloc.dart` | `lib/core/network/status/bloc` | [[04-Reference/lib/core/network/status/bloc/network_status_bloc|network_status_bloc.dart]] |
| `data_pool_impl.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool_impl|data_pool_impl.dart]] |
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

### Enums
#### `enum NetworkStatus`
Values: ``

This file contains top-level functions or standalone variables.

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
enum NetworkStatus {
  /// Normal active internet connectivity.
  online,

  /// High latency (> 2500ms) or consecutive request timeouts detected.
  slow,

  /// No network connection detected on any device interface.
  offline,

  /// Transient state when transitioning from offline/slow back to online.
  restored,
}
```
