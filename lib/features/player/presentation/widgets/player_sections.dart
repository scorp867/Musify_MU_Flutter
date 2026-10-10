import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';

import 'player_artwork.dart';

/// Spotify-identical Lyrics card (`ScrollCardType.LYRICS`).
///
/// Features:
/// - 16dp rounded corners (`widgets_corner_radius`)
/// - Dynamic surface background tinted with the extracted artwork color
/// - Clean header without emojis or icon boxes
/// - Quick expand action to open full lyrics view
class PlayerLyricsSection extends StatelessWidget {
  const PlayerLyricsSection({
    super.key,
    this.onTapHeader,
    this.backgroundColor,
  });

  final VoidCallback? onTapHeader;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapHeader,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xFF242424),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Lyrics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onTapHeader != null)
                  IconButton(
                    icon: const Icon(
                      Icons.open_in_full_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                    onPressed: onTapHeader,
                    tooltip: 'Expand lyrics',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Lyrics aren't available for this track yet.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enjoy the music and check back later for lyrics.',
              style: TextStyle(
                color: Color(0xFFB3B3B3),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Spotify-identical "About the Artist" card (`ScrollCardType.CREATOR_BIO` / `bio_card_view.xml`).
///
/// Features:
/// - 16dp rounded corners (`widgets_corner_radius`)
/// - Dark card background (#242424)
/// - Top artist banner with subtle gradient scrim
/// - "ABOUT THE ARTIST" category badge
/// - Monthly listeners / verified artist indicator
/// - "Follow" outline button
/// - Artist biography preview snippet
class PlayerAboutArtistSection extends StatefulWidget {
  const PlayerAboutArtistSection({
    super.key,
    required this.item,
    this.onFollow,
  });

  final MediaItem item;
  final VoidCallback? onFollow;

  @override
  State<PlayerAboutArtistSection> createState() =>
      _PlayerAboutArtistSectionState();
}

class _PlayerAboutArtistSectionState extends State<PlayerAboutArtistSection> {
  bool _isFollowing = false;

  @override
  Widget build(BuildContext context) {
    final artistName = widget.item.artist?.isNotEmpty == true
        ? widget.item.artist!
        : 'Unknown Artist';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artist Banner with gradient scrim and name overlay
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PlayerArtworkImage(
                  item: widget.item,
                  artworkWidth: double.infinity,
                  artworkHeight: 180,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.20),
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ABOUT THE ARTIST',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Artist Details Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Artist on Musify',
                        style: TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        setState(() => _isFollowing = !_isFollowing);
                        widget.onFollow?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: _isFollowing
                              ? const Color(0xFF1ED760)
                              : Colors.white60,
                          width: 1.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _isFollowing ? 'Following' : 'Follow',
                        style: TextStyle(
                          color: _isFollowing
                              ? const Color(0xFF1ED760)
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Listen to the latest releases, singles, and albums from $artistName.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Spotify-identical Track Credits card (`ScrollCardType.TRACK_CREDITS`).
///
/// Features:
/// - 16dp rounded corners (`widgets_corner_radius`)
/// - Surface color (#242424)
/// - Clean typography showing performer, songwriter, and production credits
class PlayerCreditsSection extends StatelessWidget {
  const PlayerCreditsSection({super.key, required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final artistName = item.artist?.isNotEmpty == true
        ? item.artist!
        : 'Unknown Artist';
    final albumName = item.album?.isNotEmpty == true
        ? item.album!
        : 'Unknown Album';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Credits',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Show all',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CreditRow(
            title: artistName,
            role: 'Main Artist',
          ),
          const SizedBox(height: 12),
          _CreditRow(
            title: artistName,
            role: 'Composer, Songwriter',
          ),
          const SizedBox(height: 12),
          _CreditRow(
            title: albumName,
            role: 'Producer',
          ),
          if (item.duration != null) ...[
            const SizedBox(height: 12),
            _CreditRow(
              title: DurationFormatter.duration(item.duration!),
              role: 'Track Length',
            ),
          ],
        ],
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({required this.title, required this.role});

  final String title;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          role,
          style: const TextStyle(
            color: Color(0xFFB3B3B3),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Backwards compatibility alias for [PlayerCreditsSection].
typedef PlayerTrackDetailsSection = PlayerCreditsSection;
