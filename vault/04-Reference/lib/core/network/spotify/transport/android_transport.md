---
title: "android_transport.dart"
path: "lib/core/network/spotify/transport/android_transport.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, network]
lines: 44
incoming_dependencies: 1
outgoing_dependencies: 2
---

# android_transport.dart

> Source File: `[lib/core/network/spotify/transport/android_transport.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/spotify/transport/android_transport.dart)`
> Layer: `lib/core/network/spotify/transport`

## Executive Summary
`android_transport.dart` is an essential file in `lib/core/network/spotify/transport` providing definitions for `AndroidTransport`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `runtime_context.dart` | `lib/core/config` | [[04-Reference/lib/core/config/runtime_context|runtime_context.dart]] |
| `base_spotify_transport.dart` | `lib/core/network/spotify/transport` | [[04-Reference/lib/core/network/spotify/transport/base_spotify_transport|base_spotify_transport.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class AndroidTransport`
- **Archetype**: Core Component
- **Extends**: `BaseSpotifyTransport`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_ctx` | `RuntimeContext` |
| `accessToken` | `final` |
| `clientToken` | `final` |
| `profile` | `final` |
| `headers` | `final` |
| `headers` | `return` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `buildHeaders` | `String>>` | `Map<String, String>? extra` |
| `removeWhere` | `dynamic` | `(k, _` |
| `removeWhere` | `dynamic` | `(_, v` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Token refresh mutex active: serializes asynchronous 401 recovery; deadlock risk if refresh throws unhandled.

## Implementation Highlight
```dart
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/network/spotify/transport/base_spotify_transport.dart';

/// Spotify transport using Android app identity headers.
///
/// Used by endpoints that reject WebPlayer identity, such as
/// the rootlist endpoint for fetching the user's playlist library.
class AndroidTransport extends BaseSpotifyTransport {
  final RuntimeContext _ctx;

  AndroidTransport({
    required super.auth,
    required super.client,
    required RuntimeContext ctx,
    super.refreshMutex,
  }) : _ctx = ctx;

  @override
  Future<Map<String, String>> buildHeaders(Map<String, String>? extra) async {
    final accessToken = await auth.getAccessToken();
    final clientToken = await auth.getClientToken();
    final profile = DeviceProfile.android;

    final headers = <String, String>{
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      'client-token': ?clientToken,
      'accept': 'application/x-protobuf',
      'accept-language': _ctx.acceptLanguage,
      'app-platform': profile.appPlatform,
      'spotify-app-version': profile.appVersion,
      'User-Agent': profile.userAgent,
      'cache-control': 'no-cache, no-store',
    };

    if (extra != null) {
      for (final entry in extra.entries) {
        headers.removeWhere((k, _) => k.toLowerCase() == entry.key.toLowerCase());
        headers[entry.key] = entry.value;
      }
    }
    headers.removeWhere((_, v) => v.isEmpty);
    return headers;
  }
}
```
