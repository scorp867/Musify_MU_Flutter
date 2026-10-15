---
title: "shortcuts_card_trait.dart"
path: "lib/features/home_feed/domain/models/traits/shortcuts_card_trait.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 17
incoming_dependencies: 0
outgoing_dependencies: 0
---

# shortcuts_card_trait.dart

> Source File: `[lib/features/home_feed/domain/models/traits/shortcuts_card_trait.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/traits/shortcuts_card_trait.dart)`
> Layer: `lib/features/home_feed/domain/models/traits`

## Executive Summary
`shortcuts_card_trait.dart` is an essential file in `lib/features/home_feed/domain/models/traits` providing definitions for `ShortcutsCardTrait`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class ShortcutsCardTrait`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Extends**: `Trait`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `title` | `String` |
| `imageUrl` | `String?` |

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

/// ExtensionKind 119 (SHORTCUTS_CARD_TRAIT).
class ShortcutsCardTrait extends Trait {
  final String title;
  final String? imageUrl;

  const ShortcutsCardTrait({required this.title, this.imageUrl});

  @override
  Map<String, dynamic> toJson() => {'title': title, 'imageUrl': imageUrl};

  factory ShortcutsCardTrait.fromJson(Map<String, dynamic> json) => ShortcutsCardTrait(
    title: json['title'] ?? '',
    imageUrl: json['imageUrl'],
  );
}
```
