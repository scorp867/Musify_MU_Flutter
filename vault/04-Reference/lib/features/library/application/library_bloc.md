---
title: "library_bloc.dart"
path: "lib/features/library/application/library_bloc.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, library]
lines: 238
incoming_dependencies: 7
outgoing_dependencies: 3
---

# library_bloc.dart

> Source File: `[lib/features/library/application/library_bloc.dart](file:///c:/Users/Admin/Musify_MU/lib/features/library/application/library_bloc.dart)`
> Layer: `lib/features/library/application`

## Executive Summary
`library_bloc.dart` is an essential file in `lib/features/library/application` providing definitions for `LibraryEvent`, `LibraryLoadRequested`, `LibraryRefreshRequested`, `LibraryCancelRequested`, `LibraryActivated`, `LibraryState`, `LibraryLoading`, `LibraryLoaded`, `LibraryError`, `LibraryBloc`.
**Primary Architecture Role**: Core Component, Domain Model / Entity, BLoC State Machine

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `network_monitor_service.dart` | `lib/core/network/status` | [[04-Reference/lib/core/network/status/network_monitor_service|network_monitor_service.dart]] |
| `network_status.dart` | `lib/core/network/status` | [[04-Reference/lib/core/network/status/network_status|network_status.dart]] |
| `load_library.dart` | `lib/features/library/domain/usecases` | [[04-Reference/lib/features/library/domain/usecases/load_library|load_library.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `app.dart` | `lib/app` | [[04-Reference/lib/app/app|app.dart]] |
| `hidden_drawer_scaffold.dart` | `lib/features/shell/presentation` | [[04-Reference/lib/features/shell/presentation/hidden_drawer_scaffold|hidden_drawer_scaffold.dart]] |
| `main_screen.dart` | `lib/features/shell/presentation` | [[04-Reference/lib/features/shell/presentation/main_screen|main_screen.dart]] |
| `playlist_detail_screen.dart` | `lib/features/playlist_detail/presentation` | [[04-Reference/lib/features/playlist_detail/presentation/playlist_detail_screen|playlist_detail_screen.dart]] |
| `library_view.dart` | `lib/features/library/presentation` | [[04-Reference/lib/features/library/presentation/library_view|library_view.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `library_bloc_test.dart` | `test/features/library` | [[04-Reference/test/features/library/library_bloc_test|library_bloc_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class LibraryEvent`
- **Archetype**: Core Component

#### `class LibraryLoadRequested`
- **Archetype**: Core Component
- **Extends**: `LibraryEvent`

#### `class LibraryRefreshRequested`
- **Archetype**: Core Component
- **Extends**: `LibraryEvent`

#### `class LibraryCancelRequested`
- **Archetype**: Core Component
- **Extends**: `LibraryEvent`

#### `class LibraryActivated`
- **Archetype**: Core Component
- **Extends**: `LibraryEvent`

#### `class LibraryState`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

#### `class LibraryLoading`
- **Archetype**: Core Component
- **Extends**: `LibraryState`

#### `class LibraryLoaded`
- **Archetype**: Core Component
- **Extends**: `LibraryState`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `data` | `LibraryViewData` |
| `isRefreshing` | `bool` |

#### `class LibraryError`
- **Archetype**: Core Component
- **Extends**: `LibraryState`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `message` | `String` |
| `staleData` | `LibraryViewData?` |

#### `class LibraryBloc`
- **Archetype**: BLoC State Machine
- **Extends**: `Bloc<LibraryEvent, LibraryState>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_loadLibrary` | `LoadLibrary` |
| `_networkMonitor` | `NetworkMonitorService?` |
| `_networkSubscription` | `StreamSubscription<NetworkStatus>?` |
| `_cancelToken` | `CancelToken?` |
| `_isActive` | `bool` |
| `_needsRevalidation` | `bool` |
| `current` | `final` |
| `cancelToken` | `final` |
| `loadedData` | `LibraryViewData?` |
| `hasData` | `bool` |
| `receivedFresh` | `bool` |
| `cancelToken` | `final` |
| `currentData` | `final` |
| `data` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `listen` | `dynamic` | `(status` |
| `close` | `Future<void>` | `(none)` |
| `_onActivated` | `void` | `LibraryActivated event, Emitter<LibraryState> e...` |
| `_onCancel` | `void` | `LibraryCancelRequested event, Emitter<LibrarySt...` |
| `_onLoad` | `Future<void>` | `LibraryLoadRequested event, Emitter<LibraryStat...` |
| `_onRefresh` | `Future<void>` | `LibraryRefreshRequested event, Emitter<LibraryS...` |

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
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';
import 'package:musify_mu/features/library/domain/usecases/load_library.dart';

// ─── Events ──────────────────────────────────────────────────────────

sealed class LibraryEvent {
  const LibraryEvent();
}

final class LibraryLoadRequested extends LibraryEvent {
  const LibraryLoadRequested();
}

final class LibraryRefreshRequested extends LibraryEvent {
  const LibraryRefreshRequested();
}

/// Screen left or inactive  -  cancel in-flight network requests.
final class LibraryCancelRequested extends LibraryEvent {
  const LibraryCancelRequested();
}

/// Screen became active / resumed  -  revalidate if data is stale.
final class LibraryActivated extends LibraryEvent {
  const LibraryActivated();
}

// ─── States ──────────────────────────────────────────────────────────

sealed class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object?> get props => [];
}

final class LibraryLoading extends LibraryState {
  const LibraryLoading();
}
// ... [remaining code in source file] ...
```
