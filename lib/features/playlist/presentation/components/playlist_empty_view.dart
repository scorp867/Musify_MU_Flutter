library;

import 'package:flutter/material.dart';

/// 1:1 replica of Spotify's empty playlist state (`empty_view_playlist_all_songs.xml`).
class PlaylistEmptyView extends StatelessWidget {
  final VoidCallback onAddSongsTapped;

  const PlaylistEmptyView({
    super.key,
    required this.onAddSongsTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.queue_music,
              size: 56,
              color: Color(0xFF535353),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your playlist is empty',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Find and add songs to build your personal soundtrack.',
              style: TextStyle(
                color: Color(0xFFB3B3B3),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAddSongsTapped,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Add to this playlist',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
