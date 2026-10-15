---
title: "credits_card_data_element.dart"
path: "lib/features/player/data/elements/credits_card_data_element.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 29
incoming_dependencies: 0
outgoing_dependencies: 4
---

# credits_card_data_element.dart

> Source File: `[lib/features/player/data/elements/credits_card_data_element.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/data/elements/credits_card_data_element.dart)`
> Layer: `lib/features/player/data/elements`

## Executive Summary
`credits_card_data_element.dart` is an essential file in `lib/features/player/data/elements` providing definitions for `CreditsCardDataElement`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `data_pool.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool|data_pool.dart]] |
| `data_element.dart` | `lib/core/kodiak/element` | [[04-Reference/lib/core/kodiak/element/data_element|data_element.dart]] |
| `data_statement.dart` | `lib/core/kodiak/statement` | [[04-Reference/lib/core/kodiak/statement/data_statement|data_statement.dart]] |
| `scroll_card_descriptor.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/scroll_card_descriptor|scroll_card_descriptor.dart]] |

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class CreditsCardDataElement`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Implements**: `DataElement`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `id` | `String` |
| `dataPool` | `DataPool` |
| `trackUri` | `String` |
| `contributorUris` | `List<String>` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/element/data_element.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';

/// DataElement for the Track Credits scroll card in Now Playing view.
///
/// 1:1 replica of Spotify Android's `p/llk.java` (case 0, `CreditsCardDataElement`).
/// Declares level 1 requirement for track metadata and level 2 for contributor identities.
class CreditsCardDataElement implements DataElement {
  @override
  final String id;

  @override
  final DataPool dataPool;

  final String trackUri;
  final List<String> contributorUris;

  const CreditsCardDataElement({
    required this.id,
    required this.dataPool,
    required this.trackUri,
    this.contributorUris = const [],
  });

  @override
  DataStatement get dataStatement => CreditsCardDescriptor.statement;
}
```
