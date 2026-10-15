---
title: "section_mapper.dart"
path: "lib/features/home_feed/data/section_mapper.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 280
incoming_dependencies: 1
outgoing_dependencies: 2
---

# section_mapper.dart

> Source File: `[lib/features/home_feed/data/section_mapper.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/data/section_mapper.dart)`
> Layer: `lib/features/home_feed/data`

## Executive Summary
`section_mapper.dart` is an essential file in `lib/features/home_feed/data` providing definitions for `SectionMapper`.
**Primary Architecture Role**: Parser / Data Mapper

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `home_feature_type.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/home_feature_type|home_feature_type.dart]] |
| `spotify_entity.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/spotify_entity|spotify_entity.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `casita_parser.dart` | `lib/features/home_feed/data` | [[04-Reference/lib/features/home_feed/data/casita_parser|casita_parser.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class SectionMapper`
- **Archetype**: Parser / Data Mapper

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `sectionId` | `final` |
| `featureType` | `final` |
| `items` | `final` |
| `title` | `final` |
| `items` | `final` |
| `title` | `final` |
| `items` | `final` |
| `title` | `final` |
| `items` | `final` |
| `items` | `final` |
| `title` | `final` |
| `items` | `final` |
| `title` | `final` |
| `items` | `final` |
| `title` | `final` |
| `items` | `final` |
| `uri` | `final` |
| `ep` | `final` |
| `thumbUrl` | `final` |
| `coverUrl` | `final` |
| `durationSec` | `int` |
| `durationStr` | `final` |
| `title` | `final` |
| `items` | `final` |
| `items` | `final` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:musify_mu/core/protocol/generated/spotify/casita/resolved.pb.dart' as casita;
import 'package:musify_mu/features/home_feed/domain/models/home_feature_type.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Direct equivalent to Spotify Android's `p.kw1` (`SectionMapper`).
/// Evaluates `section.whichFeatureType()` (featureTypeCase_) and instantiates
/// the corresponding `HomeFeatureType` (p.f410).
class SectionMapper {
  const SectionMapper();

  /// Maps a Casita Protobuf Section to its strongly typed HomeFeatureType (matches kw1.F).
  HomeFeatureType? mapSection(
    casita.Section section, {
    required List<SpotifyEntity> Function(casita.ItemSource) extractSource,
    required List<SpotifyEntity> Function(List<casita.Item>) extractList,
    required List<SpotifyEntity> Function(casita.Item) extractSingle,
    required String Function(casita.Heading heading, [String sectionId]) extractTitle,
    required void Function(String uri, Trait trait) storeTrait,
    required String? Function(String url) cleanImageUrl,
  }) {
    final sectionId = section.hasSectionInfo() ? section.sectionInfo.sectionId : '';
    final featureType = section.whichFeatureType();

    switch (featureType) {
      case casita.Section_FeatureType.shortcuts:
        final items = extractSource(section.shortcuts.itemSource);
        return ShortcutsFeatureType(id: sectionId, title: '', items: items);

      case casita.Section_FeatureType.imageLink:
        final title = extractTitle(section.imageLink.heading, sectionId);
        final items = extractSource(section.imageLink.itemSource);
        return ImageLinkFeatureType(
          id: sectionId,
          title: title,
          items: items,
          density: section.imageLink.density,
        );

      case casita.Section_FeatureType.preview:
        final title = extractTitle(section.preview.heading, sectionId);
        final items = extractSingle(section.preview.item);
        return PreviewFeatureType(id: sectionId, title: title, items: items);

      case casita.Section_FeatureType.immersivePreview:
        final title = extractTitle(section.immersivePreview.heading, sectionId);
// ... [remaining code in source file] ...
```
