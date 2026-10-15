---
title: "preview_playback_trait.dart"
path: "lib/features/home_feed/domain/models/traits/preview_playback_trait.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 44
incoming_dependencies: 0
outgoing_dependencies: 0
---

# preview_playback_trait.dart

> Source File: `[lib/features/home_feed/domain/models/traits/preview_playback_trait.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/traits/preview_playback_trait.dart)`
> Layer: `lib/features/home_feed/domain/models/traits`

## Executive Summary
`preview_playback_trait.dart` is an essential file in `lib/features/home_feed/domain/models/traits` providing definitions for `PreviewPlaybackTrait`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class PreviewPlaybackTrait`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Extends**: `Trait`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `uri` | `String` |
| `reportingUri` | `String` |
| `audioUrl` | `String` |
| `videoUrl` | `String` |
| `videoImageUrl` | `String` |
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

/// Content-agnostic preview playback (ExtensionKind 181).
/// Can hold either an audio or video preview.
class PreviewPlaybackTrait extends Trait {
  final String uri;
  final String reportingUri;
  final String audioUrl;
  final String videoUrl;
  final String videoImageUrl;
  final int durationMs;

  const PreviewPlaybackTrait({
    this.uri = '',
    this.reportingUri = '',
    this.audioUrl = '',
    this.videoUrl = '',
    this.videoImageUrl = '',
    this.durationMs = 0,
  });

  bool get hasAudio => audioUrl.isNotEmpty;
  bool get hasVideo => videoUrl.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
    'uri': uri,
    'reportingUri': reportingUri,
    'audioUrl': audioUrl,
    'videoUrl': videoUrl,
    'videoImageUrl': videoImageUrl,
    'durationMs': durationMs,
  };

  factory PreviewPlaybackTrait.fromJson(Map<String, dynamic> json) =>
      PreviewPlaybackTrait(
        uri: json['uri'] ?? '',
        reportingUri: json['reportingUri'] ?? '',
        audioUrl: json['audioUrl'] ?? '',
        videoUrl: json['videoUrl'] ?? '',
        videoImageUrl: json['videoImageUrl'] ?? '',
        durationMs: json['durationMs'] ?? 0,
      );
}
```
