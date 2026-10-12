import 'dart:developer' as dev;
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';

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

  static const String defaultHost = 'https://gae2-spclient.spotify.com';

  const ColorLyricsClient({required SpotifyTransport transport})
      : _transport = transport;

  /// Fetches lyrics with synchronized lines and extracted Spotify color scheme.
  Future<ColorLyricsResponse?> getColorLyrics({
    required String trackId,
    bool vocalRemoval = false,
    String clientLanguage = 'en_US',
    bool preview = false,
    String? host,
  }) async {
    final query = 'vocalRemoval=$vocalRemoval&clientLanguage=${Uri.encodeComponent(clientLanguage)}&preview=$preview';
    final path = 'color-lyrics/v2/track/$trackId?$query';

    try {
      final bytes = await _transport.get(
        path,
        baseHost: host ?? defaultHost,
        priority: NetworkPriority.interactive,
        extraHeaders: const {
          'Accept': 'application/protobuf',
        },
      );

      if (bytes == null || bytes.isEmpty) {
        return null;
      }

      return ColorLyricsResponse.fromBuffer(bytes);
    } catch (e, st) {
      dev.log(
        'ColorLyricsClient: Failed to fetch lyrics for track $trackId',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}
