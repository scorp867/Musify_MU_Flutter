import 'package:musify_mu/core/network/spotify/auth/spotify_client_token.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_refresher.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';

export 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart'
    show
        AuthClientProfile,
        AuthClientProfileConfig,
        SpotifyTokenStoreClientProfileExtension;

/// Provides auth credentials and active client profile configuration to
/// transports and native bridges without exposing token refresh mechanics to
/// feature code (`#47 §1`).
abstract class AuthSessionProvider {
  /// Returns the current access token, refreshing if expired, or `null` if
  /// unavailable.
  Future<String?> getAccessToken();

  /// Returns the current client token, fetching a new one if needed.
  Future<String?> getClientToken();

  /// Refreshes the access token. Returns the new token or `null` on failure.
  Future<String?> refreshAccessToken();

  /// Forces invalidation and re-acquisition of the client token while
  /// preserving the canonical 40-hex `device_id` (`#47 §1` reason code `2`).
  Future<String?> forceRefreshClientToken();

  /// Returns the active Spotify `client_id` bound to the current session.
  Future<String> getActiveClientId();

  /// Returns the active [AuthClientProfile] (`webPlayer` or `android`).
  Future<AuthClientProfile> getActiveClientProfile();

  /// Returns the full [AuthClientProfileConfig] for header and FFI binding.
  Future<AuthClientProfileConfig> getActiveClientProfileConfig();
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
  Future<String?> getAccessToken() async {
    if (await _tokenStore.isAccessTokenExpired()) {
      final refreshed = await _tokenRefresher.refresh();
      if (refreshed != null && refreshed.isNotEmpty) {
        return refreshed;
      }
    }
    return _tokenStore.getAccessToken();
  }

  @override
  Future<String?> getClientToken() => _clientTokenFetcher.getClientToken();

  @override
  Future<String?> refreshAccessToken() => _tokenRefresher.refresh();

  @override
  Future<String?> forceRefreshClientToken() =>
      _clientTokenFetcher.forceRefreshClientToken();

  @override
  Future<String> getActiveClientId() => _tokenStore.getActiveClientId();

  @override
  Future<AuthClientProfile> getActiveClientProfile() =>
      _tokenStore.getActiveClientProfile();

  @override
  Future<AuthClientProfileConfig> getActiveClientProfileConfig() =>
      _tokenStore.getActiveClientProfileConfig();
}
