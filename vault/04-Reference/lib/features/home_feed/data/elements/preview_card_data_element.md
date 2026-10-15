---
title: "preview_card_data_element.dart"
path: "lib/features/home_feed/data/elements/preview_card_data_element.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 62
incoming_dependencies: 5
outgoing_dependencies: 5
---

# preview_card_data_element.dart

> Source File: `[lib/features/home_feed/data/elements/preview_card_data_element.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/data/elements/preview_card_data_element.dart)`
> Layer: `lib/features/home_feed/data/elements`

## Executive Summary
`preview_card_data_element.dart` is an essential file in `lib/features/home_feed/data/elements` providing definitions for `PreviewCardDataElement`.
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
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `episode_list_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/episode_list_section|episode_list_section.dart]] |
| `preview_carousel_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/preview_carousel_section|preview_carousel_section.dart]] |
| `preview_feed_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/preview_feed_section|preview_feed_section.dart]] |
| `video_carousel_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/video_carousel_section|video_carousel_section.dart]] |
| `kodiak_data_layer_test.dart` | `test/features/home_feed` | [[04-Reference/test/features/home_feed/kodiak_data_layer_test|kodiak_data_layer_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class PreviewCardDataElement`
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

/// Direct equivalent to Spotify Android's `p.wab0` / `p.w8b0` (`PreviewCardDataElement`).
class PreviewCardDataElement implements DataElement {
  @override
  final String id;

  @override
  final DataPool dataPool;

  static const DataStatement statement = DataStatement([
    DataRequirement(
      extensionKindValue: 118,
      extensionKind: ExtensionKind.PREVIEW_CARD_TRAIT,
      priority: DataPriority.required,
      traitType: PreviewCardTrait,
    ),
    DataRequirement(
      extensionKindValue: 116,
      extensionKind: ExtensionKind.AUDIO_PREVIEW_PLAYBACK_TRAIT,
      priority: DataPriority.required,
      traitType: AudioPreviewPlaybackTrait,
    ),
    DataRequirement(
      extensionKindValue: 178,
      extensionKind: ExtensionKind.IDENTITY_TRAIT,
      priority: DataPriority.optional,
      traitType: IdentityTrait,
    ),
    DataRequirement(
      extensionKindValue: 179,
      extensionKind: ExtensionKind.VISUAL_IDENTITY_TRAIT,
      priority: DataPriority.optional,
      traitType: VisualIdentityTrait,
    ),
    DataRequirement(
      extensionKindValue: 181,
      extensionKind: ExtensionKind.PREVIEW_PLAYBACK_TRAIT,
      priority: DataPriority.optional,
      traitType: PreviewPlaybackTrait,
// ... [remaining code in source file] ...
```
