import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/network/spotify/transport/base_spotify_transport.dart';

/// Spotify transport using Chrome/WebPlayer identity headers.
///
/// Used by most endpoints: casita, browsita, extended-metadata,
/// playlist detail, collection paging, etc.
class WebPlayerTransport extends BaseSpotifyTransport {
  final RuntimeContext _ctx;

  WebPlayerTransport({
    required super.auth,
    required super.client,
    required RuntimeContext ctx,
    super.refreshMutex,
  }) : _ctx = ctx;

  @override
  Future<Map<String, String>> buildHeaders(Map<String, String>? extra) async {
    final accessToken = await auth.getAccessToken();
    final clientToken = await auth.getClientToken();
    final profile = DeviceProfile.webPlayer;

    final headers = <String, String>{
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      'client-token': ?clientToken,
      'accept': 'application/x-protobuf, application/json',
      'accept-language': '${_ctx.acceptLanguage},en;q=0.8',
      'app-platform': profile.appPlatform,
      'spotify-app-version': profile.appVersion,
      'User-Agent': profile.userAgent,
      'Origin': 'https://open.spotify.com',
      'Referer': 'https://open.spotify.com/',
      'Sec-Fetch-Dest': 'empty',
      'Sec-Fetch-Mode': 'cors',
      'Sec-Fetch-Site': 'same-site',
      'sec-ch-ua':
          '"Chromium";v="146", "Not-A.Brand";v="24", "Google Chrome";v="146"',
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': '"Windows"',
      'sec-gpc': '1',
    };

    if (extra != null) headers.addAll(extra);
    headers.removeWhere((_, v) => v.isEmpty);
    return headers;
  }
}
