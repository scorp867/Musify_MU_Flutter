---
title: "track_meta_trait.dart"
path: "lib/features/home_feed/domain/models/traits/track_meta_trait.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 49
incoming_dependencies: 1
outgoing_dependencies: 0
---

# track_meta_trait.dart

> Source File: `[lib/features/home_feed/domain/models/traits/track_meta_trait.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/traits/track_meta_trait.dart)`
> Layer: `lib/features/home_feed/domain/models/traits`

## Executive Summary
`track_meta_trait.dart` is an essential file in `lib/features/home_feed/domain/models/traits` providing definitions for `TrackMetaTrait`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `scroll_card_descriptor.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/scroll_card_descriptor|scroll_card_descriptor.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class TrackMetaTrait`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Extends**: `Trait`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `uri` | `String` |
| `title` | `String` |
| `subtitle` | `String` |
| `albumName` | `String` |
| `largeImageHex` | `String?` |
| `durationMs` | `int` |

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

/// Metadata for tracks and episodes (ExtensionKind 10 TRACK_V4, ExtensionKind 12 EPISODE_V4).
class TrackMetaTrait extends Trait {
  final String uri;
  final String title;
  final String subtitle;
  final String albumName;
  final Map<String, String> imageUrls;
  final String? largeImageHex;
  final int durationMs;

  String get imageUrl =>
      imageUrls['large'] ??
      imageUrls['medium'] ??
      imageUrls['small'] ??
      '';

  const TrackMetaTrait({
    required this.uri,
    this.title = '',
    this.subtitle = '',
    this.albumName = '',
    this.imageUrls = const {},
    this.largeImageHex,
    this.durationMs = 0,
  });

  @override
  Map<String, dynamic> toJson() => {
    'uri': uri,
    'title': title,
    'subtitle': subtitle,
    'albumName': albumName,
    'imageUrls': imageUrls,
    if (largeImageHex != null) 'largeImageHex': largeImageHex,
    'durationMs': durationMs,
  };

  factory TrackMetaTrait.fromJson(Map<String, dynamic> json) => TrackMetaTrait(
    uri: json['uri'] ?? '',
    title: json['title'] ?? '',
    subtitle: json['subtitle'] ?? '',
    albumName: json['albumName'] ?? '',
    imageUrls: Map<String, String>.from(json['imageUrls'] ?? const {}),
// ... [remaining code in source file] ...
```
