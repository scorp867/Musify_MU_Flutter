---
title: "track_v4_plugin.dart"
path: "lib/core/kodiak/extendedmetadataimpl/plugins/track_v4_plugin.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, kodiak]
lines: 73
incoming_dependencies: 0
outgoing_dependencies: 2
---

# track_v4_plugin.dart

> Source File: `[lib/core/kodiak/extendedmetadataimpl/plugins/track_v4_plugin.dart](file:///c:/Users/Admin/Musify_MU/lib/core/kodiak/extendedmetadataimpl/plugins/track_v4_plugin.dart)`
> Layer: `lib/core/kodiak/extendedmetadataimpl/plugins`

## Executive Summary
`track_v4_plugin.dart` is an essential file in `lib/core/kodiak/extendedmetadataimpl/plugins` providing definitions for `TrackV4Plugin`.
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
#### `class TrackV4Plugin`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Implements**: `ExtendedMetadataPlugin<TrackMetaTrait>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `track` | `final` |
| `title` | `final` |
| `artists` | `final` |
| `subtitle` | `final` |
| `albumName` | `final` |
| `duration` | `final` |
| `imageUrls` | `final` |
| `largeImageHex` | `String?` |
| `hex` | `final` |
| `url` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `parse` | `TrackMetaTrait` | `Uint8List payload` |
| `map` | `dynamic` | `(a` |
| `where` | `dynamic` | `(n` |
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

/// Plugin for ExtensionKind 10 (TRACK_V4).
/// Provides complete track metadata matching Spotify Android's TrackV4 extension.
class TrackV4Plugin implements ExtendedMetadataPlugin<TrackMetaTrait> {
  const TrackV4Plugin();

  @override
  Type get traitType => TrackMetaTrait;

  @override
  int get extensionKindValue => 10;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.TRACK_V4;

  @override
  TrackMetaTrait parse(Uint8List payload) {
    final track = meta_pb.Track.fromBuffer(payload);
    final title = track.name;
    final artists = track.artist.map((a) => a.name).where((n) => n.isNotEmpty);
    final subtitle = artists.join(', ');
    final albumName = track.hasAlbum() ? track.album.name : '';
    final duration = track.hasDuration() ? track.duration : 0;

    final imageUrls = <String, String>{};
    String? largeImageHex;

    if (track.hasAlbum() && track.album.hasCoverGroup()) {
      for (final image in track.album.coverGroup.image) {
        if (!image.hasFileId() || image.fileId.isEmpty) continue;
        final hex = image.fileId
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        final url = 'https://i.scdn.co/image/$hex';

        switch (image.size) {
          case meta_pb.Image_Size.SMALL:
            imageUrls['small'] = url;
            break;
// ... [remaining code in source file] ...
```
