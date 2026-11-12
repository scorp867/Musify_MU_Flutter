import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/library/domain/models/library_item.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_header.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_theme.dart';
import 'package:musify_mu/features/player/presentation/widgets/pull_to_dismiss_scaffold.dart';
import 'package:musify_mu/features/player/presentation/widgets/spotify_scroll_physics.dart';
import 'package:musify_mu/features/vault/application/portability/vault_portability_cubit.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_local_song_picker_sheet.dart';

enum PortabilityTabEnum {
  importToVault,
  exportToPublic;

  String get title => switch (this) {
        PortabilityTabEnum.importToVault => 'Import to Vault',
        PortabilityTabEnum.exportToPublic => 'Export to Public',
      };
}

/// Modal bottom sheet for importing public Spotify and local media into the Vault,
/// or exporting isolated sandbox tracks back to device storage (Option A).
class VaultPortabilitySheet extends StatelessWidget {
  final VaultPortabilityCubit? cubitOverride;

  const VaultPortabilitySheet({super.key, this.cubitOverride});

  /// Displays [VaultPortabilitySheet] inside a modal route.
  static Future<void> show(
    BuildContext context, {
    VaultPortabilityCubit? cubitOverride,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => VaultPortabilitySheet(cubitOverride: cubitOverride),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = switch (cubitOverride) {
          final c? => c,
          null => VaultPortabilityCubit(),
        };
        cubit.loadPortabilityData();
        return cubit;
      },
      child: PullToDismissScaffold(
        builder: (scaffoldContext, dismissController) {
          return const _VaultPortabilityContent();
        },
      ),
    );
  }
}

class _VaultPortabilityContent extends StatefulWidget {
  const _VaultPortabilityContent();

  @override
  State<_VaultPortabilityContent> createState() =>
      _VaultPortabilityContentState();
}

