---
title: "data_requirement.dart"
path: "lib/core/kodiak/statement/data_requirement.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, kodiak]
lines: 55
incoming_dependencies: 17
outgoing_dependencies: 0
---

# data_requirement.dart

> Source File: `[lib/core/kodiak/statement/data_requirement.dart](file:///c:/Users/Admin/Musify_MU/lib/core/kodiak/statement/data_requirement.dart)`
> Layer: `lib/core/kodiak/statement`

## Executive Summary
`data_requirement.dart` is an essential file in `lib/core/kodiak/statement` providing definitions for `DataRequirement`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `scroll_card_descriptor.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/scroll_card_descriptor|scroll_card_descriptor.dart]] |
| `campaign_card_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/campaign_card_data_element|campaign_card_data_element.dart]] |
| `caught_up_banner_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/caught_up_banner_data_element|caught_up_banner_data_element.dart]] |
| `destination_image_link_card_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/destination_image_link_card_data_element|destination_image_link_card_data_element.dart]] |
| `episode_row_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/episode_row_data_element|episode_row_data_element.dart]] |
| `full_bleed_banner_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/full_bleed_banner_data_element|full_bleed_banner_data_element.dart]] |
| `image_link_card_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/image_link_card_data_element|image_link_card_data_element.dart]] |
| `interactive_prompt_card_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/interactive_prompt_card_data_element|interactive_prompt_card_data_element.dart]] |
| `live_event_card_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/live_event_card_data_element|live_event_card_data_element.dart]] |
| `podcast_preview_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/podcast_preview_data_element|podcast_preview_data_element.dart]] |
| `preview_card_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/preview_card_data_element|preview_card_data_element.dart]] |
| `recents_card_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/recents_card_data_element|recents_card_data_element.dart]] |
| `reflection_card_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/reflection_card_data_element|reflection_card_data_element.dart]] |
| `shortcuts_card_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/shortcuts_card_data_element|shortcuts_card_data_element.dart]] |
| `showcase_card_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/showcase_card_data_element|showcase_card_data_element.dart]] |
| `video_promo_card_data_element.dart` | `lib/features/home_feed/data/elements` | [[04-Reference/lib/features/home_feed/data/elements/video_promo_card_data_element|video_promo_card_data_element.dart]] |
| `data_statement.dart` | `lib/core/kodiak/statement` | [[04-Reference/lib/core/kodiak/statement/data_statement|data_statement.dart]] |

## Declarations & API Breakdown

### Enums
#### `enum DataPriority`
Values: `required(1)`, `optional(2);

  final int level;
  const DataPriority(this.level);`

### Classes & Mixins
#### `class DataRequirement`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `extensionKindValue` | `int` |
| `extensionKind` | `ExtensionKind?` |
| `priority` | `DataPriority` |
| `traitType` | `Type` |
| `operator` | `bool` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `toString` | `String` | `(none)` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';

/// Priority level of a data requirement, matching Kodiak's levels:
/// - Level 1: Required (needed for base card layout & rendering)
/// - Level 2: Optional (enrichment traits: badges, visual identity, playback hooks, pricing)
enum DataPriority {
  required(1),
  optional(2);

  final int level;
  const DataPriority(this.level);
}

/// Represents a single trait requirement for a Kodiak DataElement.
/// Direct equivalent to Spotify Android's `p.y7n` / `p.l2t0` (`k2t0` / `j2t0`).
class DataRequirement {
  /// The integer ExtensionKind corresponding to the trait.
  final int extensionKindValue;

  /// The protobuf ExtensionKind enum if known.
  final ExtensionKind? extensionKind;

  /// Priority of this trait (Level 1 = Required, Level 2 = Optional).
  final DataPriority priority;

  /// The Dart model type of this trait (e.g. `SimpleCardTrait`).
  final Type traitType;

  const DataRequirement({
    required this.extensionKindValue,
    this.extensionKind,
    required this.priority,
    required this.traitType,
  });

  bool get isRequired => priority == DataPriority.required;
  bool get isOptional => priority == DataPriority.optional;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataRequirement &&
          runtimeType == other.runtimeType &&
          extensionKindValue == other.extensionKindValue &&
          priority == other.priority &&
// ... [remaining code in source file] ...
```
