---
title: "audiobook_specifics_trait.dart"
path: "lib/features/home_feed/domain/models/traits/audiobook_specifics_trait.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 33
incoming_dependencies: 0
outgoing_dependencies: 0
---

# audiobook_specifics_trait.dart

> Source File: `[lib/features/home_feed/domain/models/traits/audiobook_specifics_trait.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/traits/audiobook_specifics_trait.dart)`
> Layer: `lib/features/home_feed/domain/models/traits`

## Executive Summary
`audiobook_specifics_trait.dart` is an essential file in `lib/features/home_feed/domain/models/traits` providing definitions for `AudiobookSpecificsTrait`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class AudiobookSpecificsTrait`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Extends**: `Trait`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `narrator` | `String` |
| `author` | `String` |
| `durationSeconds` | `int` |
| `isUnabridged` | `bool` |

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

/// Audiobook specific details (ExtensionKind 52).
/// Equivalent to Spotify Android's `eu6` (AudiobookSpecificsTrait).
class AudiobookSpecificsTrait extends Trait {
  final String narrator;
  final String author;
  final int durationSeconds;
  final bool isUnabridged;

  const AudiobookSpecificsTrait({
    this.narrator = '',
    this.author = '',
    this.durationSeconds = 0,
    this.isUnabridged = true,
  });

  @override
  Map<String, dynamic> toJson() => {
    'narrator': narrator,
    'author': author,
    'durationSeconds': durationSeconds,
    'isUnabridged': isUnabridged,
  };

  factory AudiobookSpecificsTrait.fromJson(Map<String, dynamic> json) =>
      AudiobookSpecificsTrait(
        narrator: json['narrator'] ?? '',
        author: json['author'] ?? '',
        durationSeconds: json['durationSeconds'] ?? 0,
        isUnabridged: json['isUnabridged'] ?? true,
      );
}
```
