import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';
import 'package:musify_mu/core/ui/widgets/shell_bottom_spacer.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_metadata.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_uri.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_bloc.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_state.dart';
import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/domain/commands/options/prepare_play_options.dart';
import 'package:musify_mu/features/player/domain/commands/options/skip_to_track.dart';
import 'package:musify_mu/features/player/domain/models/context.dart';
import 'package:musify_mu/features/player/domain/models/context_page.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/play_origin.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_artwork.dart';

class LocalMusicScreen extends StatelessWidget {
  const LocalMusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildSectionTitle('Local Files (Offline)'),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            _buildLocalLibrarySliver(),
            const SliverShellBottomSpacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLocalLibrarySliver() {
    return BlocBuilder<LocalMusicBloc, LocalMusicState>(
      builder: (context, state) {
        switch (state) {
          case LocalMusicInitial():
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          case LocalMusicLoading():
            return const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981)),
              ),
            );
          case LocalMusicError(:final message):
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          case LocalMusicLoaded(:final tracks):
            if (tracks.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                  child: Center(
                    child: Text(
                      'No local music found on your device.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.builder(
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final file = tracks[index];
                  return _LocalFileRow(
                    key: ValueKey<String>(file.path),
                    file: file,
                    onTap: () => _playLocalContext(tracks, index),
                  );
                },
              ),
            );
        }
      },
    );
  }

  void _playLocalContext(List<LocalFile> tracks, int index) {
    if (index < 0 || index >= tracks.length) return;
    if (!getIt.isRegistered<PlayerQueueMobiusController>()) return;

    final allContextTracks = <ContextTrack>[
      for (var i = 0; i < tracks.length; i++)
        LocalFileUri.toContextTrack(tracks[i], uidIndex: i),
    ];

    final tappedTrack = allContextTracks[index];
    final controller = getIt<PlayerQueueMobiusController>();

    final page = ContextPage.builder().tracks(allContextTracks).build();
    final contextModel = Context.builder('spotify:internal:local-files')
        .url('context://spotify:internal:local-files')
        .metadata({
          ContextTrackMetadata.keyTitle: 'Local Files',
        })
        .pages([page])
        .build();

    final playOptions = PreparePlayOptions.builder()
        .skipTo(
          SkipToTrack.builder()
              .trackUid(tappedTrack.uid)
              .trackUri(tappedTrack.uri)
              .build(),
        )
        .build();

    controller.playContext(
      contextModel,
      options: playOptions,
      playOrigin: const PlayOrigin(
        featureIdentifier: 'local_files',
        viewUri: 'spotify:internal:local-files',
      ),
    );
  }
}

class _LocalFileRow extends StatelessWidget {
  final LocalFile file;
  final VoidCallback onTap;

  const _LocalFileRow({
    super.key,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = switch (file.metadata) {
      final m? => m,
      null => const LocalFileMetadata(),
    };
    final trackUri = LocalFileUri.fromLocalFile(file);
    final imageUri = LocalFileUri.toLocalFileImageUri(trackUri);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            PlayerArtworkImage(
              imageUrl: imageUri,
              artworkWidth: 50,
              artworkHeight: 50,
              placeholderIconSize: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta.artist,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (meta.duration > 0)
              Text(
                DurationFormatter.milliseconds(meta.duration * 1000),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
