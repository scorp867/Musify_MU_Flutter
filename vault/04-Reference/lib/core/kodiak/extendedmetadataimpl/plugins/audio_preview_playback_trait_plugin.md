---
title: "audio_preview_playback_trait_plugin.dart"
path: "lib/core/kodiak/extendedmetadataimpl/plugins/audio_preview_playback_trait_plugin.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, kodiak]
lines: 26
incoming_dependencies: 0
outgoing_dependencies: 2
---

# audio_preview_playback_trait_plugin.dart

> Source File: `[lib/core/kodiak/extendedmetadataimpl/plugins/audio_preview_playback_trait_plugin.dart](file:///c:/Users/Admin/Musify_MU/lib/core/kodiak/extendedmetadataimpl/plugins/audio_preview_playback_trait_plugin.dart)`
> Layer: `lib/core/kodiak/extendedmetadataimpl/plugins`

## Executive Summary
`audio_preview_playback_trait_plugin.dart` is an essential file in `lib/core/kodiak/extendedmetadataimpl/plugins` providing definitions for `AudioPreviewPlaybackTraitPlugin`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `extended_metadata_plugin.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/extended_metadata_plugin|extended_metadata_plugin.dart]] |
| `traits.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/traits|traits.dart]] |

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class AudioPreviewPlaybackTraitPlugin`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Implements**: `ExtendedMetadataPlugin<AudioPreviewPlaybackTrait>`

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `parse` | `AudioPreviewPlaybackTrait` | `Uint8List payload` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 116 (AUDIO_PREVIEW_PLAYBACK_TRAIT).
/// Equivalent to Spotify Android's `u17` decoder plugin.
class AudioPreviewPlaybackTraitPlugin
    implements ExtendedMetadataPlugin<AudioPreviewPlaybackTrait> {
  const AudioPreviewPlaybackTraitPlugin();

  @override
  Type get traitType => AudioPreviewPlaybackTrait;

  @override
  int get extensionKindValue => 116;

  @override
  ExtensionKind? get extensionKind =>
      ExtensionKind.AUDIO_PREVIEW_PLAYBACK_TRAIT;

  @override
  AudioPreviewPlaybackTrait parse(Uint8List payload) {
    return const AudioPreviewPlaybackTrait();
  }
}
```
