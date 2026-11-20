import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// Typed failure hierarchy for [ApResolveService] endpoint resolution.
@immutable
sealed class ApResolveFailure extends Equatable {
  final String message;

  const ApResolveFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// APResolve request exceeded its configured timeout.
@immutable
final class ApResolveTimeoutFailure extends ApResolveFailure {
  final Duration timeout;

  const ApResolveTimeoutFailure({
    required this.timeout,
    required String message,
  }) : super(message);

  @override
  List<Object?> get props => [timeout, message];
}

/// APResolve failed due to socket/network unavailability.
@immutable
final class ApResolveOfflineFailure extends ApResolveFailure {
  const ApResolveOfflineFailure(super.message);
}

/// APResolve returned a non-200 HTTP status code.
@immutable
final class ApResolveHttpStatusFailure extends ApResolveFailure {
  final int statusCode;

  const ApResolveHttpStatusFailure({
    required this.statusCode,
    required String message,
  }) : super(message);

  @override
  List<Object?> get props => [statusCode, message];
}

/// APResolve payload was malformed or contained no usable endpoints.
@immutable
final class ApResolveParseFailure extends ApResolveFailure {
  const ApResolveParseFailure(super.message);
}

/// Immutable resolved Spotify `spclient`, `dealer-g2`, and `accesspoint`
/// endpoints matching C++ `ApResolveClient` (`#47 §3`).
@immutable
final class ApResolveEndpoints extends Equatable {
  static const String fallbackSpclientBaseUrl =
      'https://spclient.wg.spotify.com/';
  static const String fallbackDealerWsUrl = 'wss://dealer.g2.spotify.com:443/';

  /// Normalized HTTPS base URL with trailing slash (e.g. `https://spclient.wg.spotify.com/`).
  final String spclientBaseUrl;

  /// Normalized WSS URL with port and trailing slash (e.g. `wss://dealer.g2.spotify.com:443/`).
  final String dealerWsUrl;

  /// Access points (`host:port`) resolved from `accesspoint`.
  final UnmodifiableListView<String> accessPoints;

  /// Whether [spclientBaseUrl] or [dealerWsUrl] fell back to static defaults.
  final bool resolvedFromFallback;

  /// Typed failure cause when [resolvedFromFallback] is `true` due to an error.
  final ApResolveFailure? failure;

  ApResolveEndpoints({
    required this.spclientBaseUrl,
    required this.dealerWsUrl,
    required List<String> accessPoints,
    required this.resolvedFromFallback,
    this.failure,
  }) : accessPoints = UnmodifiableListView<String>(
          List<String>.of(accessPoints),
        ) {
    if (spclientBaseUrl.trim().isEmpty) {
      throw ArgumentError.value(
        spclientBaseUrl,
        'spclientBaseUrl',
        'Must be non-empty',
      );
    }
    if (dealerWsUrl.trim().isEmpty) {
      throw ArgumentError.value(
        dealerWsUrl,
        'dealerWsUrl',
        'Must be non-empty',
      );
    }
  }

