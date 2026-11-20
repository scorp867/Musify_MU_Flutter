import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/core/config/runtime_context.dart';

/// Active Spotify client authentication profile (`#47 §1`).
///
/// - [webPlayer]: `sp_dc` + TOTP WebPlayer session (`d8a5ed958d274c2e8ee717e6a4b0971d`),
///   requires `Origin`/`Referer` headers on HTTP and query `access_token` on Dealer WS.
/// - [android]: Native Android session (`9a8d2f0ce77a4e248bb71fefcb557637`),
///   uses `App-Platform: Android` without `Origin`/`Referer`.
enum AuthClientProfile {
  webPlayer,
  android,
}

/// Immutable header and identity configuration bound to the active
/// [AuthClientProfile] (`#47 §1`, `#47 §2.11`).
@immutable
final class AuthClientProfileConfig extends Equatable {
  static const String webPlayerClientId = 'd8a5ed958d274c2e8ee717e6a4b0971d';
  static const String androidClientId = '9a8d2f0ce77a4e248bb71fefcb557637';

  static final AuthClientProfileConfig webPlayerDefault =
      AuthClientProfileConfig(
    profile: AuthClientProfile.webPlayer,
    clientId: webPlayerClientId,
    appPlatform: DeviceProfile.webPlayer.appPlatform,
    appVersion: DeviceProfile.webPlayer.appVersion,
    userAgent: DeviceProfile.webPlayer.userAgent,
    sendOriginHeaders: true,
  );

  static final AuthClientProfileConfig androidDefault =
      AuthClientProfileConfig(
    profile: AuthClientProfile.android,
    clientId: androidClientId,
    appPlatform: DeviceProfile.android.appPlatform,
    appVersion: DeviceProfile.android.appVersion,
    userAgent: DeviceProfile.android.userAgent,
    sendOriginHeaders: false,
  );

  final AuthClientProfile profile;
  final String clientId;
  final String appPlatform;
  final String appVersion;
  final String userAgent;
  final bool sendOriginHeaders;

  const AuthClientProfileConfig({
    required this.profile,
    required this.clientId,
    required this.appPlatform,
    required this.appVersion,
    required this.userAgent,
    required this.sendOriginHeaders,
  });

  /// Resolves the coherent [AuthClientProfileConfig] for [rawClientId].
  ///
  /// Defaults to [webPlayerDefault] when [rawClientId] is null or empty.
  factory AuthClientProfileConfig.forClientId(String? rawClientId) {
    final trimmed = switch (rawClientId) {
      final value? => value.trim(),
      null => '',
    };
    if (trimmed.isEmpty) {
      return webPlayerDefault;
    }
    if (trimmed.toLowerCase() == androidClientId) {
      return AuthClientProfileConfig(
        profile: AuthClientProfile.android,
        clientId: trimmed,
        appPlatform: DeviceProfile.android.appPlatform,
        appVersion: DeviceProfile.android.appVersion,
        userAgent: DeviceProfile.android.userAgent,
        sendOriginHeaders: false,
      );
    }
    return AuthClientProfileConfig(
      profile: AuthClientProfile.webPlayer,
      clientId: trimmed,
      appPlatform: DeviceProfile.webPlayer.appPlatform,
      appVersion: DeviceProfile.webPlayer.appVersion,
      userAgent: DeviceProfile.webPlayer.userAgent,
      sendOriginHeaders: true,
    );
  }

  @override
  List<Object?> get props => [
        profile,
        clientId,
        appPlatform,
        appVersion,
        userAgent,
        sendOriginHeaders,
      ];
}

final Expando<String> _fakeStoreActiveClientIdExpando =
    Expando<String>('SpotifyTokenStore.activeClientId');
final Expando<int> _fakeStoreAccessTokenExpiryExpando =
    Expando<int>('SpotifyTokenStore.accessTokenExpiry');

/// Securely persists Spotify auth tokens using platform-level encryption.
///
/// - Android: AES-256 via EncryptedSharedPreferences
/// - iOS: Keychain
class SpotifyTokenStore {
  static const _kSpDc = 'spotify_sp_dc';
  static const _kAccessToken = 'spotify_access_token';
  static const _kAccessTokenExpiry = 'spotify_access_token_expiry';
  static const _kActiveClientId = 'spotify_active_client_id';
  static const _kUsername = 'spotify_username';
  static const _kClientToken = 'spotify_client_token';
  static const _kClientTokenExpiry = 'spotify_client_token_expiry';
  static const _kDisplayName = 'spotify_display_name';
  static const _kAvatarUrl = 'spotify_avatar_url';
  static const _kCountry = 'spotify_country';
  static const _kProduct = 'spotify_product';

  final FlutterSecureStorage _storage;
  final Set<void Function()> _changeListeners = <void Function()>{};
  final bool _isConcreteStore = true;

