---
title: "spotify_profile_fetcher.dart"
path: "lib/features/auth/data/spotify_profile_fetcher.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, auth]
lines: 132
incoming_dependencies: 3
outgoing_dependencies: 6
---

# spotify_profile_fetcher.dart

> Source File: `[lib/features/auth/data/spotify_profile_fetcher.dart](file:///c:/Users/Admin/Musify_MU/lib/features/auth/data/spotify_profile_fetcher.dart)`
> Layer: `lib/features/auth/data`

## Executive Summary
`spotify_profile_fetcher.dart` is an essential file in `lib/features/auth/data` providing definitions for `SpotifyProfileFetcher`.
**Primary Architecture Role**: Data Source / Remote Client

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `runtime_context.dart` | `lib/core/config` | [[04-Reference/lib/core/config/runtime_context|runtime_context.dart]] |
| `network_priority.dart` | `lib/core/network/priority` | [[04-Reference/lib/core/network/priority/network_priority|network_priority.dart]] |
| `network_result.dart` | `lib/core/network/result` | [[04-Reference/lib/core/network/result/network_result|network_result.dart]] |
| `spotify_token_store.dart` | `lib/core/network/spotify/auth` | [[04-Reference/lib/core/network/spotify/auth/spotify_token_store|spotify_token_store.dart]] |
| `spotify_transport.dart` | `lib/core/network/spotify/transport` | [[04-Reference/lib/core/network/spotify/transport/spotify_transport|spotify_transport.dart]] |
| `spotify_user.dart` | `lib/features/auth/domain/entities` | [[04-Reference/lib/features/auth/domain/entities/spotify_user|spotify_user.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `auth_bloc.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_bloc|auth_bloc.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `auth_bloc_test.dart` | `test/features/auth` | [[04-Reference/test/features/auth/auth_bloc_test|auth_bloc_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class SpotifyProfileFetcher`
- **Archetype**: Data Source / Remote Client

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_transport` | `SpotifyTransport` |
| `_tokenStore` | `SpotifyTokenStore` |
| `_ctx` | `RuntimeContext` |
| `body` | `final` |
| `bodyBytes` | `final` |
| `result` | `final` |
| `null` | `return` |
| `responseBytes` | `final` |
| `jsonStr` | `final` |
| `json` | `final` |
| `data` | `final` |
| `me` | `final` |
| `profileData` | `final` |
| `username` | `final` |
| `displayName` | `final` |
| `avatarUrl` | `final` |
| `country` | `final` |
| `product` | `final` |
| `null` | `return` |
| `avatar` | `final` |
| `sources` | `final` |
| `null` | `return` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `fetchProfile` | `Future<SpotifyUser?>` | `(none)` |
| `_extractAvatarUrl` | `String?` | `Map<String, dynamic> profile` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/result/network_result.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';
import 'package:musify_mu/features/auth/domain/entities/spotify_user.dart';

/// Fetches the current user's Spotify profile using Pathfinder (GQL).
///
/// Uses the managed [SpotifyTransport] with dynamic host routing to
/// `https://api-partner.spotify.com`, automatically benefiting from
/// keep-alive connection reuse, mutex 401 token refresh, and diagnostic logging.
class SpotifyProfileFetcher {
  final SpotifyTransport _transport;
  final SpotifyTokenStore _tokenStore;
  final RuntimeContext _ctx;

  static const _profileHashV1 =
      '53bcb064f6cd18c23f752bc324a791194d20df612d8e1239c735144ab0399ced';
  static const _apiPartnerHost = 'https://api-partner.spotify.com';

  SpotifyProfileFetcher({
    required SpotifyTransport transport,
    required RuntimeContext ctx,
    required SpotifyTokenStore tokenStore,
  })  : _transport = transport,
        _ctx = ctx,
        _tokenStore = tokenStore;

  /// Fetches and caches the current user's profile.
  /// Returns a [SpotifyUser] on success, null on failure.
  Future<SpotifyUser?> fetchProfile() async {
    try {
      final body = jsonEncode({
        'variables': <String, dynamic>{},
        'operationName': 'profileAttributes',
        'extensions': {
          'persistedQuery': {
            'version': 1,
            'sha256Hash': _profileHashV1,
          },
// ... [remaining code in source file] ...
```
