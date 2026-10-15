---
title: "network_status_bloc.dart"
path: "lib/core/network/status/bloc/network_status_bloc.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, network]
lines: 129
incoming_dependencies: 8
outgoing_dependencies: 2
---

# network_status_bloc.dart

> Source File: `[lib/core/network/status/bloc/network_status_bloc.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/status/bloc/network_status_bloc.dart)`
> Layer: `lib/core/network/status/bloc`

## Executive Summary
`network_status_bloc.dart` is an essential file in `lib/core/network/status/bloc` providing definitions for `NetworkStatusEvent`, `NetworkStatusChanged`, `DismissRestoredStatus`, `NetworkStatusState`, `NetworkStatusBloc`.
**Primary Architecture Role**: Core Component, Domain Model / Entity, BLoC State Machine

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `network_monitor_service.dart` | `lib/core/network/status` | [[04-Reference/lib/core/network/status/network_monitor_service|network_monitor_service.dart]] |
| `network_status.dart` | `lib/core/network/status` | [[04-Reference/lib/core/network/status/network_status|network_status.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `app.dart` | `lib/app` | [[04-Reference/lib/app/app|app.dart]] |
| `main_screen.dart` | `lib/features/shell/presentation` | [[04-Reference/lib/features/shell/presentation/main_screen|main_screen.dart]] |
| `network_status_bottom_bar.dart` | `lib/features/shell/presentation/widgets` | [[04-Reference/lib/features/shell/presentation/widgets/network_status_bottom_bar|network_status_bottom_bar.dart]] |
| `app_network_image.dart` | `lib/core/widgets` | [[04-Reference/lib/core/widgets/app_network_image|app_network_image.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `network_status_bottom_bar_test.dart` | `test/features/shell` | [[04-Reference/test/features/shell/network_status_bottom_bar_test|network_status_bottom_bar_test.dart]] |
| `network_reconnect_retry_test.dart` | `test/core/kodiak` | [[04-Reference/test/core/kodiak/network_reconnect_retry_test|network_reconnect_retry_test.dart]] |
| `network_status_bloc_test.dart` | `test/core/network/status` | [[04-Reference/test/core/network/status/network_status_bloc_test|network_status_bloc_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class NetworkStatusEvent`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

#### `class NetworkStatusChanged`
- **Archetype**: Core Component
- **Extends**: `NetworkStatusEvent`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `status` | `NetworkStatus` |

#### `class DismissRestoredStatus`
- **Archetype**: Core Component
- **Extends**: `NetworkStatusEvent`

#### `class NetworkStatusState`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `status` | `NetworkStatus` |
| `message` | `String?` |

#### `class NetworkStatusBloc`
- **Archetype**: BLoC State Machine
- **Extends**: `Bloc<NetworkStatusEvent, NetworkStatusState>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_monitorService` | `NetworkMonitorService` |
| `_statusSubscription` | `StreamSubscription<NetworkStatus>?` |
| `_restoredDismissTimer` | `Timer?` |
| `initialState` | `NetworkStatusState` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `super` | `dynamic` | `initialState` |
| `listen` | `dynamic` | `(status` |
| `_onStatusChanged` | `void` | `NetworkStatusChanged event, Emitter<NetworkStat...` |
| `_onDismissRestored` | `void` | `DismissRestoredStatus event, Emitter<NetworkSta...` |
| `close` | `Future<void>` | `(none)` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';

// ─── Events ──────────────────────────────────────────────────────────

sealed class NetworkStatusEvent extends Equatable {
  const NetworkStatusEvent();

  @override
  List<Object?> get props => [];
}

final class NetworkStatusChanged extends NetworkStatusEvent {
  final NetworkStatus status;

  const NetworkStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}

final class DismissRestoredStatus extends NetworkStatusEvent {
  const DismissRestoredStatus();
}

// ─── State ───────────────────────────────────────────────────────────

final class NetworkStatusState extends Equatable {
  final NetworkStatus status;
  final String? message;

  const NetworkStatusState({
    required this.status,
    this.message,
  });

  const NetworkStatusState.initial()
      : status = NetworkStatus.online,
        message = null;

  bool get isVisible => status != NetworkStatus.online;

// ... [remaining code in source file] ...
```
