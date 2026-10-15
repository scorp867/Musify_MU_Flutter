---
title: "color_lyrics_client.dart"
path: "lib/features/player/data/datasources/color_lyrics_client.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 65
incoming_dependencies: 2
outgoing_dependencies: 2
---

# color_lyrics_client.dart

> Source File: `[lib/features/player/data/datasources/color_lyrics_client.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/data/datasources/color_lyrics_client.dart)`
> Layer: `lib/features/player/data/datasources`

## Executive Summary
`color_lyrics_client.dart` is an essential file in `lib/features/player/data/datasources` providing definitions for `ColorLyricsClient`.
**Primary Architecture Role**: Data Source / Remote Client

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `network_priority.dart` | `lib/core/network/priority` | [[04-Reference/lib/core/network/priority/network_priority|network_priority.dart]] |
| `spotify_transport.dart` | `lib/core/network/spotify/transport` | [[04-Reference/lib/core/network/spotify/transport/spotify_transport|spotify_transport.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `color_lyrics_repository.dart` | `lib/features/player/data/repositories` | [[04-Reference/lib/features/player/data/repositories/color_lyrics_repository|color_lyrics_repository.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class ColorLyricsClient`
- **Archetype**: Data Source / Remote Client

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_transport` | `SpotifyTransport` |
| `vocalRemoval` | `bool` |
| `clientLanguage` | `String` |
| `preview` | `bool` |
| `query` | `final` |
| `path` | `final` |
| `bytes` | `final` |
| `null` | `return` |
| `null` | `return` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `getColorLyrics` | `Future<ColorLyricsResponse?>` | `{ required String trackId, bool vocalRemoval = ...` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:developer' as dev;
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';

/// Client for Spotify's Color Lyrics v2 service.
///
/// 1:1 replica of decompiled Retrofit interface:
/// `p/hq80.java` (`src_main_java_com_spotify_lyrics_serviceretrofit-serviceretrofit`).
///
/// Annotation contract:
/// ```java
/// @xo00({"Accept: application/protobuf"})
/// @cqy("color-lyrics/v2/track/{trackId}")
/// Single<ColorLyricsResponse> a(
///     @w1k0("trackId") String trackId,
///     @qrp0("vocalRemoval") boolean vocalRemoval,
///     @qrp0("clientLanguage") String clientLanguage,
///     @qrp0("preview") boolean isPreview
/// );
/// ```
class ColorLyricsClient {
  final SpotifyTransport _transport;

  static const String defaultHost = 'https://gae2-spclient.spotify.com';

  const ColorLyricsClient({required SpotifyTransport transport})
      : _transport = transport;

  /// Fetches lyrics with synchronized lines and extracted Spotify color scheme.
  Future<ColorLyricsResponse?> getColorLyrics({
    required String trackId,
    bool vocalRemoval = false,
    String clientLanguage = 'en_US',
    bool preview = false,
    String? host,
  }) async {
    final query = 'vocalRemoval=$vocalRemoval&clientLanguage=${Uri.encodeComponent(clientLanguage)}&preview=$preview';
    final path = 'color-lyrics/v2/track/$trackId?$query';

    try {
      final bytes = await _transport.get(
        path,
        baseHost: host ?? defaultHost,
        priority: NetworkPriority.interactive,
// ... [remaining code in source file] ...
```
