import 'dart:core';

/// Pure abstract interface providing monotonic time tracking backed by the OS monotonic
/// clock (e.g., CLOCK_MONOTONIC via Dart Stopwatch or direct C++ clock reads).
///
/// Defeats device clock tampering, time-zone manipulations, and daylight-savings jumps
/// across active session cool-off timers, background grace countdowns, and brute-force
/// lockout cooldowns.
abstract interface class IMonotonicClock {
  /// Monotonic elapsed milliseconds since the clock or reference base was started.
  ///
  /// Guaranteed to never decrease even if the device system time is adjusted backwards.
  int get elapsedMilliseconds;

  /// Current timestamp in monotonic milliseconds suitable for calculating deadlines
  /// and verifying session cool-off expiration.
  int get currentMonotonicMs;

  /// Creates and returns a freshly allocated [Stopwatch] instance backed by the
  /// underlying monotonic clock.
  Stopwatch createStopwatch();
}
