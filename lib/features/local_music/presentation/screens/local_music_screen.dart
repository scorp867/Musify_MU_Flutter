import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';
import 'package:musify_mu/core/ui/widgets/shell_bottom_spacer.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_bloc.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_state.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_bloc.dart';
import 'package:musify_mu/features/player/domain/commands/options/prepare_play_options.dart';
import 'package:musify_mu/features/player/domain/commands/options/skip_to_track.dart';
import 'package:musify_mu/features/player/domain/models/context.dart';
import 'package:musify_mu/features/player/domain/models/context_page.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/play_origin.dart';
import 'package:on_audio_query/on_audio_query.dart';

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
        if (state is LocalMusicLoading) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            ),
          );
        } else if (state is LocalMusicError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        } else if (state is LocalMusicLoaded) {
          final tracks = state.tracks;

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
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final track = tracks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () {
                      final allContextTracks = tracks.map((t) {
                        return ContextTrack.builder('spotify:local:${t.id}')
                            .uid('local_${t.id}')
                            .metadata({
                              ContextTrackMetadata.keyTitle: t.title,
                              ContextTrackMetadata.keyArtistName: t.artist,
                              ContextTrackMetadata.keyAlbumTitle: t.album ?? 'Local Music',
                              ContextTrackMetadata.keyDuration: t.duration?.toString() ?? '0',
                              ContextTrackMetadata.keyLocalFilePath: t.dataPath ?? '',
                              if (t.songId != null)
                                ContextTrackMetadata.keySongId: t.songId.toString(),
                              ContextTrackMetadata.keyIsQueued: 'false',
                            })
                            .build();
                      }).toList(growable: false);

                      final tappedTrack = allContextTracks[index];

                      if (getIt.isRegistered<PlayerQueueBloc>()) {
                        final activeBloc = getIt<PlayerQueueBloc>();

                        final page = ContextPage.builder()
                            .tracks(allContextTracks)
                            .build();

                        final contextModel = Context.builder('spotify:internal:local-files')
                            .url('context://spotify:internal:local-files')
                            .metadata({
                              ContextTrackMetadata.keyTitle: 'Local Files',
                            })
                            .pages([page])
                            .build();

                        final playOptions = PreparePlayOptions.builder()
                            .skipTo(SkipToTrack.fromUri(tappedTrack.uri))
                            .build();

                        activeBloc.add(PlayContext(
                          context: contextModel,
                          options: playOptions,
                          playOrigin: const PlayOrigin(
                            featureIdentifier: 'local_files',
                            viewUri: 'spotify:internal:local-files',
                          ),
                        ));
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        QueryArtworkWidget(
                          id: track.songId ?? int.tryParse(track.id) ?? 0,
                          type: ArtworkType.AUDIO,
                          artworkHeight: 50,
                          artworkWidth: 50,
                          artworkBorder: BorderRadius.zero,
                          artworkClipBehavior: Clip.none,
                          artworkQuality: FilterQuality.low,
                          quality: 50,
                          keepOldArtwork: true,
                          nullArtworkWidget: Container(
                            width: 50,
                            height: 50,
                            color: const Color(0xFF1E293B),
                            child: const Icon(
                              Icons.music_note,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
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
                                track.artist,
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
                        if (track.duration != null)
                          Text(
                            _formatDuration(track.duration!),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }, childCount: tracks.length),
            ),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }

  String _formatDuration(int milliseconds) {
    return DurationFormatter.milliseconds(milliseconds);
  }
}
