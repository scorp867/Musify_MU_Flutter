import 'package:flutter/material.dart';

/// Reusable overlay that draws subtle protection scrims over the status bar
/// and navigation bar insets while allowing edge-to-edge content to render underneath.
class EdgeToEdgeScrim extends StatelessWidget {
  const EdgeToEdgeScrim({
    super.key,
    required this.child,
    this.topScrimColor,
    this.bottomScrimColor,
    this.showTopScrim = true,
    this.showBottomScrim = true,
  });

  final Widget child;
  final Color? topScrimColor;
  final Color? bottomScrimColor;
  final bool showTopScrim;
  final bool showBottomScrim;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (showTopScrim && topPadding > 0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPadding + 16,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      topScrimColor ?? Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (showBottomScrim && bottomPadding > 0)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: bottomPadding + 28,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.55, 1.0],
                    colors: [
                      bottomScrimColor ?? Colors.black.withValues(alpha: 0.70),
                      (bottomScrimColor ?? Colors.black).withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
