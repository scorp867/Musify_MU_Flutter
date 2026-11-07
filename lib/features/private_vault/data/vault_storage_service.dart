import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:musify_mu/features/private_vault/domain/models/gesture_pattern.dart';
import 'package:musify_mu/features/private_vault/domain/models/private_playlist.dart';
import 'package:musify_mu/features/private_vault/domain/models/vault_settings.dart';
import 'package:musify_mu/features/private_vault/domain/repositories/i_vault_storage_service.dart';

export 'package:musify_mu/features/private_vault/domain/repositories/i_vault_storage_service.dart';

/// Production implementation storing AES-256 encrypted payloads in FlutterSecureStorage.
final class VaultStorageService implements IVaultStorageService {
  static const String _keyMasterSecret = 'vault_master_key_aes256';
  static const String _keyPlaylists = 'vault_playlists_payload';
  static const String _keySettings = 'vault_settings_payload';
  static const String _keyGesture = 'vault_gesture_payload';

  final FlutterSecureStorage _secureStorage;
  enc.Key? _cachedKey;

  VaultStorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<enc.Key> _getOrCreateMasterKey() async {
    final cached = _cachedKey;
    if (cached != null) {
      return cached;
    }

    final existingBase64 = await _secureStorage.read(key: _keyMasterSecret);
    if (existingBase64 != null && existingBase64.isNotEmpty) {
      try {
        final keyBytes = base64Decode(existingBase64);
        if (keyBytes.length == 32) {
          final key = enc.Key(keyBytes);
          _cachedKey = key;
          return key;
        }
      } catch (_) {
        // Fallthrough on key corruption to recreate
      }
    }

    final newKey = enc.Key.fromSecureRandom(32);
    await _secureStorage.write(
      key: _keyMasterSecret,
      value: base64Encode(newKey.bytes),
    );
    _cachedKey = newKey;
    return newKey;
  }

  Future<String> _encrypt(String plainText) async {
    final key = await _getOrCreateMasterKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    final combinedBytes = <int>[...iv.bytes, ...encrypted.bytes];
    return base64Encode(combinedBytes);
  }

  Future<String> _decrypt(String base64Payload) async {
    final key = await _getOrCreateMasterKey();
    final combinedBytes = base64Decode(base64Payload);
    if (combinedBytes.length < 17) {
      throw const FormatException('Corrupted encrypted payload: buffer too short');
    }

    final ivBytes = combinedBytes.sublist(0, 16);
    final cipherBytes = combinedBytes.sublist(16);

    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final decrypted = encrypter.decrypt(enc.Encrypted(cipherBytes), iv: iv);
    return decrypted;
  }

  @override
  Future<List<PrivatePlaylist>> loadPlaylists() async {
    final encryptedData = await _secureStorage.read(key: _keyPlaylists);
    if (encryptedData == null || encryptedData.isEmpty) {
      return const <PrivatePlaylist>[];
    }

    final decryptedJson = await _decrypt(encryptedData);
    final dynamic decoded = jsonDecode(decryptedJson);

    if (decoded is! List) {
      throw const FormatException('Expected List in decrypted playlists JSON');
    }

    final result = <PrivatePlaylist>[];
    for (final element in decoded) {
      if (element is Map<String, dynamic>) {
        result.add(PrivatePlaylist.fromJson(element));
      } else if (element is Map) {
        result.add(PrivatePlaylist.fromJson(Map<String, dynamic>.from(element)));
      } else {
        throw const FormatException('Malformed playlist map in vault storage');
      }
    }

    return List<PrivatePlaylist>.unmodifiable(result);
  }

  @override
  Future<void> savePlaylists(List<PrivatePlaylist> playlists) async {
    final jsonList = playlists.map((p) => p.toJson()).toList();
    final rawString = jsonEncode(jsonList);
    final encrypted = await _encrypt(rawString);
    await _secureStorage.write(key: _keyPlaylists, value: encrypted);
  }

  @override
  Future<VaultSettings> loadSettings() async {
    final encryptedData = await _secureStorage.read(key: _keySettings);
    if (encryptedData == null || encryptedData.isEmpty) {
      return VaultSettings.defaultSettings;
    }

    try {
      final decryptedJson = await _decrypt(encryptedData);
      final dynamic decoded = jsonDecode(decryptedJson);
      if (decoded is Map<String, dynamic>) {
        return VaultSettings.fromJson(decoded);
      } else if (decoded is Map) {
        return VaultSettings.fromJson(Map<String, dynamic>.from(decoded));
      }
      return VaultSettings.defaultSettings;
    } catch (_) {
      return VaultSettings.defaultSettings;
    }
  }

  @override
  Future<void> saveSettings(VaultSettings settings) async {
    final rawString = jsonEncode(settings.toJson());
    final encrypted = await _encrypt(rawString);
    await _secureStorage.write(key: _keySettings, value: encrypted);
  }

  @override
  Future<GesturePattern> loadGesturePattern() async {
    final encryptedData = await _secureStorage.read(key: _keyGesture);
    if (encryptedData == null || encryptedData.isEmpty) {
      return GesturePattern.defaultPattern;
    }

    try {
      final decryptedJson = await _decrypt(encryptedData);
      final dynamic decoded = jsonDecode(decryptedJson);
      if (decoded is List) {
        return GesturePattern.fromJson(decoded);
      }
      return GesturePattern.defaultPattern;
    } catch (_) {
      return GesturePattern.defaultPattern;
    }
  }

  @override
  Future<void> saveGesturePattern(GesturePattern pattern) async {
    final rawString = jsonEncode(pattern.toJson());
    final encrypted = await _encrypt(rawString);
    await _secureStorage.write(key: _keyGesture, value: encrypted);
  }

  @override
  void purgeDecryptedMemory() {
    _cachedKey = null;
  }
}
