import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';
import 'package:musify_mu/core/ui/widgets/app_header.dart';
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
import 'package:musify_mu/features/player/presentation/widgets/player_artwork.dart';

/// Offline library view showing local music files in a library layout.
class OfflineLibraryView extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onToggleMode;

  const OfflineLibraryView({
    super.key,
    this.onMenuPressed,
    this.onToggleMode,
  });

  @override
  State<OfflineLibraryView> createState() => _OfflineLibraryViewState();
}

class _OfflineLibraryViewState extends State<OfflineLibraryView> {
  String _searchQuery = '';

  List<LocalFile> _filter(List<LocalFile> tracks) {
    if (_searchQuery.isEmpty) return tracks;
    final q = _searchQuery.toLowerCase();
    return tracks.where((file) {
      final meta = switch (file.metadata) {
        final m? => m,
        null => const LocalFileMetadata(),
      };
      return meta.title.toLowerCase().contains(q) ||
          meta.artist.toLowerCase().contains(q) ||
          meta.album.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<LocalMusicBloc, LocalMusicState>(
          builder: (context, state) {
            final tracks = switch (state) {
              LocalMusicLoaded(:final tracks) => tracks,
              _ => const <LocalFile>[],
            };
            final filtered = _filter(tracks);
            final trackCount = tracks.length;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: AppHeader(
                    leading: GestureDetector(
                      onTap: widget.onMenuPressed,
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF535353),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                    title: 'Your Library',
                    trailing: [
                      GestureDetector(
                        onTap: widget.onToggleMode,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Transform.flip(
                            flipX: true,
                            child: Image.asset(
                              'assets/images/app_icon.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search local library',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                        filled: true,
                        fillColor: const Color(0xFF282828),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Text(
                      '$trackCount tracks on device',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (state is LocalMusicLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF1DB954)),
                    ),
                  )
                else if (state is LocalMusicError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No local music found on your device.'
                            : 'No results for "$_searchQuery"',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.builder(
                      itemCount: filtered.length + 1,
                      itemBuilder: (context, index) {
                        if (index == filtered.length) {
                          return const ShellBottomSpacer(
                            key: ValueKey<String>('offline_library_bottom_spacer'),
                          );
                        }
                        final file = filtered[index];
                        return _TrackTile(
                          key: ValueKey<String>(file.path),
                          file: file,
                          onTap: () => _playTrack(filtered, index),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _playTrack(List<LocalFile> tracks, int index) {
    if (index < 0 || index >= tracks.length) return;
    if (!getIt.isRegistered<PlayerQueueMobiusController>()) return;

    final contextTracks = <ContextTrack>[
      for (var i = 0; i < tracks.length; i++)
        LocalFileUri.toContextTrack(tracks[i], uidIndex: i),
    ];
    final activeTrack = contextTracks[index];

    final contextPage = ContextPage.builder().tracks(contextTracks).build();
    final playContext = Context.builder('spotify:internal:local-files')
        .pages([contextPage])
        .metadata({
          'context_description': 'Local Files',
        })
        .build();

    final options = PreparePlayOptions.builder()
        .skipTo(
          SkipToTrack.builder()
              .trackUid(activeTrack.uid)
              .trackUri(activeTrack.uri)
              .build(),
        )
        .build();

    getIt<PlayerQueueMobiusController>().playContext(
      playContext,
      options: options,
    );
  }
}

class _TrackTile extends StatelessWidget {
  final LocalFile file;
  final VoidCallback onTap;

  const _TrackTile({
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

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            PlayerArtworkImage(
              imageUrl: imageUri,
              artworkWidth: 50,
              artworkHeight: 50,
              placeholderIconSize: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
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
