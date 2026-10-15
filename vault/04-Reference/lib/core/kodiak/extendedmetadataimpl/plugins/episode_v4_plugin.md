---
title: "episode_v4_plugin.dart"
path: "lib/core/kodiak/extendedmetadataimpl/plugins/episode_v4_plugin.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, kodiak]
lines: 71
incoming_dependencies: 0
outgoing_dependencies: 2
---

# episode_v4_plugin.dart

> Source File: `[lib/core/kodiak/extendedmetadataimpl/plugins/episode_v4_plugin.dart](file:///c:/Users/Admin/Musify_MU/lib/core/kodiak/extendedmetadataimpl/plugins/episode_v4_plugin.dart)`
> Layer: `lib/core/kodiak/extendedmetadataimpl/plugins`

## Executive Summary
`episode_v4_plugin.dart` is an essential file in `lib/core/kodiak/extendedmetadataimpl/plugins` providing definitions for `EpisodeV4Plugin`.
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
#### `class EpisodeV4Plugin`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Implements**: `ExtendedMetadataPlugin<EpisodeMetaTrait>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `ep` | `final` |
| `title` | `final` |
| `showName` | `final` |
| `duration` | `final` |
| `imageUrls` | `final` |
| `largeImageHex` | `String?` |
| `hex` | `final` |
| `url` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `parse` | `EpisodeMetaTrait` | `Uint8List payload` |
| `map` | `dynamic` | `(b` |
| `putIfAbsent` | `dynamic` | `'medium', (` |
| `map` | `dynamic` | `(b` |

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
import 'package:musify_mu/core/protocol/generated/spotify/metadata.pb.dart'
    as meta_pb;
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 12 (EPISODE_V4).
/// Provides complete podcast episode metadata matching Spotify Android's EpisodeV4 extension.
class EpisodeV4Plugin implements ExtendedMetadataPlugin<EpisodeMetaTrait> {
  const EpisodeV4Plugin();

  @override
  Type get traitType => EpisodeMetaTrait;

  @override
  int get extensionKindValue => 12;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.EPISODE_V4;

  @override
  EpisodeMetaTrait parse(Uint8List payload) {
    final ep = meta_pb.Episode.fromBuffer(payload);
    final title = ep.name;
    final showName =
        (ep.hasShow() && ep.show.hasName()) ? ep.show.name : '';
    final duration = ep.hasDuration() ? ep.duration : 0;

    final imageUrls = <String, String>{};
    String? largeImageHex;

    if (ep.hasCoverImage()) {
      for (final image in ep.coverImage.image) {
        if (!image.hasFileId() || image.fileId.isEmpty) continue;
        final hex = image.fileId
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        final url = 'https://i.scdn.co/image/$hex';

        switch (image.size) {
          case meta_pb.Image_Size.SMALL:
            imageUrls['small'] = url;
            break;
          case meta_pb.Image_Size.LARGE:
// ... [remaining code in source file] ...
```
