library;

import 'package:flutter/material.dart';
import '../../../../core/ui/icons/spotify_encore_icons.dart';

/// 1:1 replica of Spotify's Playlist Action Bar (`nk20.java` & `PlayButtonView.java`, `play_button_view.xml`).
///
/// Features:
/// 1. Download circle arrow button with state transition
/// 2. Permission-aware action: Share button for owners (`canEdit`), Follow/Heart for viewers
/// 3. Shuffle toggle with green active indicator dot
/// 4. 56x56 slot placeholder aligning with the floating PlayButtonBehavior FAB
class PlaylistActionRow extends StatelessWidget {
  final bool isOwner;
  final bool isFollowed;
  final bool isDownloaded;
  final bool isShuffleEnabled;
  final bool isPlaying;
  final VoidCallback onFollowTapped;
  final VoidCallback onDownloadTapped;
  final VoidCallback onShareTapped;
  final VoidCallback onShuffleTapped;
  final VoidCallback? onPlayTapped;

  const PlaylistActionRow({
    super.key,
    required this.isOwner,
    required this.isFollowed,
    required this.isDownloaded,
    required this.isShuffleEnabled,
    required this.isPlaying,
    required this.onFollowTapped,
    required this.onDownloadTapped,
    required this.onShareTapped,
    required this.onShuffleTapped,
    this.onPlayTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        children: [
          // 1. Offline Download Button (Circle with Down Arrow)
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isDownloaded
                    ? SpotifyIcon.downloaded(
                        key: const ValueKey<bool>(true),
                        color: const Color(0xFF1DB954),
                        size: 24,
                      )
                    : SpotifyIcon.download(
                        key: const ValueKey<bool>(false),
                        color: const Color(0xFFB3B3B3),
                        size: 24,
                      ),
              ),
              onPressed: onDownloadTapped,
              tooltip: isDownloaded
                  ? 'Downloaded'
                  : 'Download for offline',
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 8),

          // 2. Permission-Aware Action: Share for Owner, Heart/Follow for Viewer
          if (isOwner)
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                icon: SpotifyIcon.share(
                  color: const Color(0xFFB3B3B3),
                  size: 24,
                ),
                onPressed: onShareTapped,
                tooltip: 'Share playlist',
                padding: EdgeInsets.zero,
              ),
            )
          else
            SizedBox(
              width: 40,
              height: 40,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 1.0,
                  end: isFollowed ? 1.2 : 1.0,
                ),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: child,
                        ),
                        child: isFollowed
                            ? SpotifyIcon.heartActive(
                                key: const ValueKey<bool>(true),
                                color: const Color(0xFF1DB954),
                                size: 24,
                              )
                            : SpotifyIcon.heart(
                                key: const ValueKey<bool>(false),
                                color: const Color(0xFFB3B3B3),
                                size: 24,
                              ),
                      ),
                      onPressed: onFollowTapped,
                      tooltip: isFollowed
                          ? 'Remove from library'
                          : 'Save to library',
                      padding: EdgeInsets.zero,
                    ),
                  );
                },
              ),
            ),

          const Spacer(),

          // 3. Shuffle Toggle with Active Dot (Encore Shuffle Toggle)
          InkWell(
            onTap: onShuffleTapped,
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: SpotifyIcon.shuffle(
                      key: ValueKey<bool>(isShuffleEnabled),
                      color: isShuffleEnabled
                          ? const Color(0xFF1DB954)
                          : const Color(0xFFB3B3B3),
                      size: 24,
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isShuffleEnabled ? 1.0 : 0.0,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1DB954),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 4. 56x56 Layout Placeholder aligning with floating PlayButtonBehavior FAB
          const SizedBox(
            width: 56,
            height: 56,
          ),
        ],
      ),
    );
  }
}
