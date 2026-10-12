import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/identity_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/on_platform_reputation_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/visual_identity_trait.dart';

import '../player_artwork.dart';

/// Spotify-identical "About the Artist" card (`ScrollCardType.CREATOR_BIO` / `bio_card_view.xml`).
///
/// Features:
/// - 16dp rounded corners (`widgets_corner_radius`)
/// - Dark card background (#242424 / `dark_base_background_elevated_base`)
/// - Top artist banner with subtle gradient scrim (`bio_card_gradient`)
/// - "ABOUT THE ARTIST" category badge
/// - Monthly listeners / verified artist indicator
/// - "Follow" outline button
/// - Artist biography preview snippet with expandable "See more" behavior
/// - Dual-mode: Binds reactively to [DataPool] when available (online),
///   or falls back to [MediaItem] metadata (offline).
class PlayerAboutArtistSection extends StatefulWidget {
  const PlayerAboutArtistSection({
    super.key,
    required this.item,
    this.dataPool,
    this.artistUri,
    this.onFollow,
  });

  final MediaItem item;
  final DataPool? dataPool;
  final String? artistUri;
  final VoidCallback? onFollow;

  @override
  State<PlayerAboutArtistSection> createState() =>
      _PlayerAboutArtistSectionState();
}

class _PlayerAboutArtistSectionState extends State<PlayerAboutArtistSection> {
  bool _isFollowing = false;
  bool _isBioExpanded = false;

  @override
  Widget build(BuildContext context) {
    final artistName = widget.item.artist?.isNotEmpty == true
        ? widget.item.artist!
        : 'Unknown Artist';

    final artistUri = widget.artistUri ??
        (widget.item.extras?['artistUri'] as String?);

    // If DataPool and an artist URI exist, watch for live Kodiak traits
    if (widget.dataPool != null && artistUri != null && artistUri.isNotEmpty) {
      return StreamBuilder<Map<String, dynamic>>(
        stream: widget.dataPool!.watchEntity(artistUri),
        initialData: widget.dataPool!.getTraits(artistUri),
        builder: (context, snapshot) {
          final identity = widget.dataPool!.getTrait<IdentityTrait>(artistUri);
          final visual = widget.dataPool!.getTrait<VisualIdentityTrait>(artistUri);
          final reputation =
              widget.dataPool!.getTrait<OnPlatformReputationTrait>(artistUri);
          final bannerUrl = visual?.wideFullBleedUrl ?? visual?.squareCoverUrl;

          return _buildCard(
            artistName: identity?.name.isNotEmpty == true
                ? identity!.name
                : artistName,
            monthlyListeners: reputation?.monthlyListeners,
            bio: identity?.description.isNotEmpty == true
                ? identity!.description
                : null,
            isVerified: reputation?.isVerified ?? false,
            bannerImageUrl: bannerUrl,
          );
        },
      );
    }

    // Offline: render with MediaItem metadata only (no trait data available)
    return _buildCard(
      artistName: artistName,
    );
  }

  Widget _buildCard({
    required String artistName,
    int? monthlyListeners,
    String? bio,
    bool isVerified = false,
    String? bannerImageUrl,
  }) {
    final listenersText = monthlyListeners != null && monthlyListeners > 0
        ? '${_formatListeners(monthlyListeners)} monthly listeners'
        : (isVerified ? 'Verified Artist' : 'Artist on Spotify');

    final defaultBio =
        'Listen to the latest releases, singles, and albums from $artistName.';
    final bioText = bio?.isNotEmpty == true ? bio! : defaultBio;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Artist Banner with gradient scrim & "About the artist" title overlay
          SizedBox(
            height: 190,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (bannerImageUrl != null && bannerImageUrl.isNotEmpty)
                  Image.network(
                    bannerImageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 190,
                    errorBuilder: (context, error, stackTrace) => PlayerArtworkImage(
                      item: widget.item,
                      artworkWidth: double.infinity,
                      artworkHeight: 190,
                    ),
                  )
                else
                  PlayerArtworkImage(
                    item: widget.item,
                    artworkWidth: double.infinity,
                    artworkHeight: 190,
                  ),
                // Subtle gradient overlay for top contrast
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.50),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.40),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
                const Positioned(
                  top: 16,
                  left: 16,
                  child: Text(
                    'About the artist',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(
                          color: Color(0x66000000),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 2. Artist Details Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Artist Name + Verified Badge + Follow Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              artistName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified,
                              color: Color(0xFF1DB954),
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        setState(() => _isFollowing = !_isFollowing);
                        widget.onFollow?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: _isFollowing
                              ? const Color(0xFF1DB954)
                              : Colors.white54,
                          width: 1.0,
                        ),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _isFollowing ? 'Following' : 'Follow',
                        style: TextStyle(
                          color: _isFollowing
                              ? const Color(0xFF1DB954)
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Monthly Listeners
                Text(
                  listenersText,
                  style: const TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 14),
                // Bio with inline "see more"
                GestureDetector(
                  onTap: () {
                    setState(() => _isBioExpanded = !_isBioExpanded);
                  },
                  child: _buildBioText(bioText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioText(String bio) {
    if (_isBioExpanded) {
      return Text(
        bio,
        style: const TextStyle(
          color: Color(0xFFB3B3B3),
          fontSize: 13,
          height: 1.45,
        ),
      );
    }

    final isLong = bio.length > 120;
    final preview = isLong ? '${bio.substring(0, 115).trim()}... ' : bio;

    return Text.rich(
      TextSpan(
        text: preview,
        style: const TextStyle(
          color: Color(0xFFB3B3B3),
          fontSize: 13,
          height: 1.45,
        ),
        children: [
          if (isLong)
            const TextSpan(
              text: 'see more',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  static String _formatListeners(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
