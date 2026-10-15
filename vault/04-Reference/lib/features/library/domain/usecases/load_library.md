---
title: "load_library.dart"
path: "lib/features/library/domain/usecases/load_library.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, library]
lines: 21
incoming_dependencies: 3
outgoing_dependencies: 2
---

# load_library.dart

> Source File: `[lib/features/library/domain/usecases/load_library.dart](file:///c:/Users/Admin/Musify_MU/lib/features/library/domain/usecases/load_library.dart)`
> Layer: `lib/features/library/domain/usecases`

## Executive Summary
`load_library.dart` is an essential file in `lib/features/library/domain/usecases` providing definitions for `LoadLibrary`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `library_view_data.dart` | `lib/features/library/domain/models` | [[04-Reference/lib/features/library/domain/models/library_view_data|library_view_data.dart]] |
| `library_repository.dart` | `lib/features/library/domain/repositories` | [[04-Reference/lib/features/library/domain/repositories/library_repository|library_repository.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `library_bloc.dart` | `lib/features/library/application` | [[04-Reference/lib/features/library/application/library_bloc|library_bloc.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `library_bloc_test.dart` | `test/features/library` | [[04-Reference/test/features/library/library_bloc_test|library_bloc_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class LoadLibrary`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_repository` | `LibraryRepository` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `call` | `Stream<LibraryViewData>` | `{CancelToken? cancelToken}` |
| `refresh` | `Future<LibraryViewData?>` | `{CancelToken? cancelToken}` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:dio/dio.dart';
import 'package:musify_mu/features/library/domain/models/library_view_data.dart';
import 'package:musify_mu/features/library/domain/repositories/library_repository.dart';

export 'package:musify_mu/features/library/domain/models/library_view_data.dart';

/// Loads user library data via SWR (cache-then-network) or network-only refresh.
class LoadLibrary {
  final LibraryRepository _repository;

  const LoadLibrary(this._repository);

  /// SWR stream: yields cached data first, then fresh.
  Stream<LibraryViewData> call({CancelToken? cancelToken}) =>
      _repository.getLibrary(cancelToken: cancelToken);

  /// Network-only refresh, skipping cache.
  /// Forces re-sync of playlist details so mosaics and counts update.
  Future<LibraryViewData?> refresh({CancelToken? cancelToken}) =>
      _repository.fetchFresh(forceSync: true, cancelToken: cancelToken);
}
```
