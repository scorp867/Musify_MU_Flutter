import 'package:flutter/material.dart';

import 'player_theme.dart';

class PlayerHeader extends StatelessWidget {
  const PlayerHeader({super.key, required this.onClose, required this.onMore});

  final VoidCallback onClose;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              PlayerCircleButton(
                icon: Icons.keyboard_arrow_down_rounded,
                tooltip: 'Close player',
                onPressed: onClose,
              ),
              const Expanded(
                child: Text(
                  'Now Playing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              PlayerCircleButton(
                icon: Icons.more_horiz_rounded,
                tooltip: 'More options',
                onPressed: onMore,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PlayerCircleButton extends StatelessWidget {
  const PlayerCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor = Colors.white,
    this.backgroundColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, color: iconColor, size: 22),
        splashRadius: 22,
      ),
    );
  }
}

class PlayerEmptyState extends StatelessWidget {
  const PlayerEmptyState({
    super.key,
    required this.onClose,
    required this.onMore,
  });

  final VoidCallback onClose;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: Container(
        height: 460,
        color: PlayerColors.background,
        child: SafeArea(
          child: Column(
            children: [
              PlayerHeader(onClose: onClose, onMore: onMore),
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.music_off_rounded,
                          color: PlayerColors.accent,
                          size: 58,
                        ),
                        SizedBox(height: 18),
                        Text(
                          'Nothing is playing',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Choose a song from your library to start listening.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: PlayerColors.muted,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
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
