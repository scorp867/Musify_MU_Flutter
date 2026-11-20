import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/audio/musify_ffi_bindings.dart';
import 'package:musify_mu/core/audio/native_playback_session_bridge.dart';
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/network/auth/token_refresh_mutex.dart';
import 'package:musify_mu/core/network/spotify/auth/auth_session_provider.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

final class _RecordedClientProfileCall {
  final String clientId;
  final String appPlatform;
  final String appVersion;
  final String userAgent;
  final int sendOriginHeaders;

  const _RecordedClientProfileCall({
    required this.clientId,
    required this.appPlatform,
    required this.appVersion,
    required this.userAgent,
    required this.sendOriginHeaders,
  });
}

final class _RecordedAuthSessionCall {
  final String accessToken;
  final String clientToken;
  final String spDc;
  final String country;
  final String catalogue;
  final String acceptLanguage;
  final String cacheDir;

  const _RecordedAuthSessionCall({
    required this.accessToken,
    required this.clientToken,
    required this.spDc,
    required this.country,
    required this.catalogue,
    required this.acceptLanguage,
    required this.cacheDir,
  });
}

final class _BridgeFakeFfiBindings extends Fake implements MusifyFfiBindings {
  final List<String> callOrder = <String>[];
  final List<_RecordedClientProfileCall> clientProfiles =
      <_RecordedClientProfileCall>[];
  final List<_RecordedAuthSessionCall> authSessions =
      <_RecordedAuthSessionCall>[];
  int authRefreshPort = 0;

  @override
  int initDartApiDl(Pointer<Void> data) {
    callOrder.add('initDartApiDl');
    return 0;
  }

  @override
  void setAuthRefreshPort(int port) {
    authRefreshPort = port;
    callOrder.add('setAuthRefreshPort:$port');
  }

  @override
  void setClientProfile({
    required Pointer<Utf8> clientId,
    required Pointer<Utf8> appPlatform,
    required Pointer<Utf8> appVersion,
    required Pointer<Utf8> userAgent,
    required int sendOriginHeaders,
  }) {
    callOrder.add('setClientProfile');
    clientProfiles.add(
      _RecordedClientProfileCall(
        clientId: clientId.toDartString(),
        appPlatform: appPlatform.toDartString(),
        appVersion: appVersion.toDartString(),
        userAgent: userAgent.toDartString(),
        sendOriginHeaders: sendOriginHeaders,
      ),
    );
  }

  @override
  void setAuthSession({
    required Pointer<Utf8> accessToken,
    required Pointer<Utf8> clientToken,
    required Pointer<Utf8> spDc,
    required Pointer<Utf8> country,
    required Pointer<Utf8> catalogue,
    required Pointer<Utf8> acceptLanguage,
    required Pointer<Utf8> cacheDir,
  }) {
    callOrder.add('setAuthSession');
    authSessions.add(
      _RecordedAuthSessionCall(
        accessToken: accessToken.toDartString(),
        clientToken: clientToken.toDartString(),
        spDc: spDc.toDartString(),
        country: country.toDartString(),
        catalogue: catalogue.toDartString(),
        acceptLanguage: acceptLanguage.toDartString(),
        cacheDir: cacheDir.toDartString(),
      ),
    );
  }
}

final class _FakeTokenStore implements SpotifyTokenStore {
  final Set<void Function()> _listeners = <void Function()>{};
  String? accessToken = 'initial_access_token';
  String? clientToken = 'initial_client_token';
  String? spDc = 'initial_sp_dc_cookie';

  @override
  void addChangeListener(void Function() listener) {
    _listeners.add(listener);
  }

  @override
  void removeChangeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  int get listenerCount => _listeners.length;

  void notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getClientToken() async => clientToken;

  @override
  Future<String?> getSpDc() async => spDc;

  @override
  Future<void> clearAll() async {
    accessToken = null;
    clientToken = null;
    spDc = null;
  }

  @override
  Future<void> deleteClientToken() async {
    clientToken = null;
  }

  @override
  Future<
      ({
        String? avatarUrl,
        String? country,
        String displayName,
        String? product,
        String username,
      })?> getCachedProfile() async => null;

  @override
  Future<String?> getUsername() async => null;

  @override
  Future<bool> hasSpDc() async => spDc != null;

  @override
  Future<bool> hasValidAccessToken() async => accessToken != null;

  @override
  Future<bool> isAccessTokenExpired() async => false;

  @override
  Future<bool> isClientTokenExpired() async => false;

