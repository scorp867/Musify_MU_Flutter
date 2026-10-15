---
title: "show_access_trait.dart"
path: "lib/features/home_feed/domain/models/traits/show_access_trait.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 27
incoming_dependencies: 0
outgoing_dependencies: 0
---

# show_access_trait.dart

> Source File: `[lib/features/home_feed/domain/models/traits/show_access_trait.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/traits/show_access_trait.dart)`
> Layer: `lib/features/home_feed/domain/models/traits`

## Executive Summary
`show_access_trait.dart` is an essential file in `lib/features/home_feed/domain/models/traits` providing definitions for `ShowAccessTrait`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class ShowAccessTrait`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Extends**: `Trait`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `hasAccess` | `bool` |
| `isLocked` | `bool` |
| `accessType` | `String` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `toJson` | `dynamic>` | `(none)` |
| `fromJson` | `dynamic` | `Map<String, dynamic> json` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'trait.dart';

/// Show / Podcast access entitlement metadata (ExtensionKind 31).
class ShowAccessTrait extends Trait {
  final bool hasAccess;
  final bool isLocked;
  final String accessType;

  const ShowAccessTrait({
    this.hasAccess = true,
    this.isLocked = false,
    this.accessType = '',
  });

  @override
  Map<String, dynamic> toJson() => {
    'hasAccess': hasAccess,
    'isLocked': isLocked,
    'accessType': accessType,
  };

  factory ShowAccessTrait.fromJson(Map<String, dynamic> json) => ShowAccessTrait(
    hasAccess: json['hasAccess'] ?? true,
    isLocked: json['isLocked'] ?? false,
    accessType: json['accessType'] ?? '',
  );
}
```
