import 'dart:developer' as dev;
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';
import 'package:musify_mu/core/protocol/generated/spotify/scrollsita/v1/scrollsita.pb.dart';

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

  static const String baseHost = 'https://gae2-spclient.spotify.com';

  const ScrollSitaClient({required SpotifyTransport transport})
      : _transport = transport;

  /// Fetches the ordered scroll sections for the current track.
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
    final tz = timezone ?? _resolveIanaTimezone();
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

    final path = 'scrollsita/v1/scroll/$nowPlayingUri?$queryString';

    try {
      final bytes = await _transport.get(
        path,
        baseHost: baseHost,
        priority: NetworkPriority.interactive,
        extraHeaders: const {
          'Content-Type': 'application/x-protobuf',
          'Accept': 'application/protobuf',
        },
      );

      if (bytes == null || bytes.isEmpty) {
        return null;
      }

      return NpvScrollResponse.fromBuffer(bytes);
    } catch (e, st) {
      dev.log(
        'ScrollSitaClient: Error fetching scroll structure for $nowPlayingUri',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  static String _resolveIanaTimezone() {
    final name = DateTime.now().timeZoneName;
    if (name.contains('/')) return name;
    return switch (name) {
      'IST' => 'Asia/Calcutta',
      'UTC' || 'GMT' => 'UTC',
      'EST' => 'America/New_York',
      'EDT' => 'America/New_York',
      'CST' => 'America/Chicago',
      'CDT' => 'America/Chicago',
      'PST' => 'America/Los_Angeles',
      'PDT' => 'America/Los_Angeles',
      'BST' => 'Europe/London',
      'CET' => 'Europe/Paris',
      'CEST' => 'Europe/Paris',
      _ => 'Asia/Calcutta',
    };
  }
}