  @override
  Future<void> saveAccessToken(String token, {int lifetimeMs = 3600000}) async {
    accessToken = token;
  }

  @override
  Future<void> saveClientToken(
    String token, {
    int lifetimeMs = 86400000,
  }) async {
    clientToken = token;
  }

  @override
  Future<void> saveProfile({
    required String username,
    required String displayName,
    String? avatarUrl,
    String? country,
    String? product,
  }) async {}

  @override
  Future<void> saveSpDc(String value) async {
    spDc = value;
  }

  @override
  Future<void> saveUsername(String username) async {}
}

final class _FakeAuthSessionProvider implements AuthSessionProvider {
  final _FakeTokenStore tokenStore;
  AuthClientProfileConfig profileConfig =
      AuthClientProfileConfig.webPlayerDefault;

  int refreshAccessTokenCalls = 0;
  int getClientTokenCalls = 0;
  int forceRefreshClientTokenCalls = 0;

  String? nextRefreshedAccessToken = 'refreshed_access_token';
  String? nextClientToken = 'fresh_client_token';
  String? nextForcedClientToken = 'forced_client_token';

  _FakeAuthSessionProvider(this.tokenStore);

  @override
  Future<String?> getAccessToken() async => tokenStore.accessToken;

  @override
  Future<String?> getClientToken() async {
    getClientTokenCalls += 1;
    if (nextClientToken != null) {
      tokenStore.clientToken = nextClientToken;
    }
    return tokenStore.clientToken;
  }

  @override
  Future<String?> refreshAccessToken() async {
    refreshAccessTokenCalls += 1;
    tokenStore.accessToken = nextRefreshedAccessToken;
    return nextRefreshedAccessToken;
  }

  @override
  Future<String?> forceRefreshClientToken() async {
    forceRefreshClientTokenCalls += 1;
    tokenStore.clientToken = nextForcedClientToken;
    return nextForcedClientToken;
  }

  @override
  Future<String> getActiveClientId() async => profileConfig.clientId;

  @override
  Future<AuthClientProfile> getActiveClientProfile() async =>
      profileConfig.profile;

  @override
  Future<AuthClientProfileConfig> getActiveClientProfileConfig() async =>
      profileConfig;
}

final class _NoopDataPool implements DataPool {
  final List<String>? eventLog;
  int ensureDiskLoadedCalls = 0;
  bool failNextEnsureDiskLoaded = false;

  _NoopDataPool({this.eventLog});

  @override
  void dispose() {}

  @override
  Future<void> ensureDiskLoaded() async {
    ensureDiskLoadedCalls += 1;
    eventLog?.add('ensureDiskLoaded');
    if (failNextEnsureDiskLoaded) {
      failNextEnsureDiskLoaded = false;
      throw StateError('disk warm-up failed');
    }
  }

  @override
  T? getTrait<T extends Trait>(String uri) => null;

  @override
  Map<String, Trait>? getTraits(String uri) => null;

  @override
  bool hasRequiredTraits(String uri, DataStatement statement) => false;

  @override
  void ingestBatch(Map<String, Map<String, Trait>> batch) {}

  @override
  void ingestCells(Map<CellKey, Trait> cells) {}

  @override
  void ingestRawPayloads(Map<(int, String), Uint8List> rawPayloads) {}

  @override
  void ingestTraits(String uri, Map<String, Trait> traits) {}

  @override
  bool isKindResolved(String uri, int kind) => false;

  @override
  Future<void> loadBatch({
    required List<String> uris,
    required DataStatement statement,
  }) async {}

  @override
  Stream<Map<String, Trait>> watchEntity(String uri) =>
      const Stream<Map<String, Trait>>.empty();
}

