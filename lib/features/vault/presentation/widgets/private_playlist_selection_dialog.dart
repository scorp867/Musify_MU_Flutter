import 'package:flutter/material.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_artwork_image.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_settings_components.dart';

/// Modal bottom sheet allowing the user to select an existing vault playlist
/// or create a new one on the fly.
class PrivatePlaylistSelectionDialog extends StatefulWidget {
  final IVaultStorageRepository storageRepository;
  final VaultThemeData? vaultTheme;

  const PrivatePlaylistSelectionDialog({
    super.key,
    required this.storageRepository,
    this.vaultTheme,
  });

  /// Displays the playlist picker and returns the selected [PrivatePlaylist],
  /// or null if dismissed.
  static Future<PrivatePlaylist?> show(
    BuildContext context, {
    required IVaultStorageRepository storageRepository,
    VaultThemeData? vaultTheme,
  }) {
    final resolvedTheme = resolveVaultTheme(context, vaultTheme);
    return showModalBottomSheet<PrivatePlaylist>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) => VaultTheme(
        data: resolvedTheme,
        child: PrivatePlaylistSelectionDialog(
          storageRepository: storageRepository,
          vaultTheme: resolvedTheme,
        ),
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
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

  Future<void> _handleCreateNewPlaylist(VaultThemeData vaultTheme) async {
    final created = await showVaultCreatePlaylistSheet(
      context,
      vaultTheme,
      title: 'New Playlist',
      subtitle: 'Create a playlist and add this track right away.',
      showDescription: false,
    );

    if (created case final submission? when submission.name.isNotEmpty) {
      final createResult = await widget.storageRepository.createPlaylist(
        name: submission.name,
        description: submission.description,
      );
      if (!mounted) return;
      switch (createResult) {
        case VaultSuccess<PrivatePlaylist>(:final data):
          Navigator.of(context).pop(data);
        case VaultFailureResult(:final failure):
          showVaultSettingsSnackBar(
            context,
            vaultTheme,
            message: failure.message,
            isError: true,
            clearExisting: true,
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultTheme = resolveVaultTheme(context, widget.vaultTheme);

    return VaultSheetScaffold(
      vaultTheme: vaultTheme,
      title: 'Add to Vault Playlist',
      subtitle: 'Choose a destination playlist',
      onClose: () => Navigator.of(context).pop(),
      headerTrailing: SizedBox(
        height: 36.0,
        child: OutlinedButton.icon(
          onPressed: () => _handleCreateNewPlaylist(vaultTheme),
          style: OutlinedButton.styleFrom(
            foregroundColor: vaultTheme.accent,
            side: BorderSide(
              color: vaultTheme.borderSubtle,
              width: VaultTheme.borderWidth,
            ),
            shape: VaultTheme.shape8,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
          ),
          icon: const Icon(Icons.add_rounded, size: 17.0),
          label: const Text(
            'New',
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 13.0,
            ),
          ),
        ),
      ),
      body: _buildBody(vaultTheme),
    );
  }

  Widget _buildBody(VaultThemeData vaultTheme) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(36.0),
        child: Center(
          child: CircularProgressIndicator(color: vaultTheme.accent),
        ),
      );
    }

    if (_errorMessage case final err?) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: vaultTheme.background,
            borderRadius: VaultTheme.borderRadius8,
            border: Border.all(
              color: vaultTheme.borderSubtle,
              width: VaultTheme.borderWidth,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: vaultDangerInk(vaultTheme),
                size: 32.0,
              ),
              const SizedBox(height: 10.0),
              Text(
                err,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  color: vaultTheme.textMediumSalience,
                  fontSize: 13.0,
                ),
              ),
              const SizedBox(height: 14.0),
              SizedBox(
                height: 44.0,
                child: OutlinedButton(
                  onPressed: _loadPlaylists,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: vaultTheme.accent,
                    side: BorderSide(
                      color: vaultTheme.border,
                      width: VaultTheme.borderWidth,
                    ),
                    shape: VaultTheme.shape8,
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontFamily: VaultTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_playlists.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 20.0),
          decoration: BoxDecoration(
            color: vaultTheme.background,
            borderRadius: VaultTheme.borderRadius8,
            border: Border.all(
              color: vaultTheme.borderSubtle,
              width: VaultTheme.borderWidth,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48.0,
                height: 48.0,
                decoration: BoxDecoration(
                  color: vaultTheme.surfaceSubtle,
                  borderRadius: VaultTheme.borderRadius8,
                  border: Border.all(
                    color: vaultTheme.borderSubtle,
                    width: VaultTheme.borderWidth,
                  ),
                ),
                child: Icon(
                  Icons.library_music_outlined,
                  color: vaultTheme.textLowSalience,
                  size: 24.0,
                ),
              ),
              const SizedBox(height: 12.0),
              Text(
                'No Playlists Yet',
                style: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  color: vaultTheme.textHighSalience,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Create a playlist to keep saved tracks organized.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  color: vaultTheme.textMediumSalience,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                height: 44.0,
                child: OutlinedButton.icon(
                  onPressed: () => _handleCreateNewPlaylist(vaultTheme),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: vaultTheme.accent,
                    side: BorderSide(
                      color: vaultTheme.border,
                      width: VaultTheme.borderWidth,
                    ),
                    shape: VaultTheme.shape8,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18.0),
                  label: const Text(
                    'New Playlist',
                    style: TextStyle(
                      fontFamily: VaultTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
      itemCount: _playlists.length,
      itemBuilder: (ctx, index) {
        final playlist = _playlists[index];
        final trackNoun = playlist.trackCount == 1 ? 'track' : 'tracks';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Material(
            color: vaultTheme.background,
            shape: RoundedRectangleBorder(
              borderRadius: VaultTheme.borderRadius8,
              side: BorderSide(
                color: vaultTheme.borderSubtle,
                width: VaultTheme.borderWidth,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
            key: ValueKey('picker_playlist_${playlist.id}'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 4.0,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: VaultArtworkImage.forPlaylist(
                playlist,
                size: 42.0,
                placeholderIconSize: 20.0,
                vaultTheme: vaultTheme,
              ),
            ),
            title: Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                color: vaultTheme.textHighSalience,
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${playlist.trackCount} $trackNoun',
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                color: vaultTheme.textMediumSalience,
                fontSize: 12.0,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              size: 20.0,
              color: vaultTheme.textLowSalience,
            ),
            onTap: () => Navigator.of(context).pop(playlist),
            ),
          ),
        );
      },
    );
  }
}
