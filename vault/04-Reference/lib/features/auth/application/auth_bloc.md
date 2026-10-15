---
title: "auth_bloc.dart"
path: "lib/features/auth/application/auth_bloc.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, auth, bloc, session, totp]
lines: 204
incoming_dependencies: 2
outgoing_dependencies: 8
---

# auth_bloc.dart

> Source File: `[lib/features/auth/application/auth_bloc.dart](file:///c:/Users/Admin/Musify_MU/lib/features/auth/application/auth_bloc.dart)`
> Layer: `lib/features/auth/application` (Authentication State Machine)

## Executive Summary
`auth_bloc.dart` implements `AuthBloc`, the app-wide authentication state machine for Musify MU. It coordinates stored `sp_dc` cookies, auto-refreshes expired access tokens in the background, schedules preemptive refreshes ~5 minutes before token expiry, listens for network reconnection events to recover sessions, and emits cached profiles synchronously so users never see a loading spinner upon app launch.

**Primary Architecture Role**: Global Authentication State Machine & Token Refresh Scheduler

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `app_cache_manager.dart` | `lib/core/cache` | [[04-Reference/lib/core/cache/app_cache_manager|app_cache_manager.dart]] |
| `network_monitor_service.dart` | `lib/core/network/status` | [[04-Reference/lib/core/network/status/network_monitor_service|network_monitor_service.dart]] |
| `network_status.dart` | `lib/core/network/status` | [[04-Reference/lib/core/network/status/network_status|network_status.dart]] |
| `auth_event.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_event|auth_event.dart]] |
| `spotify_profile_fetcher.dart` | `lib/features/auth/data` | [[04-Reference/lib/features/auth/data/spotify_profile_fetcher|spotify_profile_fetcher.dart]] |
| `spotify_token_refresher.dart` | `lib/core/network/spotify/auth` | [[04-Reference/lib/core/network/spotify/auth/spotify_token_refresher|spotify_token_refresher.dart]] |
| `spotify_token_store.dart` | `lib/core/network/spotify/auth` | [[04-Reference/lib/core/network/spotify/auth/spotify_token_store|spotify_token_store.dart]] |
| `spotify_totp.dart` | `lib/core/network/spotify/auth` | [[04-Reference/lib/core/network/spotify/auth/spotify_totp|spotify_totp.dart]] |
| `auth_state.dart` | `lib/features/auth/domain/entities` | [[04-Reference/lib/features/auth/domain/entities/auth_state|auth_state.dart]] |
| `spotify_user.dart` | `lib/features/auth/domain/entities` | [[04-Reference/lib/features/auth/domain/entities/spotify_user|spotify_user.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `app.dart` | `lib/app` | [[04-Reference/lib/app/app|app.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class AuthBloc extends Bloc<AuthEvent, AuthState>`

**Dependencies & Timers:**
- `final SpotifyTokenStore _tokenStore`: Secure enclave storage for session cookies and access tokens.
- `final SpotifyTokenRefresher _refresher`: Executes TOTP-signed token exchanges.
- `final SpotifyProfileFetcher _profileFetcher`: Pathfinder GraphQL profile query client.
- `final AppCacheManager _cacheManager`: Manages user-specific cache folders.
- `final NetworkMonitorService? _networkMonitor`: Connection state monitor.
- `Timer? _refreshTimer`: Periodic timer triggering token renewal ~5 minutes before expiration.

**Registered Event Handlers:**
- `on<AuthSessionRestored>(_onSessionRestored)`: Restores cached session from storage on boot.
- `on<AuthLoginRequested>(_onLoginRequested)`: Transitions state to `Authenticating(step: Webview)`.
- `on<AuthTokensCaptured>(_onTokensCaptured)`: Receives cookies and client tokens from webview login.
- `on<AuthLogoutRequested>(_onLogoutRequested)`: Purges stored credentials and emits `Unauthenticated()`.

## State & Data Flow Analysis
- **Zero-Spinner Startup Flow**:
  1. `_onSessionRestored` checks `hasSpDc()`. If false, emits `Unauthenticated()`.
  2. If session cookie exists, calls `_emitFromCache(emit)`, immediately transitioning to `Authenticated(user: cachedUser)`.
  3. Checks `hasValidAccessToken()`. If expired, initiates a silent background refresh via `_refresher.refresh()` without dropping UI authentication state.
- **Auto-Reconnection Recovery**:
  Subscribes to `_networkMonitor.statusStream`. When the device recovers from offline mode, `_onNetworkRestored()` verifies token validity and immediately refreshes if the token expired while offline.

## Implementation Highlight
```dart
Future<void> _onSessionRestored(
  AuthSessionRestored event,
  Emitter<AuthState> emit,
) async {
  await SpotifyTotp().loadFromCache();

  final hasSpDc = await _tokenStore.hasSpDc();
  if (!hasSpDc) {
    emit(const Unauthenticated());
    return;
  }

  await _emitFromCache(emit);

  final hasValidToken = await _tokenStore.hasValidAccessToken();
  if (hasValidToken) {
    _scheduleTokenRefresh();
    _refreshProfileInBackground();
    return;
  }

  // Token expired - refresh silently in background
  final newToken = await _refresher.refresh();
  if (newToken != null) {
    _scheduleTokenRefresh();
    _refreshProfileInBackground();
  }
}
```
