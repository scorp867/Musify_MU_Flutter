---
title: "scroll_card_descriptor.dart"
path: "lib/features/player/domain/models/scroll_card_descriptor.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 207
incoming_dependencies: 12
outgoing_dependencies: 9
---

# scroll_card_descriptor.dart

> Source File: `[lib/features/player/domain/models/scroll_card_descriptor.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/domain/models/scroll_card_descriptor.dart)`
> Layer: `lib/features/player/domain/models`

## Executive Summary
`scroll_card_descriptor.dart` is an essential file in `lib/features/player/domain/models` providing definitions for `ScrollCardDescriptor`, `CreatorBioCardDescriptor`, `CreditsCardDescriptor`, `LyricsCardDescriptor`, `DiscoveryFeedCardDescriptor`, `LiveEventsCardDescriptor`, `MerchCardDescriptor`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `data_requirement.dart` | `lib/core/kodiak/statement` | [[04-Reference/lib/core/kodiak/statement/data_requirement|data_requirement.dart]] |
| `data_statement.dart` | `lib/core/kodiak/statement` | [[04-Reference/lib/core/kodiak/statement/data_statement|data_statement.dart]] |
| `concert_location_trait.dart` | `lib/features/home_feed/domain/models/traits` | [[04-Reference/lib/features/home_feed/domain/models/traits/concert_location_trait|concert_location_trait.dart]] |
| `concert_trait.dart` | `lib/features/home_feed/domain/models/traits` | [[04-Reference/lib/features/home_feed/domain/models/traits/concert_trait|concert_trait.dart]] |
| `identity_trait.dart` | `lib/features/home_feed/domain/models/traits` | [[04-Reference/lib/features/home_feed/domain/models/traits/identity_trait|identity_trait.dart]] |
| `track_meta_trait.dart` | `lib/features/home_feed/domain/models/traits` | [[04-Reference/lib/features/home_feed/domain/models/traits/track_meta_trait|track_meta_trait.dart]] |
| `visual_identity_trait.dart` | `lib/features/home_feed/domain/models/traits` | [[04-Reference/lib/features/home_feed/domain/models/traits/visual_identity_trait|visual_identity_trait.dart]] |
| `on_platform_reputation_trait.dart` | `lib/features/home_feed/domain/models/traits` | [[04-Reference/lib/features/home_feed/domain/models/traits/on_platform_reputation_trait|on_platform_reputation_trait.dart]] |
| `credits_trait.dart` | `lib/features/home_feed/domain/models/traits` | [[04-Reference/lib/features/home_feed/domain/models/traits/credits_trait|credits_trait.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `debug_now_playing_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/debug_now_playing_screen|debug_now_playing_screen.dart]] |
| `player_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/player_screen|player_screen.dart]] |
| `scroll_card_registry.dart` | `lib/features/player/presentation/scroll` | [[04-Reference/lib/features/player/presentation/scroll/scroll_card_registry|scroll_card_registry.dart]] |
| `scrollsita_repository.dart` | `lib/features/player/domain/repositories` | [[04-Reference/lib/features/player/domain/repositories/scrollsita_repository|scrollsita_repository.dart]] |
| `about_artist_data_element.dart` | `lib/features/player/data/elements` | [[04-Reference/lib/features/player/data/elements/about_artist_data_element|about_artist_data_element.dart]] |
| `credits_card_data_element.dart` | `lib/features/player/data/elements` | [[04-Reference/lib/features/player/data/elements/credits_card_data_element|credits_card_data_element.dart]] |
| `live_events_card_data_element.dart` | `lib/features/player/data/elements` | [[04-Reference/lib/features/player/data/elements/live_events_card_data_element|live_events_card_data_element.dart]] |
| `scrollsita_repository.dart` | `lib/features/player/data/repositories` | [[04-Reference/lib/features/player/data/repositories/scrollsita_repository|scrollsita_repository.dart]] |
| `now_playing_scroll_bloc.dart` | `lib/features/player/application/scroll` | [[04-Reference/lib/features/player/application/scroll/now_playing_scroll_bloc|now_playing_scroll_bloc.dart]] |
| `now_playing_scroll_state.dart` | `lib/features/player/application/scroll` | [[04-Reference/lib/features/player/application/scroll/now_playing_scroll_state|now_playing_scroll_state.dart]] |
| `now_playing_scroll_bloc_test.dart` | `test/features/player/application` | [[04-Reference/test/features/player/application/now_playing_scroll_bloc_test|now_playing_scroll_bloc_test.dart]] |
| `scroll_card_registry_test.dart` | `test/features/player/presentation/scroll` | [[04-Reference/test/features/player/presentation/scroll/scroll_card_registry_test|scroll_card_registry_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class ScrollCardDescriptor`
- **Archetype**: Core Component

#### `class CreatorBioCardDescriptor`
- **Archetype**: Core Component
- **Implements**: `ScrollCardDescriptor`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `creatorUri` | `String` |
| `title` | `String` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `toString` | `String` | `(none)` |

#### `class CreditsCardDescriptor`
- **Archetype**: Core Component
- **Implements**: `ScrollCardDescriptor`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `entityUri` | `String` |
| `contributorUris` | `List<String>` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `toString` | `String` | `(none)` |

#### `class LyricsCardDescriptor`
- **Archetype**: Core Component
- **Implements**: `ScrollCardDescriptor`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `entityUri` | `String` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `toString` | `String` | `(none)` |

#### `class DiscoveryFeedCardDescriptor`
- **Archetype**: Core Component
- **Implements**: `ScrollCardDescriptor`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `title` | `String` |
| `itemUris` | `List<String>` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `toString` | `String` | `(none)` |

#### `class LiveEventsCardDescriptor`
- **Archetype**: Core Component
- **Implements**: `ScrollCardDescriptor`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `artistUri` | `String` |
| `concertUris` | `List<String>` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `toString` | `String` | `(none)` |

#### `class MerchCardDescriptor`
- **Archetype**: Core Component
- **Implements**: `ScrollCardDescriptor`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `entityUri` | `String` |

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
import 'package:musify_mu/core/kodiak/statement/data_requirement.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/concert_location_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/concert_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/identity_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/track_meta_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/visual_identity_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/on_platform_reputation_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/credits_trait.dart';

/// Interface matching Spotify's `p/m3h0.java`.
///
/// Each scroll card in the Now Playing scroll view implements this interface
/// to declare the entity URIs and Kodiak [DataStatement] it depends on for data loading.
abstract class ScrollCardDescriptor {
  /// The Spotify entity URIs (artists, tracks, concerts, albums) that this card requires.
  /// Matches `p/m3h0.java -> List a()`.
  List<String> get entityUris;

  /// Declarative [DataStatement] declaring required and optional traits.
  /// Matches `p/x1.java` and `p/llk.java` in Spotify Android.
  DataStatement? get dataStatement;
}

/// Creator bio card descriptor.
/// 1:1 replica of `p/z1h0.java` (associated with `p/x1.java` `AboutCardDataElement`).
class CreatorBioCardDescriptor implements ScrollCardDescriptor {
  final String creatorUri;
  final String title;

  static const DataStatement statement = DataStatement([
    DataRequirement(
      extensionKindValue: 8,
      extensionKind: ExtensionKind.ARTIST_V4,
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
// ... [remaining code in source file] ...
```
