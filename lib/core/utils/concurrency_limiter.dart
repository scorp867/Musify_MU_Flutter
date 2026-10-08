import 'dart:async';

/// Limits concurrent asynchronous operations to prevent socket starvation,
/// OS connection pool exhaustion, and server rate-limiting (HTTP 429).
class ConcurrencyLimiter {
  final int maxConcurrent;
  int _activeCount = 0;
  final List<Completer<void>> _waitQueue = [];

  ConcurrencyLimiter({required this.maxConcurrent})
      : assert(maxConcurrent > 0, 'maxConcurrent must be positive');

  /// Runs [task] as soon as an execution slot is available.
  Future<T> run<T>(Future<T> Function() task) async {
    while (_activeCount >= maxConcurrent) {
      final completer = Completer<void>();
      _waitQueue.add(completer);
      await completer.future;
    }

    _activeCount++;
    try {
      return await task();
    } finally {
      _activeCount--;
      if (_waitQueue.isNotEmpty) {
        final next = _waitQueue.removeAt(0);
        next.complete();
      }
    }
  }

  /// Convenience utility: runs all [items] through [task] with concurrency capped at [maxConcurrent].
  /// Preserves input ordering in the returned results list.
  static Future<List<R>> runPooled<T, R>(
    List<T> items,
    Future<R> Function(T item) task, {
    int maxConcurrent = 4,
  }) async {
    if (items.isEmpty) return [];
    if (items.length <= maxConcurrent) {
      return Future.wait(items.map(task));
    }

    final limiter = ConcurrencyLimiter(maxConcurrent: maxConcurrent);
    return Future.wait(items.map((item) => limiter.run(() => task(item))));
  }
}
