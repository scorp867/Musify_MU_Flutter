import 'package:flutter/material.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';

/// Modal bottom sheet allowing the user to select an existing private playlist
/// or create a brand new private playlist on the fly.
class PrivatePlaylistSelectionDialog extends StatefulWidget {
  final IVaultStorageRepository storageRepository;

  const PrivatePlaylistSelectionDialog({
    super.key,
    required this.storageRepository,
  });

  /// Displays the playlist picker and returns the selected [PrivatePlaylist],
  /// or null if dismissed.
  static Future<PrivatePlaylist?> show(
    BuildContext context, {
    required IVaultStorageRepository storageRepository,
  }) {
    return showModalBottomSheet<PrivatePlaylist>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => PrivatePlaylistSelectionDialog(
        storageRepository: storageRepository,
      ),
    );
  }

  @override
  State<PrivatePlaylistSelectionDialog> createState() =>
      _PrivatePlaylistSelectionDialogState();
}

class _PrivatePlaylistSelectionDialogState
    extends State<PrivatePlaylistSelectionDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  List<PrivatePlaylist> _playlists = const [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final result = await widget.storageRepository.getPlaylists();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      switch (result) {
        case VaultSuccess<List<PrivatePlaylist>>(:final data):
          _playlists = data;
          _errorMessage = null;
        case VaultFailureResult(:final failure):
          _errorMessage = failure.message;
      }
    });
  }

  Future<void> _handleCreateNewPlaylist() async {
    final controller = TextEditingController();
    final created = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: const BorderSide(color: Color(0xFF383838), width: 1.0),
        ),
        title: const Text(
          'New Private Playlist',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: const TextStyle(color: Color(0xFF727272), fontSize: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Color(0xFF383838)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Color(0xFF1ED760)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFB3B3B3))),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(dialogCtx).pop(text);
              }
            },
            child: const Text('Create', style: TextStyle(color: Color(0xFF1ED760))),
          ),
        ],
      ),
    );

    if (created case final name? when name.trim().isNotEmpty) {
      final createResult = await widget.storageRepository.createPlaylist(
        name: name.trim(),
        description: 'Private Playlist',
      );
      if (!mounted) return;
      if (createResult case VaultSuccess<PrivatePlaylist>(:final data)) {
        Navigator.of(context).pop(data);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF282828),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select Private Playlist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _handleCreateNewPlaylist,
                    icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF1ED760)),
                    label: const Text(
                      'New',
                      style: TextStyle(
                        color: Color(0xFF1ED760),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF383838), height: 1),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF1ED760)),
                ),
              )
            else if (_errorMessage case final err?)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    err,
                    style: const TextStyle(color: Color(0xFFE91429), fontSize: 13),
                  ),
                ),
              )
            else if (_playlists.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 24.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, color: Color(0xFF727272), size: 36),
                      const SizedBox(height: 12),
                      const Text(
                        'No Private Playlists Found',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _handleCreateNewPlaylist,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1ED760),
                          side: const BorderSide(color: Color(0xFF383838)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text('Create Private Playlist'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _playlists.length,
                  itemBuilder: (ctx, index) {
                    final playlist = _playlists[index];
                    return ListTile(
                      key: ValueKey('picker_playlist_${playlist.id}'),
                      leading: const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      title: Text(
                        playlist.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      subtitle: Text(
                        '${playlist.trackCount} tracks',
                        style: const TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(playlist),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
