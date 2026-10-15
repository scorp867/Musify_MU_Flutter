---
title: "on_platform_reputation_trait.dart"
path: "lib/features/home_feed/domain/models/traits/on_platform_reputation_trait.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 38
incoming_dependencies: 2
outgoing_dependencies: 0
---

# on_platform_reputation_trait.dart

> Source File: `[lib/features/home_feed/domain/models/traits/on_platform_reputation_trait.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/traits/on_platform_reputation_trait.dart)`
> Layer: `lib/features/home_feed/domain/models/traits`

## Executive Summary
`on_platform_reputation_trait.dart` is an essential file in `lib/features/home_feed/domain/models/traits` providing definitions for `OnPlatformReputationTrait`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `about_artist_card.dart` | `lib/features/player/presentation/widgets/sections` | [[04-Reference/lib/features/player/presentation/widgets/sections/about_artist_card|about_artist_card.dart]] |
| `scroll_card_descriptor.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/scroll_card_descriptor|scroll_card_descriptor.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class OnPlatformReputationTrait`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Extends**: `Trait`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `monthlyListeners` | `int` |
| `totalPlays` | `int` |
| `totalEstablishedUserRelationships` | `int` |
| `isVerified` | `bool` |
| `isRegistered` | `bool` |

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

/// ExtensionKind 185 (ON_PLATFORM_REPUTATION_TRAIT).
/// Equivalent to Spotify Android's `aip0`.
class OnPlatformReputationTrait extends Trait {
  final int monthlyListeners;
  final int totalPlays;
  final int totalEstablishedUserRelationships;
  final bool isVerified;
  final bool isRegistered;

  const OnPlatformReputationTrait({
    this.monthlyListeners = 0,
    this.totalPlays = 0,
    this.totalEstablishedUserRelationships = 0,
    this.isVerified = false,
    this.isRegistered = false,
  });

  @override
  Map<String, dynamic> toJson() => {
    'monthlyListeners': monthlyListeners,
    'totalPlays': totalPlays,
    'totalEstablishedUserRelationships': totalEstablishedUserRelationships,
    'isVerified': isVerified,
    'isRegistered': isRegistered,
  };

  factory OnPlatformReputationTrait.fromJson(Map<String, dynamic> json) =>
      OnPlatformReputationTrait(
        monthlyListeners: json['monthlyListeners'] as int? ?? 0,
        totalPlays: json['totalPlays'] as int? ?? 0,
        totalEstablishedUserRelationships:
            json['totalEstablishedUserRelationships'] as int? ?? 0,
        isVerified: json['isVerified'] as bool? ?? false,
        isRegistered: json['isRegistered'] as bool? ?? false,
      );
}
```
