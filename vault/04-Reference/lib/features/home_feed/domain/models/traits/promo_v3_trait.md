---
title: "promo_v3_trait.dart"
path: "lib/features/home_feed/domain/models/traits/promo_v3_trait.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 27
incoming_dependencies: 0
outgoing_dependencies: 0
---

# promo_v3_trait.dart

> Source File: `[lib/features/home_feed/domain/models/traits/promo_v3_trait.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/traits/promo_v3_trait.dart)`
> Layer: `lib/features/home_feed/domain/models/traits`

## Executive Summary
`promo_v3_trait.dart` is an essential file in `lib/features/home_feed/domain/models/traits` providing definitions for `PromoV3Trait`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class PromoV3Trait`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Extends**: `Trait`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `title` | `String` |
| `imageUrl` | `String?` |
| `actionUri` | `String` |

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

/// Promotion V3 card trait (ExtensionKind 171).
class PromoV3Trait extends Trait {
  final String title;
  final String? imageUrl;
  final String actionUri;

  const PromoV3Trait({
    required this.title,
    this.imageUrl,
    this.actionUri = '',
  });

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'imageUrl': imageUrl,
    'actionUri': actionUri,
  };

  factory PromoV3Trait.fromJson(Map<String, dynamic> json) => PromoV3Trait(
    title: json['title'] ?? '',
    imageUrl: json['imageUrl'],
    actionUri: json['actionUri'] ?? '',
  );
}
```
