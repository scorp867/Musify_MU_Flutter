import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/data/gesture/raw_touch_filter.dart';
import 'package:musify_mu/features/vault/data/services/gesture_recognizer_service.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_visibility_policy.dart';

/// Single-stroke invisible sensor canvas embedded inside DrawerMenu spacer area.
///
/// Features:
/// 1. Eager Arena Victory: Uses [RawGestureDetector] with [EagerGestureRecognizer]
///    to unconditionally win the gesture arena on [PointerDownEvent], preventing
///    parent drawer dismissal drags.
/// 2. Flexible Spacer Sizing: Expands to occupy the full available height and width
///    of the drawer spacer area, relying on downstream normalization for scale invariance.
/// 3. In-Flight Isolate Superseding: Cancels in-flight background evaluations on rapid
///    re-touches via monotonic epoch invalidation.
/// 4. Pure Stealth vs Hairline: Respects [GestureVisibilityPolicyEnum].
/// 5. Kinematic Pre-Filtering: Drops stationary tremor (zero displacement) and
///    sub-deadband touches (< 2.5px) synchronously on the UI thread without background isolate evaluation.
/// 6. Deterministic Dissipation Lifecycle: Manages [AnimationController] with explicit forward
///    completion and status listeners to guarantee ticker termination within 280ms duration.
class StealthGesturePad extends StatefulWidget {
  /// Callback invoked when a drawn gesture matches [activeTemplate] under [sensitivityTier].
  final VoidCallback onGestureMatched;

  /// Underlying recognition pipeline service. Defaults to [GestureRecognizerService].
  final IGestureRecognizer recognizer;

  /// Canonical or enrolled gesture template. Defaults to [DefaultGestureTemplate.canonicalVShape].
  final GestureTemplate activeTemplate;

  /// Minimum consensus score policy tier. Defaults to [GestureSensitivityTierEnum.balanced84Percent].
  final GestureSensitivityTierEnum sensitivityTier;

  /// Visual ink rendering policy. Defaults to [GestureVisibilityPolicyEnum.invisibleStealth].
  final GestureVisibilityPolicyEnum visibilityPolicy;

  /// Optional evaluation completed callback for testing and telemetry.
  final ValueChanged<RecognitionScore>? onEvaluationCompleted;

  StealthGesturePad({
    super.key,
    required this.onGestureMatched,
    IGestureRecognizer? recognizer,
    GestureTemplate? activeTemplate,
    this.sensitivityTier = GestureSensitivityTierEnum.balanced84Percent,
    this.visibilityPolicy = GestureVisibilityPolicyEnum.invisibleStealth,
    this.onEvaluationCompleted,
  })  : recognizer = (recognizer != null)
            ? recognizer
            : GestureRecognizerService(),
        activeTemplate = (activeTemplate != null)
            ? activeTemplate
            : DefaultGestureTemplate.canonicalVShape;

  @override
  State<StealthGesturePad> createState() => _StealthGesturePadState();
}

