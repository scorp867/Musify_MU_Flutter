---
title: "audio_preview_playback_trait.dart"
path: "lib/features/home_feed/domain/models/traits/audio_preview_playback_trait.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 50
incoming_dependencies: 0
outgoing_dependencies: 0
---

# audio_preview_playback_trait.dart

> Source File: `[lib/features/home_feed/domain/models/traits/audio_preview_playback_trait.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/traits/audio_preview_playback_trait.dart)`
> Layer: `lib/features/home_feed/domain/models/traits`

## Executive Summary
`audio_preview_playback_trait.dart` is an essential file in `lib/features/home_feed/domain/models/traits` providing definitions for `AudioPreviewPlaybackTrait`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class AudioPreviewPlaybackTrait`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Extends**: `Trait`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `audioFileUrl` | `String` |
| `transcriptUrl` | `String` |
| `videoFileId` | `String` |
| `videoPlaceholderImageUrl` | `String` |
| `previewDurationMs` | `int` |
| `durationFromOriginalMs` | `int` |
| `previewStreamReportingUri` | `String` |
| `previewRestriction` | `int` |

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

/// Audio preview playback data (ExtensionKind 116).
/// Provides audio file URL, duration, and preview metadata for
/// sections like AudioSpotlight, AudioPromo, and ImmersivePreview.
class AudioPreviewPlaybackTrait extends Trait {
  final String audioFileUrl;
  final String transcriptUrl;
  final String videoFileId;
  final String videoPlaceholderImageUrl;
  final int previewDurationMs;
  final int durationFromOriginalMs;
  final String previewStreamReportingUri;
  final int previewRestriction;

  const AudioPreviewPlaybackTrait({
    this.audioFileUrl = '',
    this.transcriptUrl = '',
    this.videoFileId = '',
    this.videoPlaceholderImageUrl = '',
    this.previewDurationMs = 0,
    this.durationFromOriginalMs = 0,
    this.previewStreamReportingUri = '',
    this.previewRestriction = 0,
  });

  @override
  Map<String, dynamic> toJson() => {
    'audioFileUrl': audioFileUrl,
    'transcriptUrl': transcriptUrl,
    'videoFileId': videoFileId,
    'videoPlaceholderImageUrl': videoPlaceholderImageUrl,
    'previewDurationMs': previewDurationMs,
    'durationFromOriginalMs': durationFromOriginalMs,
    'previewStreamReportingUri': previewStreamReportingUri,
    'previewRestriction': previewRestriction,
  };

  factory AudioPreviewPlaybackTrait.fromJson(Map<String, dynamic> json) =>
      AudioPreviewPlaybackTrait(
        audioFileUrl: json['audioFileUrl'] ?? '',
        transcriptUrl: json['transcriptUrl'] ?? '',
        videoFileId: json['videoFileId'] ?? '',
        videoPlaceholderImageUrl: json['videoPlaceholderImageUrl'] ?? '',
        previewDurationMs: json['previewDurationMs'] ?? 0,
// ... [remaining code in source file] ...
```