  /// Deterministic static fallback endpoints (`https://spclient.wg.spotify.com/`
  /// and `wss://dealer.g2.spotify.com:443/`).
  factory ApResolveEndpoints.fallback({ApResolveFailure? failure}) {
    return ApResolveEndpoints(
      spclientBaseUrl: fallbackSpclientBaseUrl,
      dealerWsUrl: fallbackDealerWsUrl,
      accessPoints: const <String>[],
      resolvedFromFallback: true,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [
        spclientBaseUrl,
        dealerWsUrl,
        accessPoints,
        resolvedFromFallback,
        failure,
      ];
}

/// Resolves regional Spotify `spclient`, `dealer-g2`, and `accesspoint`
/// endpoints from `https://apresolve.spotify.com/v2`.
final class ApResolveService {
  static const String _apResolveBaseUrl = 'https://apresolve.spotify.com/v2';
  static const Duration defaultTimeout = Duration(seconds: 8);

  final http.Client? _httpClient;
  final int Function() _epochSecondsProvider;
  ApResolveEndpoints? _lastResolvedEndpoints;

  ApResolveService({
    http.Client? httpClient,
    int Function()? epochSecondsProvider,
  })  : _httpClient = httpClient,
        _epochSecondsProvider = switch (epochSecondsProvider) {
          final provider? => provider,
          null => _defaultEpochSeconds,
        };

  static int _defaultEpochSeconds() =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// Most recent resolved endpoints snapshot, or `null` before first [resolve].
  ApResolveEndpoints? get lastResolvedEndpoints => _lastResolvedEndpoints;

  /// Resolves Spotify endpoints from `apresolve.spotify.com/v2` with an
  /// explicit [timeout], falling back deterministically to
  /// [ApResolveEndpoints.fallback] on timeout, offline, HTTP, or parse failure.
  Future<ApResolveEndpoints> resolve({
    Duration timeout = defaultTimeout,
  }) async {
    final epochSeconds = _epochSecondsProvider();
    final uri = Uri.parse(
      '$_apResolveBaseUrl?time=$epochSeconds'
      '&type=accesspoint&type=spclient&type=dealer-g2',
    );

    final client = _httpClient;
    try {
      final http.Response response;
      if (client != null) {
        response = await client.get(
          uri,
          headers: const <String, String>{
            'Accept': 'application/json',
          },
        ).timeout(timeout);
      } else {
        response = await http.get(
          uri,
          headers: const <String, String>{
            'Accept': 'application/json',
          },
        ).timeout(timeout);
      }

      if (response.statusCode != 200) {
        final failure = ApResolveHttpStatusFailure(
          statusCode: response.statusCode,
          message: 'APResolve returned HTTP ${response.statusCode}',
        );
        dev.log(
          'ApResolveService: ${failure.message}, using fallback endpoints',
          name: 'NET',
        );
        final fallback = ApResolveEndpoints.fallback(failure: failure);
        _lastResolvedEndpoints = fallback;
        return fallback;
      }

      final parsed = parseResponseJson(response.body);
      _lastResolvedEndpoints = parsed;
      dev.log(
        'ApResolveService: spclient=${parsed.spclientBaseUrl} '
        'dealer=${parsed.dealerWsUrl} fallback=${parsed.resolvedFromFallback}',
        name: 'NET',
      );
      return parsed;
    } on TimeoutException catch (e) {
      final failure = ApResolveTimeoutFailure(
        timeout: timeout,
        message: 'APResolve timed out after ${timeout.inMilliseconds}ms: $e',
      );
      dev.log(
        'ApResolveService: ${failure.message}, using fallback endpoints',
        name: 'NET',
      );
      final fallback = ApResolveEndpoints.fallback(failure: failure);
      _lastResolvedEndpoints = fallback;
      return fallback;
    } on SocketException catch (e) {
      final failure = ApResolveOfflineFailure(
        'APResolve socket failure: ${e.message}',
      );
      dev.log(
        'ApResolveService: ${failure.message}, using fallback endpoints',
        name: 'NET',
      );
      final fallback = ApResolveEndpoints.fallback(failure: failure);
      _lastResolvedEndpoints = fallback;
      return fallback;
    } on http.ClientException catch (e) {
      final failure = ApResolveOfflineFailure(
        'APResolve client failure: ${e.message}',
      );
      dev.log(
        'ApResolveService: ${failure.message}, using fallback endpoints',
        name: 'NET',
      );
      final fallback = ApResolveEndpoints.fallback(failure: failure);
      _lastResolvedEndpoints = fallback;
      return fallback;
    } on FormatException catch (e) {
      final failure = ApResolveParseFailure(
        'APResolve parse failure: ${e.message}',
      );
      dev.log(
        'ApResolveService: ${failure.message}, using fallback endpoints',
        name: 'NET',
      );
      final fallback = ApResolveEndpoints.fallback(failure: failure);
      _lastResolvedEndpoints = fallback;
      return fallback;
    }
  }

  /// Parses an APResolve v2/v1 JSON response body into [ApResolveEndpoints].
  ///
  /// Throws [FormatException] if [jsonBody] is not a valid JSON object or
  /// contains neither a valid `spclient` nor `dealer-g2` candidate.
  static ApResolveEndpoints parseResponseJson(String jsonBody) {
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonBody);
    } on FormatException catch (e) {
      throw FormatException('Invalid APResolve JSON: ${e.message}', jsonBody);
    }

    if (decoded is! Map<String, Object?>) {
      throw FormatException(
        'APResolve JSON root must be a JSON object',
        jsonBody,
      );
    }

    final spclientCandidates = _extractHostCandidates(decoded['spclient']);
    final dealerG2Candidates = _extractHostCandidates(decoded['dealer-g2']);
    final legacyDealerCandidates = _extractHostCandidates(decoded['dealer']);
    final dealerCandidates = dealerG2Candidates.isNotEmpty
        ? dealerG2Candidates
        : legacyDealerCandidates;
    final accessPoints = _extractHostCandidates(decoded['accesspoint']);

    if (spclientCandidates.isEmpty && dealerCandidates.isEmpty) {
      throw FormatException(
        'APResolve response contained no spclient or dealer-g2 candidates',
        jsonBody,
      );
    }

    final String spclientBaseUrl;
    var usedFallback = false;
    if (spclientCandidates.isNotEmpty) {
      spclientBaseUrl = normalizeSpclientBaseUrl(spclientCandidates.first);
    } else {
      spclientBaseUrl = ApResolveEndpoints.fallbackSpclientBaseUrl;
      usedFallback = true;
    }

    final String dealerWsUrl;
    if (dealerCandidates.isNotEmpty) {
      dealerWsUrl = normalizeDealerWsUrl(dealerCandidates.first);
    } else {
      dealerWsUrl = ApResolveEndpoints.fallbackDealerWsUrl;
      usedFallback = true;
    }

    return ApResolveEndpoints(
      spclientBaseUrl: spclientBaseUrl,
      dealerWsUrl: dealerWsUrl,
      accessPoints: accessPoints,
      resolvedFromFallback: usedFallback,
    );
  }

