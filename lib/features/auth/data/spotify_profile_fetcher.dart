import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';
import 'package:musify_mu/features/auth/domain/entities/spotify_user.dart';

/// Fetches the current user's Spotify profile using Pathfinder (GQL).
///
/// Uses the same approach as the Kotlin codebase:
/// POST to `api-partner.spotify.com/pathfinder/v2/query` with the
/// `profileAttributes` operation.
///
/// After a successful fetch, updates [RuntimeContext] with the user's
/// country and product tier so all downstream services use live values.
class SpotifyProfileFetcher {
  final SpotifyTokenStore _tokenStore;
  final RuntimeContext _ctx;

  static const _profileHashV1 =
      '53bcb064f6cd18c23f752bc324a791194d20df612d8e1239c735144ab0399ced';

  SpotifyProfileFetcher({
    required RuntimeContext ctx,
    required SpotifyTokenStore tokenStore,
  })  : _ctx = ctx,
        _tokenStore = tokenStore;

  /// Fetches and caches the current user's profile.
  /// Returns a [SpotifyUser] on success, null on failure.
  Future<SpotifyUser?> fetchProfile() async {
    try {
      final token = await _tokenStore.getAccessToken();
      if (token == null) return null;

      final profile = DeviceProfile.webPlayer;

      final body = jsonEncode({
        'variables': <String, dynamic>{},
        'operationName': 'profileAttributes',
        'extensions': {
          'persistedQuery': {
            'version': 1,
            'sha256Hash': _profileHashV1,
          },
        },
      });

      final response = await http.post(
        Uri.parse('https://api-partner.spotify.com/pathfinder/v2/query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json;charset=UTF-8',
          'User-Agent': profile.userAgent,
          'app-platform': profile.appPlatform,
          'Origin': 'https://open.spotify.com',
          'Referer': 'https://open.spotify.com/',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // Navigate: data > me > profile
      final data = json['data'] as Map<String, dynamic>?;
      final me = data?['me'] as Map<String, dynamic>?;
      final profileData = me?['profile'] as Map<String, dynamic>?;

      if (profileData == null) return null;

      final username = profileData['username'] as String? ??
          profileData['id'] as String? ??
          'spotify_user';
      final displayName =
          profileData['name'] as String? ?? username;
      final avatarUrl = _extractAvatarUrl(profileData);
      final country = profileData['country'] as String?;
      final product = profileData['product'] as String?;

      // Populate RuntimeContext with live values from the profile.
      _ctx.updateFromProfile(userCountry: country, product: product);

      // Cache the full profile locally.
      await _tokenStore.saveProfile(
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
        country: country,
        product: product,
      );

      return SpotifyUser(
        id: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
        country: country,
        product: product,
      );
    } catch (e) {
      log('ProfileFetcher error: $e');
      return null;
    }
  }

  String? _extractAvatarUrl(Map<String, dynamic> profile) {
    try {
      final avatar = profile['avatar'] as Map<String, dynamic>?;
      final sources = avatar?['sources'] as List<dynamic>?;
      if (sources != null && sources.isNotEmpty) {
        return (sources.first as Map<String, dynamic>)['url'] as String?;
      }
    } catch (e) {
      log('ProfileFetcher error: $e');
    }
    return null;
  }
}
