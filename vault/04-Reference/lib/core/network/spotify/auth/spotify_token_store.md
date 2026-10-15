---
title: "spotify_token_store.dart"
path: "lib/core/network/spotify/auth/spotify_token_store.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, network]
lines: 120
incoming_dependencies: 7
outgoing_dependencies: 0
---

# spotify_token_store.dart

> Source File: `[lib/core/network/spotify/auth/spotify_token_store.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/spotify/auth/spotify_token_store.dart)`
> Layer: `lib/core/network/spotify/auth`

## Executive Summary
`spotify_token_store.dart` is an essential file in `lib/core/network/spotify/auth` providing definitions for `SpotifyTokenStore`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `auth_bloc.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_bloc|auth_bloc.dart]] |
| `spotify_profile_fetcher.dart` | `lib/features/auth/data` | [[04-Reference/lib/features/auth/data/spotify_profile_fetcher|spotify_profile_fetcher.dart]] |
| `auth_session_provider.dart` | `lib/core/network/spotify/auth` | [[04-Reference/lib/core/network/spotify/auth/auth_session_provider|auth_session_provider.dart]] |
| `spotify_client_token.dart` | `lib/core/network/spotify/auth` | [[04-Reference/lib/core/network/spotify/auth/spotify_client_token|spotify_client_token.dart]] |
| `spotify_token_refresher.dart` | `lib/core/network/spotify/auth` | [[04-Reference/lib/core/network/spotify/auth/spotify_token_refresher|spotify_token_refresher.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `auth_bloc_test.dart` | `test/features/auth` | [[04-Reference/test/features/auth/auth_bloc_test|auth_bloc_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class SpotifyTokenStore`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_storage` | `FlutterSecureStorage` |
| `expiry` | `final` |
| `expiryStr` | `final` |
| `expiry` | `final` |
| `token` | `final` |
| `username` | `final` |
| `displayName` | `final` |
| `avatarUrl` | `final` |
| `country` | `final` |
| `product` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `saveSpDc` | `Future<void>` | `String spDc` |
| `getSpDc` | `Future<String?>` | `(none)` |
| `hasSpDc` | `Future<bool>` | `(none)` |
| `saveAccessToken` | `Future<void>` | `String token, {int lifetimeMs = 3600000}` |
| `getAccessToken` | `Future<String?>` | `(none)` |
| `isAccessTokenExpired` | `Future<bool>` | `(none)` |
| `hasValidAccessToken` | `Future<bool>` | `(none)` |
| `saveUsername` | `Future<void>` | `String username` |
| `getUsername` | `Future<String?>` | `(none)` |
| `saveProfile` | `Future<void>` | `{ required String username, required String dis...` |
| `getCachedProfile` | `Future<({String username, String displayName, String? avatarUrl, String? country, String? product})?>` | `(none)` |
| `saveClientToken` | `Future<void>` | `String token` |
| `getClientToken` | `Future<String?>` | `(none)` |
| `clearAll` | `Future<void>` | `(none)` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Securely persists Spotify auth tokens using platform-level encryption.
///
/// - Android: AES-256 via EncryptedSharedPreferences
/// - iOS: Keychain
class SpotifyTokenStore {
  static const _kSpDc = 'spotify_sp_dc';
  static const _kAccessToken = 'spotify_access_token';
  static const _kAccessTokenExpiry = 'spotify_access_token_expiry';
  static const _kUsername = 'spotify_username';

  final FlutterSecureStorage _storage;

  SpotifyTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ── sp_dc cookie ──────────────────────────────────────────────────────

  Future<void> saveSpDc(String spDc) =>
      _storage.write(key: _kSpDc, value: spDc);

  Future<String?> getSpDc() => _storage.read(key: _kSpDc);

  Future<bool> hasSpDc() async => (await getSpDc()) != null;

  // ── Access token ──────────────────────────────────────────────────────

  Future<void> saveAccessToken(String token, {int lifetimeMs = 3600000}) async {
    final expiry = DateTime.now().millisecondsSinceEpoch + lifetimeMs;
    await _storage.write(key: _kAccessToken, value: token);
    await _storage.write(key: _kAccessTokenExpiry, value: expiry.toString());
  }

  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);

  Future<bool> isAccessTokenExpired() async {
    final expiryStr = await _storage.read(key: _kAccessTokenExpiry);
    if (expiryStr == null) return true;
    final expiry = int.tryParse(expiryStr) ?? 0;
    // Treat as expired if less than 5 minutes remain.
    return DateTime.now().millisecondsSinceEpoch > expiry - 300000;
  }

  Future<bool> hasValidAccessToken() async {
// ... [remaining code in source file] ...
```
