// Smooth horizontal marquee text with fading edges matching Spotify's
// `basicMarquee` / `TrackInfoView` marquee behavior.

import 'package:flutter/material.dart';

/// Single-line text widget that scrolls smoothly horizontally when its
/// intrinsic width exceeds the available width, with subtle edge fading.
///
/// When the text fits within the available width (or [enableMarquee] is
/// `false`), no animation runs and rendering incurs zero ticker overhead.
class SpotifyMarqueeText extends StatefulWidget {
  const SpotifyMarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.textSpan,
    this.enableMarquee = true,
    this.velocityDpPerSecond = 28.0,
    this.gap = 32.0,
    this.fadeEdgeWidth = 10.0,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle style;

  /// Optional rich [InlineSpan] (used by MiniPlayer 1-line `"Title • Artist"`
  /// with bold title, inline badge icons, and subdued artist).
  final InlineSpan? textSpan;

  final bool enableMarquee;
  final double velocityDpPerSecond;
  final double gap;
  final double fadeEdgeWidth;
  final TextAlign textAlign;

  @override
  State<SpotifyMarqueeText> createState() => _SpotifyMarqueeTextState();
}

class _SpotifyMarqueeTextState extends State<SpotifyMarqueeText>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  double _cycleDistance = 0.0;
  double _viewportWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant SpotifyMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.textSpan != widget.textSpan ||
        oldWidget.style != widget.style ||
        oldWidget.enableMarquee != widget.enableMarquee) {
      _stopMarquee();
    }
  }

  @override
  void dispose() {
    if (_controller case final controller?) {
      controller.dispose();
      _controller = null;
    }
    super.dispose();
  }

  void _stopMarquee() {
    final controller = _controller;
    if (controller != null && controller.isAnimating) {
      controller.stop();
      controller.value = 0.0;
    }
  }

  void _syncMarqueeMetrics({
    required double textWidth,
    required double viewportWidth,
  }) {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    final bool shouldScroll =
        widget.enableMarquee &&
        viewportWidth.isFinite &&
        viewportWidth > 0 &&
        textWidth > viewportWidth + 1.0;

    if (!shouldScroll) {
      _cycleDistance = 0.0;
      _viewportWidth = viewportWidth;
      if (controller.isAnimating || controller.value != 0.0) {
        controller.stop();
        controller.value = 0.0;
      }
      return;
    }

    final double nextCycle = textWidth + widget.gap;
    final bool metricsChanged =
        (nextCycle - _cycleDistance).abs() > 0.5 ||
        (viewportWidth - _viewportWidth).abs() > 0.5;
    _cycleDistance = nextCycle;
    _viewportWidth = viewportWidth;

    if (metricsChanged || !controller.isAnimating) {
      final int scrollMs =
          ((nextCycle / widget.velocityDpPerSecond) * 1000.0).round();
      final int totalMs = scrollMs + 1600;
      controller.duration = Duration(milliseconds: totalMs < 1800 ? 1800 : totalMs);
      if (!controller.isAnimating) {
        controller.repeat();
      }
    }
  }

  Size _measureTextSize(BuildContext context, TextDirection textDirection) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final InlineSpan span = switch (widget.textSpan) {
      final explicit? => explicit,
      null => TextSpan(text: widget.text, style: widget.style),
    };
    final painter = TextPainter(
      text: span,
      maxLines: 1,
      textDirection: textDirection,
      textScaler: scaler,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    final size = painter.size;
    painter.dispose();
    return size;
  }

  Widget _buildSingleLineText() {
    if (widget.textSpan case final span?) {
      return Text.rich(
        span,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        textAlign: widget.textAlign,
      );
    }
    return Text(
      widget.text,
      style: widget.style,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      textAlign: widget.textAlign,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final Size textSize = _measureTextSize(context, textDirection);
    final double textWidth = textSize.width;
    final double textHeight = textSize.height > 0 ? textSize.height : 16.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final bool overflows =
            widget.enableMarquee &&
            maxWidth.isFinite &&
            maxWidth > 0 &&
            textWidth > maxWidth + 1.0;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _syncMarqueeMetrics(
              textWidth: textWidth,
              viewportWidth: maxWidth,
            );
          }
        });

        if (!overflows) {
          if (widget.textSpan case final span?) {
            return Text.rich(
              span,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: widget.textAlign,
            );
          }
          return Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: widget.textAlign,
          );
        }

        final controller = _controller;
        if (controller == null) {
          return _buildSingleLineText();
        }

        final double effectiveCycle = textWidth + widget.gap;
        final double fadeStop = maxWidth > 0
            ? (widget.fadeEdgeWidth / maxWidth > 0.2
                ? 0.2
                : widget.fadeEdgeWidth / maxWidth)
            : 0.08;

        return RepaintBoundary(
          child: SizedBox(
            width: maxWidth,
            height: textHeight,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: const <Color>[
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: <double>[
                    0.0,
                    fadeStop,
                    1.0 - fadeStop,
                    1.0,
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    // Hold at start for the initial 20% of the cycle so the
                    // beginning of the title/device name is effortlessly legible.
                    const double holdFraction = 0.20;
                    final double t = controller.value;
                    final double scrollProgress = t <= holdFraction
                        ? 0.0
                        : (t - holdFraction) / (1.0 - holdFraction);
                    final double dx = -scrollProgress * effectiveCycle;
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: child,
                    );
                  },
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: 0,
                    maxWidth: double.infinity,
                    minHeight: 0,
                    maxHeight: textHeight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSingleLineText(),
                        SizedBox(width: widget.gap),
                        // Seamless wrap-around copy painted directly on Canvas
                        // so accessibility and widget trees never duplicate text.
                        ExcludeSemantics(
                          child: CustomPaint(
                            size: Size(textWidth, textHeight),
                            painter: _MarqueeGhostTextPainter(
                              span: switch (widget.textSpan) {
                                final explicit? => explicit,
                                null => TextSpan(
                                    text: widget.text,
                                    style: widget.style,
                                  ),
                              },
                              textDirection: textDirection,
                              textScaler: MediaQuery.textScalerOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _MarqueeGhostTextPainter extends CustomPainter {
  const _MarqueeGhostTextPainter({
    required this.span,
    required this.textDirection,
    required this.textScaler,
  });

  final InlineSpan span;
  final TextDirection textDirection;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    final painter = TextPainter(
      text: span,
      maxLines: 1,
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    painter.paint(canvas, Offset.zero);
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _MarqueeGhostTextPainter oldDelegate) {
    return oldDelegate.span != span ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.textScaler != textScaler;
  }
}
