---
title: "home_feature_type.dart"
path: "lib/features/home_feed/domain/models/home_feature_type.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 383
incoming_dependencies: 1
outgoing_dependencies: 2
---

# home_feature_type.dart

> Source File: `[lib/features/home_feed/domain/models/home_feature_type.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/home_feature_type.dart)`
> Layer: `lib/features/home_feed/domain/models`

## Executive Summary
`home_feature_type.dart` is an essential file in `lib/features/home_feed/domain/models` providing definitions for `HomeFeatureType`, `ShortcutsFeatureType`, `ImageLinkFeatureType`, `PreviewFeatureType`, `ImmersivePreviewFeatureType`, `AnchorsFeatureType`, `ContentEvaluationListFeatureType`, `RecentsShelfFeatureType`, `WatchFeedFeatureType`, `PromotionV1FeatureType`, `PromotionV3FeatureType`, `ActionCardCarouselFeatureType`, `LiveEventFeatureType`, `ShowcaseFeatureType`, `VideoPromoFeatureType`, `CampaignLinkCarouselFeatureType`, `VerticalSingleEntryFeatureType`, `VideoCarouselFeatureType`, `AssociatedPreviewFeatureType`, `BannerWithAnimationsFeatureType`, `InteractiveEntrypointFeatureType`, `TopStoryCarouselFeatureType`, `AudioPromoFeatureType`, `InlineCardFeatureType`, `PlayLinkPromoFeatureType`, `AudioSpotlightFeatureType`, `PreviewCarouselFeatureType`, `PreviewPromotionCarouselFeatureType`, `ReflectionFeatureType`, `FullBleedBannerFeatureType`, `BannerFeatureType`.
**Primary Architecture Role**: Core Component, Domain Model / Entity

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `home_view_data.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/home_view_data|home_view_data.dart]] |
| `spotify_entity.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/spotify_entity|spotify_entity.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `section_mapper.dart` | `lib/features/home_feed/data` | [[04-Reference/lib/features/home_feed/data/section_mapper|section_mapper.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class HomeFeatureType`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `id` | `String` |
| `title` | `String` |
| `subtitle` | `String` |
| `items` | `List<SpotifyEntity>` |
| `sectionType` | `String` |
| `colorCode` | `String?` |
| `imageUrl` | `String?` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `toHomeSection` | `HomeSection` | `{SectionLayout? layout}` |

#### `class ShortcutsFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class ImageLinkFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `density` | `int` |

#### `class PreviewFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class ImmersivePreviewFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class AnchorsFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class ContentEvaluationListFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class RecentsShelfFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class WatchFeedFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class PromotionV1FeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class PromotionV3FeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class ActionCardCarouselFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class LiveEventFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class ShowcaseFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class VideoPromoFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `targetUri` | `String` |

#### `class CampaignLinkCarouselFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class VerticalSingleEntryFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class VideoCarouselFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class AssociatedPreviewFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class BannerWithAnimationsFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class InteractiveEntrypointFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `prompt` | `String` |

#### `class TopStoryCarouselFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class AudioPromoFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class InlineCardFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class PlayLinkPromoFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class AudioSpotlightFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class PreviewCarouselFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class PreviewPromotionCarouselFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class ReflectionFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

#### `class FullBleedBannerFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `accessibility` | `String` |

#### `class BannerFeatureType`
- **Archetype**: Core Component
- **Extends**: `HomeFeatureType`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `bannerType` | `int` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:equatable/equatable.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Direct equivalent to Spotify Android's `p.f410` (`HomeFeatureType`).
/// Base contract for all server-driven Casita home sections.
abstract class HomeFeatureType extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final List<SpotifyEntity> items;
  final String sectionType;
  final String? colorCode;
  final String? imageUrl;
  final Map<String, dynamic> metadata;

  const HomeFeatureType({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.items = const [],
    required this.sectionType,
    this.colorCode,
    this.imageUrl,
    this.metadata = const {},
  });

  /// Converts to HomeSection for backward compatibility with view layer.
  HomeSection toHomeSection({SectionLayout? layout}) {
    return HomeSection(
      title: title,
      subtitle: subtitle,
      items: items,
      layout: layout ?? defaultLayout,
      sectionUri: id,
      sectionType: sectionType,
      colorCode: colorCode,
      imageUrl: imageUrl,
      metadata: metadata,
    );
  }

  SectionLayout get defaultLayout {
    switch (sectionType) {
      case 'shortcuts':
// ... [remaining code in source file] ...
```
