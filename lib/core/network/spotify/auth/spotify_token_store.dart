import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Securely persists Spotify auth tokens using platform-level encryption.
///
/// - Android: AES-256 via EncryptedSharedPreferences
/// - iOS: Keychain
class SpotifyTokenStore {
  static const _kSpDc = 'spotify_sp_dc';
  static const _kAccessToken = 'spotify_access_token';
  static const _kAccessTokenExpiry = 'spotify_access_token_expiry';
  static const _kUsername = 'spotify_username';

  final FlutterSecureStorage _storage;

  SpotifyTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ── sp_dc cookie ──────────────────────────────────────────────────────

  Future<void> saveSpDc(String spDc) =>
      _storage.write(key: _kSpDc, value: spDc);

  Future<String?> getSpDc() => _storage.read(key: _kSpDc);

  Future<bool> hasSpDc() async => (await getSpDc()) != null;

  // ── Access token ──────────────────────────────────────────────────────

  Future<void> saveAccessToken(String token, {int lifetimeMs = 3600000}) async {
    final expiry = DateTime.now().millisecondsSinceEpoch + lifetimeMs;
    await _storage.write(key: _kAccessToken, value: token);
    await _storage.write(key: _kAccessTokenExpiry, value: expiry.toString());
  }

  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);

  Future<bool> isAccessTokenExpired() async {
    final expiryStr = await _storage.read(key: _kAccessTokenExpiry);
    if (expiryStr == null) return true;
    final expiry = int.tryParse(expiryStr) ?? 0;
    // Treat as expired if less than 5 minutes remain.
    return DateTime.now().millisecondsSinceEpoch > expiry - 300000;
  }

  Future<bool> hasValidAccessToken() async {
    final token = await getAccessToken();
    if (token == null) return false;
    return !(await isAccessTokenExpired());
  }

  static const _kDisplayName = 'spotify_display_name';
  static const _kAvatarUrl = 'spotify_avatar_url';
  static const _kCountry = 'spotify_country';
  static const _kProduct = 'spotify_product';

  // ── Username ──────────────────────────────────────────────────────────

  Future<void> saveUsername(String username) =>
      _storage.write(key: _kUsername, value: username);

  Future<String?> getUsername() => _storage.read(key: _kUsername);

  // ── Profile (cached) ──────────────────────────────────────────────────

  /// Saves a full profile snapshot locally. No network on next restore.
  Future<void> saveProfile({
    required String username,
    required String displayName,
    String? avatarUrl,
    String? country,
    String? product,
  }) async {
    await _storage.write(key: _kUsername, value: username);
    await _storage.write(key: _kDisplayName, value: displayName);
    if (avatarUrl != null) {
      await _storage.write(key: _kAvatarUrl, value: avatarUrl);
    }
    if (country != null) {
      await _storage.write(key: _kCountry, value: country);
    }
    if (product != null) {
      await _storage.write(key: _kProduct, value: product);
    }
  }

  /// Returns cached profile fields.
  /// Returns null if no profile has been cached yet.
  Future<({String username, String displayName, String? avatarUrl, String? country, String? product})?> getCachedProfile() async {
    final username = await _storage.read(key: _kUsername);
    if (username == null) return null;
    final displayName = await _storage.read(key: _kDisplayName) ?? username;
    final avatarUrl = await _storage.read(key: _kAvatarUrl);
    final country = await _storage.read(key: _kCountry);
    final product = await _storage.read(key: _kProduct);
    return (username: username, displayName: displayName, avatarUrl: avatarUrl, country: country, product: product);
  }

  // ── Client Token ───────────────────────────────────────────────────

  static const _kClientToken = 'spotify_client_token';

  Future<void> saveClientToken(String token) =>
      _storage.write(key: _kClientToken, value: token);

  Future<String?> getClientToken() => _storage.read(key: _kClientToken);

  // ── Clear all ─────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await _storage.delete(key: _kSpDc);
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kAccessTokenExpiry);
    await _storage.delete(key: _kUsername);
    await _storage.delete(key: _kDisplayName);
    await _storage.delete(key: _kAvatarUrl);
    await _storage.delete(key: _kCountry);
    await _storage.delete(key: _kProduct);
    await _storage.delete(key: _kClientToken);
  }
}
