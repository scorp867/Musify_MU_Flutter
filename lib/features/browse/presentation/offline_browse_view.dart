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

/// Offline browse view for searching and exploring local music files by artist/album.
class OfflineBrowseView extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onToggleMode;

  const OfflineBrowseView({
    super.key,
    this.onMenuPressed,
    this.onToggleMode,
  });

  @override
  State<OfflineBrowseView> createState() => _OfflineBrowseViewState();
}

class _OfflineBrowseViewState extends State<OfflineBrowseView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<LocalMusicBloc, LocalMusicState>(
          builder: (context, state) {
            final allTracks = switch (state) {
              LocalMusicLoaded(:final tracks) => tracks,
              _ => const <LocalFile>[],
            };

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
                    title: 'Search',
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
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'What do you want to play?',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon:
                            Icon(Icons.search, color: Colors.grey.shade500),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFF282828),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                if (state is LocalMusicLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF1DB954)),
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
                else if (allTracks.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'No local music found on your device.',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ),
                  )
                else if (_searchQuery.isEmpty)
                  _buildBrowseGrid(allTracks)
                else
                  _buildSearchResults(allTracks),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBrowseGrid(List<LocalFile> tracks) {
    final artistMap = <String, List<LocalFile>>{};
    final albumMap = <String, List<LocalFile>>{};
    for (final file in tracks) {
      final meta = switch (file.metadata) {
        final m? => m,
        null => const LocalFileMetadata(),
      };
      if (meta.artist.isNotEmpty) {
        artistMap.putIfAbsent(meta.artist, () => []).add(file);
      }
      if (meta.album.isNotEmpty) {
        albumMap.putIfAbsent(meta.album, () => []).add(file);
      }
    }

    final topArtists = artistMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final topAlbums = albumMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final displayCount = tracks.length > 10 ? 10 : tracks.length;

    return SliverList(
      delegate: SliverChildListDelegate([
        if (topArtists.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'Artists',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: topArtists.length,
              itemBuilder: (context, index) {
                final entry = topArtists[index];
                return GestureDetector(
                  key: ValueKey<String>('artist_${entry.key}'),
                  onTap: () => _playTrack(entry.value, 0),
                  child: _ArtistCard(
                    name: entry.key,
                    trackCount: entry.value.length,
                    sampleTrack: entry.value.first,
                  ),
                );
              },
            ),
          ),
        ],
        if (topAlbums.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              'Albums',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: topAlbums.length,
              itemBuilder: (context, index) {
                final entry = topAlbums[index];
                final firstMeta = switch (entry.value.first.metadata) {
                  final m? => m,
                  null => const LocalFileMetadata(),
                };
                return GestureDetector(
                  key: ValueKey<String>('album_${entry.key}'),
                  onTap: () => _playTrack(entry.value, 0),
                  child: _AlbumCard(
                    name: entry.key,
                    artist: firstMeta.artist,
                    sampleTrack: entry.value.first,
                  ),
                );
              },
            ),
          ),
        ],
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            'All Songs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: displayCount,
          itemBuilder: (context, index) {
            final file = tracks[index];
            return KeyedSubtree(
              key: ValueKey<String>(file.path),
              child: _buildTrackRow(file, () => _playTrack(tracks, index)),
            );
          },
        ),
        const ShellBottomSpacer(),
      ]),
    );
  }

  Widget _buildSearchResults(List<LocalFile> tracks) {
    final q = _searchQuery.toLowerCase();
    final results = tracks.where((file) {
      final meta = switch (file.metadata) {
        final m? => m,
        null => const LocalFileMetadata(),
      };
      return meta.title.toLowerCase().contains(q) ||
          meta.artist.toLowerCase().contains(q) ||
          meta.album.toLowerCase().contains(q);
    }).toList();

    if (results.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'No results found for "$_searchQuery"',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: results.length + 1,
        itemBuilder: (context, index) {
          if (index == results.length) {
            return const ShellBottomSpacer(
              key: ValueKey<String>('offline_browse_bottom_spacer'),
            );
          }
          final file = results[index];
          return KeyedSubtree(
            key: ValueKey<String>(file.path),
            child: _buildTrackRow(file, () => _playTrack(results, index)),
          );
        },
      ),
    );
  }

  Widget _buildTrackRow(LocalFile file, VoidCallback onTap) {
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
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: PlayerArtworkImage(
                imageUrl: imageUri,
                artworkWidth: 48,
                artworkHeight: 48,
                placeholderIconSize: 22,
              ),
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
                    meta.album.isNotEmpty
                        ? '${meta.artist} \u2022 ${meta.album}'
                        : meta.artist,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (meta.duration > 0)
              Text(
                DurationFormatter.milliseconds(meta.duration * 1000),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
          ],
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

class _ArtistCard extends StatelessWidget {
  final String name;
  final int trackCount;
  final LocalFile sampleTrack;

  const _ArtistCard({
    required this.name,
    required this.trackCount,
    required this.sampleTrack,
  });

  @override
  Widget build(BuildContext context) {
    final trackUri = LocalFileUri.fromLocalFile(sampleTrack);
    final imageUri = LocalFileUri.toLocalFileImageUri(trackUri);

    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: PlayerArtworkImage(
              imageUrl: imageUri,
              artworkWidth: 100,
              artworkHeight: 100,
              placeholderIconSize: 40,
              placeholderIcon: Icons.person,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            '$trackCount tracks',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final String name;
  final String artist;
  final LocalFile sampleTrack;

  const _AlbumCard({
    required this.name,
    required this.artist,
    required this.sampleTrack,
  });

  @override
  Widget build(BuildContext context) {
    final trackUri = LocalFileUri.fromLocalFile(sampleTrack);
    final imageUri = LocalFileUri.toLocalFileImageUri(trackUri);

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: PlayerArtworkImage(
              imageUrl: imageUri,
              artworkWidth: 150,
              artworkHeight: 150,
              placeholderIconSize: 48,
              placeholderIcon: Icons.album,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            artist,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
