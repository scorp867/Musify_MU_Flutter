import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_bloc.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_state.dart';
import 'package:on_audio_query/on_audio_query.dart';

class LocalMusicScreen extends StatelessWidget {
  final PlaybackController? playbackController;

  const LocalMusicScreen({super.key, this.playbackController});

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
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
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
                      final playback = playbackController;
                      if (playback == null) return;
                      final mediaItems = tracks
                          .map(
                            (track) => MediaItemMapper.fromTrack(
                              id: track.id,
                              title: track.title,
                              artist: track.artist,
                              album: track.album,
                              durationMilliseconds: track.duration,
                              songId: track.songId,
                              dataPath: track.dataPath,
                              dateModified: track.dateModified,
                            ),
                          )
                          .toList(growable: false);
                      playback.playQueue(mediaItems, index);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: QueryArtworkWidget(
                            id: track.songId ?? int.tryParse(track.id) ?? 0,
                            type: ArtworkType.AUDIO,
                            artworkHeight: 50,
                            artworkWidth: 50,
                            keepOldArtwork: true,
                            nullArtworkWidget: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.music_note,
                                color: Color(0xFF10B981),
                              ),
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
