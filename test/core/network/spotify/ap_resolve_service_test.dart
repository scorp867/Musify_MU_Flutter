import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:musify_mu/core/network/spotify/ap_resolve_service.dart';

final class _FakeHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) _handler;
  Uri? lastRequestedUri;
  Map<String, String> lastHeaders = const <String, String>{};

  _FakeHttpClient(this._handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequestedUri = request.url;
    lastHeaders = Map<String, String>.of(request.headers);
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

void main() {
  group('ApResolveEndpoints & URL normalization', () {
    test('ApResolveEndpoints validates non-empty URLs and exposes immutable accessPoints', () {
      final endpoints = ApResolveEndpoints(
        spclientBaseUrl: 'https://gew4-spclient.spotify.com/',
        dealerWsUrl: 'wss://gew4-dealer.spotify.com:443/',
        accessPoints: <String>['ap1.spotify.com:4070'],
        resolvedFromFallback: false,
      );

      expect(endpoints.accessPoints, equals(<String>['ap1.spotify.com:4070']));
      expect(() => endpoints.accessPoints.add('mutated'), throwsUnsupportedError);
      expect(endpoints.resolvedFromFallback, isFalse);
      expect(endpoints.failure, isNull);

      expect(
        () => ApResolveEndpoints(
          spclientBaseUrl: '   ',
          dealerWsUrl: 'wss://dealer.g2.spotify.com:443/',
          accessPoints: const <String>[],
          resolvedFromFallback: false,
        ),
        throwsArgumentError,
      );
      expect(
        () => ApResolveEndpoints(
          spclientBaseUrl: 'https://spclient.wg.spotify.com/',
          dealerWsUrl: '',
          accessPoints: const <String>[],
          resolvedFromFallback: false,
        ),
        throwsArgumentError,
      );
    });

    test('normalizeSpclientBaseUrl and normalizeDealerWsUrl format hosts and fail fast on invalid input', () {
      expect(
        ApResolveService.normalizeSpclientBaseUrl('gew4-spclient.spotify.com:443'),
        equals('https://gew4-spclient.spotify.com/'),
      );
      expect(
        ApResolveService.normalizeSpclientBaseUrl('spclient.wg.spotify.com:8443'),
        equals('https://spclient.wg.spotify.com:8443/'),
      );
      expect(
        ApResolveService.normalizeSpclientBaseUrl('https://spclient.wg.spotify.com'),
        equals('https://spclient.wg.spotify.com/'),
      );
      expect(
        ApResolveService.normalizeSpclientBaseUrl('https://spclient.wg.spotify.com:9443/v1'),
        equals('https://spclient.wg.spotify.com:9443/'),
      );

      expect(
        ApResolveService.normalizeDealerWsUrl('gew4-dealer.spotify.com:443'),
        equals('wss://gew4-dealer.spotify.com:443/'),
      );
      expect(
        ApResolveService.normalizeDealerWsUrl('wss://dealer.g2.spotify.com:443/'),
        equals('wss://dealer.g2.spotify.com:443/'),
      );
      expect(
        ApResolveService.normalizeDealerWsUrl('ws://dealer.g2.spotify.com'),
        equals('wss://dealer.g2.spotify.com:443/'),
      );

      expect(
        () => ApResolveService.normalizeSpclientBaseUrl(''),
        throwsFormatException,
      );
      expect(
        () => ApResolveService.normalizeSpclientBaseUrl('host:99999'),
        throwsFormatException,
      );
      expect(
        () => ApResolveService.normalizeDealerWsUrl('   '),
        throwsFormatException,
      );
      expect(
        () => ApResolveService.normalizeDealerWsUrl('host:0'),
        throwsFormatException,
      );
    });

    test('parseResponseJson parses APResolve v2 regional/global hierarchy and v1 flat lists', () {
      const v2Json = '''
      {
        "spclient": {
          "regional": ["gew4-spclient.spotify.com:443"],
          "global": ["spclient.wg.spotify.com:443"]
        },
        "dealer-g2": {
          "regional": ["gew4-dealer.g2.spotify.com:443"],
          "global": ["dealer.g2.spotify.com:443"]
        },
        "accesspoint": ["ap-gew4.spotify.com:4070", "ap-gew4.spotify.com:443"]
      }
      ''';

      final parsedV2 = ApResolveService.parseResponseJson(v2Json);
      expect(
        parsedV2.spclientBaseUrl,
        equals('https://gew4-spclient.spotify.com/'),
      );
      expect(
        parsedV2.dealerWsUrl,
        equals('wss://gew4-dealer.g2.spotify.com:443/'),
      );
      expect(
        parsedV2.accessPoints,
        equals(<String>[
          'ap-gew4.spotify.com:4070',
          'ap-gew4.spotify.com:443',
        ]),
      );
      expect(parsedV2.resolvedFromFallback, isFalse);

      const v2GlobalFallbackJson = '''
      {
        "spclient": {
          "regional": [],
          "global": ["spclient.wg.spotify.com:443"]
        },
        "dealer": ["gae2-dealer.spotify.com:443"]
      }
      ''';
      final parsedGlobal = ApResolveService.parseResponseJson(v2GlobalFallbackJson);
      expect(
        parsedGlobal.spclientBaseUrl,
        equals('https://spclient.wg.spotify.com/'),
      );
      expect(
        parsedGlobal.dealerWsUrl,
        equals('wss://gae2-dealer.spotify.com:443/'),
      );
      expect(parsedGlobal.resolvedFromFallback, isFalse);

      const partialSpclientOnlyJson = '''
      {
        "spclient": ["gae2-spclient.spotify.com:443"]
      }
      ''';
      final partial = ApResolveService.parseResponseJson(partialSpclientOnlyJson);
      expect(
        partial.spclientBaseUrl,
        equals('https://gae2-spclient.spotify.com/'),
      );
      expect(
        partial.dealerWsUrl,
        equals(ApResolveEndpoints.fallbackDealerWsUrl),
      );
      expect(partial.resolvedFromFallback, isTrue);

      expect(
        () => ApResolveService.parseResponseJson('not-json'),
        throwsFormatException,
      );
      expect(
        () => ApResolveService.parseResponseJson('["array-root"]'),
        throwsFormatException,
      );
      expect(
        () => ApResolveService.parseResponseJson('{"spclient": [], "dealer-g2": []}'),
        throwsFormatException,
      );
    });
  });

  group('ApResolveService.resolve()', () {
    test('resolves endpoints from apresolve.spotify.com/v2 and caches lastResolvedEndpoints', () async {
      final client = _FakeHttpClient((_) async {
        return http.Response(
          '{"spclient":{"regional":["gew4-spclient.spotify.com:443"]},'
          '"dealer-g2":{"regional":["gew4-dealer.g2.spotify.com:443"]},'
          '"accesspoint":["ap.spotify.com:4070"]}',
          200,
        );
      });
      final service = ApResolveService(
        httpClient: client,
        epochSecondsProvider: () => 1763578800,
      );

      expect(service.lastResolvedEndpoints, isNull);
      final endpoints = await service.resolve();

      expect(
        client.lastRequestedUri.toString(),
        equals(
          'https://apresolve.spotify.com/v2'
          '?time=1763578800&type=accesspoint&type=spclient&type=dealer-g2',
        ),
      );
      expect(client.lastHeaders['Accept'], equals('application/json'));
      expect(
        endpoints.spclientBaseUrl,
        equals('https://gew4-spclient.spotify.com/'),
      );
      expect(
        endpoints.dealerWsUrl,
        equals('wss://gew4-dealer.g2.spotify.com:443/'),
      );
      expect(endpoints.resolvedFromFallback, isFalse);
      expect(endpoints.failure, isNull);
      expect(service.lastResolvedEndpoints, equals(endpoints));
    });

    test('falls back deterministically with typed ApResolveFailure on HTTP error, timeout, offline, and parse error', () async {
      final http503Service = ApResolveService(
        httpClient: _FakeHttpClient((_) async => http.Response('unavailable', 503)),
        epochSecondsProvider: () => 1000,
      );
      final http503Result = await http503Service.resolve();
      expect(http503Result.resolvedFromFallback, isTrue);
      expect(
        http503Result.spclientBaseUrl,
        equals(ApResolveEndpoints.fallbackSpclientBaseUrl),
      );
      expect(
        http503Result.dealerWsUrl,
        equals(ApResolveEndpoints.fallbackDealerWsUrl),
      );
      expect(http503Result.failure, isA<ApResolveHttpStatusFailure>());
      if (http503Result.failure case final ApResolveHttpStatusFailure f) {
        expect(f.statusCode, equals(503));
      }

      final timeoutService = ApResolveService(
        httpClient: _FakeHttpClient((_) async {
          throw TimeoutException('deadline exceeded');
        }),
      );
      final timeoutResult = await timeoutService.resolve(
        timeout: const Duration(seconds: 2),
      );
      expect(timeoutResult.resolvedFromFallback, isTrue);
      expect(timeoutResult.failure, isA<ApResolveTimeoutFailure>());

      final socketService = ApResolveService(
        httpClient: _FakeHttpClient((_) async {
          throw const SocketException('Network unreachable');
        }),
      );
      final socketResult = await socketService.resolve();
      expect(socketResult.resolvedFromFallback, isTrue);
      expect(socketResult.failure, isA<ApResolveOfflineFailure>());

      final clientErrService = ApResolveService(
        httpClient: _FakeHttpClient((_) async {
          throw http.ClientException('TLS handshake error');
        }),
      );
      final clientErrResult = await clientErrService.resolve();
      expect(clientErrResult.resolvedFromFallback, isTrue);
      expect(clientErrResult.failure, isA<ApResolveOfflineFailure>());

      final parseErrService = ApResolveService(
        httpClient: _FakeHttpClient(
          (_) async => http.Response('{"spclient":[],"dealer-g2":[]}', 200),
        ),
      );
      final parseErrResult = await parseErrService.resolve();
      expect(parseErrResult.resolvedFromFallback, isTrue);
      expect(parseErrResult.failure, isA<ApResolveParseFailure>());
    });
  });
}
