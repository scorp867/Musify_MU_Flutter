import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';
import 'package:musify_mu/core/ui/widgets/app_header.dart';
import 'package:musify_mu/core/ui/widgets/shell_bottom_spacer.dart';
import 'package:musify_mu/features/local_music/domain/entities/domain_track.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_bloc.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_state.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_bloc.dart';
import 'package:musify_mu/features/player/domain/commands/options/prepare_play_options.dart';
import 'package:musify_mu/features/player/domain/commands/options/skip_to_track.dart';
import 'package:musify_mu/features/player/domain/models/context.dart';
import 'package:musify_mu/features/player/domain/models/context_page.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Offline browse view -- search and explore local music files by artist/album.
/// Displayed when the app is in offline mode on the Browse tab.
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
            final allTracks =
                state is LocalMusicLoaded ? state.tracks : <DomainTrack>[];

            return CustomScrollView(
              slivers: [
                // Header
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

                // Search field
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

                // Content: Browse grid or search results
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

  Widget _buildBrowseGrid(List<DomainTrack> tracks) {
    // Group by artist
    final artistMap = <String, List<DomainTrack>>{};
    for (final t in tracks) {
      final a = t.artist.isNotEmpty ? t.artist : 'Unknown Artist';
      artistMap.putIfAbsent(a, () => []).add(t);
    }

    // Group by album
    final albumMap = <String, List<DomainTrack>>{};
    for (final t in tracks) {
      if (t.album != null && t.album!.isNotEmpty) {
        albumMap.putIfAbsent(t.album!, () => []).add(t);
      }
    }

    final topArtists = artistMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final topAlbums = albumMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return SliverList(
      delegate: SliverChildListDelegate([
        // Artists section
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

        // Albums section
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
                return GestureDetector(
                  onTap: () => _playTrack(entry.value, 0),
                  child: _AlbumCard(
                    name: entry.key,
                    artist: entry.value.first.artist,
                    sampleTrack: entry.value.first,
                  ),
                );
              },
            ),
          ),
        ],

        // Quick play all section
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
          itemCount: tracks.length.clamp(0, 10),
          itemBuilder: (context, index) {
            final track = tracks[index];
            return _buildTrackRow(track, () => _playTrack(tracks, index));
          },
        ),

        const ShellBottomSpacer(),
      ]),
    );
  }

  Widget _buildSearchResults(List<DomainTrack> tracks) {
    final q = _searchQuery.toLowerCase();
    final results = tracks
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q) ||
            (t.album?.toLowerCase().contains(q) ?? false))
        .toList();

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
            return const ShellBottomSpacer();
          }
          final track = results[index];
          return _buildTrackRow(track, () => _playTrack(results, index));
        },
      ),
    );
  }

  Widget _buildTrackRow(DomainTrack track, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: QueryArtworkWidget(
                id: track.songId ?? int.tryParse(track.id) ?? 0,
                type: ArtworkType.AUDIO,
                artworkHeight: 48,
                artworkWidth: 48,
                keepOldArtwork: true,
                nullArtworkWidget: Container(
                  width: 48,
                  height: 48,
                  color: const Color(0xFF1E293B),
                  child: const Icon(Icons.music_note,
                      color: Color(0xFF1DB954), size: 24),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
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
                    '${track.artist}${track.album != null ? " \u2022 ${track.album}" : ""}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (track.duration != null)
              Text(
                DurationFormatter.milliseconds(track.duration!),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  void _playTrack(List<DomainTrack> tracks, int index) {
    if (index >= 0 && index < tracks.length) {
      final contextTracks = tracks.map((t) {
        final uri = t.isLocal
            ? (t.dataPath != null && t.dataPath!.isNotEmpty
                ? 'spotify:local:${Uri.encodeComponent(t.dataPath!)}'
                : 'spotify:local:${t.id}')
            : 'spotify:track:${t.id}';
        return ContextTrack.builder(uri)
            .uid(t.id)
            .metadata({
              ContextTrackMetadata.keyTitle: t.title,
              ContextTrackMetadata.keyArtistName:
                  t.artist.isNotEmpty ? t.artist : 'Local Artist',
              if (t.album != null) ContextTrackMetadata.keyAlbumTitle: t.album!,
              if (t.duration != null)
                ContextTrackMetadata.keyDuration: t.duration.toString(),
              if (t.dataPath != null)
                ContextTrackMetadata.keyLocalFilePath: t.dataPath!,
              if (t.songId != null)
                ContextTrackMetadata.keySongId: t.songId.toString(),
              if (t.artUri != null) ContextTrackMetadata.keyImageUrl: t.artUri!,
              ContextTrackMetadata.keyIsQueued: 'false',
            })
            .build();
      }).toList(growable: false);

      final activeTrack = contextTracks[index];

      final contextPage = ContextPage.builder()
          .tracks(contextTracks)
          .build();

      final playContext = Context.builder('spotify:internal:local-files')
          .pages([contextPage])
          .metadata({
            'context_description': 'Local Files',
          })
          .build();

      final options = PreparePlayOptions.builder()
          .skipTo(SkipToTrack.builder()
              .trackUid(activeTrack.uid)
              .trackUri(activeTrack.uri)
              .build())
          .build();

      final bloc =
          getIt.isRegistered<PlayerQueueBloc>() ? getIt<PlayerQueueBloc>() : null;
      if (bloc != null) {
        bloc.add(PlayContext(
          context: playContext,
          options: options,
        ));
      }
    }
  }
}

// ---- Cards for the browse grid ----

class _ArtistCard extends StatelessWidget {
  final String name;
  final int trackCount;
  final DomainTrack sampleTrack;

  const _ArtistCard({
    required this.name,
    required this.trackCount,
    required this.sampleTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: QueryArtworkWidget(
              id: sampleTrack.songId ?? int.tryParse(sampleTrack.id) ?? 0,
              type: ArtworkType.AUDIO,
              artworkHeight: 100,
              artworkWidth: 100,
              keepOldArtwork: true,
              nullArtworkWidget: Container(
                width: 100,
                height: 100,
                color: const Color(0xFF282828),
                child: const Icon(Icons.person, color: Colors.white54, size: 40),
              ),
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
  final DomainTrack sampleTrack;

  const _AlbumCard({
    required this.name,
    required this.artist,
    required this.sampleTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: QueryArtworkWidget(
              id: sampleTrack.songId ?? int.tryParse(sampleTrack.id) ?? 0,
              type: ArtworkType.AUDIO,
              artworkHeight: 150,
              artworkWidth: 150,
              keepOldArtwork: true,
              nullArtworkWidget: Container(
                width: 150,
                height: 150,
                color: const Color(0xFF282828),
                child: const Icon(Icons.album, color: Colors.white54, size: 48),
              ),
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
