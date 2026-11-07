import 'package:musify_mu/features/private_vault/domain/models/gesture_pattern.dart';
import 'package:musify_mu/features/private_vault/domain/models/private_playlist.dart';
import 'package:musify_mu/features/private_vault/domain/models/vault_settings.dart';

/// Pure domain abstraction for isolated and cryptographically protected vault persistence.
abstract interface class IVaultStorageService {
  Future<List<PrivatePlaylist>> loadPlaylists();
  Future<void> savePlaylists(List<PrivatePlaylist> playlists);
  Future<VaultSettings> loadSettings();
  Future<void> saveSettings(VaultSettings settings);
  Future<GesturePattern> loadGesturePattern();
  Future<void> saveGesturePattern(GesturePattern pattern);
  void purgeDecryptedMemory();
}
