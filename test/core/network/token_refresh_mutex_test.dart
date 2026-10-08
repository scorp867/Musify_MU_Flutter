import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/network/auth/token_refresh_mutex.dart';

void main() {
  group('TokenRefreshMutex', () {
    test('concurrent callers only invoke refresh action once', () async {
      final mutex = TokenRefreshMutex();
      var refreshCount = 0;

      Future<String?> simulateRefresh() async {
        refreshCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return 'fresh_token_123';
      }

      // Fire 10 concurrent requests requesting refresh through the mutex
      final results = await Future.wait(
        List.generate(10, (_) => mutex.lock(simulateRefresh)),
      );

      // Verify that all 10 callers received the fresh token
      for (final token in results) {
        expect(token, equals('fresh_token_123'));
      }

      // Verify that the underlying refresh action was called EXACTLY once
      expect(refreshCount, equals(1));
    });

    test('subsequent calls after refresh completion can run again', () async {
      final mutex = TokenRefreshMutex();
      var refreshCount = 0;

      Future<String?> simulateRefresh() async {
        refreshCount++;
        return 'token_$refreshCount';
      }

      final first = await mutex.lock(simulateRefresh);
      expect(first, equals('token_1'));
      expect(refreshCount, equals(1));

      final second = await mutex.lock(simulateRefresh);
      expect(second, equals('token_2'));
      expect(refreshCount, equals(2));
    });
  });
}
