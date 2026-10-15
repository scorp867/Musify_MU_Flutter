---
title: "spotify_token_refresher.dart"
path: "lib/core/network/spotify/auth/spotify_token_refresher.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, network]
lines: 160
incoming_dependencies: 4
outgoing_dependencies: 2
---

# spotify_token_refresher.dart

> Source File: `[lib/core/network/spotify/auth/spotify_token_refresher.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/spotify/auth/spotify_token_refresher.dart)`
> Layer: `lib/core/network/spotify/auth`

## Executive Summary
`spotify_token_refresher.dart` is an essential file in `lib/core/network/spotify/auth` providing definitions for `SpotifyTokenRefresher`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `spotify_totp.dart` | `lib/core/network/spotify/auth` | [[04-Reference/lib/core/network/spotify/auth/spotify_totp|spotify_totp.dart]] |
| `spotify_token_store.dart` | `lib/core/network/spotify/auth` | [[04-Reference/lib/core/network/spotify/auth/spotify_token_store|spotify_token_store.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `auth_bloc.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_bloc|auth_bloc.dart]] |
| `auth_session_provider.dart` | `lib/core/network/spotify/auth` | [[04-Reference/lib/core/network/spotify/auth/auth_session_provider|auth_session_provider.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `auth_bloc_test.dart` | `test/features/auth` | [[04-Reference/test/features/auth/auth_bloc_test|auth_bloc_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class SpotifyTokenRefresher`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_tokenStore` | `SpotifyTokenStore` |
| `_totp` | `SpotifyTotp` |
| `spDc` | `final` |
| `null` | `return` |
| `null` | `return` |
| `result` | `var` |
| `result` | `return` |
| `result` | `return` |
| `serverTimeMs` | `final` |
| `null` | `return` |
| `localTimeMs` | `final` |
| `totpLocal` | `final` |
| `totpServer` | `final` |
| `version` | `final` |
| `url` | `final` |
| `response` | `final` |
| `null` | `return` |
| `body` | `final` |
| `accessToken` | `final` |
| `isAnonymous` | `final` |
| `null` | `return` |
| `expiresMs` | `final` |
| `lifetimeMs` | `final` |
| `accessToken` | `return` |
| `null` | `return` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `refresh` | `Future<String?>` | `(none)` |
| `_attemptRefresh` | `Future<String?>` | `String spDc` |
| `_fetchServerTimeMs` | `Future<int?>` | `(none)` |

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
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:musify_mu/core/network/spotify/auth/spotify_totp.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';

/// Refreshes the Spotify Web Player access token using the sp_dc cookie + TOTP.
///
/// Flow:
/// 1. Fetch Spotify's server time to avoid clock skew.
/// 2. Generate TOTP codes (local + server time).
/// 3. Call `GET /api/token` with sp_dc cookie + TOTP params.
/// 4. If 401/403 -> cipher was rotated -> refresh cipher -> retry once.
class SpotifyTokenRefresher {
  final SpotifyTokenStore _tokenStore;
  final SpotifyTotp _totp;

  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36';

  SpotifyTokenRefresher({
    required SpotifyTokenStore tokenStore,
    SpotifyTotp? totp,
  })  : _tokenStore = tokenStore,
        _totp = totp ?? SpotifyTotp();

  /// Attempts to refresh the access token.
  /// Returns the new token on success, or null on failure.
  Future<String?> refresh() async {
    final spDc = await _tokenStore.getSpDc();
    if (spDc == null || spDc.isEmpty) {
      dev.log('TokenRefresh: No sp_dc cookie stored', name: 'Auth');
      return null;
    }

    // Validate the sp_dc is a real cookie value, not a placeholder.
    if (!spDc.startsWith('sp_dc=') || spDc.length < 20) {
      dev.log(
        'TokenRefresh: Invalid sp_dc format: '
        '${spDc.substring(0, spDc.length.clamp(0, 20))}...',
        name: 'Auth',
      );
// ... [remaining code in source file] ...
```
