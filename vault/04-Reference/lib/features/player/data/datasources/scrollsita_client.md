---
title: "scrollsita_client.dart"
path: "lib/features/player/data/datasources/scrollsita_client.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 98
incoming_dependencies: 2
outgoing_dependencies: 2
---

# scrollsita_client.dart

> Source File: `[lib/features/player/data/datasources/scrollsita_client.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/data/datasources/scrollsita_client.dart)`
> Layer: `lib/features/player/data/datasources`

## Executive Summary
`scrollsita_client.dart` is an essential file in `lib/features/player/data/datasources` providing definitions for `ScrollSitaClient`.
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
| `scrollsita_repository.dart` | `lib/features/player/data/repositories` | [[04-Reference/lib/features/player/data/repositories/scrollsita_repository|scrollsita_repository.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class ScrollSitaClient`
- **Archetype**: Data Source / Remote Client

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_transport` | `SpotifyTransport` |
| `isEnhancedContext` | `bool` |
| `isPersonalizedContext` | `bool` |
| `isTablet` | `bool` |
| `isAiDjContext` | `bool` |
| `isVideoLayerActive` | `bool` |
| `tz` | `final` |
| `queryParams` | `final` |
| `queryString` | `final` |
| `path` | `final` |
| `bytes` | `final` |
| `null` | `return` |
| `null` | `return` |
| `name` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `getNpvScroll` | `Future<NpvScrollResponse?>` | `{ required String nowPlayingUri, String? playCo...` |
| `map` | `dynamic` | `(e` |
| `_resolveIanaTimezone` | `String` | `(none)` |

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
import 'package:musify_mu/core/protocol/generated/spotify/scrollsita/v1/scrollsita.pb.dart';

/// Client for Spotify's Scrollsita endpoint.
///
/// 1:1 replica of decompiled Retrofit interface:
/// `p/epu0.java` (`src_main_java_com_spotify_nowplaying_scrollsection_nova-nova`).
///
/// Annotation contract:
/// ```java
/// @xo00({"Content-Type: application/x-protobuf", "Accept: application/protobuf"})
/// @cqy("scrollsita/v1/scroll/{now_playing_uri}")
/// Single<NpvScrollResponse> a(...);
/// ```
class ScrollSitaClient {
  final SpotifyTransport _transport;

  static const String baseHost = 'https://gae2-spclient.spotify.com';

  const ScrollSitaClient({required SpotifyTransport transport})
      : _transport = transport;

  /// Fetches the ordered scroll sections for the current track.
  Future<NpvScrollResponse?> getNpvScroll({
    required String nowPlayingUri,
    String? playContextUri,
    bool isEnhancedContext = false,
    bool isPersonalizedContext = true,
    bool isTablet = false,
    bool isAiDjContext = false,
    bool isVideoLayerActive = false,
    String? timezone,
  }) async {
    final tz = timezone ?? _resolveIanaTimezone();
    final queryParams = <String, String>{
      if (playContextUri != null && playContextUri.isNotEmpty)
        'play_context_uri': playContextUri,
      'is_enhanced_context': isEnhancedContext.toString(),
      'is_personalized_context': isPersonalizedContext.toString(),
      'is_tablet': isTablet.toString(),
      'is_ai_dj_context': isAiDjContext.toString(),
      'is_video_layer_active': isVideoLayerActive.toString(),
      'timezone': tz,
// ... [remaining code in source file] ...
```
