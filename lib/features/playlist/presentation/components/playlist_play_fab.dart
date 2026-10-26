library;

import 'package:flutter/material.dart';

/// 1:1 replica of Spotify's Play Button View
/// (`PlayButtonView.java`, `play_button_view.xml`, `PlayButtonBehavior.java`, `ComposePlayButtonBehavior.java`).
///
/// Features:
/// 1. 56x56 circular FAB (`button_play_and_pause`) with Spotify green background (`#1DB954`)
/// 2. 30dp black Play / Pause icon with scale and fade crossfade transition
/// 3. 20dp Shuffle Badge (`button_badge`) anchored to bottom-right corner, visible only when
///    shuffle is enabled and playback is paused (`PlayButtonView.java` line 305)
/// 4. Tap compression animation (scales down to 0.92 on press, `Curves.easeOutCubic`)
/// 5. Elevation 4.0 matching Spotify Encore FAB specifications
class PlaylistPlayFab extends StatefulWidget {
  final bool isPlaying;
  final bool isShuffleEnabled;
  final VoidCallback onPlayTapped;

  const PlaylistPlayFab({
    super.key,
    required this.isPlaying,
    required this.isShuffleEnabled,
    required this.onPlayTapped,
  });

  @override
  State<PlaylistPlayFab> createState() => _PlaylistPlayFabState();
}

class _PlaylistPlayFabState extends State<PlaylistPlayFab> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Badge visibility matches Spotify PlayButtonView.java line 305:
    // If isPlaying is true or shuffle is disabled, badge is hidden.
    final showShuffleBadge = widget.isShuffleEnabled && !widget.isPlaying;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPlayTapped();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Main 56x56 Circular Green Play Button (Encore button_play_and_pause)
              Positioned.fill(
                child: Material(
                  color: const Color(0xFF1DB954),
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: FadeTransition(
                          opacity: anim,
                          child: child,
                        ),
                      ),
                      child: Icon(
                        widget.isPlaying ? Icons.pause : Icons.play_arrow,
                        key: ValueKey<bool>(widget.isPlaying),
                        color: Colors.black,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),

              // 2. 20dp Shuffle Badge (`button_badge` in play_button_view.xml)
              Positioned(
                right: -2,
                bottom: -2,
                child: AnimatedScale(
                  scale: showShuffleBadge ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212), // play_button_badge_background
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF121212),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.shuffle,
                        color: Color(0xFF1DB954), // encore_accent_color
                        size: 11, // encore_play_button_badge_size = 11dp
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
