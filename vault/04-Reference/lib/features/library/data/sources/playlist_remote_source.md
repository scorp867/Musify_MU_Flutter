---
title: "playlist_remote_source.dart"
path: "lib/features/library/data/sources/playlist_remote_source.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, library]
lines: 40
incoming_dependencies: 2
outgoing_dependencies: 1
---

# playlist_remote_source.dart

> Source File: `[lib/features/library/data/sources/playlist_remote_source.dart](file:///c:/Users/Admin/Musify_MU/lib/features/library/data/sources/playlist_remote_source.dart)`
> Layer: `lib/features/library/data/sources`

## Executive Summary
`playlist_remote_source.dart` is an essential file in `lib/features/library/data/sources` providing definitions for `PlaylistRemoteSource`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `spotify_transport.dart` | `lib/core/network/spotify/transport` | [[04-Reference/lib/core/network/spotify/transport/spotify_transport|spotify_transport.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `library_repository_impl.dart` | `lib/features/library/data/repository` | [[04-Reference/lib/features/library/data/repository/library_repository_impl|library_repository_impl.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class PlaylistRemoteSource`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_client` | `SpotifyTransport` |
| `encodedRev` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `fetchFull` | `Future<Uint8List?>` | `String playlistId, {CancelToken? cancelToken}` |
| `fetchDiff` | `Future<Uint8List?>` | `String playlistId, String revision, { CancelTok...` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';

/// Network layer for playlist full-fetch and diff endpoints.
/// Returns raw bytes. No parsing, no business logic.
class PlaylistRemoteSource {
  final SpotifyTransport _client;

  const PlaylistRemoteSource({required SpotifyTransport client})
      : _client = client;

  /// GET /playlist/v2/playlist/{id} -> full snapshot bytes.
  Future<Uint8List?> fetchFull(String playlistId, {CancelToken? cancelToken}) {
    return _client.get(
      '/playlist/v2/playlist/$playlistId',
      tag: 'playlist_$playlistId',
      ttl: const Duration(seconds: 45),
      cancelToken: cancelToken,
    );
  }

  /// GET /playlist/v2/playlist/{id}/diff?revision={rev} -> diff bytes.
  Future<Uint8List?> fetchDiff(
    String playlistId,
    String revision, {
    CancelToken? cancelToken,
  }) {
    final encodedRev = Uri.encodeComponent(revision);
    return _client.get(
      '/playlist/v2/playlist/$playlistId/diff'
      '?revision=$encodedRev'
      '&handlesContent=',
      tag: 'playlist_diff_$playlistId',
      ttl: const Duration(seconds: 45),
      cancelToken: cancelToken,
    );
  }
}
```
