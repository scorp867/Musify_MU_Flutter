import 'package:musify_mu/core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/home_feed/data/elements/image_link_card_data_element.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Recents carousel matching Spotify's 1:1 layout:
///   - 112dp card width, 97dp artwork size, 175dp carousel height
///   - Stacked artwork for multiple tracks (Layer 2 -> Layer 1 -> Layer 0)
///   - Anchored bottom-left badge (0.373 * 97 = 36dp):
///       * Liked Songs: #431337 badge with white heart
///       * Playlists: 2x2 miniature grid badge
///   - Inline green circle checkmark (#1DB954, Icons.check) before action subtitle
class RecentsCarouselSection extends StatefulWidget {
  final String title;
  final List<SpotifyEntity> items;

  const RecentsCarouselSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<RecentsCarouselSection> createState() => _RecentsCarouselSectionState();
}

class _RecentsCarouselSectionState extends State<RecentsCarouselSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSectionTraits();
  }

  @override
  void didUpdateWidget(covariant RecentsCarouselSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _loadSectionTraits();
    }
  }

  DataPool? _resolvePool() {
    try {
      return context.read<DataPool>();
    } catch (_) {
      return null;
    }
  }

  void _loadSectionTraits() {
    if (widget.items.isEmpty) return;
    final pool = _resolvePool();
    final allUris = <String>{};

    for (final item in widget.items) {
      allUris.add(item.uri);
      final meta = item.getTrait<RecentsMetadataTrait>();
      if (meta != null && meta.entityUris.isNotEmpty) {
        allUris.addAll(meta.entityUris.take(3));
      }
    }

    pool?.loadBatch(
      uris: allUris.toList(),
      statement: ImageLinkCardDataElement.statement,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final pool = _resolvePool();
    if (pool == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with "Show all"
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title.isNotEmpty ? widget.title : 'Recents',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Show all',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
        // Compact horizontal cards (112dp width, 175dp height)
        SizedBox(
          height: 175,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final rawItem = widget.items[index];
              return StreamBuilder<Map<String, Trait>>(
                stream: pool.watchEntity(rawItem.uri),
                initialData: pool.getTraits(rawItem.uri),
                builder: (context, snapshot) {
                  final currentTraits = <String, Trait>{
                    ...rawItem.traits,
                    ...?snapshot.data,
                  };
                  final entity = SpotifyEntity(
                    uri: rawItem.uri,
                    type: rawItem.type,
                    traits: currentTraits,
                  );
                  return _RecentsCard(item: entity, pool: pool);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentsCard extends StatelessWidget {
  final SpotifyEntity item;
  final DataPool pool;

  const _RecentsCard({required this.item, required this.pool});

  @override
  Widget build(BuildContext context) {
    final title = item.cardTitle;
    final recentsMeta = item.getTrait<RecentsMetadataTrait>();
    final isArtist = item.type == ContentType.artist;
    final isEpisode = item.type == ContentType.episode;
    final isLikedSongs = item.uri == 'spotify:collection:tracks' ||
        item.uri.endsWith(':collection') ||
        title.toLowerCase() == 'liked songs';

    return SizedBox(
      width: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artwork area: 112 wide x 103 high to contain 97dp artwork + stack offset
          SizedBox(
            width: 112,
            height: 103,
            child: isArtist
                ? _buildArtistAvatar()
                : _buildStackedArtworkWithBadge(isLikedSongs, isEpisode, recentsMeta),
          ),
          const SizedBox(height: 6),
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          // Subtitle with inline green checkmark
          _buildSubtitleRow(recentsMeta),
        ],
      ),
    );
  }

  Widget _buildArtistAvatar() {
    final imageUrl = item.cardImageUrl;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: 97,
        height: 97,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF282828),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? AppNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 200,
                memCacheHeight: 200,
                errorWidget: (_, _, _) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _buildStackedArtworkWithBadge(
    bool isLikedSongs,
    bool isEpisode,
    RecentsMetadataTrait? recentsMeta,
  ) {
    // Collect track covers for stacked artwork if available
    final trackCovers = <String>[];
    if (recentsMeta != null && recentsMeta.entityUris.isNotEmpty) {
      for (final trackUri in recentsMeta.entityUris.take(3)) {
        final traits = pool.getTraits(trackUri);
        final simple = traits?['SimpleCardTrait'] as SimpleCardTrait?;
        final visual = traits?['VisualIdentityTrait'] as VisualIdentityTrait?;
        final img = simple?.imageUrl ?? visual?.squareCoverUrl;
        if (img != null && img.isNotEmpty) {
          trackCovers.add(img);
        }
      }
    }

    // Determine front cover:
    // If Liked Songs and we have a recently added track cover, use that; otherwise fallback
    final frontCoverUrl = (isLikedSongs && trackCovers.isNotEmpty)
        ? trackCovers.first
        : (item.cardImageUrl ?? (trackCovers.isNotEmpty ? trackCovers.first : null));

    final hasMultipleTracks = trackCovers.length > 1;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Stacked layers (Layer 2 -> Layer 1 -> Layer 0)
        if (hasMultipleTracks) ...[
          // Layer 2 (backmost)
          if (trackCovers.length >= 3)
            Positioned(
              top: 0,
              right: 2,
              child: Transform.scale(
                scale: 0.88,
                alignment: Alignment.topRight,
                child: _artworkTile(trackCovers[2], 97, 97),
              ),
            ),
          // Layer 1 (middle)
          Positioned(
            top: 3,
            right: 4,
            child: Transform.scale(
              scale: 0.94,
              alignment: Alignment.topRight,
              child: _artworkTile(trackCovers[1], 97, 97),
            ),
          ),
        ],

        // Layer 0 (front artwork)
        Positioned(
          top: 6,
          left: 0,
          child: _artworkTile(frontCoverUrl, 97, 97, isEpisode: isEpisode),
        ),

        // Anchored bottom-left corner badge (0.373 * 97 = 36dp)
        if (isLikedSongs)
          Positioned(
            left: 0,
            bottom: 0,
            child: _buildLikedSongsBadge(),
          )
        else if (recentsMeta != null && recentsMeta.songsCount > 1)
          Positioned(
            left: 0,
            bottom: 0,
            child: _buildPlaylistMiniBadge(trackCovers),
          ),
      ],
    );
  }

  Widget _artworkTile(
    String? imageUrl,
    double width,
    double height, {
    bool isEpisode = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            AppNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              memCacheWidth: 200,
              memCacheHeight: 200,
              errorWidget: (_, _, _) => _placeholder(),
            )
          else
            _placeholder(),
          // Episode progress bar
          if (isEpisode)
            Positioned(
              left: 4,
              right: 4,
              bottom: 3,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(1.5),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.35,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DB954),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 1:1 Liked Songs badge: #431337 dark plum/magenta with white heart
  Widget _buildLikedSongsBadge() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF431337),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF121212), width: 2),
      ),
      child: const Center(
        child: Icon(
          Icons.favorite,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  /// 1:1 Playlist miniature badge (2x2 grid or playlist placeholder)
  Widget _buildPlaylistMiniBadge(List<String> trackCovers) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF121212), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: item.cardImageUrl != null && item.cardImageUrl!.isNotEmpty
          ? AppNetworkImage(
              imageUrl: item.cardImageUrl!,
              fit: BoxFit.cover,
              memCacheWidth: 100,
              memCacheHeight: 100,
              errorWidget: (_, _, _) => const Icon(
                Icons.queue_music,
                color: Colors.white70,
                size: 18,
              ),
            )
          : const Icon(
              Icons.queue_music,
              color: Colors.white70,
              size: 18,
            ),
    );
  }

  Widget _buildSubtitleRow(RecentsMetadataTrait? meta) {
    final showCheckmark = meta != null &&
        (meta.recentType == 'saved' || meta.songsCount > 0);

    String subtitleText;
    if (meta != null && meta.songsCount > 0) {
      subtitleText = '${meta.songsCount} ${meta.songsCount == 1 ? 'song' : 'songs'} added';
    } else if (meta != null && meta.recentType.isNotEmpty) {
      subtitleText = switch (meta.recentType) {
        'played' => 'Played',
        'shared' => 'Shared',
        'autoGenerated' => 'Made for you',
        _ => meta.recentType,
      };
    } else {
      subtitleText = switch (item.type) {
        ContentType.album => 'Album',
        ContentType.playlist => 'Playlist',
        ContentType.artist => 'Artist',
        ContentType.podcast => 'Podcast',
        ContentType.episode => 'Episode',
        _ => '',
      };
    }

    if (subtitleText.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCheckmark) ...[
          Container(
            width: 13,
            height: 13,
            decoration: const BoxDecoration(
              color: Color(0xFF1DB954),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 9.5,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            subtitleText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(Icons.music_note, color: Colors.grey.shade700, size: 24),
    );
  }
}
