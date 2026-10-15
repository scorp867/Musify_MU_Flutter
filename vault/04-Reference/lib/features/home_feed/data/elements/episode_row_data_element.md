---
title: "episode_row_data_element.dart"
path: "lib/features/home_feed/data/elements/episode_row_data_element.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 60
incoming_dependencies: 0
outgoing_dependencies: 5
---

# episode_row_data_element.dart

> Source File: `[lib/features/home_feed/data/elements/episode_row_data_element.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/data/elements/episode_row_data_element.dart)`
> Layer: `lib/features/home_feed/data/elements`

## Executive Summary
`episode_row_data_element.dart` is an essential file in `lib/features/home_feed/data/elements` providing definitions for `EpisodeRowDataElement`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `data_pool.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool|data_pool.dart]] |
| `data_element.dart` | `lib/core/kodiak/element` | [[04-Reference/lib/core/kodiak/element/data_element|data_element.dart]] |
| `data_requirement.dart` | `lib/core/kodiak/statement` | [[04-Reference/lib/core/kodiak/statement/data_requirement|data_requirement.dart]] |
| `data_statement.dart` | `lib/core/kodiak/statement` | [[04-Reference/lib/core/kodiak/statement/data_statement|data_statement.dart]] |
| `traits.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/traits|traits.dart]] |

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class EpisodeRowDataElement`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Implements**: `DataElement`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `id` | `String` |
| `dataPool` | `DataPool` |

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
import 'package:musify_mu/core/kodiak/statement/data_requirement.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Direct 1:1 equivalent to Spotify Android's `p.w8b0` (`ContentEvaluationRowDataElement` / `EpisodeRowDataElement`).
/// Used for episode lists, chapter rows, and content evaluation shelves.
class EpisodeRowDataElement implements DataElement {
  @override
  final String id;

  @override
  final DataPool dataPool;

  /// Direct 1:1 equivalent to Spotify Android `p.w8b0.c`:
  /// - Required: Kind 97 (SIMPLE_TRAIT / c6y0), Kind 178 (IDENTITY_TRAIT / l020)
  /// - Optional: Kind 179 (VISUAL_IDENTITY_TRAIT / sw71), Kind 31 (SHOW_ACCESS / fhx0), Kind 116 (AUDIO_PREVIEW_PLAYBACK_TRAIT)
  static const DataStatement statement = DataStatement([
    DataRequirement(
      extensionKindValue: 97,
      extensionKind: ExtensionKind.SIMPLE_TRAIT,
      priority: DataPriority.required,
      traitType: SimpleCardTrait,
    ),
    DataRequirement(
      extensionKindValue: 178,
      extensionKind: ExtensionKind.IDENTITY_TRAIT,
      priority: DataPriority.required,
      traitType: IdentityTrait,
    ),
    DataRequirement(
      extensionKindValue: 179,
      extensionKind: ExtensionKind.VISUAL_IDENTITY_TRAIT,
      priority: DataPriority.optional,
      traitType: VisualIdentityTrait,
    ),
    DataRequirement(
      extensionKindValue: 31,
      extensionKind: ExtensionKind.SHOW_ACCESS,
      priority: DataPriority.optional,
      traitType: ShowAccessTrait,
    ),
    DataRequirement(
// ... [remaining code in source file] ...
```