class _VaultPortabilityContentState extends State<_VaultPortabilityContent> {
  final ScrollController _scrollController = ScrollController();
  PortabilityTabEnum _activeTab = PortabilityTabEnum.importToVault;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PlayerColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              // 1. Top Drag Handle & Sheet Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Vault Portability',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        PlayerCircleButton(
                          icon: Icons.close_rounded,
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Segmented Mode Control [ Import to Vault | Export to Public ]
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: _buildTabSwitcher(),
              ),

              const Divider(color: PlayerColors.divider, height: 1),

              // 3. Tab Body
              Expanded(
                child: BlocConsumer<VaultPortabilityCubit, VaultPortabilityState>(
                  listener: (context, state) {
                    if (state is VaultPortabilitySuccessState) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            state.summaryMessage,
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      context.read<VaultPortabilityCubit>().loadPortabilityData();
                    }
                  },
                  builder: (context, state) {
                    return switch (state) {
                      VaultPortabilityInitialState() ||
                      VaultPortabilityLoadingState() =>
                        const Center(
                          child:
                              CircularProgressIndicator(color: Color(0xFF1DB954)),
                        ),
                      VaultPortabilityProcessingState(
                        :final progressMessage,
                        :final current,
                        :final total
                      ) =>
                        _buildProcessingView(progressMessage, current, total),
                      VaultPortabilityErrorState(:final errorMessage) =>
                        _buildErrorView(errorMessage),
                      VaultPortabilityLoadedState() ||
                      VaultPortabilitySuccessState() =>
                        _buildLoadedView(context),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: PlayerColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              tab: PortabilityTabEnum.importToVault,
              icon: Icons.file_download_outlined,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              tab: PortabilityTabEnum.exportToPublic,
              icon: Icons.file_upload_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required PortabilityTabEnum tab,
    required IconData icon,
  }) {
    final isSelected = _activeTab == tab;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _activeTab = tab);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1DB954) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.black : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                tab.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.black : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingView(String message, int current, int total) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF1DB954)),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (total > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$current of $total items processed',
                style: const TextStyle(
                  color: PlayerColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 44),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () =>
                  context.read<VaultPortabilityCubit>().loadPortabilityData(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1DB954),
                side: const BorderSide(color: Color(0xFF1DB954)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context) {
    final state = context.watch<VaultPortabilityCubit>().state;
    if (state is! VaultPortabilityLoadedState) {
      return const SizedBox.shrink();
    }

    return SpotifyStretchOverscrollIndicator(
      axisDirection: AxisDirection.down,
      child: ListView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: switch (_activeTab) {
          PortabilityTabEnum.importToVault => _buildImportSection(context, state),
          PortabilityTabEnum.exportToPublic => _buildExportSection(context, state),
        },
      ),
    );
  }

  List<Widget> _buildImportSection(
    BuildContext context,
    VaultPortabilityLoadedState state,
  ) {
    final cubit = context.read<VaultPortabilityCubit>();

    return [
      // 1. Device Local Music Bulk Ingestion
      _buildSectionHeader('Device Local Audio'),
      Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: PlayerColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.library_music_rounded,
                    color: Color(0xFF1DB954), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'All Device Music Files',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${state.localTracksCount} tracks discovered on device',
                        style: const TextStyle(
                          color: PlayerColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('portability_import_local_copy_btn'),
                    onPressed: state.localTracksCount > 0
                        ? () => cubit.importLocalTracks(
                              playlistName: 'Local Audio (Referenced)',
                              ingestionMode: VaultSongIngestionModeEnum.copyToVault,
                            )
                        : null,
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy to Vault',
                        style: TextStyle(fontSize: 12.5)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    key: const ValueKey('portability_import_local_move_btn'),
                    onPressed: state.localTracksCount > 0
                        ? () => cubit.importLocalTracks(
                              playlistName: 'Local Audio (Sandbox Isolated)',
                              ingestionMode: VaultSongIngestionModeEnum.moveToVault,
                            )
                        : null,
                    icon: const Icon(Icons.drive_file_move_outlined,
                        size: 16, color: Colors.black),
                    label: const Text(
                      'Move to Vault',
                      style: TextStyle(fontSize: 12.5, color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB954),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      const SizedBox(height: 24),

      // 2. Spotify Playlists Section
      _buildSectionHeader('Spotify Playlists (${state.spotifyPlaylists.length})'),
      if (state.spotifyPlaylists.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              'No Spotify playlists discovered in your library.',
              style: TextStyle(
                color: PlayerColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        )
      else
        ...state.spotifyPlaylists.map(
          (item) => _buildSpotifyPlaylistTile(context, item, cubit),
        ),
    ];
  }

  Widget _buildSpotifyPlaylistTile(
    BuildContext context,
    LibraryItem item,
    VaultPortabilityCubit cubit,
  ) {
    final subtitleText = switch (item.trackCount) {
      final count? => 'Spotify Playlist \u2022 $count tracks',
      null => 'Spotify Playlist',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: PlayerColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      child: ListTile(
        key: ValueKey('portability_sp_${item.uri}'),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Icon(Icons.playlist_play_rounded,
                color: Color(0xFF1DB954), size: 24),
          ),
        ),
        title: Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitleText,
          style: const TextStyle(
            color: PlayerColors.textSecondary,
            fontSize: 12.5,
          ),
        ),
        trailing: OutlinedButton(
          onPressed: () => cubit.importSpotifyPlaylist(
            playlistUri: item.uri,
            playlistName: item.name,
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1DB954),
            side: const BorderSide(color: Color(0xFF1DB954)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          ),
          child: const Text('Import',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  List<Widget> _buildExportSection(
    BuildContext context,
    VaultPortabilityLoadedState state,
  ) {
    final cubit = context.read<VaultPortabilityCubit>();

    return [
      _buildSectionHeader('Unvault & Move Back to Device'),
      Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: PlayerColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Option A: Restore to Public Storage',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Only audio files that were physically moved into the vault sandbox can be exported. Exporting moves files back to device storage (Music/Musify_Exported), re-registers them into your local music index, and unvaults them.',
              style: TextStyle(
                color: PlayerColors.textSecondary,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                key: const ValueKey('portability_export_all_btn'),
                onPressed: state.totalExportableTracksCount > 0
                    ? () => cubit.exportSandboxTracks()
                    : null,
                icon: const Icon(Icons.file_upload_outlined,
                    size: 18, color: Colors.black),
                label: Text(
                  state.totalExportableTracksCount > 0
                      ? 'Export All ${state.totalExportableTracksCount} Sandboxed Tracks'
                      : 'No Sandboxed Tracks to Export',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  disabledBackgroundColor:
                      const Color(0xFF1DB954).withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 24),

      _buildSectionHeader(
          'Export by Private Playlist (${state.exportablePlaylists.length})'),
      if (state.exportablePlaylists.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              'No private playlists have sandbox-isolated tracks.',
              style: TextStyle(
                color: PlayerColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        )
      else
        ...state.exportablePlaylists.map(
          (pl) => _buildExportablePlaylistTile(context, pl, cubit),
        ),
    ];
  }

  Widget _buildExportablePlaylistTile(
    BuildContext context,
    PrivatePlaylist playlist,
    VaultPortabilityCubit cubit,
  ) {
    final sandboxedCount = playlist.trackRefs
        .where((r) => r.sourceType == TrackSourceTypeEnum.localSandbox)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: PlayerColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      child: ListTile(
        key: ValueKey('portability_export_pl_${playlist.id}'),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Icon(Icons.lock_outline_rounded,
                color: Color(0xFF1DB954), size: 22),
          ),
        ),
        title: Text(
          playlist.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '$sandboxedCount physically isolated media tracks',
          style: const TextStyle(
            color: PlayerColors.textSecondary,
            fontSize: 12.5,
          ),
        ),
        trailing: OutlinedButton(
          onPressed: () =>
              cubit.exportSandboxTracks(specificPlaylistId: playlist.id),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1DB954),
            side: const BorderSide(color: Color(0xFF1DB954)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          ),
          child: const Text('Export',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
