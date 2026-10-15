---
title: "concurrency_limiter.dart"
path: "lib/core/utils/concurrency_limiter.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, utils]
lines: 48
incoming_dependencies: 2
outgoing_dependencies: 0
---

# concurrency_limiter.dart

> Source File: `[lib/core/utils/concurrency_limiter.dart](file:///c:/Users/Admin/Musify_MU/lib/core/utils/concurrency_limiter.dart)`
> Layer: `lib/core/utils`

## Executive Summary
`concurrency_limiter.dart` is an essential file in `lib/core/utils` providing definitions for `ConcurrencyLimiter`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `library_repository_impl.dart` | `lib/features/library/data/repository` | [[04-Reference/lib/features/library/data/repository/library_repository_impl|library_repository_impl.dart]] |
| `concurrency_limiter_test.dart` | `test/core/utils` | [[04-Reference/test/core/utils/concurrency_limiter_test|concurrency_limiter_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class ConcurrencyLimiter`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `maxConcurrent` | `int` |
| `_activeCount` | `int` |
| `_waitQueue` | `List<Completer<void>>` |
| `completer` | `final` |
| `next` | `final` |
| `maxConcurrent` | `int` |
| `limiter` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `wait` | `dynamic` | `items.map((item` |
| `run` | `dynamic` | `(` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:async';

/// Limits concurrent asynchronous operations to prevent socket starvation,
/// OS connection pool exhaustion, and server rate-limiting (HTTP 429).
class ConcurrencyLimiter {
  final int maxConcurrent;
  int _activeCount = 0;
  final List<Completer<void>> _waitQueue = [];

  ConcurrencyLimiter({required this.maxConcurrent})
      : assert(maxConcurrent > 0, 'maxConcurrent must be positive');

  /// Runs [task] as soon as an execution slot is available.
  Future<T> run<T>(Future<T> Function() task) async {
    while (_activeCount >= maxConcurrent) {
      final completer = Completer<void>();
      _waitQueue.add(completer);
      await completer.future;
    }

    _activeCount++;
    try {
      return await task();
    } finally {
      _activeCount--;
      if (_waitQueue.isNotEmpty) {
        final next = _waitQueue.removeAt(0);
        next.complete();
      }
    }
  }

  /// Convenience utility: runs all [items] through [task] with concurrency capped at [maxConcurrent].
  /// Preserves input ordering in the returned results list.
  static Future<List<R>> runPooled<T, R>(
    List<T> items,
    Future<R> Function(T item) task, {
    int maxConcurrent = 4,
  }) async {
    if (items.isEmpty) return [];
    if (items.length <= maxConcurrent) {
      return Future.wait(items.map(task));
    }

    final limiter = ConcurrencyLimiter(maxConcurrent: maxConcurrent);
// ... [remaining code in source file] ...
```
