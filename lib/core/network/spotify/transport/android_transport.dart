import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/network/spotify/transport/base_spotify_transport.dart';

/// Spotify transport using Android app identity headers.
///
/// Used by endpoints that reject WebPlayer identity, such as
/// the rootlist endpoint for fetching the user's playlist library.
class AndroidTransport extends BaseSpotifyTransport {
  final RuntimeContext _ctx;

  AndroidTransport({required super.auth, required RuntimeContext ctx})
      : _ctx = ctx;

  @override
  Future<Map<String, String>> buildHeaders(Map<String, String>? extra) async {
    final accessToken = await auth.getAccessToken();
    final clientToken = await auth.getClientToken();
    final profile = DeviceProfile.android;

    final headers = <String, String>{
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      'client-token': ?clientToken,
      'accept': 'application/x-protobuf',
      'accept-language': _ctx.acceptLanguage,
      'accept-encoding': 'gzip',
      'app-platform': profile.appPlatform,
      'spotify-app-version': profile.appVersion,
      'User-Agent': profile.userAgent,
      'cache-control': 'no-cache, no-store',
    };

    if (extra != null) headers.addAll(extra);
    headers.removeWhere((_, v) => v.isEmpty);
    return headers;
  }
}
