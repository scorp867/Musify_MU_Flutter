---
title: "data_statement.dart"
path: "lib/core/kodiak/statement/data_statement.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, kodiak]
lines: 42
incoming_dependencies: 22
outgoing_dependencies: 1
---

# data_statement.dart

> Source File: `[lib/core/kodiak/statement/data_statement.dart](file:///c:/Users/Admin/Musify_MU/lib/core/kodiak/statement/data_statement.dart)`
> Layer: `lib/core/kodiak/statement`

## Executive Summary
`data_statement.dart` is an essential file in `lib/core/kodiak/statement` providing definitions for `DataStatement`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `data_requirement.dart` | `lib/core/kodiak/statement` | [[04-Reference/lib/core/kodiak/statement/data_requirement|data_requirement.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `scroll_card_descriptor.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/scroll_card_descriptor|scroll_card_descriptor.dart]] |
| `about_artist_data_element.dart` | `lib/features/player/data/elements` | [[04-Reference/lib/features/player/data/elements/about_artist_data_element|about_artist_data_element.dart]] |
| `credits_card_data_element.dart` | `lib/features/player/data/elements` | [[04-Reference/lib/features/player/data/elements/credits_card_data_element|credits_card_data_element.dart]] |
| `live_events_card_data_element.dart` | `lib/features/player/data/elements` | [[04-Reference/lib/features/player/data/elements/live_events_card_data_element|live_events_card_data_element.dart]] |
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
| `data_pool.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool|data_pool.dart]] |
| `data_pool_impl.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool_impl|data_pool_impl.dart]] |
| `data_element.dart` | `lib/core/kodiak/element` | [[04-Reference/lib/core/kodiak/element/data_element|data_element.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class DataStatement`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `requirements` | `List<DataRequirement>` |
| `operator` | `bool` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `where` | `dynamic` | `(r` |
| `where` | `dynamic` | `(r` |
| `map` | `dynamic` | `(r` |
| `hasKind` | `bool` | `int kind` |
| `any` | `dynamic` | `(r` |
| `hasTraitType` | `bool` | `Type type` |
| `any` | `dynamic` | `(r` |
| `every` | `dynamic` | `(r` |
| `toString` | `String` | `(none)` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:musify_mu/core/kodiak/statement/data_requirement.dart';

/// Immutable declaration of required and optional traits for a Kodiak element.
/// Direct equivalent to Spotify Android's `com.spotify.kodiak.dataloader.statement.DataStatement`.
class DataStatement {
  final List<DataRequirement> requirements;

  const DataStatement(this.requirements);

  /// All required (Level 1) traits for the element.
  List<DataRequirement> get requiredRequirements =>
      requirements.where((r) => r.isRequired).toList();

  /// All optional (Level 2) traits for the element.
  List<DataRequirement> get optionalRequirements =>
      requirements.where((r) => r.isOptional).toList();

  /// List of all extension kind integers required by this statement.
  List<int> get extensionKindValues =>
      requirements.map((r) => r.extensionKindValue).toList();

  /// Checks if this statement contains a specific trait requirement.
  bool hasKind(int kind) =>
      requirements.any((r) => r.extensionKindValue == kind);

  /// Checks if this statement requires a specific trait type.
  bool hasTraitType(Type type) => requirements.any((r) => r.traitType == type);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataStatement &&
          runtimeType == other.runtimeType &&
          requirements.length == other.requirements.length &&
          requirements.every((r) => other.requirements.contains(r));

  @override
  int get hashCode => Object.hashAll(requirements);

  @override
  String toString() => 'DataStatement(${requirements.length} traits)';
}
```
