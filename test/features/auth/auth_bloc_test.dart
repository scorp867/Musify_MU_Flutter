import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_refresher.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/application/auth_event.dart';
import 'package:musify_mu/features/auth/data/spotify_profile_fetcher.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';
import 'package:musify_mu/features/auth/domain/entities/spotify_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class _InMemorySecureStorage extends Fake
    implements FlutterSecureStorage {
  final Map<String, String> data = <String, String>{};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      data.remove(key);
    } else {
      data[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return data[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    data.remove(key);
  }
}

class FakeTokenStore extends SpotifyTokenStore {
  final _InMemorySecureStorage _backing;
  bool? tokenExpiredOverride;

  FakeTokenStore() : this._(_InMemorySecureStorage());

  FakeTokenStore._(this._backing) : super(storage: _backing);

  bool get tokenExpired => switch (tokenExpiredOverride) {
        final v? => v,
        null => false,
      };

  set tokenExpired(bool value) {
    tokenExpiredOverride = value;
  }

  void setRawExpiryMs(int expiryMs) {
    _backing.data['spotify_access_token_expiry'] = expiryMs.toString();
  }

  @override
  Future<bool> isAccessTokenExpired() async {
    if (tokenExpiredOverride case final forced?) {
      return forced;
    }
    return super.isAccessTokenExpired();
  }

  @override
  Future<bool> hasValidAccessToken() async {
    final token = await getAccessToken();
    if (token == null) return false;
    return !(await isAccessTokenExpired());
  }
}

class FakeTokenRefresher implements SpotifyTokenRefresher {
  final FakeTokenStore? tokenStore;
  int refreshCallCount = 0;
  String? refreshReturnValue = 'new_refreshed_token';
  int? nextExpiryEpochMs;

  FakeTokenRefresher({this.tokenStore});

  @override
  Future<String?> refresh() async {
    refreshCallCount += 1;
    final token = refreshReturnValue;
    final store = tokenStore;
    if (token != null && store != null) {
      await store.saveAccessToken(token);
      if (nextExpiryEpochMs case final expiryMs?) {
        store.setRawExpiryMs(expiryMs);
      }
      store.tokenExpiredOverride = false;
    }
    return token;
  }
}

class FakeProfileFetcher implements SpotifyProfileFetcher {
  @override
  Future<SpotifyUser?> fetchProfile() async => null;
}

class FakeNetworkMonitor implements NetworkMonitorService {
  final StreamController<NetworkStatus> _controller =
      StreamController<NetworkStatus>.broadcast();
  NetworkStatus _current = NetworkStatus.online;

  @override
  NetworkStatus get currentStatus => _current;

  @override
  Stream<NetworkStatus> get statusStream => _controller.stream;

  void emit(NetworkStatus s) {
    _current = s;
    _controller.add(s);
  }

  @override
  void recordLatency(Duration latency) {}

  @override
  void recordTimeout() {}

  @override
  void recordConnectionError() {}

  @override
  void recordSuccess() {}

  @override
  void dispose() {
    unawaited(_controller.close());
  }
}

final class _CapturedTimer implements Timer {
  final Duration duration;
  final void Function() _callback;
  bool _isActive = true;
  bool _isCanceled = false;

  _CapturedTimer(this.duration, this._callback);

  @override
  bool get isActive => _isActive;

  bool get isCanceled => _isCanceled;

  @override
  int get tick => 0;

  @override
  void cancel() {
    _isActive = false;
    _isCanceled = true;
  }

  void fire() {
    if (!_isActive) {
      return;
    }
    _isActive = false;
    _callback();
  }
}

final class _AuthTestHarness {
  final FakeTokenStore tokenStore;
  final FakeTokenRefresher refresher;
  final FakeProfileFetcher profileFetcher;
  final AppCacheManager cacheManager;
  final FakeNetworkMonitor networkMonitor;

  const _AuthTestHarness({
    required this.tokenStore,
    required this.refresher,
    required this.profileFetcher,
    required this.cacheManager,
    required this.networkMonitor,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  group('AuthBloc cold start and token refresh tests', () {
    _AuthTestHarness? activeHarness;

    _AuthTestHarness harness() {
      if (activeHarness case final h?) {
        return h;
      }
      throw StateError('Harness not initialized');
    }

    setUp(() {
      final tokenStore = FakeTokenStore();
      final refresher = FakeTokenRefresher(tokenStore: tokenStore);
      activeHarness = _AuthTestHarness(
        tokenStore: tokenStore,
        refresher: refresher,
        profileFetcher: FakeProfileFetcher(),
        cacheManager: AppCacheManager(),
        networkMonitor: FakeNetworkMonitor(),
      );
    });

    tearDown(() {
      if (activeHarness case final h?) {
        h.networkMonitor.dispose();
      }
      activeHarness = null;
    });

    test('initial state is Authenticated directly if initialUser is passed (no flash)', () async {
      final h = harness();
      const initialUser = SpotifyUser(id: 'test_user', displayName: 'Test User');
      final bloc = AuthBloc(
        tokenStore: h.tokenStore,
        refresher: h.refresher,
        profileFetcher: h.profileFetcher,
        cacheManager: h.cacheManager,
        networkMonitor: h.networkMonitor,
        initialUser: initialUser,
      );

      expect(bloc.state, isA<Authenticated>());
      expect((bloc.state as Authenticated).user.id, equals('test_user'));
      await bloc.close();
    });

    test('AuthSessionRestored with expired token keeps user Authenticated and refreshes silently without emitting Authenticating', () async {
      final h = harness();
      await h.tokenStore.saveSpDc('sp_dc=valid_cookie_1234567890');
      await h.tokenStore.saveProfile(
        username: 'user_123',
        displayName: 'Cached Name',
      );
      h.tokenStore.tokenExpired = true;

      final bloc = AuthBloc(
        tokenStore: h.tokenStore,
        refresher: h.refresher,
        profileFetcher: h.profileFetcher,
        cacheManager: h.cacheManager,
        networkMonitor: h.networkMonitor,
      );

      final states = <AuthState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const AuthSessionRestored());
      await pumpEventQueue();

      expect(states.any((s) => s is Authenticating), isFalse);
      expect(bloc.state, isA<Authenticated>());
      expect((bloc.state as Authenticated).user.id, equals('user_123'));
      expect(h.refresher.refreshCallCount, equals(1));

      await sub.cancel();
      await bloc.close();
    });

    test('network restoration triggers silent token refresh when token is expired', () async {
      final h = harness();
      const initialUser =
          SpotifyUser(id: 'user_123', displayName: 'Cached Name');
      h.tokenStore.tokenExpired = true;

      final bloc = AuthBloc(
        tokenStore: h.tokenStore,
        refresher: h.refresher,
        profileFetcher: h.profileFetcher,
        cacheManager: h.cacheManager,
        networkMonitor: h.networkMonitor,
        initialUser: initialUser,
      );

      expect(h.refresher.refreshCallCount, equals(0));

      h.networkMonitor.emit(NetworkStatus.restored);
      await pumpEventQueue();

      expect(h.refresher.refreshCallCount, equals(1));

      await bloc.close();
    });

    test('computeRefreshDelay calculates dynamic delay from expiresAtMs minus 5m lead window', () {
      const nowMs = 1700000000000;

      // Null expiresAtMs -> fallbackRefreshDelay (50m)
      expect(
        AuthBloc.computeRefreshDelay(expiresAtMs: null, nowMs: nowMs),
        equals(AuthBloc.fallbackRefreshDelay),
      );

      // 35 minutes until expiry -> 35m - 5m lead = 30m delay
      final thirtyFiveMinLater =
          nowMs + const Duration(minutes: 35).inMilliseconds;
      expect(
        AuthBloc.computeRefreshDelay(
          expiresAtMs: thirtyFiveMinLater,
          nowMs: nowMs,
        ),
        equals(const Duration(minutes: 30)),
      );

      // Within 5m lead window (e.g. 2m until expiry) -> minimumRefreshDelay (30s)
      final twoMinLater = nowMs + const Duration(minutes: 2).inMilliseconds;
      expect(
        AuthBloc.computeRefreshDelay(expiresAtMs: twoMinLater, nowMs: nowMs),
        equals(AuthBloc.minimumRefreshDelay),
      );

      // Already expired -> minimumRefreshDelay (30s)
      expect(
        AuthBloc.computeRefreshDelay(expiresAtMs: nowMs - 5000, nowMs: nowMs),
        equals(AuthBloc.minimumRefreshDelay),
      );
    });

    test('proactively schedules and executes token refresh from persisted expiresAtMs', () async {
      final h = harness();
      const baseNowMs = 1700000000000;
      final capturedTimers = <_CapturedTimer>[];

      await runZoned<Future<void>>(
        () async {
          await h.tokenStore.saveSpDc('sp_dc=valid_cookie_for_timer');
          await h.tokenStore.saveProfile(
            username: 'user_timer',
            displayName: 'Timer User',
          );
          await h.tokenStore.saveAccessToken('initial_token');
          // Persisted expiry is baseNowMs + 10m -> refresh delay = 10m - 5m = 5m
          h.tokenStore.setRawExpiryMs(
            baseNowMs + const Duration(minutes: 10).inMilliseconds,
          );
          h.tokenStore.tokenExpiredOverride = false;

          final bloc = AuthBloc(
            tokenStore: h.tokenStore,
            refresher: h.refresher,
            profileFetcher: h.profileFetcher,
            cacheManager: h.cacheManager,
            networkMonitor: h.networkMonitor,
            nowMsProvider: () => baseNowMs,
          );

          // Cold start with valid token schedules dynamic 5m refresh timer
          bloc.add(const AuthSessionRestored());
          await pumpEventQueue();

          expect(bloc.state, isA<Authenticated>());
          expect(h.refresher.refreshCallCount, equals(0));
          expect(capturedTimers, hasLength(1));
          expect(capturedTimers.first.duration, equals(const Duration(minutes: 5)));
          expect(capturedTimers.first.isActive, isTrue);

          // Next refresh returns expiry 65m ahead -> reschedule delay = 60m
          h.refresher.nextExpiryEpochMs =
              baseNowMs + const Duration(minutes: 65).inMilliseconds;

          // Fire the 5m timer -> refreshes token and schedules 60m timer
          capturedTimers.first.fire();
          await pumpEventQueue();

          expect(h.refresher.refreshCallCount, equals(1));
          expect(capturedTimers, hasLength(2));
          expect(capturedTimers[1].duration, equals(const Duration(minutes: 60)));
          expect(capturedTimers[1].isActive, isTrue);

          // Logout cancels scheduled refresh timer and clears store
          bloc.add(const AuthLogoutRequested());
          await pumpEventQueue();

          expect(bloc.state, isA<Unauthenticated>());
          expect(capturedTimers[1].isCanceled, isTrue);
          expect(capturedTimers[1].isActive, isFalse);
          expect(await h.tokenStore.getSpDc(), isNull);

          await bloc.close();
        },
        zoneSpecification: ZoneSpecification(
          createTimer: (self, parent, zone, duration, callback) {
            if (duration == Duration.zero) {
              return parent.createTimer(zone, duration, callback);
            }
            final timer = _CapturedTimer(duration, callback);
            capturedTimers.add(timer);
            return timer;
          },
        ),
      );
    });
  });
}
