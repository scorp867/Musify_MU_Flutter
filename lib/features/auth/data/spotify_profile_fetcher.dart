import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/result/network_result.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';
import 'package:musify_mu/features/auth/domain/entities/spotify_user.dart';

/// Fetches the current user's Spotify profile using Pathfinder (GQL).
///
/// Uses the managed [SpotifyTransport] with dynamic host routing to
/// `https://api-partner.spotify.com`, automatically benefiting from
/// keep-alive connection reuse, mutex 401 token refresh, and diagnostic logging.
class SpotifyProfileFetcher {
  final SpotifyTransport _transport;
  final SpotifyTokenStore _tokenStore;
  final RuntimeContext _ctx;

  static const _profileHashV1 =
      '53bcb064f6cd18c23f752bc324a791194d20df612d8e1239c735144ab0399ced';
  static const _apiPartnerHost = 'https://api-partner.spotify.com';

  SpotifyProfileFetcher({
    required SpotifyTransport transport,
    required RuntimeContext ctx,
    required SpotifyTokenStore tokenStore,
  })  : _transport = transport,
        _ctx = ctx,
        _tokenStore = tokenStore;

  /// Fetches and caches the current user's profile.
  /// Returns a [SpotifyUser] on success, null on failure.
  Future<SpotifyUser?> fetchProfile() async {
    try {
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

      final bodyBytes = Uint8List.fromList(utf8.encode(body));

      final result = await _transport.postResult(
        '/pathfinder/v2/query',
        bodyBytes,
        baseHost: _apiPartnerHost,
        contentType: 'application/json;charset=UTF-8',
        priority: NetworkPriority.interactive,
      );

      if (result is NetworkFailure<Uint8List>) {
        dev.log(
          'ProfileFetcher network failure: ${result.error}',
          name: 'Auth',
        );
        return null;
      }

      final responseBytes = (result as NetworkSuccess<Uint8List>).data;
      if (responseBytes.isEmpty) return null;

      final jsonStr = utf8.decode(responseBytes);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Navigate: data > me > profile
      final data = json['data'] as Map<String, dynamic>?;
      final me = data?['me'] as Map<String, dynamic>?;
      final profileData = me?['profile'] as Map<String, dynamic>?;

      if (profileData == null) return null;

      final username = profileData['username'] as String? ??
          profileData['id'] as String? ??
          'spotify_user';
      final displayName = profileData['name'] as String? ?? username;
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
    } catch (e, st) {
      dev.log(
        'ProfileFetcher error: $e',
        name: 'Auth',
        error: e,
        stackTrace: st,
      );
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
      dev.log('ProfileFetcher avatar parse error: $e', name: 'Auth');
    }
    return null;
  }
}
