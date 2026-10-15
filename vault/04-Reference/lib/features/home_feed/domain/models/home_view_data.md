---
title: "home_view_data.dart"
path: "lib/features/home_feed/domain/models/home_view_data.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 103
incoming_dependencies: 14
outgoing_dependencies: 0
---

# home_view_data.dart

> Source File: `[lib/features/home_feed/domain/models/home_view_data.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/home_view_data.dart)`
> Layer: `lib/features/home_feed/domain/models`

## Executive Summary
`home_view_data.dart` is an essential file in `lib/features/home_feed/domain/models` providing definitions for `HomeViewData`, `HomeSection`, `HomeChip`.
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
| `home_feed_view.dart` | `lib/features/home_feed/presentation` | [[04-Reference/lib/features/home_feed/presentation/home_feed_view|home_feed_view.dart]] |
| `section_registry.dart` | `lib/features/home_feed/presentation` | [[04-Reference/lib/features/home_feed/presentation/section_registry|section_registry.dart]] |
| `facet_chip_row.dart` | `lib/features/home_feed/presentation/widgets` | [[04-Reference/lib/features/home_feed/presentation/widgets/facet_chip_row|facet_chip_row.dart]] |
| `caught_up_banner_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/caught_up_banner_section|caught_up_banner_section.dart]] |
| `full_bleed_banner_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/full_bleed_banner_section|full_bleed_banner_section.dart]] |
| `home_feature_type.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/home_feature_type|home_feature_type.dart]] |
| `home_repository.dart` | `lib/features/home_feed/domain/repositories` | [[04-Reference/lib/features/home_feed/domain/repositories/home_repository|home_repository.dart]] |
| `load_home_feed.dart` | `lib/features/home_feed/domain/usecases` | [[04-Reference/lib/features/home_feed/domain/usecases/load_home_feed|load_home_feed.dart]] |
| `home_header.dart` | `lib/features/home/presentation/widgets` | [[04-Reference/lib/features/home/presentation/widgets/home_header|home_header.dart]] |
| `banner_sections_widget_test.dart` | `test/features/home_feed` | [[04-Reference/test/features/home_feed/banner_sections_widget_test|banner_sections_widget_test.dart]] |
| `kodiak_data_layer_test.dart` | `test/features/home_feed` | [[04-Reference/test/features/home_feed/kodiak_data_layer_test|kodiak_data_layer_test.dart]] |

## Declarations & API Breakdown

### Enums
#### `enum HomeFacet`
Values: `all(pathSegment: 'default'`, `label: 'All'`, `recentsPath: '/playlist/v2/list/recents/main')`, `music(pathSegment: 'music-chip'`, `label: 'Music'`, `recentsPath: '/playlist/v2/list/recents/music')`, `podcasts(pathSegment: 'podcasts-chip'`, `label: 'Podcasts'`, `recentsPath: '/playlist/v2/list/recents/podcasts');

  final String pathSegment;
  final String label;
  final String recentsPath;

  const HomeFacet({
    required this.pathSegment`, `required this.label`, `required this.recentsPath`

#### `enum SectionLayout`
Values: `quick access).
  quickGrid`

### Classes & Mixins
#### `class HomeViewData`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `greeting` | `String` |
| `sections` | `List<HomeSection>` |
| `chips` | `List<HomeChip>` |

#### `class HomeSection`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `title` | `String` |
| `subtitle` | `String` |
| `items` | `List<SpotifyEntity>` |
| `layout` | `SectionLayout` |
| `sectionUri` | `String?` |
| `sectionType` | `String` |
| `colorCode` | `String?` |
| `imageUrl` | `String?` |

#### `class HomeChip`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `id` | `String` |
| `label` | `String` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:equatable/equatable.dart';
import 'spotify_entity.dart';

/// Spotify home feed facets (filter chips).
/// Maps 1:1 with Casita endpoint paths: /casita/v1/home/{pathSegment}.
enum HomeFacet {
  all(pathSegment: 'default', label: 'All', recentsPath: '/playlist/v2/list/recents/main'),
  music(pathSegment: 'music-chip', label: 'Music', recentsPath: '/playlist/v2/list/recents/music'),
  podcasts(pathSegment: 'podcasts-chip', label: 'Podcasts', recentsPath: '/playlist/v2/list/recents/podcasts');

  final String pathSegment;
  final String label;
  final String recentsPath;

  const HomeFacet({
    required this.pathSegment,
    required this.label,
    required this.recentsPath,
  });
}

/// Complete home feed data  -  everything the UI needs.
class HomeViewData extends Equatable {
  final String greeting;
  final List<HomeSection> sections;
  final List<HomeChip> chips;

  static const List<HomeChip> defaultChips = [
    HomeChip(id: 'all', label: 'All'),
    HomeChip(id: 'music', label: 'Music'),
    HomeChip(id: 'podcasts', label: 'Podcasts'),
  ];

  const HomeViewData({
    this.greeting = '',
    this.sections = const [],
    this.chips = defaultChips,
  });

  @override
  List<Object?> get props => [greeting, sections, chips];
}

/// A single section row on the home screen (e.g. "Recently Played").
class HomeSection extends Equatable {
// ... [remaining code in source file] ...
```