  SpotifyTokenStore({FlutterSecureStorage? storage})
      : _storage = switch (storage) {
          final providedStorage? => providedStorage,
          null => const FlutterSecureStorage(),
        };

  /// Strips any leading `"sp_dc="` prefix(es) and surrounding whitespace so
  /// raw cookie values are stored cleanly without double `"sp_dc=sp_dc="`
  /// formatting.
  static String normalizeSpDcValue(String rawSpDc) {
    var normalized = rawSpDc.trim();
    while (normalized.toLowerCase().startsWith('sp_dc=')) {
      normalized = normalized.substring('sp_dc='.length).trim();
    }
    return normalized;
  }

  /// Formats a raw or prefixed `sp_dc` value as a single `"sp_dc=<value>"`
  /// HTTP `Cookie` header value.
  static String formatSpDcCookieHeader(String rawOrPrefixedSpDc) {
    final rawValue = normalizeSpDcValue(rawOrPrefixedSpDc);
    if (rawValue.isEmpty) {
      return '';
    }
    return 'sp_dc=$rawValue';
  }

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
    final normalized = normalizeSpDcValue(spDc);
    await _storage.write(key: _kSpDc, value: normalized);
    _notifyChanged();
  }

  Future<String?> getSpDc() async {
    final stored = await _storage.read(key: _kSpDc);
    if (stored == null) {
      return null;
    }
    final normalized = normalizeSpDcValue(stored);
    return normalized.isEmpty ? null : normalized;
  }

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
    await _storage.delete(key: _kActiveClientId);
    await _storage.delete(key: _kUsername);
    await _storage.delete(key: _kDisplayName);
    await _storage.delete(key: _kAvatarUrl);
    await _storage.delete(key: _kCountry);
    await _storage.delete(key: _kProduct);
    await _storage.delete(key: _kClientToken);
    await _storage.delete(key: _kClientTokenExpiry);
    _notifyChanged();
  }

  Future<void> _saveActiveClientIdInternal(String clientId) async {
    final trimmed = clientId.trim();
    if (trimmed.isEmpty) {
      return;
    }
    await _storage.write(key: _kActiveClientId, value: trimmed);
    _notifyChanged();
  }

  Future<String> _getActiveClientIdInternal() async {
    final stored = await _storage.read(key: _kActiveClientId);
    if (stored != null) {
      final trimmed = stored.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return AuthClientProfileConfig.webPlayerClientId;
  }

  Future<int?> _getAccessTokenExpiryMsInternal() async {
    final expiryStr = await _storage.read(key: _kAccessTokenExpiry);
    if (expiryStr == null) {
      return null;
    }
    return int.tryParse(expiryStr);
  }
}

/// Coherent client profile and token expiry accessors on [SpotifyTokenStore].
///
/// Provided via extension so existing test doubles that use
/// `implements SpotifyTokenStore` remain 100% source-compatible without
/// requiring boilerplate overrides.
extension SpotifyTokenStoreClientProfileExtension on SpotifyTokenStore {
  bool _isConcreteInstance() {
    try {
      return _isConcreteStore;
    } on Object {
      return false;
    }
  }

  /// Persists the `clientId` captured from `/api/token` alongside the active
  /// session (`#47 §1`).
  Future<void> saveActiveClientId(String clientId) async {
    final trimmed = clientId.trim();
    if (trimmed.isEmpty) {
      return;
    }
    if (_isConcreteInstance()) {
      await _saveActiveClientIdInternal(trimmed);
      return;
    }
    _fakeStoreActiveClientIdExpando[this] = trimmed;
  }

  /// Returns the persisted `activeClientId`, defaulting to WebPlayer
  /// `d8a5ed958d274c2e8ee717e6a4b0971d` when absent in legacy sessions.
  Future<String> getActiveClientId() async {
    if (_isConcreteInstance()) {
      return _getActiveClientIdInternal();
    }
    final stored = _fakeStoreActiveClientIdExpando[this];
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }
    return AuthClientProfileConfig.webPlayerClientId;
  }

  /// Returns the active [AuthClientProfile] derived from [getActiveClientId].
  Future<AuthClientProfile> getActiveClientProfile() async {
    final config = await getActiveClientProfileConfig();
    return config.profile;
  }

  /// Returns the active [AuthClientProfileConfig] derived from
  /// [getActiveClientId].
  Future<AuthClientProfileConfig> getActiveClientProfileConfig() async {
    final activeClientId = await getActiveClientId();
    return AuthClientProfileConfig.forClientId(activeClientId);
  }

  /// Returns the persisted access token expiration epoch timestamp in
  /// milliseconds, or `null` if unavailable.
  Future<int?> getAccessTokenExpiryMs() async {
    if (_isConcreteInstance()) {
      return _getAccessTokenExpiryMsInternal();
    }
    return _fakeStoreAccessTokenExpiryExpando[this];
  }
}
