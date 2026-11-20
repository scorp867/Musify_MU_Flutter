import 'dart:async';
import 'dart:developer' as dev;

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_refresher.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_totp.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';
import 'package:musify_mu/features/auth/application/auth_event.dart';
import 'package:musify_mu/features/auth/data/spotify_profile_fetcher.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';
import 'package:musify_mu/features/auth/domain/entities/spotify_user.dart';

/// Manages the app-wide authentication state.
///
/// On session restore, checks for stored tokens and auto-refreshes if expired.
/// Schedules token refresh from the persisted `expiresAtMs` timestamp with a
/// 5-minute safety lead window before actual expiry.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static const Duration refreshLeadWindow = Duration(minutes: 5);
  static const Duration minimumRefreshDelay = Duration(seconds: 30);
  static const Duration fallbackRefreshDelay = Duration(minutes: 50);

  final SpotifyTokenStore _tokenStore;
  final SpotifyTokenRefresher _refresher;
  final SpotifyProfileFetcher _profileFetcher;
  final AppCacheManager _cacheManager;
  final NetworkMonitorService? _networkMonitor;
  final int Function() _nowMsProvider;

  StreamSubscription<NetworkStatus>? _networkSubscription;
  Timer? _refreshTimer;
  int _refreshScheduleEpoch = 0;

  AuthBloc({
    required SpotifyTokenStore tokenStore,
    required SpotifyTokenRefresher refresher,
    required SpotifyProfileFetcher profileFetcher,
    required AppCacheManager cacheManager,
    NetworkMonitorService? networkMonitor,
    SpotifyUser? initialUser,
    int Function()? nowMsProvider,
  })  : _tokenStore = tokenStore,
        _refresher = refresher,
        _profileFetcher = profileFetcher,
        _cacheManager = cacheManager,
        _networkMonitor = networkMonitor,
        _nowMsProvider = switch (nowMsProvider) {
          final provider? => provider,
          null => _defaultNowMs,
        },
        super(
          initialUser != null
              ? Authenticated(user: initialUser)
              : const Unauthenticated(),
        ) {
    on<AuthSessionRestored>(_onSessionRestored, transformer: sequential());
    on<AuthLoginRequested>(_onLoginRequested, transformer: sequential());
    on<AuthTokensCaptured>(_onTokensCaptured, transformer: sequential());
    on<AuthLogoutRequested>(_onLogoutRequested, transformer: sequential());

    if (_networkMonitor case final monitor?) {
      _networkSubscription = monitor.statusStream.listen(
        (status) {
          if (status == NetworkStatus.online ||
              status == NetworkStatus.restored) {
            unawaited(_onNetworkRestored());
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          dev.log(
            'AuthBloc: network status stream error: $error',
            name: 'Auth',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
    }
  }

  static int _defaultNowMs() => DateTime.now().millisecondsSinceEpoch;

  /// Computes the delay until the next proactive access-token refresh given
  /// the token's [expiresAtMs] epoch timestamp and current [nowMs].
  static Duration computeRefreshDelay({
    required int? expiresAtMs,
    required int nowMs,
  }) {
    if (expiresAtMs == null) {
      return fallbackRefreshDelay;
    }
    final remainingUntilLeadMs =
        expiresAtMs - nowMs - refreshLeadWindow.inMilliseconds;
    if (remainingUntilLeadMs <= 0) {
      return minimumRefreshDelay;
    }
    if (remainingUntilLeadMs < minimumRefreshDelay.inMilliseconds) {
      return minimumRefreshDelay;
    }
    return Duration(milliseconds: remainingUntilLeadMs);
  }

  @override
  Future<void> close() async {
    _cancelRefreshSchedule();
    if (_networkSubscription case final sub?) {
      _networkSubscription = null;
      await sub.cancel();
    }
    return super.close();
  }

  Future<void> _onNetworkRestored() async {
    if (isClosed || state is! Authenticated) return;
    try {
      final hasValidToken = await _tokenStore.hasValidAccessToken();
      if (isClosed || state is! Authenticated) return;
      if (!hasValidToken) {
        dev.log(
          'Auth: Network restored, refreshing expired token',
          name: 'Auth',
        );
        final newToken = await _refresher.refresh();
        if (isClosed || state is! Authenticated) return;
        if (newToken != null && newToken.isNotEmpty) {
          await _scheduleTokenRefresh();
          _refreshProfileInBackground();
        }
      }
    } on Object catch (error, stackTrace) {
      dev.log(
        'Auth: Network restoration refresh failed: $error',
        name: 'Auth',
        error: error,
        stackTrace: stackTrace,
      );
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
      _cancelRefreshSchedule();
      emit(const Unauthenticated());
      return;
    }

    // Has session cookie: always ensure we emit Authenticated from cache
    // so the user never sees a login screen or loading spinner.
    await _emitFromCache(emit);

    final hasValidToken = await _tokenStore.hasValidAccessToken();
    if (hasValidToken) {
      await _scheduleTokenRefresh();
      _refreshProfileInBackground();
      return;
    }

    // Token expired: refresh silently in background without blocking UI
    // or flashing the login welcome screen.
    final newToken = await _refresher.refresh();
    if (newToken != null && newToken.isNotEmpty) {
      await _scheduleTokenRefresh();
      _refreshProfileInBackground();
    } else {
      dev.log(
        'Auth: Token refresh returned null (offline or network error)',
        name: 'Auth',
      );
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
      await _scheduleTokenRefresh();
    } on Object catch (error, stackTrace) {
      dev.log(
        'Auth: Token capture failed: $error',
        name: 'Auth',
        error: error,
        stackTrace: stackTrace,
      );
      emit(AuthError('Login failed: ${error.toString()}'));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _cancelRefreshSchedule();
    await _tokenStore.clearAll();
    emit(const Unauthenticated());
  }

  /// Emits Authenticated using the locally cached profile.
  /// Zero network calls - instant on app restart.
  Future<void> _emitFromCache(Emitter<AuthState> emit) async {
    final cached = await _tokenStore.getCachedProfile();
    if (cached != null) {
      await _cacheManager.setUser(cached.username);
      emit(
        Authenticated(
          user: SpotifyUser(
            id: cached.username,
            displayName: cached.displayName,
            avatarUrl: cached.avatarUrl,
            country: cached.country,
            product: cached.product,
          ),
        ),
      );
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
    emit(
      const Authenticated(
        user: SpotifyUser(
          id: 'spotify_user',
          displayName: 'Spotify User',
        ),
      ),
    );
  }

  /// Refreshes the profile in the background without blocking the UI.
  /// Updates the cache so the next app restart shows fresh data.
  void _refreshProfileInBackground() {
    unawaited(
      _profileFetcher.fetchProfile().then(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          dev.log(
            'Auth: Background profile refresh failed: $error',
            name: 'Auth',
            error: error,
            stackTrace: stackTrace,
          );
        },
      ),
    );
  }

  void _cancelRefreshSchedule() {
    _refreshScheduleEpoch += 1;
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Schedules the next token refresh based on persisted `expiresAtMs`
  /// minus [refreshLeadWindow] (5 minutes).
  Future<void> _scheduleTokenRefresh() async {
    _cancelRefreshSchedule();
    final epoch = _refreshScheduleEpoch;

    int? expiresAtMs;
    try {
      expiresAtMs = await _tokenStore.getAccessTokenExpiryMs();
    } on Object catch (error, stackTrace) {
      dev.log(
        'Auth: Failed reading access token expiry: $error',
        name: 'Auth',
        error: error,
        stackTrace: stackTrace,
      );
      expiresAtMs = null;
    }

    if (isClosed || epoch != _refreshScheduleEpoch || state is! Authenticated) {
      return;
    }

    final delay = computeRefreshDelay(
      expiresAtMs: expiresAtMs,
      nowMs: _nowMsProvider(),
    );
    dev.log(
      'Auth: Scheduling next access token refresh in ${delay.inSeconds}s '
      '(expiresAtMs=$expiresAtMs)',
      name: 'Auth',
    );
    _refreshTimer = Timer(delay, () {
      _refreshTimer = null;
      unawaited(_executeScheduledRefresh(epoch));
    });
  }

  Future<void> _executeScheduledRefresh(int epoch) async {
    if (isClosed || epoch != _refreshScheduleEpoch || state is! Authenticated) {
      return;
    }
    try {
      final newToken = await _refresher.refresh();
      if (isClosed ||
          epoch != _refreshScheduleEpoch ||
          state is! Authenticated) {
        return;
      }
      if (newToken != null && newToken.isNotEmpty) {
        await _scheduleTokenRefresh();
      } else {
        dev.log(
          'Auth: Scheduled token refresh returned null; awaiting network or next API call',
          name: 'Auth',
        );
      }
    } on Object catch (error, stackTrace) {
      dev.log(
        'Auth: Scheduled token refresh failed: $error',
        name: 'Auth',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
