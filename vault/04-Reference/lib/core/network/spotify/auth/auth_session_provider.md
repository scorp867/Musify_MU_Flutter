---
title: "auth_session_provider.dart"
path: "lib/core/network/spotify/auth/auth_session_provider.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, network]
lines: 45
incoming_dependencies: 2
outgoing_dependencies: 3
---

# auth_session_provider.dart

> Source File: `[lib/core/network/spotify/auth/auth_session_provider.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/spotify/auth/auth_session_provider.dart)`
> Layer: `lib/core/network/spotify/auth`

## Executive Summary
`auth_session_provider.dart` is an essential file in `lib/core/network/spotify/auth` providing definitions for `AuthSessionProvider`, `SpotifyAuthSessionProvider`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `spotify_client_token.dart` | `lib/core/network/spotify/auth` | [[04-Reference/lib/core/network/spotify/auth/spotify_client_token|spotify_client_token.dart]] |
| `spotify_token_refresher.dart` | `lib/core/network/spotify/auth` | [[04-Reference/lib/core/network/spotify/auth/spotify_token_refresher|spotify_token_refresher.dart]] |
| `spotify_token_store.dart` | `lib/core/network/spotify/auth` | [[04-Reference/lib/core/network/spotify/auth/spotify_token_store|spotify_token_store.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `base_spotify_transport.dart` | `lib/core/network/spotify/transport` | [[04-Reference/lib/core/network/spotify/transport/base_spotify_transport|base_spotify_transport.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class AuthSessionProvider`
- **Archetype**: Core Component

#### `class SpotifyAuthSessionProvider`
- **Archetype**: Core Component
- **Implements**: `AuthSessionProvider`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_tokenStore` | `SpotifyTokenStore` |
| `_tokenRefresher` | `SpotifyTokenRefresher` |
| `_clientTokenFetcher` | `SpotifyClientTokenFetcher` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `getAccessToken` | `Future<String?>` | `(none)` |
| `getClientToken` | `Future<String?>` | `(none)` |
| `refreshAccessToken` | `Future<String?>` | `(none)` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:musify_mu/core/network/spotify/auth/spotify_client_token.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_refresher.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';

/// Provides auth credentials to transports without exposing
/// token refresh mechanics to feature code.
///
/// Consumers (transports) call [getAccessToken] and [getClientToken]
/// for header injection, and [refreshAccessToken] on 401 retries.
/// They never interact with the underlying token store, TOTP cipher,
/// or refresh protocol.
abstract class AuthSessionProvider {
  /// Returns the current access token, or null if unavailable.
  Future<String?> getAccessToken();

  /// Returns the current client token, fetching a new one if needed.
  Future<String?> getClientToken();

  /// Refreshes the access token. Returns the new token or null on failure.
  Future<String?> refreshAccessToken();
}

/// Concrete [AuthSessionProvider] backed by the Spotify token infrastructure.
class SpotifyAuthSessionProvider implements AuthSessionProvider {
  final SpotifyTokenStore _tokenStore;
  final SpotifyTokenRefresher _tokenRefresher;
  final SpotifyClientTokenFetcher _clientTokenFetcher;

  SpotifyAuthSessionProvider({
    required SpotifyTokenStore tokenStore,
    required SpotifyTokenRefresher tokenRefresher,
    required SpotifyClientTokenFetcher clientTokenFetcher,
  })  : _tokenStore = tokenStore,
        _tokenRefresher = tokenRefresher,
        _clientTokenFetcher = clientTokenFetcher;

  @override
  Future<String?> getAccessToken() => _tokenStore.getAccessToken();

  @override
  Future<String?> getClientToken() => _clientTokenFetcher.getClientToken();

  @override
  Future<String?> refreshAccessToken() => _tokenRefresher.refresh();
}
```
