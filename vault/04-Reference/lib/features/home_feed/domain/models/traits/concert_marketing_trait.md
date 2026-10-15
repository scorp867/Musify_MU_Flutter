---
title: "concert_marketing_trait.dart"
path: "lib/features/home_feed/domain/models/traits/concert_marketing_trait.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 24
incoming_dependencies: 0
outgoing_dependencies: 0
---

# concert_marketing_trait.dart

> Source File: `[lib/features/home_feed/domain/models/traits/concert_marketing_trait.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/traits/concert_marketing_trait.dart)`
> Layer: `lib/features/home_feed/domain/models/traits`

## Executive Summary
`concert_marketing_trait.dart` is an essential file in `lib/features/home_feed/domain/models/traits` providing definitions for `ConcertMarketingTrait`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class ConcertMarketingTrait`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Extends**: `Trait`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `ticketingPartner` | `String` |
| `ticketingUrl` | `String` |

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

/// Concert marketing details (ExtensionKind 124).
class ConcertMarketingTrait extends Trait {
  final String ticketingPartner;
  final String ticketingUrl;

  const ConcertMarketingTrait({
    this.ticketingPartner = '',
    this.ticketingUrl = '',
  });

  @override
  Map<String, dynamic> toJson() => {
    'ticketingPartner': ticketingPartner,
    'ticketingUrl': ticketingUrl,
  };

  factory ConcertMarketingTrait.fromJson(Map<String, dynamic> json) =>
      ConcertMarketingTrait(
        ticketingPartner: json['ticketingPartner'] ?? '',
        ticketingUrl: json['ticketingUrl'] ?? '',
      );
}
```
