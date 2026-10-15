---
title: "token_refresh_mutex.dart"
path: "lib/core/network/auth/token_refresh_mutex.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, network, auth, mutex, concurrency]
lines: 42
incoming_dependencies: 2
outgoing_dependencies: 0
---

# token_refresh_mutex.dart

> Source File: `[lib/core/network/auth/token_refresh_mutex.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/auth/token_refresh_mutex.dart)`
> Layer: `lib/core/network/auth` (Concurrency Synchronization)

## Executive Summary
`token_refresh_mutex.dart` implements `TokenRefreshMutex`, an asynchronous lock that guarantees only one token refresh operation executes at any given time. When high-concurrency requests receive HTTP 401 responses simultaneously, the mutex halts parallel refresh storms and ensures all concurrent callers await a single in-flight refresh operation before replaying.

**Primary Architecture Role**: Asynchronous 401 Refresh Deserializer & Storm Prevention

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- Standard Dart SDK (`dart:async`, `dart:developer`).
- Zero internal dependencies.

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `token_refresh_mutex_test.dart` | `test/core/network` | [[04-Reference/test/core/network/token_refresh_mutex_test|token_refresh_mutex_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class TokenRefreshMutex`

**Internal State:**
- `Completer<String?>? _inFlight`: The active synchronization barrier. If non-null, a refresh is in progress.

**Public API:**
| Method / Getter | Return Type | Parameters | Description |
|-----------------|-------------|------------|-------------|
| `lock` | `Future<String?>` | `Future<String?> Function() refreshAction` | Executes `refreshAction` if no refresh is active; otherwise joins `_inFlight.future` |
| `isRefreshing` | `bool` | None | True if an asynchronous token refresh is currently executing |

## State & Data Flow Analysis
- **Execution Mechanism**:
  ```dart
  if (_inFlight != null) {
    return _inFlight!.future;
  }
  final completer = Completer<String?>();
  _inFlight = completer;
  try {
    final newToken = await refreshAction();
    completer.complete(newToken);
    return newToken;
  } catch (e, st) {
    completer.completeError(e, st);
    rethrow;
  } finally {
    _inFlight = null;
  }
  ```
- **Error Propagation**: If `refreshAction()` throws (e.g. network timeout or invalid session), the error is completed on `_inFlight` so all blocked callers receive the failure simultaneously.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Deadlock Risk on Unhandled Exceptions
> The `try...finally` block guarantees `_inFlight = null` even on exceptions. Without the `finally` clause, an uncaught exception would leave `_inFlight` permanently non-null, permanently locking all future network traffic.

## Implementation Highlight
```dart
class TokenRefreshMutex {
  Completer<String?>? _inFlight;

  Future<String?> lock(Future<String?> Function() refreshAction) async {
    if (_inFlight != null) {
      dev.log(
        'TokenRefreshMutex: Awaiting existing in-flight refresh...',
        name: 'Auth',
      );
      return _inFlight!.future;
    }

    final completer = Completer<String?>();
    _inFlight = completer;

    try {
      dev.log('TokenRefreshMutex: Executing primary refresh...', name: 'Auth');
      final newToken = await refreshAction();
      completer.complete(newToken);
      return newToken;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _inFlight = null;
    }
  }

  bool get isRefreshing => _inFlight != null;
}
```
