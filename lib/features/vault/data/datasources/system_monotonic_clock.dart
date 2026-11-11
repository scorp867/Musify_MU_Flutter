import 'dart:core';
import 'dart:math' as math;

import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';

/// Production implementation of [IMonotonicClock] providing non-backward jumping
/// millisecond timestamps backed by Dart's [Stopwatch] and epoch offset.
///
/// Guaranteed to never decrease during application execution, defeating device clock
/// tampering, timezone adjustments, and daylight savings jumps across active session
/// cool-off timers, background grace countdowns, and brute-force lockout cooldowns.
final class SystemMonotonicClock implements IMonotonicClock {
  final Stopwatch _stopwatch;
  final int _baseEpochMs;
  int _lastTimeMs;
  int _lastElapsedMs = 0;

  /// Creates a [SystemMonotonicClock] with optional injected [stopwatch] and [baseEpochMs]
  /// for deterministic testing.
  SystemMonotonicClock({
    Stopwatch? stopwatch,
    int? baseEpochMs,
  })  : _stopwatch = stopwatch ?? (Stopwatch()..start()),
        _baseEpochMs = baseEpochMs ?? DateTime.now().millisecondsSinceEpoch,
        _lastTimeMs = baseEpochMs ?? DateTime.now().millisecondsSinceEpoch;

  @override
  int get elapsedMilliseconds {
    final currentElapsed = _stopwatch.elapsedMilliseconds;
    _lastElapsedMs = math.max(_lastElapsedMs, currentElapsed);
    return _lastElapsedMs;
  }

  @override
  int get currentMonotonicMs {
    final newTimeMs = _baseEpochMs + _stopwatch.elapsedMilliseconds;
    _lastTimeMs = math.max(_lastTimeMs, newTimeMs);
    return _lastTimeMs;
  }

  @override
  Stopwatch createStopwatch() => Stopwatch();
}
