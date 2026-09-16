import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/auth/application/auth_event.dart';
import 'package:musify_mu/features/auth/data/spotify_profile_fetcher.dart';
import 'package:musify_mu/features/auth/data/spotify_token_refresher.dart';
import 'package:musify_mu/features/auth/data/spotify_token_store.dart';
import 'package:musify_mu/features/auth/data/spotify_totp.dart';
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
  Timer? _refreshTimer;

  AuthBloc({
    SpotifyTokenStore? tokenStore,
    SpotifyTokenRefresher? refresher,
    SpotifyProfileFetcher? profileFetcher,
  })  : _tokenStore = tokenStore ?? SpotifyTokenStore(),
        _refresher = refresher ?? SpotifyTokenRefresher(),
        _profileFetcher = profileFetcher ?? SpotifyProfileFetcher(),
        super(const Unauthenticated()) {
    on<AuthSessionRestored>(_onSessionRestored);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthTokensCaptured>(_onTokensCaptured);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
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

    // Has session cookie — try to get a valid token.
    final hasValidToken = await _tokenStore.hasValidAccessToken();
    if (hasValidToken) {
      await _emitFromCache(emit);
      _scheduleTokenRefresh();
      _refreshProfileInBackground();
      return;
    }

    // Token expired — try auto-refresh.
    emit(const Authenticating());
    final newToken = await _refresher.refresh();
    if (newToken != null) {
      await _emitFromCache(emit);
      _scheduleTokenRefresh();
      _refreshProfileInBackground();
    } else {
      // Refresh failed — sp_dc may be invalid. User must re-login.
      emit(const Unauthenticated());
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
  /// Zero network calls — instant on app restart.
  Future<void> _emitFromCache(Emitter<AuthState> emit) async {
    final cached = await _tokenStore.getCachedProfile();
    if (cached != null) {
      emit(Authenticated(
        user: SpotifyUser(
          id: cached.username,
          displayName: cached.displayName,
          avatarUrl: cached.avatarUrl,
        ),
      ));
    } else {
      // No cache yet — must be first login, fetch from network.
      await _emitWithFreshProfile(emit);
    }
  }

  /// Fetches the profile from Spotify's API and emits Authenticated.
  /// Used only on first login. Caches the result for future restores.
  Future<void> _emitWithFreshProfile(Emitter<AuthState> emit) async {
    final profile = await _profileFetcher.fetchProfile();
    if (profile != null) {
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
