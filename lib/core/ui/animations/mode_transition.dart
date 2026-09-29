import 'package:flutter/material.dart';
import 'dart:math';

class ModeTransition {
  /// Starts the mode-switch animation with icon flip and status text.
  ///
  /// [isCurrentlyFlipped] tells the animation the icon's starting orientation.
  /// The icon flips FROM current state TO the opposite.
  ///
  /// [onHideOriginal] is called immediately so the caller can hide the
  /// original icon (making it look like it "left" its position).
  static void start(
    BuildContext context, {
    required GlobalKey iconKey,
    required String targetModeName,
    required bool isCurrentlyFlipped,
    required Future<void> Function() onReady,
    VoidCallback? onHideOriginal,
    VoidCallback? onShowOriginal,
  }) {
    final context = iconKey.currentContext;
    if (context == null) return;
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final startPosition = renderBox.localToGlobal(Offset.zero);
    final iconSize = renderBox.size;
    final startCenter = Offset(
      startPosition.dx + iconSize.width / 2,
      startPosition.dy + iconSize.height / 2,
    );

    // Hide the original icon immediately — the overlay takes over.
    onHideOriginal?.call();

    OverlayState overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return _TransitionOverlayWidget(
          startCenter: startCenter,
          iconSize: iconSize,
          targetModeName: targetModeName,
          isCurrentlyFlipped: isCurrentlyFlipped,
          onReady: onReady,
          onComplete: () {
            overlayEntry.remove();
            // Reveal the (now-updated) original icon.
            onShowOriginal?.call();
          },
        );
      },
    );

    overlayState.insert(overlayEntry);
  }
}

class _TransitionOverlayWidget extends StatefulWidget {
  final Offset startCenter;
  final Size iconSize;
  final String targetModeName;
  final bool isCurrentlyFlipped;
  final Future<void> Function() onReady;
  final VoidCallback onComplete;

  const _TransitionOverlayWidget({
    required this.startCenter,
    required this.iconSize,
    required this.targetModeName,
    required this.isCurrentlyFlipped,
    required this.onReady,
    required this.onComplete,
  });

  @override
  _TransitionOverlayWidgetState createState() =>
      _TransitionOverlayWidgetState();
}

class _TransitionOverlayWidgetState extends State<_TransitionOverlayWidget>
    with TickerProviderStateMixin {
  // Controls the circle-close / icon-move animation.
  late AnimationController _moveController;
  late Animation<double> _moveAnimation;

  // Controls the 180° horizontal flip.
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  // Controls the text fade-in/out.
  late AnimationController _textController;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _moveAnimation = CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOutCubic,
    );

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutBack,
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    // 1. Icon flies to center, circle closes → screen goes dark.
    await _moveController.forward();
    if (!mounted) return;

    // 2. Flip the icon 180° horizontally + fade in the text.
    await Future.wait([
      _flipController.forward(),
      _textController.forward(),
    ]);
    if (!mounted) return;

    // 3. Switch mode — animation holds at dark state until ready.
    await widget.onReady();
    if (!mounted) return;

    // 4. Brief pause so the user reads the text.
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // 5. Fade out text.
    await _textController.reverse();
    if (!mounted) return;

    // 6. Circle opens, icon flies back (now flipped) → reveal new screen.
    await _moveController.reverse();
    if (!mounted) return;

    // 7. Done.
    widget.onComplete();
  }

  @override
  void dispose() {
    _moveController.dispose();
    _flipController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);

    final maxRadius = sqrt(
      pow(screenSize.width, 2) + pow(screenSize.height, 2),
    );
    final minRadius = widget.iconSize.width / 2;

    const targetIconSize = 56.0;

    return AnimatedBuilder(
      animation:
          Listenable.merge([_moveAnimation, _flipAnimation, _textAnimation]),
      builder: (context, child) {
        final currentRadius =
            maxRadius - (maxRadius - minRadius) * _moveAnimation.value;
        final currentCenter = Offset.lerp(
          widget.startCenter,
          screenCenter,
          _moveAnimation.value,
        )!;

        final currentSize = widget.iconSize.width +
            (targetIconSize - widget.iconSize.width) * _moveAnimation.value;

        // Flip angle: starts at current orientation, ends at opposite.
        // If currently flipped (pi), animate from pi → 0.
        // If currently normal (0), animate from 0 → pi.
        final double flipAngle;
        if (widget.isCurrentlyFlipped) {
          flipAngle = pi * (1 - _flipAnimation.value); // pi → 0
        } else {
          flipAngle = pi * _flipAnimation.value; // 0 → pi
        }

        return Stack(
          children: [
            // Dark background with circular reveal.
            ClipPath(
              clipper: InwardCircleClipper(
                radius: currentRadius,
                center: currentCenter,
              ),
              child: Container(color: const Color(0xFF121212)),
            ),

            // The app icon — moves to center, flips horizontally.
            Positioned(
              left: currentCenter.dx - currentSize / 2,
              top: currentCenter.dy - currentSize / 2,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(flipAngle),
                child: Container(
                  width: currentSize,
                  height: currentSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      12 + 4 * _moveAnimation.value,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/app_icon.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // "Switching to X mode" text below the icon.
            Positioned(
              left: 0,
              right: 0,
              top: currentCenter.dy + currentSize / 2 + 24,
              child: Opacity(
                opacity: _textAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - _textAnimation.value)),
                  child: Text(
                    'Switching to ${widget.targetModeName} mode',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class InwardCircleClipper extends CustomClipper<Path> {
  final double radius;
  final Offset center;

  InwardCircleClipper({required this.radius, required this.center});

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(InwardCircleClipper oldClipper) {
    return oldClipper.radius != radius || oldClipper.center != center;
  }
}
