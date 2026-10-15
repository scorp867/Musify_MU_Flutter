---
title: "episode_meta_trait.dart"
path: "lib/features/home_feed/domain/models/traits/episode_meta_trait.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 27
incoming_dependencies: 0
outgoing_dependencies: 0
---

# episode_meta_trait.dart

> Source File: `[lib/features/home_feed/domain/models/traits/episode_meta_trait.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/traits/episode_meta_trait.dart)`
> Layer: `lib/features/home_feed/domain/models/traits`

## Executive Summary
`episode_meta_trait.dart` is an essential file in `lib/features/home_feed/domain/models/traits` providing definitions for `EpisodeMetaTrait`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class EpisodeMetaTrait`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Extends**: `TrackMetaTrait`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `meta` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `fromJson` | `dynamic` | `Map<String, dynamic> json` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'track_meta_trait.dart';

/// ExtensionKind 12 (EPISODE_V4).
class EpisodeMetaTrait extends TrackMetaTrait {
  const EpisodeMetaTrait({
    required super.uri,
    super.title,
    super.subtitle,
    super.albumName,
    super.imageUrls,
    super.largeImageHex,
    super.durationMs,
  });

  factory EpisodeMetaTrait.fromJson(Map<String, dynamic> json) {
    final meta = TrackMetaTrait.fromJson(json);
    return EpisodeMetaTrait(
      uri: meta.uri,
      title: meta.title,
      subtitle: meta.subtitle,
      albumName: meta.albumName,
      imageUrls: meta.imageUrls,
      largeImageHex: meta.largeImageHex,
      durationMs: meta.durationMs,
    );
  }
}
```
