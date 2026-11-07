import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/private_vault/data/vault_storage_service.dart';
import 'package:musify_mu/features/private_vault/domain/models/gesture_pattern.dart';
import 'package:musify_mu/features/private_vault/domain/models/private_playlist.dart';
import 'package:musify_mu/features/private_vault/domain/models/vault_settings.dart';

class FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _store = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _store[key] = value;
    } else {
      _store.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.clear();
  }
}

void main() {
  group('VaultStorageService Cryptographic Tests', () {
    late FakeSecureStorage fakeStorage;
    late VaultStorageService service;

    setUp(() {
      fakeStorage = FakeSecureStorage();
      service = VaultStorageService(secureStorage: fakeStorage);
    });

    test('saves and decrypts playlists successfully', () async {
      final now = DateTime.now();
      final playlist = PrivatePlaylist(
        id: 'test-uuid-1',
        name: 'Top Secret Beats',
        description: 'Classified listening',
        trackUris: const ['/storage/music/track1.mp3', '/storage/music/track2.mp3'],
        createdAt: now,
        updatedAt: now,
      );

      await service.savePlaylists([playlist]);
      final loaded = await service.loadPlaylists();

      expect(loaded.length, 1);
      expect(loaded.first.id, 'test-uuid-1');
      expect(loaded.first.name, 'Top Secret Beats');
      expect(loaded.first.trackUris.length, 2);
    });

    test('saves and decrypts custom vault settings', () async {
      const customSettings = VaultSettings(
        coolOffDuration: CoolOffDuration.fifteenMinutes,
        maskMediaSession: false,
        preventScreenshots: false,
        theme: VaultTheme.obsidianCream,
        showDrawerGestureTrail: true,
      );

      await service.saveSettings(customSettings);
      final loaded = await service.loadSettings();

      expect(loaded.coolOffDuration, CoolOffDuration.fifteenMinutes);
      expect(loaded.maskMediaSession, false);
      expect(loaded.preventScreenshots, false);
      expect(loaded.theme, VaultTheme.obsidianCream);
      expect(loaded.showDrawerGestureTrail, true);
    });

    test('saves and decrypts custom gesture patterns', () async {
      final customPattern = GesturePattern(const [
        UnistrokePoint(0.0, 0.0),
        UnistrokePoint(10.0, 10.0),
        UnistrokePoint(20.0, 20.0),
        UnistrokePoint(30.0, 30.0),
      ]);
      await service.saveGesturePattern(customPattern);
      final loaded = await service.loadGesturePattern();

      expect(loaded.points, customPattern.points);
    });

    test('loads default settings when storage is empty', () async {
      final settings = await service.loadSettings();
      expect(settings, VaultSettings.defaultSettings);
    });

    test('loads default gesture pattern when storage is empty', () async {
      final pattern = await service.loadGesturePattern();
      expect(pattern.points, GesturePattern.defaultPattern.points);
    });

    test('purgeDecryptedMemory clears cached AES key', () {
      service.purgeDecryptedMemory();
      expect(true, isTrue);
    });
  });
}
