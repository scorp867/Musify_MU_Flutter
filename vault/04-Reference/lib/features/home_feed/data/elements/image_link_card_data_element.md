---
title: "image_link_card_data_element.dart"
path: "lib/features/home_feed/data/elements/image_link_card_data_element.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 72
incoming_dependencies: 4
outgoing_dependencies: 5
---

# image_link_card_data_element.dart

> Source File: `[lib/features/home_feed/data/elements/image_link_card_data_element.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/data/elements/image_link_card_data_element.dart)`
> Layer: `lib/features/home_feed/data/elements`

## Executive Summary
`image_link_card_data_element.dart` is an essential file in `lib/features/home_feed/data/elements` providing definitions for `ImageLinkCardDataElement`.
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
| `content_carousel_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/content_carousel_section|content_carousel_section.dart]] |
| `recents_carousel_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/recents_carousel_section|recents_carousel_section.dart]] |
| `kodiak_data_layer_test.dart` | `test/features/home_feed` | [[04-Reference/test/features/home_feed/kodiak_data_layer_test|kodiak_data_layer_test.dart]] |
| `network_reconnect_retry_test.dart` | `test/core/kodiak` | [[04-Reference/test/core/kodiak/network_reconnect_retry_test|network_reconnect_retry_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class ImageLinkCardDataElement`
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

/// Direct equivalent to Spotify Android's `p.u520` (`ImageLinkCardDataElement`)
/// and `p.z520` (`DataStatement` declaration).
///
/// Declares the exact 6 traits queried by Spotify:
/// - Level 1 (Required): ExtensionKind 97 (SIMPLE_TRAIT)
/// - Level 2 (Optional): ExtensionKind 178 (IDENTITY_TRAIT)
/// - Level 2 (Optional): ExtensionKind 179 (VISUAL_IDENTITY_TRAIT)
/// - Level 2 (Optional): ExtensionKind 31 (SHOW_ACCESS)
/// - Level 2 (Optional): ExtensionKind 52 (AUDIOBOOK_SPECIFICS)
/// - Level 2 (Optional): ExtensionKind 64 (AUDIOBOOK_PRICE)
class ImageLinkCardDataElement implements DataElement {
  @override
  final String id;

  @override
  final DataPool dataPool;

  /// The static, immutable DataStatement matching Spotify Android `p.z520.a`.
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
// ... [remaining code in source file] ...
```
