import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/private_vault/application/private_vault_bloc.dart';
import 'package:musify_mu/features/private_vault/domain/models/private_playlist.dart';
import 'package:musify_mu/features/private_vault/presentation/theme/vault_theme_palette.dart';

/// Screen displaying tracks and management actions for a specific private playlist.
class PrivatePlaylistDetailScreen extends StatelessWidget {
  final String playlistId;
  final AppDatabase appDatabase;

  const PrivatePlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.appDatabase,
  });

  static Route<void> route({
    required String playlistId,
    required AppDatabase appDatabase,
  }) {
    return MaterialPageRoute<void>(
      builder: (context) => PrivatePlaylistDetailScreen(
        playlistId: playlistId,
        appDatabase: appDatabase,
      ),
    );
  }

  void _showAddTracksSheet(
    BuildContext context,
    PrivatePlaylist playlist,
    VaultThemePalette palette,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        side: BorderSide(color: palette.cardBorder),
      ),
      builder: (sheetContext) {
        return FutureBuilder<List<LocalTrack>>(
          future: appDatabase.getAllTracks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 250,
                child: Center(
                  child: CircularProgressIndicator(color: palette.textPrimary),
                ),
              );
            }

            final tracks = snapshot.data ?? const <LocalTrack>[];
            final availableTracks = tracks.where(
              (t) => !playlist.trackUris.contains(t.dataPath),
            ).toList();

            return SafeArea(
              child: Container(
                height: MediaQuery.sizeOf(context).height * 0.7,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Tracks to Vault',
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: palette.textSecondary),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (availableTracks.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            'No additional local tracks found on device.',
                            style: TextStyle(color: palette.textSecondary),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: availableTracks.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: palette.cardBorder),
                          itemBuilder: (context, index) {
                            final track = availableTracks[index];
                            final artist = track.artist;
                            final artistLabel = (artist != null && artist.isNotEmpty) ? artist : 'Unknown Artist';

                            return ListTile(
                              key: ValueKey('add_track_${track.id}'),
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: palette.scaffoldBackground,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: palette.cardBorder),
                                ),
                                child: Icon(Icons.music_note, color: palette.textPrimary, size: 20),
                              ),
                              title: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: palette.textPrimary, fontSize: 14),
                              ),
                              subtitle: Text(
                                artistLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: palette.textSecondary, fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.add_circle_outline, color: palette.textPrimary),
                                onPressed: () {
                                  sheetContext.read<PrivateVaultBloc>().add(
                                        VaultTrackAddRequested(
                                          playlistId: playlist.id,
                                          trackUri: track.dataPath,
                                        ),
                                      );
                                  Navigator.of(sheetContext).pop();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeletePlaylist(
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
            'Delete Private Playlist?',
            style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.',
            style: TextStyle(color: palette.textSecondary),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                context.read<PrivateVaultBloc>().add(
                      VaultPlaylistDeleteRequested(playlistId: playlist.id),
                    );
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
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
    return BlocBuilder<PrivateVaultBloc, PrivateVaultState>(
      buildWhen: (prev, curr) => curr is VaultStateUnlocked,
      builder: (context, state) {
        final palette = VaultThemePalette.of(state.settings.theme);

        if (state is! VaultStateUnlocked) {
          return Scaffold(
            backgroundColor: palette.scaffoldBackground,
            body: Center(
              child: Text('Vault locked', style: TextStyle(color: palette.textPrimary)),
            ),
          );
        }

        final playlist = state.playlists.cast<PrivatePlaylist?>().firstWhere(
              (p) => p?.id == playlistId,
              orElse: () => null,
            );

        if (playlist == null) {
          return Scaffold(
            backgroundColor: palette.scaffoldBackground,
            appBar: AppBar(
              backgroundColor: palette.scaffoldBackground,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: palette.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: Text(
                'Playlist not found or deleted',
                style: TextStyle(color: palette.textSecondary),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: palette.scaffoldBackground,
          body: CustomScrollView(
            slivers: [
              // Collapsing Architectural Banner
              SliverAppBar(
                backgroundColor: palette.scaffoldBackground,
                expandedHeight: 180,
                pinned: true,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: palette.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: palette.danger),
                    tooltip: 'Delete Playlist',
                    onPressed: () => _confirmDeletePlaylist(context, playlist, palette),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  expandedTitleScale: 1.2,
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                  title: Text(
                    playlist.name,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  background: Container(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 48),
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRIVATE VAULT // AES-256',
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (playlist.description != null && playlist.description!.isNotEmpty)
                          Text(
                            playlist.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Action Toolbar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: palette.cardBackground,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: palette.cardBorder),
                        ),
                        child: Text(
                          '${playlist.trackCount} ${playlist.trackCount == 1 ? "TRACK" : "TRACKS"}',
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.textPrimary,
                          side: BorderSide(color: palette.cardBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Tracks'),
                        onPressed: () => _showAddTracksSheet(context, playlist, palette),
                      ),
                    ],
                  ),
                ),
              ),

              // Track List
              if (playlist.trackUris.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: palette.cardBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: palette.cardBorder),
                          ),
                          child: Icon(Icons.queue_music, color: palette.textSecondary, size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Empty Private Playlist',
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "Add Tracks" to select music from your device.',
                          style: TextStyle(color: palette.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final trackUri = playlist.trackUris[index];
                        final filename = trackUri.split('/').last;

                        return Container(
                          key: ValueKey('vault_track_$trackUri'),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: palette.cardBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: palette.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${index + 1}'.padLeft(2, '0'),
                                style: TextStyle(
                                  color: palette.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  filename,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: palette.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.remove_circle_outline,
                                  size: 20,
                                  color: palette.textSecondary,
                                ),
                                tooltip: 'Remove from playlist',
                                onPressed: () {
                                  context.read<PrivateVaultBloc>().add(
                                        VaultTrackRemoveRequested(
                                          playlistId: playlist.id,
                                          trackUri: trackUri,
                                        ),
                                      );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: playlist.trackUris.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
