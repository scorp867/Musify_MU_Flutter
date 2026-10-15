---
title: "library_mapper.dart"
path: "lib/features/library/data/mappers/library_mapper.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, library]
lines: 198
incoming_dependencies: 2
outgoing_dependencies: 1
---

# library_mapper.dart

> Source File: `[lib/features/library/data/mappers/library_mapper.dart](file:///c:/Users/Admin/Musify_MU/lib/features/library/data/mappers/library_mapper.dart)`
> Layer: `lib/features/library/data/mappers`

## Executive Summary
`library_mapper.dart` is an essential file in `lib/features/library/data/mappers` providing definitions for `LibraryMapper`.
**Primary Architecture Role**: Parser / Data Mapper

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `library_item.dart` | `lib/features/library/domain/models` | [[04-Reference/lib/features/library/domain/models/library_item|library_item.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `library_decorator.dart` | `lib/features/library/data/repository` | [[04-Reference/lib/features/library/data/repository/library_decorator|library_decorator.dart]] |
| `library_repository_impl.dart` | `lib/features/library/data/repository` | [[04-Reference/lib/features/library/data/repository/library_repository_impl|library_repository_impl.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class LibraryMapper`
- **Archetype**: Parser / Data Mapper

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `response` | `final` |
| `items` | `final` |
| `listItems` | `final` |
| `metaItems` | `final` |
| `item` | `final` |
| `uri` | `final` |
| `meta` | `final` |
| `name` | `final` |
| `owner` | `final` |
| `timestamp` | `final` |
| `imageUrl` | `String?` |
| `items` | `return` |
| `response` | `final` |
| `items` | `final` |
| `uri` | `final` |
| `addedAt` | `final` |
| `items` | `return` |
| `response` | `final` |
| `nameMap` | `final` |
| `imageMap` | `final` |
| `kind` | `final` |
| `uri` | `final` |
| `payload` | `final` |
| `trait` | `final` |
| `artist` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `parseRootlist` | `List<LibraryItem>` | `Uint8List bytes` |
| `parseCollection` | `List<LibraryItem>` | `Uint8List bytes, String setName,` |
| `parseArtistDecorations` | `List<LibraryItem>` | `List<LibraryItem> artists, Uint8List data,` |
| `reduce` | `dynamic` | `(a, b` |
| `map` | `dynamic` | `(b` |
| `map` | `dynamic` | `(item` |
| `_typeFromUri` | `String` | `String uri` |
| `_nameFromUri` | `String` | `String uri` |
| `_playlistNameFromUri` | `String` | `String uri` |
| `_extractCoverFromAttributes` | `String?` | `rootlist_pb.ListAttributes attrs,` |
| `map` | `dynamic` | `(b` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Background Isolate execution: arguments and return payloads must strictly cross isolate boundaries.

## Implementation Highlight
```dart
import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:musify_mu/core/protocol/generated/spotify/collection/collection_paging.pb.dart'
    as col_pb;
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/identity_trait.pb.dart'
    as identity_pb;
import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/protocol/generated/spotify/metadata.pb.dart'
    as meta_pb;
import 'package:musify_mu/core/protocol/generated/spotify/playlist/rootlist.pb.dart'
    as rootlist_pb;
import 'package:musify_mu/features/library/domain/models/library_item.dart';

/// Converts protobuf library bytes into domain types.
/// All proto knowledge for rootlist/collection/artist is confined here.
class LibraryMapper {
  const LibraryMapper._();

  /// Parses rootlist protobuf into [LibraryItem] list. Isolate-safe.
  static List<LibraryItem> parseRootlist(Uint8List bytes) {
    final response = rootlist_pb.SelectedListContent.fromBuffer(bytes);
    final items = <LibraryItem>[];

    final listItems = response.contents.items;
    final metaItems = response.contents.metaItems;

    for (var i = 0; i < listItems.length; i++) {
      final item = listItems[i];
      final uri = item.uri;
      if (uri.isEmpty) continue;

      final meta = (i < metaItems.length) ? metaItems[i] : null;
      final name = meta?.attributes.name ?? _playlistNameFromUri(uri);
      final owner = meta?.ownerUsername ?? '';
      final timestamp = meta?.timestamp.toInt() ?? 0;

      String? imageUrl;
      if (meta != null) {
        imageUrl = _extractCoverFromAttributes(meta.attributes);
      }

      items.add(LibraryItem(
        uri: uri,
// ... [remaining code in source file] ...
```
