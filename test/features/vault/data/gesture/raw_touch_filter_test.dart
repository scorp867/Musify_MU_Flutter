import 'dart:isolate';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/gesture/raw_touch_filter.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';

void main() {
  group('RawTouchFilter', () {
    const filter = RawTouchFilter();

    group('Constants & Configuration', () {
      test('has expected default deadband threshold and kernel weights', () {
        expect(RawTouchFilter.defaultDeadbandThreshold, equals(2.5));
        expect(RawTouchFilter.kernelWeightLeft, equals(0.25));
        expect(RawTouchFilter.kernelWeightCenter, equals(0.50));
        expect(RawTouchFilter.kernelWeightRight, equals(0.25));
        expect(
          RawTouchFilter.kernelWeightLeft +
              RawTouchFilter.kernelWeightCenter +
              RawTouchFilter.kernelWeightRight,
          equals(1.0),
        );
      });
    });

    group('applyDeadband', () {
      test('returns empty unmodifiable list on empty input', () {
        final result = filter.applyDeadband(const []);
        expect(result, isEmpty);
        expect(
          () => result.add(GesturePoint(x: 0, y: 0, timestampMs: 0)),
          throwsUnsupportedError,
        );
      });

      test('returns single point list unmodifiable on single point input', () {
        final point = GesturePoint(x: 10.0, y: 20.0, timestampMs: 100);
        final result = filter.applyDeadband([point]);
        expect(result.length, equals(1));
        expect(result.first, equals(point));
      });

      test('preserves two points if distance is at least 2.5px', () {
        final p1 = GesturePoint(x: 0.0, y: 0.0, timestampMs: 100);
        final p2 = GesturePoint(x: 2.5, y: 0.0, timestampMs: 116);
        final result = filter.applyDeadband([p1, p2]);

        expect(result.length, equals(2));
        expect(result[0], equals(p1));
        expect(result[1], equals(p2));
      });

      test('drops sub-deadband second point if distance is under 2.5px', () {
        final p1 = GesturePoint(x: 0.0, y: 0.0, timestampMs: 100);
        final p2 = GesturePoint(x: 1.0, y: 1.0, timestampMs: 116);
        final result = filter.applyDeadband([p1, p2]);

        expect(result.length, equals(1));
        expect(result.first, equals(p1));
      });

      test('filters relative to last accepted point rather than previous raw point', () {
        final p0 = GesturePoint(x: 0.0, y: 0.0, timestampMs: 100);
        final p1 = GesturePoint(x: 1.0, y: 0.0, timestampMs: 110);
        final p2 = GesturePoint(x: 2.0, y: 0.0, timestampMs: 120);
        final p3 = GesturePoint(x: 3.0, y: 0.0, timestampMs: 130);

        final result = filter.applyDeadband([p0, p1, p2, p3]);
        expect(result.length, equals(2));
        expect(result[0], equals(p0));
        expect(result[1], equals(p3));
      });

      test('eliminates stationary dwell chatter (50 points in 1.2px radius)', () {
        final points = List.generate(
          50,
          (i) => GesturePoint(
            x: 10.0 + (i % 3) * 0.3,
            y: 20.0 + (i % 2) * 0.4,
            timestampMs: 100 + i * 16,
          ),
        );

        final result = filter.applyDeadband(points);
        expect(result.length, equals(1));
        expect(result.first, equals(points.first));
      });

      test('preserves terminal point coordinates for multi-point strokes', () {
        final p1 = GesturePoint(x: 0.0, y: 0.0, timestampMs: 100);
        final p2 = GesturePoint(x: 10.0, y: 0.0, timestampMs: 116);
        final p3 = GesturePoint(x: 20.0, y: 0.0, timestampMs: 132);
        final p4 = GesturePoint(x: 21.0, y: 0.0, timestampMs: 148);

        final result = filter.applyDeadband([p1, p2, p3, p4]);
        expect(result.length, equals(3));
        expect(result[0], equals(p1));
        expect(result[1], equals(p2));
        expect(result[2], equals(p4));
      });

      test('retains all points for high velocity stroke (> 10px spacing)', () {
        final points = List.generate(
          10,
          (i) => GesturePoint(
            x: i * 15.0,
            y: i * 10.0,
            timestampMs: 100 + i * 16,
          ),
        );

        final result = filter.applyDeadband(points);
        expect(result.length, equals(10));
        for (var i = 0; i < points.length; i++) {
          expect(result[i], equals(points[i]));
        }
      });

      test('throws FormatException on non-positive or non-finite deadbandThreshold', () {
        final points = [GesturePoint(x: 0, y: 0, timestampMs: 0)];
        expect(() => filter.applyDeadband(points, deadbandThreshold: 0.0), throwsFormatException);
        expect(() => filter.applyDeadband(points, deadbandThreshold: -1.0), throwsFormatException);
        expect(() => filter.applyDeadband(points, deadbandThreshold: double.nan), throwsFormatException);
        expect(() => filter.applyDeadband(points, deadbandThreshold: double.infinity), throwsFormatException);
      });

      test('throws FormatException on non-finite point coordinates in applyDeadband', () {
        expect(
          () => filter.applyDeadband([
            const GesturePoint.constant(x: double.nan, y: 10.0, timestampMs: 0),
          ]),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('RawTouchFilter point coordinates must be finite, got: (NaN, 10.0)'),
            ),
          ),
        );

        expect(
          () => filter.applyDeadband([
            const GesturePoint.constant(x: 10.0, y: double.infinity, timestampMs: 0),
          ]),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('RawTouchFilter point coordinates must be finite, got: (10.0, Infinity)'),
            ),
          ),
        );

        expect(
          () => filter.applyDeadband([
            const GesturePoint.constant(x: 0.0, y: 0.0, timestampMs: 0),
            const GesturePoint.constant(x: double.negativeInfinity, y: 5.0, timestampMs: 16),
            const GesturePoint.constant(x: 10.0, y: 10.0, timestampMs: 32),
          ]),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('RawTouchFilter point coordinates must be finite, got: (-Infinity, 5.0)'),
            ),
          ),
        );
      });
    });

    group('applyGaussianSmoothing', () {
      test('returns empty unmodifiable list on empty input', () {
        final result = filter.applyGaussianSmoothing(const []);
        expect(result, isEmpty);
      });

      test('returns 1 or 2 points unmodified', () {
        final p1 = GesturePoint(x: 5.0, y: 10.0, timestampMs: 100);
        final p2 = GesturePoint(x: 15.0, y: 20.0, timestampMs: 116);

        expect(filter.applyGaussianSmoothing([p1]), equals([p1]));
        expect(filter.applyGaussianSmoothing([p1, p2]), equals([p1, p2]));
      });

      test('applies exact [0.25, 0.50, 0.25] smoothing for 3 points preserving endpoints', () {
        final p1 = GesturePoint(x: 0.0, y: 0.0, timestampMs: 10);
        final p2 = GesturePoint(x: 10.0, y: 20.0, timestampMs: 20);
        final p3 = GesturePoint(x: 20.0, y: 0.0, timestampMs: 30);

        final result = filter.applyGaussianSmoothing([p1, p2, p3]);
        expect(result.length, equals(3));

        expect(result[0], equals(p1));
        expect(result[2], equals(p3));

        expect(result[1].x, closeTo(10.0, 1e-9));
        expect(result[1].y, closeTo(10.0, 1e-9));
        expect(result[1].timestampMs, equals(20));
      });

      test('is an exact identity transformation on collinear straight line', () {
        final points = List.generate(
          15,
          (i) => GesturePoint(
            x: i * 5.0,
            y: (i * 5.0) * 2.0 + 1.0,
            timestampMs: 100 + i * 16,
          ),
        );

        final result = filter.applyGaussianSmoothing(points);
        expect(result.length, equals(points.length));

        for (var i = 0; i < points.length; i++) {
          expect(result[i].x, closeTo(points[i].x, 1e-9));
          expect(result[i].y, closeTo(points[i].y, 1e-9));
          expect(result[i].timestampMs, equals(points[i].timestampMs));
        }
      });

      test('smooths high-frequency zig-zag noise while preserving gross shape', () {
        final points = <GesturePoint>[
          GesturePoint(x: 0.0, y: 50.0, timestampMs: 0),
          GesturePoint(x: 10.0, y: 60.0, timestampMs: 10),
          GesturePoint(x: 20.0, y: 40.0, timestampMs: 20),
          GesturePoint(x: 30.0, y: 60.0, timestampMs: 30),
          GesturePoint(x: 40.0, y: 50.0, timestampMs: 40),
        ];

        final result = filter.applyGaussianSmoothing(points);
        expect(result.first, equals(points.first));
        expect(result.last, equals(points.last));

        expect(result[2].y, closeTo(50.0, 1e-9));
      });

      test('throws FormatException on non-finite point coordinates in applyGaussianSmoothing', () {
        expect(
          () => filter.applyGaussianSmoothing([
            const GesturePoint.constant(x: double.nan, y: 10.0, timestampMs: 0),
          ]),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('RawTouchFilter point coordinates must be finite, got: (NaN, 10.0)'),
            ),
          ),
        );

        expect(
          () => filter.applyGaussianSmoothing([
            const GesturePoint.constant(x: 0.0, y: 0.0, timestampMs: 0),
            const GesturePoint.constant(x: 5.0, y: double.infinity, timestampMs: 16),
          ]),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('RawTouchFilter point coordinates must be finite, got: (5.0, Infinity)'),
            ),
          ),
        );
      });
    });

    group('filterRawPoints (End-to-End)', () {
      test('executes deadband and Gaussian smoothing sequentially', () {
        final raw = <GesturePoint>[
          GesturePoint(x: 0.0, y: 0.0, timestampMs: 0),
          GesturePoint(x: 0.5, y: 0.5, timestampMs: 10),
          GesturePoint(x: 10.0, y: 20.0, timestampMs: 20),
          GesturePoint(x: 10.5, y: 20.2, timestampMs: 30),
          GesturePoint(x: 20.0, y: 0.0, timestampMs: 40),
        ];

        final filtered = filter.filterRawPoints(raw);
        expect(filtered.length, equals(3));
        expect(filtered[0], equals(raw[0]));
        expect(filtered[1].x, closeTo(10.0, 1e-9));
        expect(filtered[1].y, closeTo(10.0, 1e-9));
        expect(filtered[2], equals(raw[4]));
      });

      test('throws FormatException on non-finite points in end-to-end pipeline', () {
        final corrupted = [
          const GesturePoint.constant(x: 0.0, y: 0.0, timestampMs: 0),
          const GesturePoint.constant(x: double.nan, y: 10.0, timestampMs: 10),
          const GesturePoint.constant(x: 20.0, y: 20.0, timestampMs: 20),
        ];

        expect(
          () => filter.filterRawPoints(corrupted),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('RawTouchFilter point coordinates must be finite, got: (NaN, 10.0)'),
            ),
          ),
        );
      });

      test('is thread-safe and re-entrant inside Isolate.run', () async {
        final raw = List.generate(
          100,
          (i) => GesturePoint(
            x: i * 4.0,
            y: (i % 2 == 0) ? 10.0 : 12.0,
            timestampMs: i * 16,
          ),
        );

        final result = await Isolate.run(() {
          const isolateFilter = RawTouchFilter();
          return isolateFilter.filterRawPoints(raw);
        });

        expect(result.length, greaterThan(1));
        expect(result.first, equals(raw.first));
        expect(result.last, equals(raw.last));
      });
    });
  });
}
