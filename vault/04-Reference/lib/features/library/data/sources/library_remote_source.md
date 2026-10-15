---
title: "library_remote_source.dart"
path: "lib/features/library/data/sources/library_remote_source.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, library]
lines: 101
incoming_dependencies: 3
outgoing_dependencies: 3
---

# library_remote_source.dart

> Source File: `[lib/features/library/data/sources/library_remote_source.dart](file:///c:/Users/Admin/Musify_MU/lib/features/library/data/sources/library_remote_source.dart)`
> Layer: `lib/features/library/data/sources`

## Executive Summary
`library_remote_source.dart` is an essential file in `lib/features/library/data/sources` providing definitions for `LibraryRemoteSource`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `runtime_context.dart` | `lib/core/config` | [[04-Reference/lib/core/config/runtime_context|runtime_context.dart]] |
| `network_priority.dart` | `lib/core/network/priority` | [[04-Reference/lib/core/network/priority/network_priority|network_priority.dart]] |
| `spotify_transport.dart` | `lib/core/network/spotify/transport` | [[04-Reference/lib/core/network/spotify/transport/spotify_transport|spotify_transport.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `library_decorator.dart` | `lib/features/library/data/repository` | [[04-Reference/lib/features/library/data/repository/library_decorator|library_decorator.dart]] |
| `library_repository_impl.dart` | `lib/features/library/data/repository` | [[04-Reference/lib/features/library/data/repository/library_repository_impl|library_repository_impl.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class LibraryRemoteSource`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_webTransport` | `SpotifyTransport` |
| `_androidTransport` | `SpotifyTransport` |
| `_ctx` | `RuntimeContext` |
| `_userId` | `String` |
| `path` | `final` |
| `request` | `final` |
| `taskId` | `final` |
| `request` | `final` |
| `entityReq` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `fetchRootlist` | `Future<Uint8List?>` | `{CancelToken? cancelToken}` |
| `fetchCollection` | `Future<Uint8List?>` | `String setName, {CancelToken? cancelToken}` |
| `fetchArtistDecorations` | `Future<Uint8List?>` | `List<String> uris` |
| `generate` | `dynamic` | `16, (_` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/protocol/generated/spotify/collection/collection_paging.pb.dart'
    as col_pb;
import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';

/// Network layer for library structure endpoints (rootlist, collections,
/// artist decorations). Returns raw bytes. No parsing, no business logic.
class LibraryRemoteSource {
  final SpotifyTransport _webTransport;
  final SpotifyTransport _androidTransport;
  final RuntimeContext _ctx;
  final String _userId;

  const LibraryRemoteSource({
    required SpotifyTransport webTransport,
    required SpotifyTransport androidTransport,
    required RuntimeContext ctx,
    required String userId,
  })  : _webTransport = webTransport,
        _androidTransport = androidTransport,
        _ctx = ctx,
        _userId = userId;

  /// GET rootlist -> raw protobuf bytes.
  Future<Uint8List?> fetchRootlist({CancelToken? cancelToken}) {
    final path =
        '/playlist/v2/user/$_userId/rootlist'
        '?decorate=revision%2Cattributes%2Clength%2Cowner%2Ccapabilities'
        '%2Cstatus_code%2Ctimestamp'
        '&from=0&length=120';

    return _androidTransport.get(
      path,
      tag: 'library_rootlist_$_userId',
      ttl: const Duration(seconds: 45),
      cancelToken: cancelToken,
      extraHeaders: {
        'spotify-playlist-sync-reason': 'CAU=',
// ... [remaining code in source file] ...
```
