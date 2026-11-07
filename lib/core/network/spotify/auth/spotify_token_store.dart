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
  static const _kClientToken = 'spotify_client_token';
  static const _kClientTokenExpiry = 'spotify_client_token_expiry';
  static const _kDisplayName = 'spotify_display_name';
  static const _kAvatarUrl = 'spotify_avatar_url';
  static const _kCountry = 'spotify_country';
  static const _kProduct = 'spotify_product';

  final FlutterSecureStorage _storage;
  final Set<void Function()> _changeListeners = <void Function()>{};

  SpotifyTokenStore({FlutterSecureStorage? storage})
      : _storage = switch (storage) {
          final providedStorage? => providedStorage,
          null => const FlutterSecureStorage(),
        };

  void addChangeListener(void Function() listener) {
    _changeListeners.add(listener);
  }

  void removeChangeListener(void Function() listener) {
    _changeListeners.remove(listener);
  }

  void _notifyChanged() {
    final snapshot = List<void Function()>.of(_changeListeners);
    for (final listener in snapshot) {
      listener();
    }
  }

  // --- sp_dc cookie ---

  Future<void> saveSpDc(String spDc) async {
    await _storage.write(key: _kSpDc, value: spDc);
    _notifyChanged();
  }

  Future<String?> getSpDc() => _storage.read(key: _kSpDc);

  Future<bool> hasSpDc() async => (await getSpDc()) != null;

  // --- Access token ---

  Future<void> saveAccessToken(String token, {int lifetimeMs = 3600000}) async {
    final expiry = DateTime.now().millisecondsSinceEpoch + lifetimeMs;
    await _storage.write(key: _kAccessToken, value: token);
    await _storage.write(key: _kAccessTokenExpiry, value: expiry.toString());
    _notifyChanged();
  }

  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);

  Future<bool> isAccessTokenExpired() async {
    final expiryStr = await _storage.read(key: _kAccessTokenExpiry);
    if (expiryStr == null) return true;
    final expiry = int.tryParse(expiryStr);
    if (expiry == null) return true;
    return DateTime.now().millisecondsSinceEpoch > expiry - 300000;
  }

  Future<bool> hasValidAccessToken() async {
    final token = await getAccessToken();
    if (token == null) return false;
    return !(await isAccessTokenExpired());
  }

  // --- Username ---

  Future<void> saveUsername(String username) =>
      _storage.write(key: _kUsername, value: username);

  Future<String?> getUsername() => _storage.read(key: _kUsername);

  // --- Profile (cached) ---

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
    _notifyChanged();
  }

  /// Returns cached profile fields, or null if no profile has been cached yet.
  Future<
      ({
        String username,
        String displayName,
        String? avatarUrl,
        String? country,
        String? product,
      })?> getCachedProfile() async {
    final username = await _storage.read(key: _kUsername);
    if (username == null) return null;
    final rawDisplayName = await _storage.read(key: _kDisplayName);
    final displayName =
        (rawDisplayName != null && rawDisplayName.isNotEmpty)
            ? rawDisplayName
            : username;
    final avatarUrl = await _storage.read(key: _kAvatarUrl);
    final country = await _storage.read(key: _kCountry);
    final product = await _storage.read(key: _kProduct);
    return (
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      country: country,
      product: product,
    );
  }

  // --- Client Token ---

  Future<void> saveClientToken(
    String token, {
    int lifetimeMs = 86400000,
  }) async {
    final expiry = DateTime.now().millisecondsSinceEpoch + lifetimeMs;
    await _storage.write(key: _kClientToken, value: token);
    await _storage.write(key: _kClientTokenExpiry, value: expiry.toString());
    _notifyChanged();
  }

  Future<String?> getClientToken() => _storage.read(key: _kClientToken);

  Future<bool> isClientTokenExpired() async {
    final expiryStr = await _storage.read(key: _kClientTokenExpiry);
    if (expiryStr == null) return true;
    final expiry = int.tryParse(expiryStr);
    if (expiry == null) return true;
    return DateTime.now().millisecondsSinceEpoch > expiry - 300000;
  }

  Future<void> deleteClientToken() async {
    await _storage.delete(key: _kClientToken);
    await _storage.delete(key: _kClientTokenExpiry);
    _notifyChanged();
  }

  // --- Clear all ---

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
    await _storage.delete(key: _kClientTokenExpiry);
    _notifyChanged();
  }
}
