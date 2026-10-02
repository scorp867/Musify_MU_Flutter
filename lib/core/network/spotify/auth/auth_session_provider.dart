import 'package:musify_mu/core/network/spotify/auth/spotify_client_token.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_refresher.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';

/// Provides auth credentials to transports without exposing
/// token refresh mechanics to feature code.
///
/// Consumers (transports) call [getAccessToken] and [getClientToken]
/// for header injection, and [refreshAccessToken] on 401 retries.
/// They never interact with the underlying token store, TOTP cipher,
/// or refresh protocol.
abstract class AuthSessionProvider {
  /// Returns the current access token, or null if unavailable.
  Future<String?> getAccessToken();

  /// Returns the current client token, fetching a new one if needed.
  Future<String?> getClientToken();

  /// Refreshes the access token. Returns the new token or null on failure.
  Future<String?> refreshAccessToken();
}

/// Concrete [AuthSessionProvider] backed by the Spotify token infrastructure.
class SpotifyAuthSessionProvider implements AuthSessionProvider {
  final SpotifyTokenStore _tokenStore;
  final SpotifyTokenRefresher _tokenRefresher;
  final SpotifyClientTokenFetcher _clientTokenFetcher;

  SpotifyAuthSessionProvider({
    required SpotifyTokenStore tokenStore,
    required SpotifyTokenRefresher tokenRefresher,
    required SpotifyClientTokenFetcher clientTokenFetcher,
  })  : _tokenStore = tokenStore,
        _tokenRefresher = tokenRefresher,
        _clientTokenFetcher = clientTokenFetcher;

  @override
  Future<String?> getAccessToken() => _tokenStore.getAccessToken();

  @override
  Future<String?> getClientToken() => _clientTokenFetcher.getClientToken();

  @override
  Future<String?> refreshAccessToken() => _tokenRefresher.refresh();
}
