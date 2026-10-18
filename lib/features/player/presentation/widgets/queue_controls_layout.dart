import 'package:flutter/material.dart';
import 'package:musify_mu/core/ui/icons/spotify_encore_icons.dart';

import 'player_theme.dart';

enum QueueShuffleMode { none, all }
enum QueueRepeatMode { none, all, one }

/// 1:1 with Spotify's layout_queue_controls.xml & screenshots:
///
///   DropShadowContainer (top gradient fade over scrolling list)
///   SessionModifierContainerView:
///     Three equal-width rounded cards (#242424) with icon + label:
///     [Shuffle]  [Repeat]  [Timer]
class QueueControlsLayout extends StatelessWidget {
  const QueueControlsLayout({
    super.key,
    required this.shuffleMode,
    required this.repeatMode,
    required this.onShuffleTapped,
    required this.onRepeatTapped,
    required this.onTimerTapped,
    this.isTimerActive = false,
  });

  final QueueShuffleMode shuffleMode;
  final QueueRepeatMode repeatMode;
  final VoidCallback onShuffleTapped;
  final VoidCallback onRepeatTapped;
  final VoidCallback onTimerTapped;
  final bool isTimerActive;

  bool get _isShuffling => shuffleMode == QueueShuffleMode.all;

  bool get _isRepeating =>
      repeatMode == QueueRepeatMode.all || repeatMode == QueueRepeatMode.one;

  bool get _isRepeatingOne => repeatMode == QueueRepeatMode.one;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DropShadowContainer (drop_shadow_top.xml: fades tracks into dock)
          IgnorePointer(
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PlayerColors.background.withValues(alpha: 0.0),
                    PlayerColors.background.withValues(alpha: 0.85),
                    PlayerColors.background,
                  ],
                ),
              ),
            ),
          ),

          // Bottom docked controls bar
          Container(
            color: PlayerColors.background,
            padding: EdgeInsets.fromLTRB(16, 4, 16, 12 + bottomSafe),
            child: Row(
              children: [
                // 1. Shuffle Card
                Expanded(
                  child: _ControlCard(
                    icon: SpotifyIcon.shuffle(
                      size: 20,
                      color: _isShuffling
                          ? PlayerColors.accent
                          : PlayerColors.textSecondary,
                    ),
                    label: 'Shuffle',
                    isActive: _isShuffling,
                    onTap: onShuffleTapped,
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Repeat Card
                Expanded(
                  child: _ControlCard(
                    icon: _isRepeatingOne
                        ? SpotifyIcon.repeatOnce(
                            size: 20,
                            color: PlayerColors.accent,
                          )
                        : SpotifyIcon.repeat(
                            size: 20,
                            color: _isRepeating
                                ? PlayerColors.accent
                                : PlayerColors.textSecondary,
                          ),
                    label: _isRepeatingOne
                        ? 'Repeat 1'
                        : (_isRepeating ? 'Repeat All' : 'Repeat'),
                    isActive: _isRepeating,
                    onTap: onRepeatTapped,
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Sleep Timer Card
                Expanded(
                  child: _ControlCard(
                    icon: SpotifyIcon.timer(
                      size: 20,
                      color: isTimerActive
                          ? PlayerColors.accent
                          : PlayerColors.textSecondary,
                    ),
                    label: 'Timer',
                    isActive: isTimerActive,
                    onTap: onTimerTapped,
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

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF242424),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? PlayerColors.accent : Colors.white70,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
