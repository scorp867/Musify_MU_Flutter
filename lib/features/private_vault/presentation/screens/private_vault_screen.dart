import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/private_vault/application/private_vault_bloc.dart';
import 'package:musify_mu/features/private_vault/domain/models/private_playlist.dart';
import 'package:musify_mu/features/private_vault/presentation/screens/private_playlist_detail_screen.dart';
import 'package:musify_mu/features/private_vault/presentation/screens/private_vault_settings_screen.dart';
import 'package:musify_mu/features/private_vault/presentation/theme/vault_theme_palette.dart';

/// Main dashboard of the isolated Private Vault.
class PrivateVaultScreen extends StatefulWidget {
  final AppDatabase appDatabase;

  const PrivateVaultScreen({
    super.key,
    required this.appDatabase,
  });

  static Route<void> route({required AppDatabase appDatabase}) {
    return MaterialPageRoute<void>(
      builder: (context) => PrivateVaultScreen(appDatabase: appDatabase),
    );
  }

  @override
  State<PrivateVaultScreen> createState() => _PrivateVaultScreenState();
}

class _PrivateVaultScreenState extends State<PrivateVaultScreen> {
  bool _isPopping = false;

  void _safePop() {
    if (_isPopping) return;
    _isPopping = true;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _showCreatePlaylistDialog(BuildContext context, VaultThemePalette palette) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: palette.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: palette.cardBorder),
          ),
          title: Text(
            'New Private Playlist',
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                style: TextStyle(color: palette.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Playlist Name',
                  labelStyle: TextStyle(color: palette.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: palette.cardBorder),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: palette.textPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: TextStyle(color: palette.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: TextStyle(color: palette.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: palette.cardBorder),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: palette.textPrimary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: palette.textSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.cardBorder,
                foregroundColor: palette.textPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: palette.cardBorder),
                ),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  context.read<PrivateVaultBloc>().add(
                        VaultPlaylistCreateRequested(
                          name: name,
                          description: descController.text.trim().isEmpty
                              ? null
                              : descController.text.trim(),
                        ),
                      );
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    PrivatePlaylist playlist,
    VaultThemePalette palette,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: palette.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: palette.cardBorder),
          ),
          title: Text(
            'Delete Playlist',
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently delete "${playlist.name}"? This action cannot be undone.',
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: palette.textSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.danger,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                context.read<PrivateVaultBloc>().add(
                      VaultPlaylistDeleteRequested(playlistId: playlist.id),
                    );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isPopping,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _isPopping = true;
          context.read<PrivateVaultBloc>().add(const VaultScreenExited());
        }
      },
      child: BlocConsumer<PrivateVaultBloc, PrivateVaultState>(
        listenWhen: (prev, curr) => curr is VaultStateLocked,
        listener: (context, state) {
          if (state is VaultStateLocked && !_isPopping) {
            final route = ModalRoute.of(context);
            if (route != null && route.isCurrent) {
              _safePop();
            }
          }
        },
        builder: (context, state) {
          final palette = VaultThemePalette.of(state.settings.theme);

          if (state is! VaultStateActive) {
            return Scaffold(
              backgroundColor: palette.scaffoldBackground,
              body: Center(
                child: CircularProgressIndicator(color: palette.textPrimary),
              ),
            );
          }

          final playlists = state.playlists;

          return Scaffold(
            backgroundColor: palette.scaffoldBackground,
            appBar: AppBar(
              backgroundColor: palette.scaffoldBackground,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: palette.textPrimary),
                onPressed: _safePop,
              ),
              title: Text(
                'Private Vault',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings, color: palette.textPrimary),
                  tooltip: 'Vault Settings',
                  onPressed: () {
                    Navigator.of(context).push(PrivateVaultSettingsScreen.route());
                  },
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${playlists.length} ${playlists.length == 1 ? "PLAYLIST" : "PLAYLISTS"}',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: palette.textPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New Playlist'),
                        onPressed: () => _showCreatePlaylistDialog(context, palette),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: playlists.isEmpty
                        ? _EmptyStateView(
                            palette: palette,
                            onCreatePlaylist: () => _showCreatePlaylistDialog(context, palette),
                          )
                        : ListView.separated(
                            itemCount: playlists.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final playlist = playlists[index];
                              return _ThemedPlaylistRow(
                                key: ValueKey(playlist.id),
                                playlist: playlist,
                                palette: palette,
                                onTap: () {
                                  Navigator.of(context).push(
                                    PrivatePlaylistDetailScreen.route(
                                      playlistId: playlist.id,
                                      appDatabase: widget.appDatabase,
                                    ),
                                  );
                                },
                                onDelete: () => _showDeleteConfirmDialog(context, playlist, palette),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ThemedPlaylistRow extends StatelessWidget {
  final PrivatePlaylist playlist;
  final VaultThemePalette palette;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ThemedPlaylistRow({
    super.key,
    required this.playlist,
    required this.palette,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleText = switch (playlist.description) {
      final desc? when desc.isNotEmpty => desc,
      _ => '${playlist.trackCount} ${playlist.trackCount == 1 ? "track" : "tracks"} • AES-256',
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: palette.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: palette.scaffoldBackground,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: palette.cardBorder),
              ),
              child: Icon(Icons.lock, size: 20, color: palette.textPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: palette.scaffoldBackground,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: palette.cardBorder),
              ),
              child: Text(
                '${playlist.trackCount}',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 20, color: palette.textSecondary),
              color: palette.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: palette.cardBorder),
              ),
              onSelected: (value) {
                if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: palette.danger),
                      const SizedBox(width: 8),
                      Text('Delete Playlist', style: TextStyle(color: palette.danger, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  final VaultThemePalette palette;
  final VoidCallback onCreatePlaylist;

  const _EmptyStateView({
    required this.palette,
    required this.onCreatePlaylist,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: palette.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Icon(
              Icons.lock_outline,
              size: 28,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Zero Vault Payloads',
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first encrypted playlist to start storing private tracks.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.textPrimary,
                  side: BorderSide(color: palette.cardBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create New Playlist'),
                onPressed: onCreatePlaylist,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
