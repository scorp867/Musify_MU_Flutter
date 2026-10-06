import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/home_feed/data/elements/image_link_card_data_element.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Recents carousel — compact cards with title + action metadata.
/// Matches Spotify's "Recents" / "Jump back in" section.
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

  void _loadSectionTraits() {
    if (widget.items.isEmpty) return;
    final pool = getIt<DataPool>();
    final uris = widget.items.map((e) => e.uri).toList();
    pool.loadBatch(uris: uris, statement: ImageLinkCardDataElement.statement);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final pool = getIt<DataPool>();

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
                widget.title,
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
        // Compact horizontal cards
        SizedBox(
          height: 158,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return StreamBuilder<Map<String, Trait>>(
                stream: pool.watchEntity(item.uri),
                initialData: pool.getTraits(item.uri),
                builder: (context, snapshot) {
                  final currentTraits = snapshot.data ?? item.traits;
                  final entity = SpotifyEntity(
                    uri: item.uri,
                    type: item.type,
                    traits: currentTraits,
                  );
                  return _RecentsCard(item: entity);
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
  const _RecentsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item.cardTitle;
    final imageUrl = item.cardImageUrl;
    final recentsMeta = item.getTrait<RecentsMetadataTrait>();
    final subtitle = _buildSubtitle(item, recentsMeta);
    final isEpisode = item.type == ContentType.episode;

    return SizedBox(
      width: 85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artwork with optional episode progress bar
          Stack(
            children: [
              ClipRRect(
                borderRadius: item.type == ContentType.artist
                    ? BorderRadius.circular(42.5)
                    : BorderRadius.circular(6),
                child: Container(
                  width: 85,
                  height: 85,
                  color: const Color(0xFF282828),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
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
          const SizedBox(height: 6),
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Action subtitle
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9.5,
                  color: Colors.grey.shade500,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  String _buildSubtitle(SpotifyEntity item, RecentsMetadataTrait? meta) {
    if (meta == null) {
      return item.getTrait<SimpleCardTrait>()?.subtitle ?? '';
    }

    final parts = <String>[];

    // Item count
    if (meta.songsCount > 0) {
      parts.add('${meta.songsCount} songs');
    }

    // Action verb
    switch (meta.recentType) {
      case 'saved':
        parts.add('added');
      case 'shared':
        parts.add('shared');
      case 'autoGenerated':
        parts.add('made for you');
      case 'played':
      default:
        if (meta.songsCount > 0) {
          parts.add('played');
        }
    }

    if (parts.isNotEmpty) return parts.join(' ');

    // Fall back to content type
    return switch (item.type) {
      ContentType.album => 'Album',
      ContentType.playlist => 'Playlist',
      ContentType.artist => 'Artist',
      ContentType.podcast => 'Podcast',
      ContentType.episode => 'Episode',
      _ => '',
    };
  }

  Widget _placeholder() {
    return Center(
      child: Icon(Icons.music_note, color: Colors.grey.shade700, size: 20),
    );
  }
}
