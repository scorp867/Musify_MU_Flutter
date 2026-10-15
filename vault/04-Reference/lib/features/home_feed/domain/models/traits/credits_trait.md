---
title: "credits_trait.dart"
path: "lib/features/home_feed/domain/models/traits/credits_trait.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 65
incoming_dependencies: 2
outgoing_dependencies: 0
---

# credits_trait.dart

> Source File: `[lib/features/home_feed/domain/models/traits/credits_trait.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/traits/credits_trait.dart)`
> Layer: `lib/features/home_feed/domain/models/traits`

## Executive Summary
`credits_trait.dart` is an essential file in `lib/features/home_feed/domain/models/traits` providing definitions for `CreditContributor`, `CreditsTrait`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element, Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `credits_card.dart` | `lib/features/player/presentation/widgets/sections` | [[04-Reference/lib/features/player/presentation/widgets/sections/credits_card|credits_card.dart]] |
| `scroll_card_descriptor.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/scroll_card_descriptor|scroll_card_descriptor.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class CreditContributor`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `name` | `String` |
| `role` | `String` |
| `uri` | `String` |
| `url` | `String` |
| `roleGroupName` | `String` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `toJson` | `dynamic>` | `(none)` |
| `fromJson` | `dynamic` | `Map<String, dynamic> json` |

#### `class CreditsTrait`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Extends**: `Trait`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `contributors` | `List<CreditContributor>` |
| `sourceNames` | `List<String>` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `toJson` | `dynamic>` | `(none)` |
| `map` | `dynamic` | `(c` |
| `fromJson` | `dynamic` | `Map<String, dynamic> json` |
| `map` | `dynamic` | `(e` |
| `map` | `dynamic` | `(e` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'trait.dart';

/// A single contributor on a track (artist, writer, producer, etc.).
class CreditContributor {
  final String name;
  final String role;
  final String uri;
  final String url;
  final String roleGroupName;

  const CreditContributor({
    required this.name,
    this.role = '',
    this.uri = '',
    this.url = '',
    this.roleGroupName = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'role': role,
    if (uri.isNotEmpty) 'uri': uri,
    if (url.isNotEmpty) 'url': url,
    if (roleGroupName.isNotEmpty) 'roleGroupName': roleGroupName,
  };

  factory CreditContributor.fromJson(Map<String, dynamic> json) =>
      CreditContributor(
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? '',
        uri: json['uri'] as String? ?? '',
        url: json['url'] as String? ?? '',
        roleGroupName: json['roleGroupName'] as String? ?? '',
      );
}

/// ExtensionKind 186 (CREDITS_V2_TRAIT).
/// Equivalent to Spotify Android's `bmk`.
class CreditsTrait extends Trait {
  final List<CreditContributor> contributors;
  final List<String> sourceNames;

  const CreditsTrait({
    this.contributors = const [],
    this.sourceNames = const [],
// ... [remaining code in source file] ...
```