void main() {
  group('NativePlaybackSessionBridge', () {
    test('NativeAuthRefreshReason.tryFromCode maps reason codes 1, 2, 3 and rejects unknown codes', () {
      expect(
        NativeAuthRefreshReason.tryFromCode(1),
        equals(NativeAuthRefreshReason.accessToken401),
      );
      expect(
        NativeAuthRefreshReason.tryFromCode(2),
        equals(NativeAuthRefreshReason.clientTokenError),
      );
      expect(
        NativeAuthRefreshReason.tryFromCode(3),
        equals(NativeAuthRefreshReason.dealerWs401),
      );
      expect(NativeAuthRefreshReason.tryFromCode(0), isNull);
      expect(NativeAuthRefreshReason.tryFromCode(4), isNull);
      expect(NativeAuthRefreshReason.tryFromCode(-1), isNull);
    });

    test('init() and syncSessionToNative() push setClientProfile strictly before setAuthSession, and clearNativeAuthSession() resets cleanly', () async {
      final ffi = _BridgeFakeFfiBindings();
      final tokenStore = _FakeTokenStore();
      final authProvider = _FakeAuthSessionProvider(tokenStore);
      final runtimeContext = RuntimeContext(
        country: 'DE',
        catalogue: 'premium',
        acceptLanguage: 'de-DE',
      );
      final bridge = NativePlaybackSessionBridge(
        authSessionProvider: authProvider,
        tokenStore: tokenStore,
        runtimeContext: runtimeContext,
        refreshMutex: TokenRefreshMutex(),
        dataPool: _NoopDataPool(),
        ffi: ffi,
        cacheDirResolver: () async => '/tmp/musify_test_cache',
      );

      await bridge.init();

      expect(ffi.authRefreshPort, isNonZero);
      expect(tokenStore.listenerCount, equals(1));
      expect(
        ffi.callOrder,
        containsAllInOrder(<String>[
          'initDartApiDl',
          'setClientProfile',
          'setAuthSession',
        ]),
      );
      expect(ffi.clientProfiles, hasLength(1));
      expect(
        ffi.clientProfiles.single.clientId,
        equals(AuthClientProfileConfig.webPlayerClientId),
      );
      expect(ffi.clientProfiles.single.appPlatform, equals('WebPlayer'));
      expect(ffi.clientProfiles.single.sendOriginHeaders, equals(1));

      expect(ffi.authSessions, hasLength(1));
      expect(
        ffi.authSessions.single.accessToken,
        equals('initial_access_token'),
      );
      expect(
        ffi.authSessions.single.clientToken,
        equals('initial_client_token'),
      );
      expect(ffi.authSessions.single.spDc, equals('initial_sp_dc_cookie'));
      expect(ffi.authSessions.single.country, equals('DE'));
      expect(ffi.authSessions.single.catalogue, equals('premium'));
      expect(ffi.authSessions.single.acceptLanguage, equals('de-DE'));
      expect(
        ffi.authSessions.single.cacheDir,
        equals('/tmp/musify_test_cache'),
      );

      // Switch to Android profile and syncAuthSession()
      authProvider.profileConfig = AuthClientProfileConfig.androidDefault;
      tokenStore.accessToken = 'android_at';
      tokenStore.clientToken = 'android_ct';
      await bridge.syncAuthSession();

      expect(ffi.clientProfiles.last.clientId, equals('9a8d2f0ce77a4e248bb71fefcb557637'));
      expect(ffi.clientProfiles.last.appPlatform, equals('Android'));
      expect(ffi.clientProfiles.last.sendOriginHeaders, equals(0));
      expect(ffi.authSessions.last.accessToken, equals('android_at'));
      expect(ffi.authSessions.last.clientToken, equals('android_ct'));

      // clearNativeAuthSession resets profile to webPlayerDefault and clears tokens
      await bridge.clearNativeAuthSession();
      expect(
        ffi.clientProfiles.last.clientId,
        equals(AuthClientProfileConfig.webPlayerClientId),
      );
      expect(ffi.clientProfiles.last.sendOriginHeaders, equals(1));
      expect(ffi.authSessions.last.accessToken, isEmpty);
      expect(ffi.authSessions.last.clientToken, isEmpty);
      expect(ffi.authSessions.last.spDc, isEmpty);

      bridge.dispose();
      expect(ffi.authRefreshPort, equals(0));
      expect(tokenStore.listenerCount, equals(0));
    });

    test('dispatches native auth refresh reason codes 1 (accessToken401), 2 (clientTokenError), and 3 (dealerWs401) and surfaces failures', () async {
      final ffi = _BridgeFakeFfiBindings();
      final tokenStore = _FakeTokenStore();
      final authProvider = _FakeAuthSessionProvider(tokenStore);
      final bridge = NativePlaybackSessionBridge(
        authSessionProvider: authProvider,
        tokenStore: tokenStore,
        runtimeContext: RuntimeContext(),
        refreshMutex: TokenRefreshMutex(),
        dataPool: _NoopDataPool(),
        ffi: ffi,
        cacheDirResolver: () async => '/tmp/musify_test_cache',
      );
      addTearDown(bridge.dispose);

      await bridge.init();
      final failures = <NativeAuthRefreshFailure>[];
      final failureSub = bridge.refreshFailures.listen(failures.add);
      addTearDown(failureSub.cancel);

      // Reason 1: access_token_401 -> refreshAccessToken() + getClientToken() + sync
      authProvider.nextRefreshedAccessToken = 'at_after_401';
      authProvider.nextClientToken = 'ct_after_401';
      await bridge.handleNativeAuthRefresh(
        NativeAuthRefreshReason.accessToken401,
      );
      expect(authProvider.refreshAccessTokenCalls, equals(1));
      expect(authProvider.getClientTokenCalls, equals(1));
      expect(authProvider.forceRefreshClientTokenCalls, equals(0));
      expect(ffi.authSessions.last.accessToken, equals('at_after_401'));
      expect(ffi.authSessions.last.clientToken, equals('ct_after_401'));

      // Reason 2: client_token_error -> forceRefreshClientToken() ONLY + sync
      authProvider.nextForcedClientToken = 'ct_forced_after_error';
      await bridge.handleNativeAuthRefresh(
        NativeAuthRefreshReason.clientTokenError,
      );
      expect(authProvider.refreshAccessTokenCalls, equals(1));
      expect(authProvider.forceRefreshClientTokenCalls, equals(1));
      expect(ffi.authSessions.last.clientToken, equals('ct_forced_after_error'));

      // Reason 3 via ReceivePort (dealer_ws_401) -> refreshAccessToken() + getClientToken() + sync
      authProvider.nextRefreshedAccessToken = 'at_after_dealer_401';
      authProvider.nextClientToken = 'ct_after_dealer_401';
      final sendPort = bridge.authRefreshSendPort;
      expect(sendPort, isNotNull);
      if (sendPort != null) {
        sendPort.send(3);
      }
      await pumpEventQueue();
      expect(authProvider.refreshAccessTokenCalls, equals(2));
      expect(authProvider.getClientTokenCalls, equals(2));
      expect(ffi.authSessions.last.accessToken, equals('at_after_dealer_401'));

      // Failure case: empty token emits NativeAuthRefreshFailure
      authProvider.nextForcedClientToken = '';
      await bridge.handleNativeAuthRefresh(
        NativeAuthRefreshReason.clientTokenError,
      );
      expect(failures, hasLength(1));
      expect(
        failures.single.reason,
        equals(NativeAuthRefreshReason.clientTokenError),
      );
    });

    test('warms Kodiak disk cache via DataPool.ensureDiskLoaded() strictly before syncSessionToNative() and retries cleanly after error', () async {
      final ffi = _BridgeFakeFfiBindings();
      final tokenStore = _FakeTokenStore();
      final authProvider = _FakeAuthSessionProvider(tokenStore);
      final dataPool = _NoopDataPool(eventLog: ffi.callOrder);
      final bridge = NativePlaybackSessionBridge(
        authSessionProvider: authProvider,
        tokenStore: tokenStore,
        runtimeContext: RuntimeContext(),
        refreshMutex: TokenRefreshMutex(),
        dataPool: dataPool,
        ffi: ffi,
        cacheDirResolver: () async => '/tmp/musify_test_cache',
      );
      addTearDown(bridge.dispose);

      await bridge.init();
      expect(dataPool.ensureDiskLoadedCalls, equals(1));
      expect(
        ffi.callOrder,
        containsAllInOrder(<String>[
          'ensureDiskLoaded',
          'setClientProfile',
          'setAuthSession',
        ]),
      );

      // Subsequent syncs coalesce onto the completed warm-up future without re-loading disk.
      await bridge.syncSessionToNative();
      expect(dataPool.ensureDiskLoadedCalls, equals(1));

      // Separate bridge where initial disk warm-up fails: resets future and retries on next sync.
      final ffi2 = _BridgeFakeFfiBindings();
      final dataPool2 = _NoopDataPool(eventLog: ffi2.callOrder)
        ..failNextEnsureDiskLoaded = true;
      final bridge2 = NativePlaybackSessionBridge(
        authSessionProvider: authProvider,
        tokenStore: tokenStore,
        runtimeContext: RuntimeContext(),
        refreshMutex: TokenRefreshMutex(),
        dataPool: dataPool2,
        ffi: ffi2,
        cacheDirResolver: () async => '/tmp/musify_test_cache',
      );
      addTearDown(bridge2.dispose);

      await bridge2.init();
      // Initial init failed warm-up -> reset future -> _executeSyncSessionToNative retried immediately!
      expect(dataPool2.ensureDiskLoadedCalls, equals(2));
      expect(ffi2.authSessions, hasLength(1));
    });
  });
}
