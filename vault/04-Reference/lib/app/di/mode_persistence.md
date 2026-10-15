---
title: "mode_persistence.dart"
path: "lib/app/di/mode_persistence.dart"
type: "source-code"
tags: [code, dart, musify-mu]
lines: 19
incoming_dependencies: 4
outgoing_dependencies: 0
---

# mode_persistence.dart

> Source File: `[lib/app/di/mode_persistence.dart](file:///c:/Users/Admin/Musify_MU/lib/app/di/mode_persistence.dart)`
> Layer: `lib/app/di`

## Executive Summary
`mode_persistence.dart` is an essential file in `lib/app/di` providing definitions for `ModePersistence`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `app.dart` | `lib/app` | [[04-Reference/lib/app/app|app.dart]] |
| `hidden_drawer_scaffold.dart` | `lib/features/shell/presentation` | [[04-Reference/lib/features/shell/presentation/hidden_drawer_scaffold|hidden_drawer_scaffold.dart]] |
| `main_screen.dart` | `lib/features/shell/presentation` | [[04-Reference/lib/features/shell/presentation/main_screen|main_screen.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class ModePersistence`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `prefs` | `final` |
| `prefs` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `loadMode` | `Future<bool?>` | `(none)` |
| `saveMode` | `Future<void>` | `bool isOnline` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Encapsulates reading/writing the online-vs-offline mode preference.
///
/// Registered in [setupInjection] so that presentation code never touches
/// [SharedPreferences] directly.
class ModePersistence {
  static const _kModeKey = 'app_mode_online';

  Future<bool?> loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kModeKey);
  }

  Future<void> saveMode(bool isOnline) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kModeKey, isOnline);
  }
}
```
