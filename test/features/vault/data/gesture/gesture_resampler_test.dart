import 'dart:isolate';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/gesture/gesture_resampler.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';

void main() {
  group('GestureResampler', () {
    group('Invariants & Boundary Conditions', () {
      test('throws FormatException when input has fewer than 2 points', () {
        expect(() => GestureResampler.resample([]), throwsFormatException);
        expect(
          () => GestureResampler.resample([
            GesturePoint(x: 10.0, y: 10.0, timestampMs: 100),
          ]),
          throwsFormatException,
        );
      });

      test('throws FormatException when targetCount is less than 2', () {
        final points = [
          GesturePoint(x: 0.0, y: 0.0, timestampMs: 100),
          GesturePoint(x: 10.0, y: 10.0, timestampMs: 116),
        ];
        expect(
          () => GestureResampler.resample(points, targetCount: 1),
          throwsFormatException,
        );
        expect(
          () => GestureResampler.resample(points, targetCount: 0),
          throwsFormatException,
        );
      });

      test('throws FormatException on zero or non-positive cumulative path length', () {
        final points = List.generate(
          10,
          (i) => GesturePoint(x: 50.0, y: 50.0, timestampMs: i * 16),
        );
        expect(() => GestureResampler.resample(points), throwsFormatException);
      });
    });

    group('Output Count Invariant (Exact N = 64)', () {
      test('resamples 2-point stroke to exactly 64 points', () {
        final points = [
          GesturePoint(x: 0.0, y: 0.0, timestampMs: 0),
          GesturePoint(x: 100.0, y: 100.0, timestampMs: 500),
        ];

        final resampled = GestureResampler.resample(points);
        expect(resampled.length, equals(64));
      });

      test('resamples strokes across diverse input sizes (3, 10, 50, 100, 800) to exactly 64', () {
        for (final inputSize in [3, 10, 50, 100, 500, 800]) {
          final points = List.generate(
            inputSize,
            (i) {
              final t = i / (inputSize - 1);
              return GesturePoint(
                x: t * 150.0,
                y: 50.0 + 30.0 * math.sin(t * math.pi * 2),
                timestampMs: i * 10,
              );
            },
          );

          final resampled = GestureResampler.resample(points);
          expect(resampled.length, equals(64),
              reason: 'Failed for input size $inputSize');
        }
      });

      test('supports custom target counts (16, 32, 128)', () {
        final points = [
          GesturePoint(x: 0.0, y: 0.0, timestampMs: 0),
          GesturePoint(x: 200.0, y: 100.0, timestampMs: 300),
        ];

        for (final target in [16, 32, 128]) {
          final resampled = GestureResampler.resample(points, targetCount: target);
          expect(resampled.length, equals(target));
        }
      });
    });

    group('Endpoint Preservation', () {
      test('strictly preserves start point P_1 and end point P_n', () {
        final points = [
          GesturePoint(x: 12.34, y: 56.78, timestampMs: 100),
          GesturePoint(x: 50.0, y: 80.0, timestampMs: 150),
          GesturePoint(x: 98.76, y: 54.32, timestampMs: 200),
        ];

        final resampled = GestureResampler.resample(points);
        expect(resampled.first.x, closeTo(points.first.x, 1e-9));
        expect(resampled.first.y, closeTo(points.first.y, 1e-9));
        expect(resampled.last.x, closeTo(points.last.x, 1e-9));
        expect(resampled.last.y, closeTo(points.last.y, 1e-9));
      });
    });

    group('Equidistant Spatial Distribution', () {
      test('produces exactly uniform 10px intervals on a 630px straight line', () {
        final points = [
          GesturePoint(x: 0.0, y: 0.0, timestampMs: 0),
          GesturePoint(x: 100.0, y: 0.0, timestampMs: 100),
          GesturePoint(x: 400.0, y: 0.0, timestampMs: 200),
          GesturePoint(x: 630.0, y: 0.0, timestampMs: 300),
        ];

        final resampled = GestureResampler.resample(points);
        expect(resampled.length, equals(64));

        for (var i = 0; i < 64; i++) {
          final expectedX = i * 10.0;
          expect(resampled[i].x, closeTo(expectedX, 1e-6));
          expect(resampled[i].y, closeTo(0.0, 1e-6));
        }

        for (var i = 0; i < 63; i++) {
          final dx = resampled[i + 1].x - resampled[i].x;
          final dy = resampled[i + 1].y - resampled[i].y;
          final dist = math.sqrt(dx * dx + dy * dy);
          expect(dist, closeTo(10.0, 1e-6));
        }
      });

      test('converts non-uniform drawing speed (slow start, fast end) to uniform spacing', () {
        final points = <GesturePoint>[];
        for (var i = 0; i < 20; i++) {
          points.add(GesturePoint(x: i * 1.0, y: 0.0, timestampMs: i * 10));
        }
        for (var i = 1; i <= 5; i++) {
          points.add(GesturePoint(x: 20.0 + i * 40.0, y: 0.0, timestampMs: 200 + i * 10));
        }

        final resampled = GestureResampler.resample(points);
        expect(resampled.length, equals(64));

        final expectedInterval = 220.0 / 63.0;
        for (var i = 0; i < 63; i++) {
          final dist = resampled[i + 1].x - resampled[i].x;
          expect(dist, closeTo(expectedInterval, 1e-5));
        }
      });
    });

    group('Timestamps & Properties', () {
      test('interpolates monotonic non-decreasing timestamps', () {
        final points = [
          GesturePoint(x: 0.0, y: 0.0, timestampMs: 100),
          GesturePoint(x: 200.0, y: 0.0, timestampMs: 500),
        ];

        final resampled = GestureResampler.resample(points);
        expect(resampled.first.timestampMs, equals(100));
        expect(resampled.last.timestampMs, equals(500));

        for (var i = 1; i < resampled.length; i++) {
          expect(resampled[i].timestampMs, greaterThanOrEqualTo(resampled[i - 1].timestampMs));
        }
      });

      test('returns unmodifiable list', () {
        final points = [
          GesturePoint(x: 0.0, y: 0.0, timestampMs: 0),
          GesturePoint(x: 100.0, y: 0.0, timestampMs: 100),
        ];

        final resampled = GestureResampler.resample(points);
        expect(
          () => resampled.add(GesturePoint(x: 0, y: 0, timestampMs: 0)),
          throwsUnsupportedError,
        );
      });

      test('skips consecutive duplicate points without division by zero', () {
        final points = [
          GesturePoint(x: 0.0, y: 0.0, timestampMs: 0),
          GesturePoint(x: 50.0, y: 50.0, timestampMs: 50),
          GesturePoint(x: 50.0, y: 50.0, timestampMs: 60),
          GesturePoint(x: 100.0, y: 100.0, timestampMs: 100),
        ];

        final resampled = GestureResampler.resample(points);
        expect(resampled.length, equals(64));
      });

      test('computePathLength calculates accurate polyline length', () {
        final points = [
          GesturePoint(x: 0.0, y: 0.0, timestampMs: 0),
          GesturePoint(x: 3.0, y: 4.0, timestampMs: 10),
          GesturePoint(x: 3.0, y: 0.0, timestampMs: 20),
        ];

        expect(GestureResampler.computePathLength(points), closeTo(9.0, 1e-9));
      });

      test('is thread-safe and re-entrant inside Isolate.run', () async {
        final points = [
          GesturePoint(x: 0.0, y: 0.0, timestampMs: 0),
          GesturePoint(x: 150.0, y: 80.0, timestampMs: 200),
        ];

        final result = await Isolate.run(() {
          return GestureResampler.resample(points);
        });

        expect(result.length, equals(64));
      });
    });
  });
}
