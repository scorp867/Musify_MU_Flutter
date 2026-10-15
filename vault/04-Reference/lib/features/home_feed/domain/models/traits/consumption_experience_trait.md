---
title: "consumption_experience_trait.dart"
path: "lib/features/home_feed/domain/models/traits/consumption_experience_trait.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 24
incoming_dependencies: 0
outgoing_dependencies: 0
---

# consumption_experience_trait.dart

> Source File: `[lib/features/home_feed/domain/models/traits/consumption_experience_trait.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/traits/consumption_experience_trait.dart)`
> Layer: `lib/features/home_feed/domain/models/traits`

## Executive Summary
`consumption_experience_trait.dart` is an essential file in `lib/features/home_feed/domain/models/traits` providing definitions for `ConsumptionExperienceTrait`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class ConsumptionExperienceTrait`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Extends**: `Trait`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `format` | `String` |
| `isInteractive` | `bool` |

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

/// Consumption experience details (ExtensionKind 182).
class ConsumptionExperienceTrait extends Trait {
  final String format;
  final bool isInteractive;

  const ConsumptionExperienceTrait({
    this.format = '',
    this.isInteractive = false,
  });

  @override
  Map<String, dynamic> toJson() => {
    'format': format,
    'isInteractive': isInteractive,
  };

  factory ConsumptionExperienceTrait.fromJson(Map<String, dynamic> json) =>
      ConsumptionExperienceTrait(
        format: json['format'] ?? '',
        isInteractive: json['isInteractive'] ?? false,
      );
}
```
