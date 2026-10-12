import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/core/ui/icons/spotify_encore_icons.dart';

import 'player_theme.dart';

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

  final AudioServiceShuffleMode shuffleMode;
  final AudioServiceRepeatMode repeatMode;
  final VoidCallback onShuffleTapped;
  final VoidCallback onRepeatTapped;
  final VoidCallback onTimerTapped;
  final bool isTimerActive;

  bool get _isShuffling =>
      shuffleMode == AudioServiceShuffleMode.all ||
      shuffleMode == AudioServiceShuffleMode.group;

  bool get _isRepeating =>
      repeatMode == AudioServiceRepeatMode.all ||
      repeatMode == AudioServiceRepeatMode.one;

  bool get _isRepeatingOne => repeatMode == AudioServiceRepeatMode.one;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Column(
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
                stops: const [0.0, 0.65, 1.0],
              ),
            ),
          ),
        ),

        // queue_controls_content_area + SessionModifierContainerView
        Container(
          color: PlayerColors.background,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 4,
            bottom: bottomSafe + 12,
          ),
          child: Row(
            children: [
              Expanded(
                child: _SessionModifierButton(
                  label: 'Shuffle',
                  isActive: _isShuffling,
                  onTap: onShuffleTapped,
                  iconBuilder: (color) => SpotifyIcon.shuffle(
                    color: color,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SessionModifierButton(
                  label: 'Repeat',
                  isActive: _isRepeating,
                  onTap: onRepeatTapped,
                  iconBuilder: (color) => _isRepeatingOne
                      ? SpotifyIcon.repeatOnce(color: color, size: 22)
                      : SpotifyIcon.repeat(color: color, size: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SessionModifierButton(
                  label: 'Timer',
                  isActive: isTimerActive,
                  onTap: onTimerTapped,
                  iconBuilder: (color) => SpotifyIcon.timer(
                    color: color,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionModifierButton extends StatefulWidget {
  const _SessionModifierButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.iconBuilder,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Widget Function(Color color) iconBuilder;

  @override
  State<_SessionModifierButton> createState() => _SessionModifierButtonState();
}

class _SessionModifierButtonState extends State<_SessionModifierButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final targetColor = widget.isActive ? PlayerColors.accent : Colors.white;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF242424),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: targetColor),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            builder: (context, animatedColor, _) {
              final resolvedColor = animatedColor ?? targetColor;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.iconBuilder(resolvedColor),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: resolvedColor.withValues(
                        alpha: widget.isActive ? 1.0 : 0.85,
                      ),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
