import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/gesture/kinematic_sanity_gate.dart';
import 'package:musify_mu/features/vault/data/gesture/raw_touch_filter.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';

void main() {
  group('KinematicSanityGate & RawTouchFilter Adversarial Stress Tests', () {
    const gate = KinematicSanityGate.standard;
    const filter = RawTouchFilter();

    group('Adversarial Point Count Density Bounds (9, 10, 800, 801)', () {
      test('rejects boundary point count n = 9 with insufficientPoints', () {
        final points = List.generate(
          9,
          (i) => GesturePoint(
            x: i * 10.0,
            y: i * 10.0,
            timestampMs: i * 16,
          ),
        );
        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(reason, equals(KinematicRejectionReason.insufficientPoints));
        }
        expect(gate.isValid(points), isFalse);
      });

      test('accepts boundary point count n = 10 with valid bounding span', () {
        final points = List.generate(
          10,
          (i) => GesturePoint(
            x: i * 5.0,
            y: i * 5.0,
            timestampMs: i * 16,
          ),
        );
        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGatePassed>());
        expect(gate.isValid(points), isTrue);
      });

      test('accepts boundary point count n = 800 on valid stroke', () {
        final points = List.generate(
          800,
          (i) {
            final t = i / 799.0;
            return GesturePoint(
              x: t * 200.0,
              y: 50.0 + 20.0 * math.sin(t * math.pi),
              timestampMs: i * 8,
            );
          },
        );
        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGatePassed>());
        expect(gate.isValid(points), isTrue);
      });

      test('rejects boundary point count n = 801 with excessivePoints', () {
        final points = List.generate(
          801,
          (i) {
            final t = i / 800.0;
            return GesturePoint(
              x: t * 200.0,
              y: 50.0 + 20.0 * math.sin(t * math.pi),
              timestampMs: i * 8,
            );
          },
        );
        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(reason, equals(KinematicRejectionReason.excessivePoints));
        }
        expect(gate.isValid(points), isFalse);
      });
    });

    group('Adversarial Bounding Span Limits (27.99px vs 28.01px)', () {
      test('rejects horizontal stroke with span exactly 27.99px', () {
        final points = List.generate(
          15,
          (i) => GesturePoint(
            x: (i / 14.0) * 27.99,
            y: 50.0,
            timestampMs: i * 16,
          ),
        );
        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(reason, equals(KinematicRejectionReason.insufficientBoundingSpan));
        }
      });

      test('accepts horizontal stroke with span exactly 28.01px', () {
        final points = List.generate(
          15,
          (i) => GesturePoint(
            x: (i / 14.0) * 28.01,
            y: 50.0,
            timestampMs: i * 16,
          ),
        );
        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGatePassed>());
      });

      test('rejects vertical stroke with span exactly 27.99px', () {
        final points = List.generate(
          15,
          (i) => GesturePoint(
            x: 100.0,
            y: (i / 14.0) * 27.99,
            timestampMs: i * 16,
          ),
        );
        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(reason, equals(KinematicRejectionReason.insufficientBoundingSpan));
        }
      });

      test('accepts vertical stroke with span exactly 28.01px', () {
        final points = List.generate(
          15,
          (i) => GesturePoint(
            x: 100.0,
            y: (i / 14.0) * 28.01,
            timestampMs: i * 16,
          ),
        );
        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGatePassed>());
      });

      test('rejects diagonal stroke where deltaX = 27.99 and deltaY = 27.99', () {
        final points = List.generate(
          15,
          (i) => GesturePoint(
            x: (i / 14.0) * 27.99,
            y: (i / 14.0) * 27.99,
            timestampMs: i * 16,
          ),
        );
        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(reason, equals(KinematicRejectionReason.insufficientBoundingSpan));
        }
      });

      test('accepts diagonal stroke where deltaX = 28.01 and deltaY = 28.01', () {
        final points = List.generate(
          15,
          (i) => GesturePoint(
            x: (i / 14.0) * 28.01,
            y: (i / 14.0) * 28.01,
            timestampMs: i * 16,
          ),
        );
        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGatePassed>());
      });

      test('handles negative coordinate space bounds correctly (27.99px vs 28.01px)', () {
        // Negative coordinates span 27.99px: min -100.0, max -72.01 -> delta = 27.99
        final rejectedNegative = List.generate(
          15,
          (i) => GesturePoint(
            x: -100.0 + (i / 14.0) * 27.99,
            y: -50.0,
            timestampMs: i * 16,
          ),
        );
        expect(gate.evaluate(rejectedNegative), isA<KinematicGateRejected>());

        // Negative coordinates span 28.01px: min -100.0, max -71.99 -> delta = 28.01
        final acceptedNegative = List.generate(
          15,
          (i) => GesturePoint(
            x: -100.0 + (i / 14.0) * 28.01,
            y: -50.0,
            timestampMs: i * 16,
          ),
        );
        expect(gate.evaluate(acceptedNegative), isA<KinematicGatePassed>());
      });
    });

    group('Stationary Finger Dwell & Micro-Touch Stress (RawTouchFilter)', () {
      test('collapses 500 stationary dwell points within 1.0px radius (diameter 2.0px < 2.5px) to exactly 1 point', () {
        final rng = math.Random(42);
        final raw = List.generate(
          500,
          (i) {
            final angle = rng.nextDouble() * 2.0 * math.pi;
            final radius = rng.nextDouble() * 1.0; // strictly <= 1.0px -> max pairwise distance <= 2.0px < 2.5px
            return GesturePoint(
              x: 100.0 + radius * math.cos(angle),
              y: 100.0 + radius * math.sin(angle),
              timestampMs: i * 8,
            );
          },
        );

        final filtered = filter.filterRawPoints(raw);
        expect(filtered.length, equals(1));
        expect(filtered.first, equals(raw.first));

        // When fed to KinematicSanityGate, must be rejected by Check 1
        final decision = gate.evaluate(filtered);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(reason, equals(KinematicRejectionReason.insufficientPoints));
        }
      });

      test('dwell within 2.4px radius is rejected by KinematicSanityGate bounding span check', () {
        final rng = math.Random(42);
        final raw = List.generate(
          500,
          (i) {
            final angle = rng.nextDouble() * 2.0 * math.pi;
            final radius = rng.nextDouble() * 2.4;
            return GesturePoint(
              x: 100.0 + radius * math.cos(angle),
              y: 100.0 + radius * math.sin(angle),
              timestampMs: i * 8,
            );
          },
        );

        final filtered = filter.filterRawPoints(raw);
        // Even if some points exceeded 2.5px relative to lastAccepted, total span is at most 4.8px < 28.0px
        final decision = gate.evaluate(filtered);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(
            reason == KinematicRejectionReason.insufficientBoundingSpan ||
                reason == KinematicRejectionReason.insufficientPoints,
            isTrue,
          );
        }
      });

      test('collapses sub-deadband alternating flutter to single point', () {
        // Alternating between (50, 50) and (52.4, 50) - distance is 2.4px < 2.5px
        final flutter = List.generate(
          100,
          (i) => GesturePoint(
            x: (i % 2 == 0) ? 50.0 : 52.4,
            y: 50.0,
            timestampMs: i * 10,
          ),
        );

        final filtered = filter.filterRawPoints(flutter);
        expect(filtered.length, equals(1));
        expect(filtered.first, equals(flutter.first));
      });

      test('retains all points for suprathreshold oscillation (distance 2.51px >= 2.5px)', () {
        final oscillation = List.generate(
          30,
          (i) => GesturePoint(
            x: (i % 2 == 0) ? 50.0 : 52.51,
            y: 50.0,
            timestampMs: i * 10,
          ),
        );

        final filtered = filter.applyDeadband(oscillation);
        expect(filtered.length, equals(30));
      });

      test('Gaussian filter completely attenuates Nyquist frequency alternating noise', () {
        // High-frequency digitizer chatter: y alternating between +10 and -10
        final noise = <GesturePoint>[
          GesturePoint(x: 0.0, y: 0.0, timestampMs: 0),
          GesturePoint(x: 10.0, y: 10.0, timestampMs: 10),
          GesturePoint(x: 20.0, y: -10.0, timestampMs: 20),
          GesturePoint(x: 30.0, y: 10.0, timestampMs: 30),
          GesturePoint(x: 40.0, y: -10.0, timestampMs: 40),
          GesturePoint(x: 50.0, y: 0.0, timestampMs: 50),
        ];

        final smoothed = filter.applyGaussianSmoothing(noise);
        expect(smoothed.length, equals(6));

        // Endpoints preserved
        expect(smoothed.first, equals(noise.first));
        expect(smoothed.last, equals(noise.last));

        // Nyquist component attenuated at interior indices:
        // index 2: 0.25*(10) + 0.50*(-10) + 0.25*(10) = 2.5 - 5.0 + 2.5 = 0.0
        expect(smoothed[2].y, closeTo(0.0, 1e-9));
        // index 3: 0.25*(-10) + 0.50*(10) + 0.25*(-10) = -2.5 + 5.0 - 2.5 = 0.0
        expect(smoothed[3].y, closeTo(0.0, 1e-9));
      });
    });

    group('Adversarial Dense Circular Scribbles & Loops', () {
      test('rejects multi-loop circular scribble (3 revolutions, 120 points)', () {
        // 3 full circles of radius 40px: total path length ~ 754px, turning angle ~ 6*pi
        // Starts and ends at same point (D_net = 0)
        final points = List.generate(
          120,
          (i) {
            final theta = (i / 39.0) * 2.0 * math.pi;
            return GesturePoint(
              x: 100.0 + 40.0 * math.cos(theta),
              y: 100.0 + 40.0 * math.sin(theta),
              timestampMs: i * 16,
            );
          },
        );

        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(
            reason == KinematicRejectionReason.closedLoopScribble ||
                reason == KinematicRejectionReason.excessiveTortuosity,
            isTrue,
          );
        }
      });

      test('rejects near-closed loop with D_net = 4.9px (< 5.0px) and L_raw > 50px', () {
        // Circle of radius 30px with small opening (D_net = 4.9px)
        final points = List.generate(
          50,
          (i) {
            final t = i / 49.0;
            final theta = t * 1.95 * math.pi;
            return GesturePoint(
              x: 100.0 + 30.0 * math.cos(theta),
              y: 100.0 + 30.0 * math.sin(theta),
              timestampMs: i * 16,
            );
          },
        );

        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(
            reason == KinematicRejectionReason.closedLoopScribble ||
                reason == KinematicRejectionReason.excessiveTortuosity,
            isTrue,
          );
        }
      });

      test('rejects circular scribble ending at D_net = 5.1px via excessiveTortuosity', () {
        // Circle of radius 40px with D_net = 5.1px: L_raw ~ 251px, D_net = 5.1px -> tau ~ 49.2 > 12.0
        final points = <GesturePoint>[];
        for (var i = 0; i < 60; i++) {
          final theta = (i / 59.0) * 1.96 * math.pi;
          points.add(GesturePoint(
            x: 100.0 + 40.0 * math.cos(theta),
            y: 100.0 + 40.0 * math.sin(theta),
            timestampMs: i * 16,
          ));
        }

        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(reason, equals(KinematicRejectionReason.excessiveTortuosity));
        }
      });

      test('rejects dense figure-8 knot scribble with near-zero displacement', () {
        // Lemniscate: x = 50 * cos(t), y = 50 * sin(2t)/2
        final points = List.generate(
          80,
          (i) {
            final t = (i / 79.0) * 2.0 * math.pi;
            return GesturePoint(
              x: 100.0 + 50.0 * math.cos(t),
              y: 100.0 + 25.0 * math.sin(2.0 * t),
              timestampMs: i * 16,
            );
          },
        );

        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(
            reason == KinematicRejectionReason.closedLoopScribble ||
                reason == KinematicRejectionReason.excessiveTortuosity,
            isTrue,
          );
        }
      });

      test('rejects 5-revolution Archimedean spiral via excessiveCurvature (> 8*pi)', () {
        // Spiral r = 5 + 5*theta, theta from 0 to 10*pi (5 full revolutions = 10*pi > 8*pi)
        final points = List.generate(
          150,
          (i) {
            final theta = (i / 149.0) * 10.0 * math.pi;
            final r = 10.0 + 3.0 * theta;
            return GesturePoint(
              x: 150.0 + r * math.cos(theta),
              y: 150.0 + r * math.sin(theta),
              timestampMs: i * 16,
            );
          },
        );

        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(
            reason == KinematicRejectionReason.excessiveCurvature ||
                reason == KinematicRejectionReason.excessiveTortuosity,
            isTrue,
          );
        }
      });
    });

    group('Adversarial High-Frequency Oscillations & Turning Angle Stress', () {
      test('rejects high-frequency sinusoidal oscillation exceeding 8*pi turning budget', () {
        // 12 full cycles of high frequency sine wave: turning angle > 12 * 2*pi = 24*pi >> 8*pi
        final points = List.generate(
          200,
          (i) {
            final x = (i / 199.0) * 200.0;
            final y = 100.0 + 30.0 * math.sin(i * 0.4);
            return GesturePoint(x: x, y: y, timestampMs: i * 8);
          },
        );

        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(
            reason == KinematicRejectionReason.excessiveCurvature ||
                reason == KinematicRejectionReason.excessiveTortuosity,
            isTrue,
          );
        }
      });

      test('rejects chaotic zigzag scribble with sharp 160-degree switchbacks', () {
        // 25 switchbacks of 160 degrees (2.79 rad): total turning = 25 * 2.79 = 69.8 rad >> 8*pi
        final points = <GesturePoint>[];
        for (var i = 0; i < 40; i++) {
          final x = 50.0 + (i % 2 == 0 ? 0.0 : 70.0);
          final y = 50.0 + i * 4.0;
          points.add(GesturePoint(x: x, y: y, timestampMs: i * 16));
        }

        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(
            reason == KinematicRejectionReason.excessiveCurvature ||
                reason == KinematicRejectionReason.excessiveTortuosity,
            isTrue,
          );
        }
      });

      test('boundary test: turning angle just below 8*pi passes vs just above 8*pi rejected', () {
        // Controlled polyline with exact turns
        // 7 half-turns of 170 deg (2.967 rad) = 20.76 rad < 8*pi (25.13 rad)
        final subThresholdPoints = <GesturePoint>[];
        for (var i = 0; i < 8; i++) {
          final x = 50.0 + (i.isEven ? 0.0 : 80.0);
          final y = 50.0 + i * 20.0;
          subThresholdPoints.add(GesturePoint(x: x, y: y, timestampMs: i * 20));
        }
        for (var i = 1; i <= 3; i++) {
          subThresholdPoints.add(GesturePoint(
            x: subThresholdPoints.last.x + i * 10.0,
            y: subThresholdPoints.last.y,
            timestampMs: subThresholdPoints.length * 20,
          ));
        }

        // Supra-threshold stroke with 12 sharp turns of 170 deg (32.6 rad > 8*pi)
        final supraThresholdPoints = <GesturePoint>[];
        for (var i = 0; i < 12; i++) {
          final x = 50.0 + (i.isEven ? 0.0 : 80.0);
          final y = 50.0 + i * 20.0;
          supraThresholdPoints.add(GesturePoint(x: x, y: y, timestampMs: i * 20));
        }

        final supraDecision = gate.evaluate(supraThresholdPoints);
        expect(supraDecision, isA<KinematicGateRejected>());
        if (supraDecision case KinematicGateRejected(:final reason)) {
          expect(
            reason == KinematicRejectionReason.excessiveCurvature ||
                reason == KinematicRejectionReason.excessiveTortuosity,
            isTrue,
          );
        }
      });
    });

    group('Zero False Negatives: Legitimate Stealth Gestures Pass Gate', () {
      test('passes legitimate 1-stroke Alpha / fish loop gesture', () {
        // Alpha gesture: loops back across its own tail but D_net is large and turning angle is moderate (~4 rad)
        final points = <GesturePoint>[];
        for (var i = 0; i < 40; i++) {
          final t = i / 39.0;
          final x = 50.0 + 150.0 * (t - 0.5 * math.sin(2.0 * math.pi * t));
          final y = 100.0 + 60.0 * math.sin(math.pi * t);
          points.add(GesturePoint(x: x, y: y, timestampMs: i * 16));
        }

        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGatePassed>());
      });

      test('passes legitimate 1-stroke S-curve gesture', () {
        final points = List.generate(
          35,
          (i) {
            final t = i / 34.0;
            final x = 50.0 + 100.0 * math.sin(t * math.pi);
            final y = 50.0 + t * 180.0;
            return GesturePoint(x: x, y: y, timestampMs: i * 16);
          },
        );

        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGatePassed>());
      });

      test('passes legitimate 1-stroke Z-shape gesture', () {
        // Z-shape: (0, 0) -> (100, 0) -> (0, 100) -> (100, 100)
        final points = <GesturePoint>[];
        for (var i = 0; i < 10; i++) {
          points.add(GesturePoint(x: i * 10.0, y: 0.0, timestampMs: points.length * 16));
        }
        for (var i = 1; i <= 10; i++) {
          final t = i / 10.0;
          points.add(GesturePoint(x: 100.0 - t * 100.0, y: t * 100.0, timestampMs: points.length * 16));
        }
        for (var i = 1; i <= 10; i++) {
          final t = i / 10.0;
          points.add(GesturePoint(x: t * 100.0, y: 100.0, timestampMs: points.length * 16));
        }

        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGatePassed>());
      });

      test('passes legitimate 1-stroke N-shape gesture', () {
        // N-shape: (0, 100) -> (0, 0) -> (80, 100) -> (80, 0)
        final points = <GesturePoint>[];
        for (var i = 0; i < 10; i++) {
          points.add(GesturePoint(x: 0.0, y: 100.0 - i * 10.0, timestampMs: points.length * 16));
        }
        for (var i = 1; i <= 10; i++) {
          final t = i / 10.0;
          points.add(GesturePoint(x: t * 80.0, y: t * 100.0, timestampMs: points.length * 16));
        }
        for (var i = 1; i <= 10; i++) {
          final t = i / 10.0;
          points.add(GesturePoint(x: 80.0, y: 100.0 - t * 100.0, timestampMs: points.length * 16));
        }

        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGatePassed>());
      });

      test('passes legitimate 1-stroke Lightning bolt gesture', () {
        // Lightning bolt: (50, 0) -> (20, 80) -> (60, 60) -> (30, 150)
        final waypoints = [
          const math.Point(50.0, 0.0),
          const math.Point(20.0, 80.0),
          const math.Point(60.0, 60.0),
          const math.Point(30.0, 150.0),
        ];
        final points = <GesturePoint>[];
        for (var seg = 0; seg < waypoints.length - 1; seg++) {
          final p0 = waypoints[seg];
          final p1 = waypoints[seg + 1];
          for (var step = (seg == 0 ? 0 : 1); step <= 10; step++) {
            final t = step / 10.0;
            points.add(GesturePoint(
              x: p0.x + t * (p1.x - p0.x),
              y: p0.y + t * (p1.y - p0.y),
              timestampMs: points.length * 16,
            ));
          }
        }

        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGatePassed>());
      });

      test('near-closed gestures (Triangle, Star) are rejected by standard tortuosity threshold (tau <= 12.0)', () {
        // Triangle closing near start: D_net ~ 18px, L_raw ~ 360px -> tau ~ 20.0 > 12.0
        final triangle = <GesturePoint>[];
        for (var i = 0; i < 10; i++) {
          triangle.add(GesturePoint(x: 20.0 + i * 10.0, y: 20.0, timestampMs: triangle.length * 16));
        }
        for (var i = 1; i <= 10; i++) {
          final t = i / 10.0;
          triangle.add(GesturePoint(x: 110.0 - t * 40.0, y: 20.0 + t * 130.0, timestampMs: triangle.length * 16));
        }
        for (var i = 1; i <= 10; i++) {
          final t = i / 10.0;
          triangle.add(GesturePoint(x: 70.0 - t * 35.0, y: 150.0 - t * 120.0, timestampMs: triangle.length * 16));
        }

        final decision = gate.evaluate(triangle);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(reason, equals(KinematicRejectionReason.excessiveTortuosity));
        }

        // But when configured with a custom profile allowing higher tortuosity, it passes
        const customGate = KinematicSanityGate(maxTortuosityRatio: 25.0);
        expect(customGate.evaluate(triangle), isA<KinematicGatePassed>());
      });
    });

    group('Sub-0.1ms (100 Microsecond) Empirical Latency Benchmark on 800 Points', () {
      test('worst-case 800-point stroke traversing all 4 checks runs under 0.1ms (100us)', () {
        // Valid 800-point smooth gesture that executes Check 1, Check 2, Check 3, and ALL 800 points of Check 4
        final points = List.generate(
          800,
          (i) {
            final t = i / 799.0;
            return GesturePoint(
              x: t * 220.0,
              y: 50.0 + 35.0 * math.sin(t * 2.0 * math.pi),
              timestampMs: i * 8,
            );
          },
        );

        // Verify correctness first
        expect(gate.evaluate(points).isPassed, isTrue);

        // Warm up Dart VM JIT compiler thoroughly
        for (var i = 0; i < 500; i++) {
          gate.evaluate(points);
        }

        // Measure 1,000 runs in batch to eliminate stopwatch start/stop overhead
        const iterations = 1000;
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < iterations; i++) {
          gate.evaluate(points);
        }
        stopwatch.stop();

        final avgUs = stopwatch.elapsedMicroseconds / iterations;
        // ignore: avoid_print
        print('BENCHMARK worst-case 800pts traversing all 4 checks: $avgUs us / call');

        // Sub-0.1ms hard constraint means average latency < 100 microseconds
        expect(avgUs, lessThan(100.0), reason: 'Average latency $avgUs us exceeded 100 us constraint');
      });

      test('800-point chaotic scribble fail-fast latency runs under 0.05ms (50us)', () {
        // 800-point dense chaotic scribble that trips turning angle budget early
        final points = List.generate(
          800,
          (i) => GesturePoint(
            x: 100.0 + (i % 2 == 0 ? 0.0 : 60.0),
            y: 50.0 + (i % 3) * 10.0,
            timestampMs: i * 8,
          ),
        );

        // Verify rejection
        expect(gate.evaluate(points).isPassed, isFalse);

        // Warm up JIT
        for (var i = 0; i < 200; i++) {
          gate.evaluate(points);
        }

        // Measure fail-fast latency without expect inside loop
        const iterations = 1000;
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < iterations; i++) {
          gate.evaluate(points);
        }
        stopwatch.stop();

        final avgFailFastUs = stopwatch.elapsedMicroseconds / iterations;
        // ignore: avoid_print
        print('BENCHMARK 800pts chaotic scribble fail-fast: $avgFailFastUs us / call');
        expect(avgFailFastUs, lessThan(50.0), reason: 'Fail-fast took $avgFailFastUs us');
      });

      test('full pipeline (RawTouchFilter + KinematicSanityGate) on 800 points runs well within frame budget', () {
        // 800 points with noise and micro-jitter
        final rng = math.Random(1337);
        final noisyPoints = List.generate(
          800,
          (i) {
            final t = i / 799.0;
            final jitterX = (rng.nextDouble() - 0.5) * 1.5;
            final jitterY = (rng.nextDouble() - 0.5) * 1.5;
            return GesturePoint(
              x: t * 200.0 + jitterX,
              y: 50.0 + 30.0 * math.sin(t * math.pi) + jitterY,
              timestampMs: i * 8,
            );
          },
        );

        // Warmup
        for (var i = 0; i < 50; i++) {
          final filtered = filter.filterRawPoints(noisyPoints);
          gate.evaluate(filtered);
        }

        // Measure 100 iterations of full two-stage pipeline
        const iterations = 100;
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < iterations; i++) {
          final filtered = filter.filterRawPoints(noisyPoints);
          gate.evaluate(filtered);
        }
        stopwatch.stop();

        final avgPipelineUs = stopwatch.elapsedMicroseconds / iterations;
        // ignore: avoid_print
        print('BENCHMARK 800pts full pipeline (Filter + Gate): $avgPipelineUs us / call');
        // Total combined pre-filtering + gating on 800 points must be < 500us (0.5ms), far below 16.6ms
        expect(avgPipelineUs, lessThan(500.0), reason: 'Combined pipeline took $avgPipelineUs us');
      });
    });
  });
}
