import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and provides the single canonical 40-character lowercase hex
/// Spotify Connect `device_id` shared across `SpotifyClientTokenFetcher`
/// (`js_sdk_data.device_id`) and native Connect `DeviceInfo.device_id` (tag 10).
///
/// Derivation contract:
/// 1. If a valid 40-char lowercase hex ID is already persisted under
///    [storageKey] in [SharedPreferences], returns it without rotation.
/// 2. Otherwise, if `androidId` is non-empty, not `"0"`, and not the broken
///    emulator sentinel `"9774d56d682e549c"`, derives
///    `SHA-1("$androidId:musify-connect-v1")`.
/// 3. Otherwise derives `SHA-1` over 32 CSPRNG bytes from [Random.secure].
final class DeviceIdentityService {
  static const String storageKey = 'musify_connect_canonical_device_id';
  static const String _derivationDomainSuffix = ':musify-connect-v1';
  static const String _emulatorAndroidIdSentinel = '9774d56d682e549c';
  static final RegExp _canonicalHex40Pattern = RegExp(r'^[0-9a-f]{40}$');

  SharedPreferences? _preferences;
  String? _cachedDeviceId;
  Future<String>? _inFlightResolution;

  DeviceIdentityService({SharedPreferences? preferences})
      : _preferences = preferences;

  /// Returns the in-memory cached 40-char hex `device_id` if already resolved,
  /// or `null` if [getOrCreateDeviceId] has not yet completed.
  String? get cachedDeviceId => _cachedDeviceId;

  /// Validates that [candidate] is an exact 40-character lowercase hex string.
  static bool isValidCanonicalDeviceId(String candidate) {
    return _canonicalHex40Pattern.hasMatch(candidate);
  }

  /// Derives a deterministic 40-character lowercase hex `device_id` from a
  /// valid Android `Settings.Secure.ANDROID_ID` value.
  ///
  /// Throws [ArgumentError] if [androidId] is empty or matches a disallowed
  /// sentinel (`"0"` or `"9774d56d682e549c"`).
  static String deriveFromAndroidId(String androidId) {
    final normalized = androidId.trim();
    if (!_isUsableAndroidId(normalized)) {
      throw ArgumentError.value(
        androidId,
        'androidId',
        'Must be non-empty and not "0" or "$_emulatorAndroidIdSentinel"',
      );
    }
    final payloadBytes = utf8.encode('$normalized$_derivationDomainSuffix');
    return sha1.convert(payloadBytes).toString().toLowerCase();
  }

  /// Generates a fresh 40-character lowercase hex `device_id` from 32 CSPRNG
  /// bytes using [Random.secure].
  static String deriveFromCsprng([Random? random]) {
    final rng = switch (random) {
      final providedRandom? => providedRandom,
      null => Random.secure(),
    };
    final seedBytes = List<int>.generate(
      32,
      (_) => rng.nextInt(256),
      growable: false,
    );
    return sha1.convert(seedBytes).toString().toLowerCase();
  }

  static bool _isUsableAndroidId(String? androidId) {
    if (androidId == null) {
      return false;
    }
    final trimmed = androidId.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    final lower = trimmed.toLowerCase();
    return lower != '0' && lower != _emulatorAndroidIdSentinel;
  }

  /// Resolves or creates the single canonical 40-character lowercase hex
  /// `device_id` and persists it in [SharedPreferences].
  ///
  /// Concurrent calls coalesce onto the same in-flight resolution future and
  /// never rotate an already-persisted canonical `device_id`.
  Future<String> getOrCreateDeviceId({String? androidId}) {
    if (_cachedDeviceId case final existing?
        when isValidCanonicalDeviceId(existing)) {
      return Future<String>.value(existing);
    }
    if (_inFlightResolution case final pending?) {
      return pending;
    }
    final future = _resolveAndPersist(androidId: androidId);
    _inFlightResolution = future;
    return future.whenComplete(() {
      _inFlightResolution = null;
    });
  }

  Future<String> _resolveAndPersist({String? androidId}) async {
    if (_cachedDeviceId case final existing?
        when isValidCanonicalDeviceId(existing)) {
      return existing;
    }

    final prefs = await _resolvePreferences();
    final stored = prefs.getString(storageKey);
    if (stored != null) {
      final normalizedStored = stored.trim().toLowerCase();
      if (isValidCanonicalDeviceId(normalizedStored)) {
        _cachedDeviceId = normalizedStored;
        return normalizedStored;
      }
    }

    final String derived;
    if (androidId != null && _isUsableAndroidId(androidId)) {
      derived = deriveFromAndroidId(androidId);
    } else {
      derived = deriveFromCsprng();
    }

    await prefs.setString(storageKey, derived);
    _cachedDeviceId = derived;
    return derived;
  }

  Future<SharedPreferences> _resolvePreferences() async {
    if (_preferences case final existing?) {
      return existing;
    }
    final loaded = await SharedPreferences.getInstance();
    _preferences = loaded;
    return loaded;
  }
}
