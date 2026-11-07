import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/private_vault/application/private_vault_bloc.dart';
import 'package:musify_mu/features/private_vault/domain/models/gesture_pattern.dart';
import 'package:musify_mu/features/private_vault/domain/services/unistroke_recognizer.dart';
import 'package:musify_mu/features/private_vault/presentation/theme/vault_theme_palette.dart';

/// Presentation mode of the gesture drawing canvas.
enum GestureCanvasRenderMode {
  stealth,
  interactiveEnrollment,
}

/// Gesture canvas capturing touch traces for vault unlock and enrollment.
class DrawerGestureCanvas extends StatefulWidget {
  final GestureCanvasRenderMode mode;
  final ValueChanged<GesturePattern>? onPatternRecorded;

  const DrawerGestureCanvas({
    super.key,
    this.mode = GestureCanvasRenderMode.stealth,
    this.onPatternRecorded,
  });

  @override
  State<DrawerGestureCanvas> createState() => DrawerGestureCanvasState();
}

class DrawerGestureCanvasState extends State<DrawerGestureCanvas>
    with SingleTickerProviderStateMixin {
  final List<Offset> _points = <Offset>[];
  final IGestureRecognizerService _recognizer = const UnistrokeRecognizer();
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _fadeController.reset();
    setState(() {
      _points.clear();
      _points.add(details.localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _points.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details, bool showTrail) {
    final renderBox = context.findRenderObject();
    final size = renderBox is RenderBox ? renderBox.size : Size.zero;

    if (size.width > 0 && size.height > 0 && _points.length >= 5) {
      if (widget.mode == GestureCanvasRenderMode.stealth) {
        // Dispatch secret gesture event to BLoC
        context.read<PrivateVaultBloc>().add(
              VaultGestureStrokeReceived(
                strokePoints: List<Offset>.from(_points),
                canvasSize: size,
              ),
            );

        if (showTrail) {
          // Fade out the disappearing ink over 400ms
          _fadeController.forward().then((_) {
            if (mounted) {
              setState(() {
                _points.clear();
              });
            }
          });
        } else {
          _points.clear();
        }
      } else {
        // Interactive enrollment mode
        try {
          final normalized = _recognizer.normalizeStroke(
            rawPoints: _points,
            canvasSize: size,
          );
          widget.onPatternRecorded?.call(normalized);
        } catch (_) {
          // Insufficient stroke length
        }
      }
    } else {
      _points.clear();
    }
  }

  void clear() {
    _fadeController.reset();
    setState(() {
      _points.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PrivateVaultBloc, PrivateVaultState, (bool showTrail, VaultThemePalette palette)>(
      selector: (state) => (
        state.settings.showDrawerGestureTrail,
        VaultThemePalette.of(state.settings.theme),
      ),
      builder: (context, config) {
        final showTrail = config.$1;
        final palette = config.$2;

        return LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: (details) => _onPanEnd(details, showTrail),
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  final opacity = widget.mode == GestureCanvasRenderMode.interactiveEnrollment
                      ? 1.0
                      : (showTrail ? (1.0 - _fadeAnimation.value) : 0.0);

                  return CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _GesturePainter(
                      points: _points,
                      opacity: opacity,
                      strokeColor: widget.mode == GestureCanvasRenderMode.interactiveEnrollment
                          ? palette.textPrimary
                          : palette.textSecondary.withValues(alpha: 0.6),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _GesturePainter extends CustomPainter {
  final List<Offset> points;
  final double opacity;
  final Color strokeColor;

  const _GesturePainter({
    required this.points,
    required this.opacity,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.0 || points.length < 2) {
      return;
    }

    final paint = Paint()
      ..color = strokeColor.withValues(alpha: opacity)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GesturePainter oldDelegate) {
    return opacity != oldDelegate.opacity ||
        points.length != oldDelegate.points.length ||
        strokeColor != oldDelegate.strokeColor;
  }
}
