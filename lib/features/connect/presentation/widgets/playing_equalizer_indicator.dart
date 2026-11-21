// 1:1 replica of Spotify's animated 3-bar playing equalizer indicator
// (`p199p/jyr0.java`, `p199p/iyr0.java` case 0, `p199p/mzq0.java` case 9).

import 'package:flutter/material.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';

/// 16x16dp 3-bar animated equalizer matching Spotify's `jyr0.java` keyframes,
/// easing curve (`Cubic(0.167, 0.167, 0.833, 0.833)`), `1250ms` cycle, and
/// `200ms` pause blend.
class PlayingEqualizerIndicator extends StatefulWidget {
  const PlayingEqualizerIndicator({
    super.key,
    required this.isPlaying,
    this.size = 16.0,
    this.color = ConnectEncoreTheme.brightAccent,
  });

  final bool isPlaying;
  final double size;
  final Color color;

  @override
  State<PlayingEqualizerIndicator> createState() =>
      _PlayingEqualizerIndicatorState();
}

class _PlayingEqualizerIndicatorState extends State<PlayingEqualizerIndicator>
    with TickerProviderStateMixin {
  static const Cubic _keyframeCurve = Cubic(0.167, 0.167, 0.833, 0.833);
  static const double _restingBarHeight = 1.0 / 6.0;

  /// Exact keyframe tracks from `jyr0.java` lines 14, 17, 20.
  static const List<double> _bar1Frames = <double>[
    0.6666667,
    0.16666667,
    0.6666667,
    0.41666666,
    0.9166667,
    0.6666667,
  ];
  static const List<double> _bar2Frames = <double>[
    0.9166667,
    0.6666667,
    0.41666666,
    0.6666667,
    0.16666667,
    0.9166667,
  ];
  static const List<double> _bar3Frames = <double>[
    0.41666666,
    0.6666667,
    0.16666667,
    0.9166667,
    0.6666667,
    0.41666666,
  ];

  AnimationController? _cycleController;
  AnimationController? _blendController;

  @override
  void initState() {
    super.initState();
    final cycle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );
    final blend = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: widget.isPlaying ? 1.0 : 0.0,
    );
    _cycleController = cycle;
    _blendController = blend;
    if (widget.isPlaying) {
      cycle.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PlayingEqualizerIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      final cycle = _cycleController;
      final blend = _blendController;
      if (cycle != null && blend != null) {
        if (widget.isPlaying) {
          if (!cycle.isAnimating) {
            cycle.repeat();
          }
          blend.forward();
        } else {
          blend.reverse().whenComplete(() {
            if (mounted && !widget.isPlaying && cycle.isAnimating) {
              cycle.stop();
            }
          });
        }
      }
    }
  }

  @override
  void dispose() {
    if (_cycleController case final cycle?) {
      cycle.dispose();
      _cycleController = null;
    }
    if (_blendController case final blend?) {
      blend.dispose();
      _blendController = null;
    }
    super.dispose();
  }

  static double _sampleTrack(List<double> frames, double t) {
    final int segments = frames.length - 1;
    final double scaled = t * segments;
    final int index = scaled.floor();
    if (index >= segments) {
      return frames[segments];
    }
    if (index < 0) {
      return frames[0];
    }
    final double localT = _keyframeCurve.transform(scaled - index);
    return frames[index] + (frames[index + 1] - frames[index]) * localT;
  }

  @override
  Widget build(BuildContext context) {
    final cycle = _cycleController;
    final blend = _blendController;
    if (cycle == null || blend == null) {
      return SizedBox.square(dimension: widget.size);
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[cycle, blend]),
        builder: (context, _) {
          final double b = blend.value;
          final double t = cycle.value;
          final double v1 = _restingBarHeight +
              (_sampleTrack(_bar1Frames, t) - _restingBarHeight) * b;
          final double v2 = _restingBarHeight +
              (_sampleTrack(_bar2Frames, t) - _restingBarHeight) * b;
          final double v3 = _restingBarHeight +
              (_sampleTrack(_bar3Frames, t) - _restingBarHeight) * b;

          return CustomPaint(
            size: Size.square(widget.size),
            painter: _EqualizerBarsPainter(
              bar1: v1,
              bar2: v2,
              bar3: v3,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

final class _EqualizerBarsPainter extends CustomPainter {
  _EqualizerBarsPainter({
    required this.bar1,
    required this.bar2,
    required this.bar3,
    required this.color,
  });

  final double bar1;
  final double bar2;
  final double bar3;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Exact proportions from iyr0.java lines 48-53 & jyr0.java lines 379-382.
    final double barWidth = size.width * (1.0 / 6.0);
    final double startX = size.width * (1.0 / 12.0);
    final double stepX = size.width * (1.0 / 3.0);

    _drawBar(canvas, paint, startX, barWidth, size.height, bar1);
    _drawBar(canvas, paint, startX + stepX, barWidth, size.height, bar2);
    _drawBar(canvas, paint, startX + stepX * 2.0, barWidth, size.height, bar3);
  }

  void _drawBar(
    Canvas canvas,
    Paint paint,
    double x,
    double width,
    double totalHeight,
    double fraction,
  ) {
    final double barHeight = totalHeight * fraction;
    final double top = totalHeight - barHeight;
    canvas.drawRect(Rect.fromLTWH(x, top, width, barHeight), paint);
  }

  @override
  bool shouldRepaint(covariant _EqualizerBarsPainter oldDelegate) {
    return oldDelegate.bar1 != bar1 ||
        oldDelegate.bar2 != bar2 ||
        oldDelegate.bar3 != bar3 ||
        oldDelegate.color != color;
  }
}
