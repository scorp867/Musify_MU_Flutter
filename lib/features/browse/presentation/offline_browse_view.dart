import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';
import 'package:musify_mu/core/ui/widgets/app_header.dart';
import 'package:musify_mu/core/ui/widgets/shell_bottom_spacer.dart';
import 'package:musify_mu/features/local_music/domain/entities/domain_track.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_bloc.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_state.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Offline browse view -- search and explore local music files by artist/album.
/// Displayed when the app is in offline mode on the Browse tab.
class OfflineBrowseView extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onToggleMode;
  final PlaybackController? playbackController;

  const OfflineBrowseView({
    super.key,
    this.onMenuPressed,
    this.onToggleMode,
    this.playbackController,
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

                // Search bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search local files',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close, color: Colors.grey.shade400),
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),

                // Content
                if (state is LocalMusicLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF1DB954)),
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

  /// When no search query, show browse-by-artist and browse-by-album grids.
  Widget _buildBrowseGrid(List<DomainTrack> tracks) {
    // Group by artist
    final artistMap = <String, List<DomainTrack>>{};
    for (final t in tracks) {
      artistMap.putIfAbsent(t.artist, () => []).add(t);
    }
    final artists = artistMap.keys.toList()..sort();

    // Group by album
    final albumMap = <String, List<DomainTrack>>{};
    for (final t in tracks) {
      final album = t.album ?? 'Unknown Album';
      albumMap.putIfAbsent(album, () => []).add(t);
    }
    final albums = albumMap.keys.toList()..sort();

    return SliverList(
      delegate: SliverChildListDelegate([
        // Artists section
        if (artists.isNotEmpty) ...[
          _sectionHeader('Artists', '${artists.length}'),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: artists.length,
              itemBuilder: (context, index) {
                final artist = artists[index];
                final count = artistMap[artist]!.length;
                final firstTrack = artistMap[artist]!.first;
                return _ArtistCard(
                  name: artist,
                  trackCount: count,
                  sampleTrack: firstTrack,
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Albums section
        if (albums.isNotEmpty) ...[
          _sectionHeader('Albums', '${albums.length}'),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                final albumTracks = albumMap[album]!;
                final artist = albumTracks.first.artist;
                final firstTrack = albumTracks.first;
                return _AlbumCard(
                  name: album,
                  artist: artist,
                  sampleTrack: firstTrack,
                );
              },
            ),
          ),
        ],

        const ShellBottomSpacer(),
      ]),
    );
  }

  Widget _sectionHeader(String title, String count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            count,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// When searching, show filtered track results.
  Widget _buildSearchResults(List<DomainTrack> tracks) {
    final q = _searchQuery.toLowerCase();
    final filtered = tracks
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q) ||
            (t.album?.toLowerCase().contains(q) ?? false))
        .toList();

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, color: Colors.grey.shade600, size: 48),
              const SizedBox(height: 12),
              Text(
                'No results for "$_searchQuery"',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: filtered.length + 1,
        itemBuilder: (context, index) {
          if (index == filtered.length) return const ShellBottomSpacer();
          final track = filtered[index];
          return GestureDetector(
            onTap: () => _playTrack(filtered, index),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  QueryArtworkWidget(
                    id: track.songId ?? int.tryParse(track.id) ?? 0,
                    type: ArtworkType.AUDIO,
                    artworkHeight: 48,
                    artworkWidth: 48,
                    artworkBorder: BorderRadius.zero,
                    artworkClipBehavior: Clip.none,
                    artworkQuality: FilterQuality.low,
                    quality: 50,
                    keepOldArtwork: true,
                    nullArtworkWidget: Container(
                      width: 48,
                      height: 48,
                      color: const Color(0xFF1E293B),
                      child: const Icon(Icons.music_note, color: Color(0xFF1DB954)),
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
        },
      ),
    );
  }

  void _playTrack(List<DomainTrack> tracks, int index) {
    final playback = widget.playbackController;
    if (playback == null) return;
    final mediaItems = tracks
        .map((t) => MediaItemMapper.fromTrack(
              id: t.id,
              title: t.title,
              artist: t.artist,
              album: t.album,
              durationMilliseconds: t.duration,
              songId: t.songId,
              dataPath: t.dataPath,
              dateModified: t.dateModified,
            ))
        .toList(growable: false);
    playback.playQueue(mediaItems, index);
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
