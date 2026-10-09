import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';
import 'package:musify_mu/features/auth/application/auth_event.dart';
import 'package:musify_mu/features/auth/data/spotify_profile_fetcher.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_refresher.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_totp.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';
import 'package:musify_mu/features/auth/domain/entities/spotify_user.dart';

/// Manages the app-wide authentication state.
///
/// On session restore, checks for stored tokens and auto-refreshes if expired.
/// Schedules periodic token refresh ~5 minutes before expiry.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SpotifyTokenStore _tokenStore;
  final SpotifyTokenRefresher _refresher;
  final SpotifyProfileFetcher _profileFetcher;
  final AppCacheManager _cacheManager;
  final NetworkMonitorService? _networkMonitor;
  StreamSubscription<NetworkStatus>? _networkSubscription;
  Timer? _refreshTimer;

  AuthBloc({
    required SpotifyTokenStore tokenStore,
    required SpotifyTokenRefresher refresher,
    required SpotifyProfileFetcher profileFetcher,
    required AppCacheManager cacheManager,
    NetworkMonitorService? networkMonitor,
    SpotifyUser? initialUser,
  })  : _tokenStore = tokenStore,
        _refresher = refresher,
        _profileFetcher = profileFetcher,
        _cacheManager = cacheManager,
        _networkMonitor = networkMonitor,
        super(initialUser != null
            ? Authenticated(user: initialUser)
            : const Unauthenticated()) {
    on<AuthSessionRestored>(_onSessionRestored);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthTokensCaptured>(_onTokensCaptured);
    on<AuthLogoutRequested>(_onLogoutRequested);

    _networkSubscription = _networkMonitor?.statusStream.listen((status) {
      if (status == NetworkStatus.online || status == NetworkStatus.restored) {
        _onNetworkRestored();
      }
    });
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    _networkSubscription?.cancel();
    return super.close();
  }

  Future<void> _onNetworkRestored() async {
    if (state is! Authenticated) return;
    final hasValidToken = await _tokenStore.hasValidAccessToken();
    if (!hasValidToken) {
      dev.log('Auth: Network restored, refreshing expired token', name: 'Auth');
      final newToken = await _refresher.refresh();
      if (newToken != null) {
        _scheduleTokenRefresh();
        _refreshProfileInBackground();
      }
    }
  }

  Future<void> _onSessionRestored(
    AuthSessionRestored event,
    Emitter<AuthState> emit,
  ) async {
    // Load cached TOTP cipher.
    await SpotifyTotp().loadFromCache();

    final hasSpDc = await _tokenStore.hasSpDc();
    if (!hasSpDc) {
      emit(const Unauthenticated());
      return;
    }

    // Has session cookie — always ensure we emit Authenticated from cache
    // so the user never sees a login screen or loading spinner.
    await _emitFromCache(emit);

    final hasValidToken = await _tokenStore.hasValidAccessToken();
    if (hasValidToken) {
      _scheduleTokenRefresh();
      _refreshProfileInBackground();
      return;
    }

    // Token expired — refresh silently in background without blocking UI
    // or flashing the login welcome screen.
    final newToken = await _refresher.refresh();
    if (newToken != null) {
      _scheduleTokenRefresh();
      _refreshProfileInBackground();
    } else {
      dev.log('Auth: Token refresh returned null (offline or network error)', name: 'Auth');
      // If offline, user stays Authenticated using cached profile.
      // When network comes back, _onNetworkRestored will refresh the token.
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const Authenticating());
  }

  Future<void> _onTokensCaptured(
    AuthTokensCaptured event,
    Emitter<AuthState> emit,
  ) async {
    emit(const Authenticating());

    try {
      await _tokenStore.saveSpDc(event.spDcCookie);
      await _tokenStore.saveAccessToken(event.accessToken);

      await _emitWithFreshProfile(emit);
      _scheduleTokenRefresh();
    } catch (e) {
      emit(AuthError('Login failed: ${e.toString()}'));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _refreshTimer?.cancel();
    await _tokenStore.clearAll();
    emit(const Unauthenticated());
  }

  /// Emits Authenticated using the locally cached profile.
  /// Zero network calls - instant on app restart.
  Future<void> _emitFromCache(Emitter<AuthState> emit) async {
    final cached = await _tokenStore.getCachedProfile();
    if (cached != null) {
      await _cacheManager.setUser(cached.username);
      emit(Authenticated(
        user: SpotifyUser(
          id: cached.username,
          displayName: cached.displayName,
          avatarUrl: cached.avatarUrl,
          country: cached.country,
          product: cached.product,
        ),
      ));
    } else {
      // No cache yet - must be first login, fetch from network.
      await _emitWithFreshProfile(emit);
    }
  }

  /// Fetches the profile from Spotify's API and emits Authenticated.
  /// Used only on first login. Caches the result for future restores.
  Future<void> _emitWithFreshProfile(Emitter<AuthState> emit) async {
    final profile = await _profileFetcher.fetchProfile();
    if (profile != null) {
      await _cacheManager.setUser(profile.id);
      emit(Authenticated(user: profile));
      return;
    }

    // Fallback to a generic user if API fails.
    emit(const Authenticated(
      user: SpotifyUser(
        id: 'spotify_user',
        displayName: 'Spotify User',
      ),
    ));
  }

  /// Refreshes the profile in the background without blocking the UI.
  /// Updates the cache so the next app restart shows fresh data.
  void _refreshProfileInBackground() {
    _profileFetcher.fetchProfile(); // fire-and-forget, saves to cache
  }

  /// Schedules a token refresh 55 minutes from now (tokens last ~60 min).
  void _scheduleTokenRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(minutes: 55), () async {
      final newToken = await _refresher.refresh();
      if (newToken != null) {
        _scheduleTokenRefresh(); // Schedule next refresh.
      }
      // If refresh fails, the next API call will trigger re-auth.
    });
  }
}
