---
title: "simple_card_trait.dart"
path: "lib/features/home_feed/domain/models/traits/simple_card_trait.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 39
incoming_dependencies: 0
outgoing_dependencies: 0
---

# simple_card_trait.dart

> Source File: `[lib/features/home_feed/domain/models/traits/simple_card_trait.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/traits/simple_card_trait.dart)`
> Layer: `lib/features/home_feed/domain/models/traits`

## Executive Summary
`simple_card_trait.dart` is an essential file in `lib/features/home_feed/domain/models/traits` providing definitions for `SimpleCardTrait`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class SimpleCardTrait`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Extends**: `Trait`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `title` | `String` |
| `subtitle` | `String` |
| `imageUrl` | `String?` |
| `navigationUri` | `String?` |
| `accessibility` | `String?` |
| `image` | `final` |

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

/// ExtensionKind 97 (SIMPLE_TRAIT).
/// Equivalent to Spotify Android's `c6y0` / `e6y0`.
class SimpleCardTrait extends Trait {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? navigationUri;
  final String? accessibility;

  const SimpleCardTrait({
    required this.title,
    this.subtitle = '',
    this.imageUrl,
    this.navigationUri,
    this.accessibility,
  });

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'navigationUri': navigationUri,
    'accessibility': accessibility,
  };

  factory SimpleCardTrait.fromJson(Map<String, dynamic> json) {
    final image = json['imageUrl'] as String?;
    return SimpleCardTrait(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: image?.isEmpty == true ? null : image,
      navigationUri: json['navigationUri'],
      accessibility: json['accessibility'],
    );
  }
}
```