  /// Extracts ordered non-empty endpoint strings from either a v2 nested map
  /// (`{"regional": [...], "global": [...]}`) preferring `regional` then
  /// `global`, or a flat list (`["host:port", ...]`).
  static List<String> _extractHostCandidates(Object? node) {
    final results = <String>[];
    if (node is Map<Object?, Object?>) {
      _appendStringItems(node['regional'], results);
      _appendStringItems(node['global'], results);
      return results;
    }
    if (node is List<Object?>) {
      _appendStringItems(node, results);
      return results;
    }
    return results;
  }

  static void _appendStringItems(Object? rawList, List<String> target) {
    if (rawList is! List<Object?>) {
      return;
    }
    for (final item in rawList) {
      if (item is String) {
        final trimmed = item.trim();
        if (trimmed.isNotEmpty && !target.contains(trimmed)) {
          target.add(trimmed);
        }
      }
    }
  }

  /// Normalizes a raw `spclient` host/URL (e.g. `"gew4-spclient.spotify.com:443"`
  /// or `"https://spclient.wg.spotify.com"`) into `"https://<host>/"` (or
  /// `"https://<host>:<port>/"` when port != 443).
  static String normalizeSpclientBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw FormatException('spclient endpoint must not be empty', raw);
    }
    if (trimmed.startsWith('https://') || trimmed.startsWith('http://')) {
      final parsed = Uri.tryParse(trimmed);
      if (parsed == null || parsed.host.isEmpty) {
        throw FormatException('Invalid spclient URL: $raw', raw);
      }
      final portPart =
          (parsed.hasPort && parsed.port != 443 && parsed.port != 80)
              ? ':${parsed.port}'
              : '';
      return 'https://${parsed.host}$portPart/';
    }

    final hostPort = _splitHostAndPort(trimmed, defaultPort: 443);
    final portSuffix = hostPort.port == 443 ? '' : ':${hostPort.port}';
    return 'https://${hostPort.host}$portSuffix/';
  }

  /// Normalizes a raw `dealer-g2` host/URL (e.g. `"gew4-dealer.spotify.com:443"`
  /// or `"wss://dealer.g2.spotify.com:443/"`) into `"wss://<host>:<port>/"`.
  static String normalizeDealerWsUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw FormatException('dealer-g2 endpoint must not be empty', raw);
    }
    if (trimmed.startsWith('wss://') || trimmed.startsWith('ws://')) {
      final parsed = Uri.tryParse(trimmed);
      if (parsed == null || parsed.host.isEmpty) {
        throw FormatException('Invalid dealer-g2 URL: $raw', raw);
      }
      final port = parsed.hasPort && parsed.port > 0 ? parsed.port : 443;
      return 'wss://${parsed.host}:$port/';
    }

    final hostPort = _splitHostAndPort(trimmed, defaultPort: 443);
    return 'wss://${hostPort.host}:${hostPort.port}/';
  }

  static ({String host, int port}) _splitHostAndPort(
    String rawHostPort, {
    required int defaultPort,
  }) {
    final slashIndex = rawHostPort.indexOf('/');
    final authority =
        slashIndex >= 0 ? rawHostPort.substring(0, slashIndex) : rawHostPort;
    final colonIndex = authority.lastIndexOf(':');
    if (colonIndex <= 0) {
      if (authority.isEmpty) {
        throw FormatException('Endpoint host must not be empty', rawHostPort);
      }
      return (host: authority, port: defaultPort);
    }
    final host = authority.substring(0, colonIndex).trim();
    final portStr = authority.substring(colonIndex + 1).trim();
    final parsedPort = int.tryParse(portStr);
    if (host.isEmpty ||
        parsedPort == null ||
        parsedPort <= 0 ||
        parsedPort > 65535) {
      throw FormatException('Invalid host:port endpoint: $rawHostPort', rawHostPort);
    }
    return (host: host, port: parsedPort);
  }
}
