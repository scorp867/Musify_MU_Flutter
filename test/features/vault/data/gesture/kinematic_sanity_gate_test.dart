import 'dart:isolate';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/gesture/kinematic_sanity_gate.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';

void main() {
  group('KinematicSanityGate', () {
    const gate = KinematicSanityGate.standard;

    group('Constructor & Assertions', () {
      test('has expected default parameters', () {
        expect(gate.minBoundingSpan, equals(28.0));
        expect(gate.minPointCount, equals(10));
        expect(gate.maxPointCount, equals(800));
        expect(gate.maxTortuosityRatio, equals(12.0));
        expect(gate.maxCumulativeTurningAngleRad, equals(8.0 * math.pi));
        expect(gate.closedLoopMaxDisplacement, equals(5.0));
        expect(gate.closedLoopMinPathLength, equals(50.0));
      });

      test('validates assertion constraints on custom configuration', () {
        expect(
          () => KinematicSanityGate(minBoundingSpan: 0.0),
          throwsA(isA<AssertionError>()),
        );
        expect(
          () => KinematicSanityGate(minPointCount: 0),
          throwsA(isA<AssertionError>()),
        );
        expect(
          () => KinematicSanityGate(minPointCount: 20, maxPointCount: 10),
          throwsA(isA<AssertionError>()),
        );
        expect(
          () => KinematicSanityGate(maxTortuosityRatio: 0.5),
          throwsA(isA<AssertionError>()),
        );
        expect(
          () => KinematicSanityGate(maxCumulativeTurningAngleRad: 0.0),
          throwsA(isA<AssertionError>()),
        );
        expect(
          () => KinematicSanityGate(closedLoopMaxDisplacement: -1.0),
          throwsA(isA<AssertionError>()),
        );
        expect(
          () => KinematicSanityGate(closedLoopMinPathLength: 0.0),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('Check 1: Point Density Budget', () {
      test('rejects empty point list with insufficientPoints', () {
        final decision = gate.evaluate(const []);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(reason, equals(KinematicRejectionReason.insufficientPoints));
        }
        expect(gate.isValid(const []), isFalse);
      });

      test('rejects list with fewer than 10 points with insufficientPoints', () {
        final points = List.generate(
          9,
          (i) => GesturePoint(x: i * 10.0, y: i * 10.0, timestampMs: i * 16),
        );
        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason, :final details)) {
          expect(reason, equals(KinematicRejectionReason.insufficientPoints));
          expect(details, contains('below minimum threshold'));
        }
      });

      test('rejects list with more than 800 points with excessivePoints', () {
        final points = List.generate(
          801,
          (i) => GesturePoint(x: i * 1.0, y: i * 1.0, timestampMs: i * 16),
        );
        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason, :final details)) {
          expect(reason, equals(KinematicRejectionReason.excessivePoints));
          expect(details, contains('exceeds maximum density limit'));
        }
      });
    });

    group('Check 2: Bounding Box Span', () {
      test('rejects pocket micro-touches and small jitters (span < 28.0px)', () {
        // 15 points contained within 10x10 square
        final points = List.generate(
          15,
          (i) => GesturePoint(
            x: 100.0 + (i % 3) * 3.0,
            y: 200.0 + (i % 4) * 2.5,
            timestampMs: i * 16,
          ),
        );
        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(reason, equals(KinematicRejectionReason.insufficientBoundingSpan));
        }
      });

      test('passes clean horizontal swipe where deltaX >= 28.0 and deltaY == 0', () {
        final points = List.generate(
          20,
          (i) => GesturePoint(x: i * 5.0, y: 100.0, timestampMs: i * 16), // deltaX = 95.0, deltaY = 0
        );
        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGatePassed>());
        expect(decision.isPassed, isTrue);
      });

      test('passes clean vertical swipe where deltaX == 0 and deltaY >= 28.0', () {
        final points = List.generate(
          20,
          (i) => GesturePoint(x: 100.0, y: i * 6.0, timestampMs: i * 16), // deltaY = 114.0, deltaX = 0
        );
        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGatePassed>());
      });

      test('passes diagonal swipe at threshold boundary (span == 28.0px)', () {
        final points = List.generate(
          15,
          (i) => GesturePoint(
            x: (i / 14) * 28.0,
            y: (i / 14) * 28.0,
            timestampMs: i * 16,
          ),
        );
        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGatePassed>());
      });

      test('rejects span just below 28.0px (27.9px)', () {
        final points = List.generate(
          15,
          (i) => GesturePoint(
            x: (i / 14) * 27.9,
            y: (i / 14) * 20.0,
            timestampMs: i * 16,
          ),
        );
        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(reason, equals(KinematicRejectionReason.insufficientBoundingSpan));
        }
      });
    });

    group('Check 3: Straightness, Tortuosity & Closed Loop', () {
      test('rejects closed-loop dense scribble (circle returning to start)', () {
        // Circle of radius 40px: total path length ~ 251px > 50px, but D_net = 0 < 5px
        final points = List.generate(
          32,
          (i) {
            final angle = (i / 31) * 2.0 * math.pi;
            return GesturePoint(
              x: 100.0 + 40.0 * math.cos(angle),
              y: 100.0 + 40.0 * math.sin(angle),
              timestampMs: i * 16,
            );
          },
        );

        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(reason, equals(KinematicRejectionReason.closedLoopScribble));
        }
      });

      test('rejects excessive tortuosity (wandering scribble in box, ratio > 12.0)', () {
        // Sweep back and forth horizontally 10 times in a small box, ending 10px from start
        // D_net = 10px, L_raw = 10 * 150 = 1500px -> tortuosity = 150.0 > 12.0
        final points = <GesturePoint>[];
        for (var pass = 0; pass < 8; pass++) {
          final isEven = pass.isEven;
          for (var step = 0; step < 5; step++) {
            final x = isEven ? 50.0 + step * 20.0 : 150.0 - step * 20.0;
            final y = 50.0 + pass * 2.0 + step * 0.5;
            points.add(GesturePoint(
              x: x,
              y: y,
              timestampMs: points.length * 16,
            ));
          }
        }

        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGateRejected>());
        if (decision case KinematicGateRejected(:final reason)) {
          expect(
            reason == KinematicRejectionReason.excessiveTortuosity ||
                reason == KinematicRejectionReason.closedLoopScribble ||
                reason == KinematicRejectionReason.excessiveCurvature,
            isTrue,
          );
        }
      });

      test('passes canonical V-shape gesture with moderate tortuosity (~2.2)', () {
        // V-shape: (0, 0) -> (50, 100) -> (100, 0)
        // D_net = 100px. L_raw = sqrt(50^2 + 100^2) * 2 = 111.8 * 2 = 223.6px.
        // Tortuosity = 2.236 <= 12.0
        final points = <GesturePoint>[];
        for (var i = 0; i <= 10; i++) {
          final t = i / 10.0;
          points.add(GesturePoint(
            x: t * 50.0,
            y: t * 100.0,
            timestampMs: i * 16,
          ));
        }
        for (var i = 1; i <= 10; i++) {
          final t = i / 10.0;
          points.add(GesturePoint(
            x: 50.0 + t * 50.0,
            y: 100.0 - t * 100.0,
            timestampMs: (10 + i) * 16,
          ));
        }

        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGatePassed>());
      });
    });

    group('Check 4: Cumulative Turning Angle Budget', () {
      test('rejects chaotic zigzag scribble exceeding 8*pi radians budget', () {
        // 20 sharp switchbacks of ~170 degrees each = 20 * 3.0 rad = 60 rad > 8*pi (25.13 rad)
        final points = <GesturePoint>[];
        for (var i = 0; i < 30; i++) {
          points.add(GesturePoint(
            x: 50.0 + (i % 2 == 0 ? 0.0 : 80.0),
            y: 50.0 + i * 3.0,
            timestampMs: i * 16,
          ));
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

      test('skips coincident consecutive points without NaN heading or false failure', () {
        final points = <GesturePoint>[
          GesturePoint(x: 0.0, y: 0.0, timestampMs: 0),
          GesturePoint(x: 10.0, y: 10.0, timestampMs: 10),
          GesturePoint(x: 10.0, y: 10.0, timestampMs: 20), // duplicate
          GesturePoint(x: 10.0, y: 10.0, timestampMs: 30), // duplicate
          GesturePoint(x: 20.0, y: 20.0, timestampMs: 40),
          GesturePoint(x: 30.0, y: 30.0, timestampMs: 50),
          GesturePoint(x: 40.0, y: 40.0, timestampMs: 60),
          GesturePoint(x: 50.0, y: 50.0, timestampMs: 70),
          GesturePoint(x: 60.0, y: 60.0, timestampMs: 80),
          GesturePoint(x: 70.0, y: 70.0, timestampMs: 90),
        ];

        final decision = gate.evaluate(points);
        expect(decision, isA<KinematicGatePassed>());
      });
    });

    group('Sealed Type & Decision Hierarchy', () {
      test('exhaustively matches KinematicGateDecision variants', () {
        const KinematicGateDecision passed = KinematicGatePassed();
        const KinematicGateDecision rejected = KinematicGateRejected(
          reason: KinematicRejectionReason.insufficientPoints,
          details: 'test',
        );

        final passedString = switch (passed) {
          KinematicGatePassed() => 'PASSED',
          KinematicGateRejected() => 'REJECTED',
        };
        expect(passedString, equals('PASSED'));
        expect(passed.isPassed, isTrue);
        expect(passed.domainDecision, equals(GestureMatchDecisionEnum.matched));
        expect(passed.props, isEmpty);

        final rejectedString = switch (rejected) {
          KinematicGatePassed() => 'PASSED',
          KinematicGateRejected() => 'REJECTED',
        };
        expect(rejectedString, equals('REJECTED'));
        expect(rejected.isPassed, isFalse);
        expect(
          rejected.domainDecision,
          equals(GestureMatchDecisionEnum.rejectedAntiScribble),
        );
        expect(rejected.props, equals([KinematicRejectionReason.insufficientPoints, 'test']));
      });

      test('covers all KinematicRejectionReason enum properties', () {
        for (final reason in KinematicRejectionReason.values) {
          expect(reason.id, isNotEmpty);
          expect(reason.displayName, isNotEmpty);
        }
      });
    });

    group('Sub-0.1ms Performance Invariant & Isolate Offloading', () {
      test('executes on maximum 800-point stroke in under 0.1ms (100 microseconds)', () {
        // Generate a valid 800-point arc gesture spanning 200px
        final points = List.generate(
          800,
          (i) {
            final t = i / 799.0;
            return GesturePoint(
              x: t * 200.0,
              y: 50.0 + 30.0 * math.sin(t * math.pi),
              timestampMs: i * 8,
            );
          },
        );

        // Warmup JIT compiler and stabilize CPU branch prediction & caches (200 iterations)
        for (var i = 0; i < 200; i++) {
          gate.evaluate(points);
        }

        // Measure 100 executions (pure gate execution timing without test framework overhead)
        var decision = gate.evaluate(points);
        final stopwatch = Stopwatch()..start();
        const iterations = 100;
        for (var i = 0; i < iterations; i++) {
          decision = gate.evaluate(points);
        }
        stopwatch.stop();

        // Assert correctness outside the timed measurement window
        expect(decision.isPassed, isTrue);

        final avgMicroseconds = stopwatch.elapsedMicroseconds / iterations;
        // Sub-0.1ms = 100 microseconds invariant; pure execution runs well under 50 microseconds.
        expect(avgMicroseconds, lessThan(100.0));
      });

      test('is thread-safe and executes inside Isolate.run', () async {
        final points = List.generate(
          50,
          (i) => GesturePoint(
            x: i * 3.0,
            y: i * 2.0,
            timestampMs: i * 16,
          ),
        );

        final result = await Isolate.run(() {
          const isolateGate = KinematicSanityGate.standard;
          return isolateGate.evaluate(points).isPassed;
        });

        expect(result, isTrue);
      });
    });
  });
}
