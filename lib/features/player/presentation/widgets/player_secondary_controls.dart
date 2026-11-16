import 'package:flutter/material.dart';

import 'player_theme.dart';

/// Secondary player control row with quick access to Shuffle, Repeat, Queue,
/// and Lyrics.
///
/// Citations:
/// - Decompiled Java: `p199p/ac0.java` (Player secondary action bar)
/// - Decompiled Java: `com/spotify/music/nowplaying/` (Secondary controls row)
class PlayerSecondaryControls extends StatelessWidget {
  const PlayerSecondaryControls({
    super.key,
    required this.shuffleEnabled,
    required this.repeatEnabled,
    required this.onShuffle,
    required this.onRepeat,
    required this.onQueue,
    required this.onLyrics,
  });

  final bool shuffleEnabled;
  final bool repeatEnabled;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;
  final VoidCallback onQueue;
  final VoidCallback onLyrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SecondaryButton(
          icon: Icons.shuffle_rounded,
          label: 'Shuffle',
          active: shuffleEnabled,
          onTap: onShuffle,
        ),
        _SecondaryButton(
          icon: repeatEnabled ? Icons.repeat_one_rounded : Icons.repeat_rounded,
          label: repeatEnabled ? 'Repeat one' : 'Repeat',
          active: repeatEnabled,
          onTap: onRepeat,
        ),
        _SecondaryButton(
          icon: Icons.queue_music_rounded,
          label: 'Queue',
          active: false,
          onTap: onQueue,
        ),
        _SecondaryButton(
          icon: Icons.lyrics_outlined,
          label: 'Lyrics',
          active: false,
          onTap: onLyrics,
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? PlayerColors.accent : PlayerColors.muted;

    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Icon(icon, color: color, size: 23),
                const SizedBox(height: 7),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
