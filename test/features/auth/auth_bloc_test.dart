import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class FakeTokenStore implements SpotifyTokenStore {
  final Map<String, String> _data = {};

  @override
  Future<void> saveSpDc(String spDc) async => _data['sp_dc'] = spDc;

  @override
  Future<String?> getSpDc() async => _data['sp_dc'];

  @override
  Future<bool> hasSpDc() async => _data.containsKey('sp_dc');

  @override
  Future<void> saveAccessToken(String token, {int lifetimeMs = 3600000}) async {
    _data['access_token'] = token;
    _data['expiry'] = (DateTime.now().millisecondsSinceEpoch + lifetimeMs).toString();
  }

  @override
  Future<String?> getAccessToken() async => _data['access_token'];

  bool tokenExpired = false;

  @override
  Future<bool> isAccessTokenExpired() async => tokenExpired;

  @override
  Future<bool> hasValidAccessToken() async => _data.containsKey('access_token') && !tokenExpired;

  @override
  Future<void> saveUsername(String username) async => _data['username'] = username;

  @override
  Future<String?> getUsername() async => _data['username'];

  @override
  Future<void> saveProfile({
    required String username,
    required String displayName,
    String? avatarUrl,
    String? country,
    String? product,
  }) async {
    _data['username'] = username;
    _data['displayName'] = displayName;
    if (avatarUrl != null) _data['avatarUrl'] = avatarUrl;
    if (country != null) _data['country'] = country;
    if (product != null) _data['product'] = product;
  }

  @override
  Future<({String username, String displayName, String? avatarUrl, String? country, String? product})?> getCachedProfile() async {
    final u = _data['username'];
    if (u == null) return null;
    return (
      username: u,
      displayName: _data['displayName'] ?? u,
      avatarUrl: _data['avatarUrl'],
      country: _data['country'],
      product: _data['product'],
    );
  }

  @override
  Future<void> saveClientToken(String token) async => _data['client_token'] = token;

  @override
  Future<String?> getClientToken() async => _data['client_token'];

  @override
  Future<void> clearAll() async => _data.clear();
}

class FakeTokenRefresher implements SpotifyTokenRefresher {
  int refreshCallCount = 0;
  String? refreshReturnValue = 'new_refreshed_token';

  @override
  Future<String?> refresh() async {
    refreshCallCount++;
    return refreshReturnValue;
  }
}

class FakeProfileFetcher implements SpotifyProfileFetcher {
  @override
  Future<SpotifyUser?> fetchProfile() async => null;
}

class FakeNetworkMonitor implements NetworkMonitorService {
  final _controller = StreamController<NetworkStatus>.broadcast();
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
    _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('AuthBloc cold start and token refresh tests', () {
    late FakeTokenStore tokenStore;
    late FakeTokenRefresher refresher;
    late FakeProfileFetcher profileFetcher;
    late AppCacheManager cacheManager;
    late FakeNetworkMonitor networkMonitor;

    setUp(() {
      tokenStore = FakeTokenStore();
      refresher = FakeTokenRefresher();
      profileFetcher = FakeProfileFetcher();
      cacheManager = AppCacheManager();
      networkMonitor = FakeNetworkMonitor();
    });

    tearDown(() {
      networkMonitor.dispose();
    });

    test('initial state is Authenticated directly if initialUser is passed (no flash)', () {
      const initialUser = SpotifyUser(id: 'test_user', displayName: 'Test User');
      final bloc = AuthBloc(
        tokenStore: tokenStore,
        refresher: refresher,
        profileFetcher: profileFetcher,
        cacheManager: cacheManager,
        networkMonitor: networkMonitor,
        initialUser: initialUser,
      );

      expect(bloc.state, isA<Authenticated>());
      expect((bloc.state as Authenticated).user.id, equals('test_user'));
      bloc.close();
    });

    test('AuthSessionRestored with expired token keeps user Authenticated and refreshes silently without emitting Authenticating', () async {
      await tokenStore.saveSpDc('sp_dc=valid_cookie_1234567890');
      await tokenStore.saveProfile(
        username: 'user_123',
        displayName: 'Cached Name',
      );
      tokenStore.tokenExpired = true;

      final bloc = AuthBloc(
        tokenStore: tokenStore,
        refresher: refresher,
        profileFetcher: profileFetcher,
        cacheManager: cacheManager,
        networkMonitor: networkMonitor,
      );

      final states = <AuthState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const AuthSessionRestored());
      await pumpEventQueue();

      // Ensure Authenticating was NEVER emitted
      expect(states.any((s) => s is Authenticating), isFalse);
      expect(bloc.state, isA<Authenticated>());
      expect((bloc.state as Authenticated).user.id, equals('user_123'));
      expect(refresher.refreshCallCount, equals(1));

      await sub.cancel();
      await bloc.close();
    });

    test('network restoration triggers silent token refresh when token is expired', () async {
      const initialUser = SpotifyUser(id: 'user_123', displayName: 'Cached Name');
      tokenStore.tokenExpired = true;

      final bloc = AuthBloc(
        tokenStore: tokenStore,
        refresher: refresher,
        profileFetcher: profileFetcher,
        cacheManager: cacheManager,
        networkMonitor: networkMonitor,
        initialUser: initialUser,
      );

      expect(refresher.refreshCallCount, equals(0));

      networkMonitor.emit(NetworkStatus.restored);
      await pumpEventQueue();

      expect(refresher.refreshCallCount, equals(1));

      await bloc.close();
    });
  });
}
