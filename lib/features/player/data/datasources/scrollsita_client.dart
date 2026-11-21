import 'dart:developer' as dev;

import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/result/network_result.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';
import 'package:musify_mu/core/protocol/generated/spotify/scrollsita/v1/scrollsita.pb.dart';
import 'package:musify_mu/features/player/domain/policies/spotify_track_eligibility_policy.dart';

/// Client for Spotify's Scrollsita endpoint.
///
/// 1:1 replica of decompiled Retrofit interface:
/// `p/epu0.java` (`src_main_java_com_spotify_nowplaying_scrollsection_nova-nova`).
///
/// Annotation contract:
/// ```java
/// @xo00({"Content-Type: application/x-protobuf", "Accept: application/protobuf"})
/// @cqy("scrollsita/v1/scroll/{now_playing_uri}")
/// Single<NpvScrollResponse> a(...);
/// ```
class ScrollSitaClient {
  final SpotifyTransport _transport;
  final RuntimeContext? _runtimeContext;

  static const String baseHost = 'https://gae2-spclient.spotify.com';

  const ScrollSitaClient({
    required SpotifyTransport transport,
    RuntimeContext? runtimeContext,
  }) : _transport = transport,
       _runtimeContext = runtimeContext;

  /// Fetches the ordered scroll sections for an eligible Spotify track URI.
  Future<NpvScrollResponse?> getNpvScroll({
    required String nowPlayingUri,
    String? playContextUri,
    bool isEnhancedContext = false,
    bool isPersonalizedContext = true,
    bool isTablet = false,
    bool isAiDjContext = false,
    bool isVideoLayerActive = false,
    String? timezone,
  }) async {
    final canonicalUri =
        SpotifyTrackEligibilityPolicy.resolveCanonicalSpotifyTrackUri(
          nowPlayingUri,
        );
    if (canonicalUri == null) {
      return null;
    }

    final tz = _resolveEffectiveTimezone(timezone);
    final queryParams = <String, String>{
      if (playContextUri != null && playContextUri.isNotEmpty)
        'play_context_uri': playContextUri,
      'is_enhanced_context': isEnhancedContext.toString(),
      'is_personalized_context': isPersonalizedContext.toString(),
      'is_tablet': isTablet.toString(),
      'is_ai_dj_context': isAiDjContext.toString(),
      'is_video_layer_active': isVideoLayerActive.toString(),
      'timezone': tz,
    };

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final path = 'scrollsita/v1/scroll/$canonicalUri?$queryString';

    final result = await _transport.getResult(
      path,
      baseHost: baseHost,
      priority: NetworkPriority.interactive,
      extraHeaders: const {
        'Content-Type': 'application/x-protobuf',
        'Accept': 'application/protobuf',
      },
    );

    switch (result) {
      case NetworkFailure(:final error, :final statusCode):
        dev.log(
          'ScrollSitaClient: HTTP failure for $canonicalUri '
          '(status=$statusCode, reason=${error.reason.name}, msg=${error.message})',
          error: error,
          name: 'ScrollSita',
        );
        return null;

      case NetworkSuccess(:final data, :final statusCode):
        if (data.isEmpty) {
          dev.log(
            'ScrollSitaClient: Empty protobuf response for $canonicalUri (status=$statusCode)',
            name: 'ScrollSita',
          );
          return null;
        }
        try {
          return NpvScrollResponse.fromBuffer(data);
        } catch (e, st) {
          dev.log(
            'ScrollSitaClient: Protobuf decode error for $canonicalUri',
            error: e,
            stackTrace: st,
            name: 'ScrollSita',
          );
          return null;
        }
    }
  }

  String _resolveEffectiveTimezone(String? explicitTimezone) {
    if (explicitTimezone case final tz? when tz.trim().isNotEmpty) {
      return tz.trim();
    }
    if (_runtimeContext?.timezone case final ctxTz?
        when ctxTz.contains('/')) {
      return ctxTz;
    }
    return _resolveIanaTimezone();
  }

  static String _resolveIanaTimezone() {
    final name = DateTime.now().timeZoneName;
    if (name.contains('/')) return name;
    return switch (name) {
      'IST' => 'Asia/Calcutta',
      'UTC' || 'GMT' => 'UTC',
      'EST' || 'EDT' => 'America/New_York',
      'CST' || 'CDT' => 'America/Chicago',
      'PST' || 'PDT' => 'America/Los_Angeles',
      'BST' => 'Europe/London',
      'CET' || 'CEST' => 'Europe/Paris',
      _ => 'UTC',
    };
  }
}
