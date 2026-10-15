---
title: "spotify_entity.dart"
path: "lib/features/home_feed/domain/models/spotify_entity.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 230
incoming_dependencies: 34
outgoing_dependencies: 0
---

# spotify_entity.dart

> Source File: `[lib/features/home_feed/domain/models/spotify_entity.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/spotify_entity.dart)`
> Layer: `lib/features/home_feed/domain/models`

## Executive Summary
`spotify_entity.dart` is an essential file in `lib/features/home_feed/domain/models` providing definitions for `SpotifyEntity`.
**Primary Architecture Role**: Domain Model / Entity

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `casita_parser.dart` | `lib/features/home_feed/data` | [[04-Reference/lib/features/home_feed/data/casita_parser|casita_parser.dart]] |
| `home_feed_cache.dart` | `lib/features/home_feed/data` | [[04-Reference/lib/features/home_feed/data/home_feed_cache|home_feed_cache.dart]] |
| `home_repository.dart` | `lib/features/home_feed/data` | [[04-Reference/lib/features/home_feed/data/home_repository|home_repository.dart]] |
| `section_mapper.dart` | `lib/features/home_feed/data` | [[04-Reference/lib/features/home_feed/data/section_mapper|section_mapper.dart]] |
| `quick_grid_section.dart` | `lib/features/home_feed/presentation/widgets` | [[04-Reference/lib/features/home_feed/presentation/widgets/quick_grid_section|quick_grid_section.dart]] |
| `artist_circle_card.dart` | `lib/features/home_feed/presentation/widgets/cards` | [[04-Reference/lib/features/home_feed/presentation/widgets/cards/artist_circle_card|artist_circle_card.dart]] |
| `episode_preview_card.dart` | `lib/features/home_feed/presentation/widgets/cards` | [[04-Reference/lib/features/home_feed/presentation/widgets/cards/episode_preview_card|episode_preview_card.dart]] |
| `preview_card.dart` | `lib/features/home_feed/presentation/widgets/cards` | [[04-Reference/lib/features/home_feed/presentation/widgets/cards/preview_card|preview_card.dart]] |
| `show_preview_card.dart` | `lib/features/home_feed/presentation/widgets/cards` | [[04-Reference/lib/features/home_feed/presentation/widgets/cards/show_preview_card|show_preview_card.dart]] |
| `square_card.dart` | `lib/features/home_feed/presentation/widgets/cards` | [[04-Reference/lib/features/home_feed/presentation/widgets/cards/square_card|square_card.dart]] |
| `action_card_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/action_card_section|action_card_section.dart]] |
| `audio_spotlight_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/audio_spotlight_section|audio_spotlight_section.dart]] |
| `campaign_carousel_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/campaign_carousel_section|campaign_carousel_section.dart]] |
| `content_carousel_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/content_carousel_section|content_carousel_section.dart]] |
| `episode_list_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/episode_list_section|episode_list_section.dart]] |
| `immersive_preview_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/immersive_preview_section|immersive_preview_section.dart]] |
| `inline_card_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/inline_card_section|inline_card_section.dart]] |
| `interactive_prompt_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/interactive_prompt_section|interactive_prompt_section.dart]] |
| `live_event_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/live_event_section|live_event_section.dart]] |
| `play_link_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/play_link_section|play_link_section.dart]] |
| `podcast_preview_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/podcast_preview_section|podcast_preview_section.dart]] |
| `preview_carousel_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/preview_carousel_section|preview_carousel_section.dart]] |
| `preview_feed_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/preview_feed_section|preview_feed_section.dart]] |
| `promotion_banner_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/promotion_banner_section|promotion_banner_section.dart]] |
| `recents_carousel_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/recents_carousel_section|recents_carousel_section.dart]] |
| `reflection_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/reflection_section|reflection_section.dart]] |
| `showcase_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/showcase_section|showcase_section.dart]] |
| `story_bubble_carousel.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/story_bubble_carousel|story_bubble_carousel.dart]] |
| `vertical_card_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/vertical_card_section|vertical_card_section.dart]] |
| `video_carousel_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/video_carousel_section|video_carousel_section.dart]] |
| `video_promo_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/video_promo_section|video_promo_section.dart]] |
| `home_feature_type.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/home_feature_type|home_feature_type.dart]] |
| `kodiak_reactive_card.dart` | `lib/core/kodiak/element` | [[04-Reference/lib/core/kodiak/element/kodiak_reactive_card|kodiak_reactive_card.dart]] |
| `kodiak_data_layer_test.dart` | `test/features/home_feed` | [[04-Reference/test/features/home_feed/kodiak_data_layer_test|kodiak_data_layer_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class SpotifyEntity`
- **Archetype**: Domain Model / Entity

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `uri` | `String` |
| `type` | `ContentType` |
| `operator` | `bool` |
| `typeName` | `final` |
| `sct` | `final` |
| `simple` | `final` |
| `identity` | `final` |
| `simple` | `final` |
| `identity` | `final` |
| `preview` | `final` |
| `sct` | `final` |
| `simple` | `final` |
| `preview` | `final` |
| `trackMeta` | `final` |
| `video` | `final` |
| `identity` | `final` |
| `preview` | `final` |
| `simple` | `final` |
| `identity` | `final` |
| `vt` | `final` |
| `vit` | `final` |
| `pt` | `final` |
| `at` | `final` |
| `null` | `return` |
| `preview` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `toJson` | `dynamic>` | `(none)` |
| `map` | `dynamic` | `(key, value` |
| `fromJson` | `dynamic` | `Map<String, dynamic> json` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
export 'traits.dart';
import 'traits.dart';

/// The core SDUI container.
/// Each entity has a URI, content type, and a bag of traits
/// that different UI widgets read from based on their context.
class SpotifyEntity {
  final String uri;
  final ContentType type;
  final Map<String, Trait> traits;

  const SpotifyEntity({
    required this.uri,
    required this.type,
    required this.traits,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpotifyEntity && other.uri == uri;
  }

  @override
  int get hashCode => uri.hashCode;

  /// Convenience fetcher for specific traits
  T? getTrait<T extends Trait>() {
    final typeName = T.toString();
    return traits[typeName] as T?;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Context-specific title/image getters
  // Each widget context has a different trait priority chain.
  // ═══════════════════════════════════════════════════════════════════

  /// Shortcuts grid: prioritizes ShortcutsCardTrait from eagerload.
  String get shortcutTitle {
    final sct = getTrait<ShortcutsCardTrait>();
    if (sct != null && sct.title.isNotEmpty) return sct.title;
    final simple = getTrait<SimpleCardTrait>();
    if (simple != null && simple.title.isNotEmpty) return simple.title;
    final identity = getTrait<IdentityTrait>();
    if (identity != null && identity.title.isNotEmpty) return identity.title;
// ... [remaining code in source file] ...
```
