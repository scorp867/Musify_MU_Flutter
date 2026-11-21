import 'dart:developer' as dev;

import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/result/network_result.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';
import 'package:musify_mu/features/player/domain/policies/spotify_track_eligibility_policy.dart';

/// Client for Spotify's Color Lyrics v2 service.
///
/// 1:1 replica of decompiled Retrofit interface:
/// `p/hq80.java` (`src_main_java_com_spotify_lyrics_serviceretrofit-serviceretrofit`).
///
/// Annotation contract:
/// ```java
/// @xo00({"Accept: application/protobuf"})
/// @cqy("color-lyrics/v2/track/{trackId}")
/// Single<ColorLyricsResponse> a(
///     @w1k0("trackId") String trackId,
///     @qrp0("vocalRemoval") boolean vocalRemoval,
///     @qrp0("clientLanguage") String clientLanguage,
///     @qrp0("preview") boolean isPreview
/// );
/// ```
class ColorLyricsClient {
  final SpotifyTransport _transport;
  final RuntimeContext? _runtimeContext;

  static const String defaultHost = 'https://gae2-spclient.spotify.com';

  const ColorLyricsClient({
    required SpotifyTransport transport,
    RuntimeContext? runtimeContext,
  }) : _transport = transport,
       _runtimeContext = runtimeContext;

  /// Fetches lyrics with synchronized lines and extracted Spotify color scheme
  /// for an eligible Spotify track ID.
  Future<ColorLyricsResponse?> getColorLyrics({
    required String trackId,
    bool vocalRemoval = false,
    String? clientLanguage,
    bool preview = false,
    String? host,
  }) async {
    final canonicalId =
        SpotifyTrackEligibilityPolicy.extractCanonicalSpotifyTrackId(trackId);
    if (canonicalId == null) {
      return null;
    }

    final resolvedLanguage = _resolveClientLanguage(clientLanguage);
    final query =
        'vocalRemoval=$vocalRemoval&clientLanguage=${Uri.encodeComponent(resolvedLanguage)}&preview=$preview';
    final path = 'color-lyrics/v2/track/$canonicalId?$query';
    final effectiveHost = switch (host) {
      final explicit? when explicit.isNotEmpty => explicit,
      _ => defaultHost,
    };

    final result = await _transport.getResult(
      path,
      baseHost: effectiveHost,
      priority: NetworkPriority.interactive,
      extraHeaders: const {
        'Accept': 'application/protobuf',
      },
    );

    switch (result) {
      case NetworkFailure(:final error, :final statusCode):
        dev.log(
          'ColorLyricsClient: HTTP failure for track $canonicalId '
          '(status=$statusCode, reason=${error.reason.name}, msg=${error.message})',
          error: error,
          name: 'ColorLyrics',
        );
        return null;

      case NetworkSuccess(:final data, :final statusCode):
        if (data.isEmpty) {
          dev.log(
            'ColorLyricsClient: Empty protobuf response for track $canonicalId (status=$statusCode)',
            name: 'ColorLyrics',
          );
          return null;
        }
        try {
          return ColorLyricsResponse.fromBuffer(data);
        } catch (e, st) {
          dev.log(
            'ColorLyricsClient: Protobuf decode error for track $canonicalId',
            error: e,
            stackTrace: st,
            name: 'ColorLyrics',
          );
          return null;
        }
    }
  }

  String _resolveClientLanguage(String? explicitLanguage) {
    if (explicitLanguage case final lang? when lang.trim().isNotEmpty) {
      return lang.trim();
    }
    if (_runtimeContext?.acceptLanguage case final ctxLang?
        when ctxLang.trim().isNotEmpty) {
      return ctxLang.trim().replaceAll('-', '_');
    }
    return 'en_US';
  }
}
