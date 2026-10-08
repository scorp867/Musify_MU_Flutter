import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/utils/concurrency_limiter.dart';

void main() {
  group('ConcurrencyLimiter', () {
    test('runPooled strictly enforces maxConcurrent limit', () async {
      const maxConcurrent = 3;
      var currentInFlight = 0;
      var peakInFlight = 0;

      final items = List.generate(20, (i) => i);

      final results = await ConcurrencyLimiter.runPooled(
        items,
        (item) async {
          currentInFlight++;
          if (currentInFlight > peakInFlight) {
            peakInFlight = currentInFlight;
          }

          await Future.delayed(const Duration(milliseconds: 20));

          currentInFlight--;
          return item * 2;
        },
        maxConcurrent: maxConcurrent,
      );

      // Verify that peak in-flight tasks never exceeded maxConcurrent
      expect(peakInFlight, lessThanOrEqualTo(maxConcurrent));
      expect(peakInFlight, equals(maxConcurrent));

      // Verify output ordering is preserved
      expect(results, equals(List.generate(20, (i) => i * 2)));
    });
  });
}