class _StealthGesturePadState extends State<StealthGesturePad>
    with SingleTickerProviderStateMixin {
  final List<GesturePoint> _rawPoints = <GesturePoint>[];
  final List<_TimedPoint> _timedPoints = <_TimedPoint>[];
  late final AnimationController _dissipationController;

  int _strokeEpoch = 0;
  int _strokeStartEpochMs = 0;
  int? _activePointerId;
  bool _isPointerDown = false;

  static const double _dissipationDurationMs = 220.0;

  @override
  void initState() {
    super.initState();
    _dissipationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(_onDissipationTick)
     ..addStatusListener(_onDissipationStatus);
  }

  @override
  void dispose() {
    if (widget.recognizer case final GestureRecognizerService service) {
      service.cancelActiveEvaluation();
    }
    _dissipationController.removeListener(_onDissipationTick);
    _dissipationController.removeStatusListener(_onDissipationStatus);
    _dissipationController.dispose();
    super.dispose();
  }

  void _onDissipationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _timedPoints.clear();
      _dissipationController.reset();
    }
  }

  void _onDissipationTick() {
    if (!widget.visibilityPolicy.isInkVisible) return;

    final int now = DateTime.now().millisecondsSinceEpoch;
    _timedPoints.removeWhere(
      (point) => (now - point.timestampMs) >= _dissipationDurationMs,
    );

    if (_timedPoints.isEmpty && !_isPointerDown) {
      if (_dissipationController.isAnimating) {
        _dissipationController.stop();
        _dissipationController.reset();
      }
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_activePointerId != null) return;
    _activePointerId = event.pointer;
    _isPointerDown = true;
    _strokeEpoch++;

    if (widget.recognizer case final GestureRecognizerService service) {
      service.cancelActiveEvaluation();
    }

    _rawPoints.clear();
    _timedPoints.clear();

    if (_dissipationController.isAnimating) {
      _dissipationController.stop();
      _dissipationController.reset();
    }

    final int now = DateTime.now().millisecondsSinceEpoch;
    _strokeStartEpochMs = (now > 0) ? now : 1;

    final point = GesturePoint(
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      timestampMs: 0,
    );
    _rawPoints.add(point);

    if (widget.visibilityPolicy.isInkVisible) {
      _timedPoints.add(_TimedPoint(event.localPosition, _strokeStartEpochMs));
      if (!_dissipationController.isAnimating) {
        _dissipationController.repeat();
      }
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointerId) return;
    if (!_isPointerDown) return;

    final lastPoint = _rawPoints.isNotEmpty ? _rawPoints.last : null;
    if (lastPoint != null &&
        event.localPosition.dx == lastPoint.x &&
        event.localPosition.dy == lastPoint.y) {
      return;
    }

    final int now = DateTime.now().millisecondsSinceEpoch;
    final int elapsedMs = now - _strokeStartEpochMs;
    final int timestampMs = (elapsedMs < 0) ? 0 : elapsedMs;

    final point = GesturePoint(
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      timestampMs: timestampMs,
    );
    _rawPoints.add(point);

    if (widget.visibilityPolicy.isInkVisible) {
      _timedPoints.add(_TimedPoint(event.localPosition, now));
    }
  }

  Future<void> _onPointerUp(PointerUpEvent event) async {
    if (event.pointer != _activePointerId) return;
    _activePointerId = null;
    _isPointerDown = false;

    final int now = DateTime.now().millisecondsSinceEpoch;
    final int elapsedMs = now - _strokeStartEpochMs;
    final int timestampMs = (elapsedMs < 0) ? 0 : elapsedMs;

    final lastPoint = _rawPoints.isNotEmpty ? _rawPoints.last : null;
    final bool hasMoved = lastPoint == null ||
        (event.localPosition.dx != lastPoint.x ||
            event.localPosition.dy != lastPoint.y);

    if (hasMoved) {
      final point = GesturePoint(
        x: event.localPosition.dx,
        y: event.localPosition.dy,
        timestampMs: timestampMs,
      );
      _rawPoints.add(point);

      if (widget.visibilityPolicy.isInkVisible) {
        _timedPoints.add(_TimedPoint(event.localPosition, now));
      }
    }

    if (widget.visibilityPolicy.isInkVisible) {
      _dissipationController.forward(from: 0.0);
    }

    if (_rawPoints.length < 2) {
      _rawPoints.clear();
      return;
    }

    final int captureEpoch = _strokeEpoch;
    final pointsCopy = List<GesturePoint>.unmodifiable(_rawPoints);
    _rawPoints.clear();

    double totalLength = 0.0;
    for (int i = 0; i < pointsCopy.length - 1; i++) {
      final dx = pointsCopy[i + 1].x - pointsCopy[i].x;
      final dy = pointsCopy[i + 1].y - pointsCopy[i].y;
      totalLength += math.sqrt(dx * dx + dy * dy);
    }

    if (totalLength < RawTouchFilter.defaultDeadbandThreshold) {
      return;
    }

    final int sampledAtEpochMs = (_strokeStartEpochMs > 0)
        ? _strokeStartEpochMs
        : ((now > 0) ? now : 1);

    final GestureSample sample;
    try {
      sample = GestureSample(
        points: pointsCopy,
        sampledAtEpochMs: sampledAtEpochMs,
        totalLength: totalLength,
      );
    } on FormatException {
      return;
    }

    final result = await widget.recognizer.evaluateStroke(
      liveStroke: sample,
      template: widget.activeTemplate,
      sensitivityTier: widget.sensitivityTier,
    );

    if (!mounted || captureEpoch != _strokeEpoch) {
      return;
    }

    switch (result) {
      case VaultSuccess<RecognitionScore>(:final data):
        switch (data.decision) {
          case GestureMatchDecisionEnum.matched:
            HapticFeedback.mediumImpact();
            widget.onGestureMatched();
          case GestureMatchDecisionEnum.rejectedAntiScribble:
          case GestureMatchDecisionEnum.rejectedStructuralGate:
          case GestureMatchDecisionEnum.rejectedClassifierFloor:
          case GestureMatchDecisionEnum.rejectedBelowSensitivityTier:
            // Silent rejection: zero UI leakage, preserve plausible deniability
            break;
        }
        widget.onEvaluationCompleted?.call(data);

      case VaultFailureResult<RecognitionScore>():
        // Silent rejection on pipeline failure or invalid input
        break;
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointerId) return;
    _activePointerId = null;
    _isPointerDown = false;
    _rawPoints.clear();
    _timedPoints.clear();
    if (_dissipationController.isAnimating) {
      _dissipationController.stop();
      _dissipationController.reset();
    }
    if (widget.recognizer case final GestureRecognizerService service) {
      service.cancelActiveEvaluation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        EagerGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
          () => EagerGestureRecognizer(),
          (EagerGestureRecognizer instance) {},
        ),
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _DissipatingHairlinePainter(
              repaint: _dissipationController,
              timedPoints: _timedPoints,
              visibilityPolicy: widget.visibilityPolicy,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _TimedPoint {
  final Offset position;
  final int timestampMs;

  const _TimedPoint(this.position, this.timestampMs);
}

class _DissipatingHairlinePainter extends CustomPainter {
  final List<_TimedPoint> timedPoints;
  final GestureVisibilityPolicyEnum visibilityPolicy;

  _DissipatingHairlinePainter({
    required super.repaint,
    required this.timedPoints,
    required this.visibilityPolicy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!visibilityPolicy.isInkVisible || timedPoints.length < 2) {
      return;
    }

    final int now = DateTime.now().millisecondsSinceEpoch;
    const double maxOpacity = 0.35;
    const double dissipationMs = 220.0;

    for (int i = 1; i < timedPoints.length; i++) {
      final p0 = timedPoints[i - 1];
      final p1 = timedPoints[i];

      final double ageMs = (now - p1.timestampMs).toDouble();
      if (ageMs >= dissipationMs || ageMs < 0.0) {
        continue;
      }

      final double rawProgress = ageMs / dissipationMs;
      final double progress = (rawProgress < 0.0)
          ? 0.0
          : ((rawProgress > 1.0) ? 1.0 : rawProgress);
      final double alphaFraction = (1.0 - progress) * (1.0 - progress);
      final double rawAlpha = alphaFraction * maxOpacity;
      final double alpha = (rawAlpha < 0.0)
          ? 0.0
          : ((rawAlpha > 1.0) ? 1.0 : rawAlpha);

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawLine(p0.position, p1.position, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DissipatingHairlinePainter oldDelegate) {
    if (!visibilityPolicy.isInkVisible) return false;
    return true;
  }
}
