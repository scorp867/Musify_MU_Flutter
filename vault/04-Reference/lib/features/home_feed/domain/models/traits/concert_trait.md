---
title: "concert_trait.dart"
path: "lib/features/home_feed/domain/models/traits/concert_trait.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 27
incoming_dependencies: 2
outgoing_dependencies: 0
---

# concert_trait.dart

> Source File: `[lib/features/home_feed/domain/models/traits/concert_trait.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/traits/concert_trait.dart)`
> Layer: `lib/features/home_feed/domain/models/traits`

## Executive Summary
`concert_trait.dart` is an essential file in `lib/features/home_feed/domain/models/traits` providing definitions for `ConcertTrait`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `events_card.dart` | `lib/features/player/presentation/widgets/sections` | [[04-Reference/lib/features/player/presentation/widgets/sections/events_card|events_card.dart]] |
| `scroll_card_descriptor.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/scroll_card_descriptor|scroll_card_descriptor.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class ConcertTrait`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Extends**: `Trait`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `title` | `String` |
| `artistName` | `String` |
| `eventDateTimestamp` | `int` |

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

/// Live Concert / Tour event trait (ExtensionKind 122).
class ConcertTrait extends Trait {
  final String title;
  final String artistName;
  final int eventDateTimestamp;

  const ConcertTrait({
    required this.title,
    this.artistName = '',
    this.eventDateTimestamp = 0,
  });

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'artistName': artistName,
    'eventDateTimestamp': eventDateTimestamp,
  };

  factory ConcertTrait.fromJson(Map<String, dynamic> json) => ConcertTrait(
    title: json['title'] ?? '',
    artistName: json['artistName'] ?? '',
    eventDateTimestamp: json['eventDateTimestamp'] ?? 0,
  );
}
```
