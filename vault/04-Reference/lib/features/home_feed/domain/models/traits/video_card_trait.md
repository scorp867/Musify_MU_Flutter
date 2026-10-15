---
title: "video_card_trait.dart"
path: "lib/features/home_feed/domain/models/traits/video_card_trait.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 44
incoming_dependencies: 0
outgoing_dependencies: 0
---

# video_card_trait.dart

> Source File: `[lib/features/home_feed/domain/models/traits/video_card_trait.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/traits/video_card_trait.dart)`
> Layer: `lib/features/home_feed/domain/models/traits`

## Executive Summary
`video_card_trait.dart` is an essential file in `lib/features/home_feed/domain/models/traits` providing definitions for `VideoCardTrait`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class VideoCardTrait`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Extends**: `Trait`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `title` | `String` |
| `subtitle` | `String` |
| `videoThumbnailUrl` | `String?` |
| `showArtworkUrl` | `String?` |
| `durationString` | `String` |
| `overline` | `String` |
| `isPlaying` | `bool` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `toJson` | `dynamic>` | `(none)` |
| `fromJson` | `dynamic` | `Map<String, dynamic> json` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'trait.dart';

/// Video card metadata for video podcasts and watch feed items.
/// Carries the 16:9 video thumbnail, square show artwork, and duration badge.
class VideoCardTrait extends Trait {
  final String title;
  final String subtitle;
  final String? videoThumbnailUrl;
  final String? showArtworkUrl;
  final String durationString;
  final String overline;
  final bool isPlaying;

  const VideoCardTrait({
    required this.title,
    this.subtitle = '',
    this.videoThumbnailUrl,
    this.showArtworkUrl,
    this.durationString = '',
    this.overline = '',
    this.isPlaying = false,
  });

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'videoThumbnailUrl': videoThumbnailUrl,
    'showArtworkUrl': showArtworkUrl,
    'durationString': durationString,
    'overline': overline,
    'isPlaying': isPlaying,
  };

  factory VideoCardTrait.fromJson(Map<String, dynamic> json) => VideoCardTrait(
    title: json['title'] ?? '',
    subtitle: json['subtitle'] ?? '',
    videoThumbnailUrl: json['videoThumbnailUrl'],
    showArtworkUrl: json['showArtworkUrl'],
    durationString: json['durationString'] ?? '',
    overline: json['overline'] ?? '',
    isPlaying: json['isPlaying'] ?? false,
  );
}
```
