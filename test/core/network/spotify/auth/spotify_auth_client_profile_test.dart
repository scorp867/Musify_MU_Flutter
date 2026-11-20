import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:musify_mu/core/config/device_identity_service.dart';
import 'package:musify_mu/core/network/spotify/auth/auth_session_provider.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_client_token.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_refresher.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_totp.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class _FakeSpotifyTotp implements SpotifyTotp {
  int ensureFreshCalls = 0;
  int refreshCipherCalls = 0;

  @override
  int get version => 61;

  @override
  String generate(int timestampMs) => '123456';

  @override
  Future<void> loadFromCache() async {}

  @override
  Future<void> ensureFreshCipher() async {
    ensureFreshCalls += 1;
  }

  @override
  Future<void> refreshCipher() async {
    refreshCipherCalls += 1;
  }
}

final class _RecordedHttpCall {
  final String method;
  final Uri url;
  final Map<String, String> headers;
  final String body;

  const _RecordedHttpCall({
    required this.method,
    required this.url,
    required this.headers,
    required this.body,
  });
}

final class _ZoneHttpClient extends http.BaseClient {
  final List<_RecordedHttpCall> calls;
  final Future<http.Response> Function(_RecordedHttpCall call) handler;

  _ZoneHttpClient({
    required this.calls,
    required this.handler,
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bodyBytes = await request.finalize().toBytes();
    final bodyText = utf8.decode(bodyBytes, allowMalformed: true);
    final call = _RecordedHttpCall(
      method: request.method,
      url: request.url,
      headers: Map<String, String>.of(request.headers),
      body: bodyText,
    );
    calls.add(call);
    final response = await handler(call);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final Map<String, String> mockSecureMap = <String, String>{};

  setUp(() {
    mockSecureMap.clear();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (MethodCall call) async {
      final args = call.arguments;
      final String? key = switch (args) {
        final Map<Object?, Object?> m => switch (m['key']) {
            final String k => k,
            _ => null,
          },
        _ => null,
      };
      final String? value = switch (args) {
        final Map<Object?, Object?> m => switch (m['value']) {
            final String v => v,
            _ => null,
          },
        _ => null,
      };

      switch (call.method) {
        case 'write':
          if (key != null && value != null) {
            mockSecureMap[key] = value;
          } else if (key != null) {
            mockSecureMap.remove(key);
          }
          return null;
        case 'read':
          if (key == null) return null;
          return mockSecureMap[key];
        case 'delete':
          if (key != null) {
            mockSecureMap.remove(key);
          }
          return null;
        case 'deleteAll':
          mockSecureMap.clear();
          return null;
        case 'containsKey':
          if (key == null) return false;
          return mockSecureMap.containsKey(key);
        case 'readAll':
          return Map<String, String>.of(mockSecureMap);
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  group('AuthClientProfileConfig & SpotifyTokenStore', () {
    test('AuthClientProfileConfig.forClientId resolves webPlayer and android profiles deterministically', () {
      final defaultNull = AuthClientProfileConfig.forClientId(null);
      expect(defaultNull, equals(AuthClientProfileConfig.webPlayerDefault));
      expect(defaultNull.profile, equals(AuthClientProfile.webPlayer));
      expect(
        defaultNull.clientId,
        equals('d8a5ed958d274c2e8ee717e6a4b0971d'),
      );
      expect(defaultNull.sendOriginHeaders, isTrue);

      final defaultEmpty = AuthClientProfileConfig.forClientId('   ');
      expect(defaultEmpty, equals(AuthClientProfileConfig.webPlayerDefault));

      final android = AuthClientProfileConfig.forClientId(
        '9a8d2f0ce77a4e248bb71fefcb557637',
      );
      expect(android.profile, equals(AuthClientProfile.android));
      expect(android.clientId, equals('9a8d2f0ce77a4e248bb71fefcb557637'));
      expect(android.appPlatform, equals('Android'));
      expect(android.sendOriginHeaders, isFalse);

      final customWeb = AuthClientProfileConfig.forClientId('custom_web_id');
      expect(customWeb.profile, equals(AuthClientProfile.webPlayer));
      expect(customWeb.clientId, equals('custom_web_id'));
      expect(customWeb.sendOriginHeaders, isTrue);
    });

    test('normalizeSpDcValue and formatSpDcCookieHeader prevent double sp_dc= prefixing', () async {
      expect(
        SpotifyTokenStore.normalizeSpDcValue('sp_dc=sp_dc=AQB_RAW_COOKIE_12345'),
        equals('AQB_RAW_COOKIE_12345'),
      );
      expect(
        SpotifyTokenStore.normalizeSpDcValue('  SP_DC=AQB_RAW_COOKIE_12345  '),
        equals('AQB_RAW_COOKIE_12345'),
      );
      expect(
        SpotifyTokenStore.formatSpDcCookieHeader(
          'sp_dc=sp_dc=AQB_RAW_COOKIE_12345',
        ),
        equals('sp_dc=AQB_RAW_COOKIE_12345'),
      );
      expect(SpotifyTokenStore.formatSpDcCookieHeader('sp_dc=   '), isEmpty);

      final store = SpotifyTokenStore(storage: const FlutterSecureStorage());
      var changeNotifications = 0;
      void onChanged() {
        changeNotifications += 1;
      }

      store.addChangeListener(onChanged);
      await store.saveSpDc('sp_dc=sp_dc=AQB_STORED_COOKIE_999');
      expect(await store.getSpDc(), equals('AQB_STORED_COOKIE_999'));
      expect(mockSecureMap['spotify_sp_dc'], equals('AQB_STORED_COOKIE_999'));
      expect(changeNotifications, equals(1));

      // Active client ID persistence & default fallback
      expect(
        await store.getActiveClientId(),
        equals(AuthClientProfileConfig.webPlayerClientId),
      );
      expect(
        await store.getActiveClientProfile(),
        equals(AuthClientProfile.webPlayer),
      );

      await store.saveActiveClientId(AuthClientProfileConfig.androidClientId);
      expect(
        await store.getActiveClientId(),
        equals(AuthClientProfileConfig.androidClientId),
      );
      expect(
        await store.getActiveClientProfile(),
        equals(AuthClientProfile.android),
      );
      final config = await store.getActiveClientProfileConfig();
      expect(config.sendOriginHeaders, isFalse);

      // Access token expiry persistence
      await store.saveAccessToken('BQD_TOKEN', lifetimeMs: 1800000);
      final expiryMs = await store.getAccessTokenExpiryMs();
      expect(expiryMs, isNotNull);

      store.removeChangeListener(onChanged);
      await store.clearAll();
      expect(await store.getSpDc(), isNull);
      expect(
        await store.getActiveClientId(),
        equals(AuthClientProfileConfig.webPlayerClientId),
      );
    });
  });

  group('SpotifyTokenRefresher & SpotifyClientTokenFetcher', () {
    test('SpotifyTokenRefresher normalizes legacy sp_dc, sends single sp_dc= Cookie, and captures clientId', () async {
      final store = SpotifyTokenStore(storage: const FlutterSecureStorage());
      // Simulate legacy double-prefixed sp_dc already in raw storage.
      mockSecureMap['spotify_sp_dc'] =
          'sp_dc=sp_dc=AQB_LEGACY_VALID_COOKIE_123456';
      expect(
        await store.getSpDc(),
        equals('AQB_LEGACY_VALID_COOKIE_123456'),
      );

      final totp = _FakeSpotifyTotp();
      final refresher = SpotifyTokenRefresher(tokenStore: store, totp: totp);
      final recordedCalls = <_RecordedHttpCall>[];

      final futureExpiryMs = DateTime.now().millisecondsSinceEpoch + 2400000;

      final token = await http.runWithClient(
        refresher.refresh,
        () => _ZoneHttpClient(
          calls: recordedCalls,
          handler: (call) async {
            if (call.method == 'HEAD') {
              return http.Response(
                '',
                200,
                headers: <String, String>{
                  'date': 'Thu, 19 Nov 2026 19:00:00 GMT',
                },
              );
            }
            return http.Response(
              jsonEncode(<String, Object>{
                'accessToken': 'BQD_FRESH_ACCESS_TOKEN',
                'isAnonymous': false,
                'clientId': 'd8a5ed958d274c2e8ee717e6a4b0971d',
                'accessTokenExpirationTimestampMs': futureExpiryMs,
              }),
              200,
            );
          },
        ),
      );

      expect(token, equals('BQD_FRESH_ACCESS_TOKEN'));
      expect(await store.getAccessToken(), equals('BQD_FRESH_ACCESS_TOKEN'));
      expect(
        await store.getActiveClientId(),
        equals('d8a5ed958d274c2e8ee717e6a4b0971d'),
      );

      final tokenGetCalls = recordedCalls
          .where((c) => c.url.path == '/api/token')
          .toList(growable: false);
      expect(tokenGetCalls, hasLength(1));
      expect(
        tokenGetCalls.single.headers['Cookie'],
        equals('sp_dc=AQB_LEGACY_VALID_COOKIE_123456'),
      );
    });

    test('SpotifyClientTokenFetcher persists canonical 40-hex device_id across forceRefreshClientToken() without rotation', () async {
      final prefs = await SharedPreferences.getInstance();
      final identityService = DeviceIdentityService(preferences: prefs);
      final canonicalId = await identityService.getOrCreateDeviceId(
        androidId: 'pixel_9_pro_real_android_id',
      );
      expect(
        DeviceIdentityService.isValidCanonicalDeviceId(canonicalId),
        isTrue,
      );

      final store = SpotifyTokenStore(storage: const FlutterSecureStorage());
      await store.saveActiveClientId(AuthClientProfileConfig.webPlayerClientId);

      final fetcher = SpotifyClientTokenFetcher(
        store,
        deviceIdentityService: identityService,
      );

      final recordedCalls = <_RecordedHttpCall>[];
      var callCounter = 0;

      Future<http.Response> handleClientToken(_RecordedHttpCall call) async {
        callCounter += 1;
        return http.Response(
          jsonEncode(<String, Object>{
            'response_type': 'RESPONSE_GRANTED_TOKEN_RESPONSE',
            'granted_token': <String, Object>{
              'token': 'CT_TOKEN_$callCounter',
              'expires_after_seconds': 3600,
            },
          }),
          200,
        );
      }

      final token1 = await http.runWithClient(
        fetcher.getClientToken,
        () => _ZoneHttpClient(
          calls: recordedCalls,
          handler: handleClientToken,
        ),
      );
      expect(token1, equals('CT_TOKEN_1'));

      // Cached call does not hit network
      final cachedToken = await http.runWithClient(
        fetcher.getClientToken,
        () => _ZoneHttpClient(
          calls: recordedCalls,
          handler: handleClientToken,
        ),
      );
      expect(cachedToken, equals('CT_TOKEN_1'));
      expect(recordedCalls, hasLength(1));

      // forceRefreshClientToken invalidates cached token and fetches fresh token
      // while preserving the exact canonical 40-hex device_id.
      final token2 = await http.runWithClient(
        fetcher.forceRefreshClientToken,
        () => _ZoneHttpClient(
          calls: recordedCalls,
          handler: handleClientToken,
        ),
      );
      expect(token2, equals('CT_TOKEN_2'));
      expect(recordedCalls, hasLength(2));

      for (final call in recordedCalls) {
        final decoded = jsonDecode(call.body);
        expect(decoded, isA<Map<String, Object?>>());
        if (decoded case final Map<String, Object?> root) {
          final clientData = root['client_data'];
          expect(clientData, isA<Map<String, Object?>>());
          if (clientData case final Map<String, Object?> cd) {
            expect(
              cd['client_id'],
              equals(AuthClientProfileConfig.webPlayerClientId),
            );
            final jsSdkData = cd['js_sdk_data'];
            expect(jsSdkData, isA<Map<String, Object?>>());
            if (jsSdkData case final Map<String, Object?> sdk) {
              expect(sdk['device_id'], equals(canonicalId));
            }
          }
        }
      }

      // Verify SpotifyAuthSessionProvider delegates all profile & refresh methods
      final provider = SpotifyAuthSessionProvider(
        tokenStore: store,
        tokenRefresher: SpotifyTokenRefresher(
          tokenStore: store,
          totp: _FakeSpotifyTotp(),
        ),
        clientTokenFetcher: fetcher,
      );
      expect(
        await provider.getActiveClientId(),
        equals(AuthClientProfileConfig.webPlayerClientId),
      );
      expect(
        await provider.getActiveClientProfile(),
        equals(AuthClientProfile.webPlayer),
      );
      final profileConfig = await provider.getActiveClientProfileConfig();
      expect(profileConfig.sendOriginHeaders, isTrue);

      final token3 = await http.runWithClient(
        provider.forceRefreshClientToken,
        () => _ZoneHttpClient(
          calls: recordedCalls,
          handler: handleClientToken,
        ),
      );
      expect(token3, equals('CT_TOKEN_3'));
    });
  });
}
