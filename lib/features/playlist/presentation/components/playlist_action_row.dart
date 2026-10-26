library;

import 'package:flutter/material.dart';

/// 1:1 replica of Spotify's Playlist Action Bar (`nk20.java`).
/// Contains: Follow/Heart, Download, Collaborators, More options, Shuffle toggle (with active dot), and 56x56 Circular Play FAB.
class PlaylistActionRow extends StatelessWidget {
  final bool isFollowed;
  final bool isDownloaded;
  final bool isShuffleEnabled;
  final bool isPlaying;
  final VoidCallback onFollowTapped;
  final VoidCallback onDownloadTapped;
  final VoidCallback onAddCollaboratorTapped;
  final VoidCallback onMoreOptionsTapped;
  final VoidCallback onShuffleTapped;
  final VoidCallback onPlayTapped;

  const PlaylistActionRow({
    super.key,
    required this.isFollowed,
    required this.isDownloaded,
    required this.isShuffleEnabled,
    required this.isPlaying,
    required this.onFollowTapped,
    required this.onDownloadTapped,
    required this.onAddCollaboratorTapped,
    required this.onMoreOptionsTapped,
    required this.onShuffleTapped,
    required this.onPlayTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        children: [
          // 1. Follow / Heart Button
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              icon: Icon(
                isFollowed ? Icons.favorite : Icons.favorite_border,
                color: isFollowed ? const Color(0xFF1DB954) : const Color(0xFFB3B3B3),
                size: 26,
              ),
              onPressed: onFollowTapped,
              tooltip: isFollowed ? 'Remove from library' : 'Save to library',
              padding: EdgeInsets.zero,
            ),
          ),

          // 2. Offline Download Button (Circle with Down Arrow)
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              icon: Icon(
                isDownloaded
                    ? Icons.arrow_circle_down
                    : Icons.arrow_circle_down_outlined,
                color: isDownloaded ? const Color(0xFF1DB954) : const Color(0xFFB3B3B3),
                size: 26,
              ),
              onPressed: onDownloadTapped,
              tooltip: isDownloaded ? 'Downloaded' : 'Download for offline',
              padding: EdgeInsets.zero,
            ),
          ),

          // 3. Add Collaborator Button
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              icon: const Icon(
                Icons.person_add_alt_1_outlined,
                color: Color(0xFFB3B3B3),
                size: 24,
              ),
              onPressed: onAddCollaboratorTapped,
              tooltip: 'Invite collaborators',
              padding: EdgeInsets.zero,
            ),
          ),

          // 4. Context More Options (3-dots)
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              icon: const Icon(
                Icons.more_vert,
                color: Color(0xFFB3B3B3),
                size: 24,
              ),
              onPressed: onMoreOptionsTapped,
              tooltip: 'Playlist options',
              padding: EdgeInsets.zero,
            ),
          ),

          const Spacer(),

          // 5. Shuffle Toggle with Active Dot (Encore Shuffle Toggle)
          InkWell(
            onTap: onShuffleTapped,
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.shuffle,
                    color: isShuffleEnabled
                        ? const Color(0xFF1DB954)
                        : const Color(0xFFB3B3B3),
                    size: 26,
                  ),
                  if (isShuffleEnabled)
                    Positioned(
                      bottom: 4,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1DB954),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 6. Spotify Big Green Play FAB (56x56dp circular, NOT pill-shaped)
          Material(
            color: const Color(0xFF1DB954),
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPlayTapped,
              child: SizedBox(
                width: 56,
                height: 56,
                child: Center(
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
