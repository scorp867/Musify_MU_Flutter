// 1:1 replica of com.spotify.player.model.SleepTimer

abstract class SleepTimer {
  const SleepTimer();
}

class SleepTimerEndOfTrack implements SleepTimer {
  const SleepTimerEndOfTrack();

  static SleepTimerEndOfTrack create() => const SleepTimerEndOfTrack();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SleepTimerEndOfTrack);

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SleepTimer.EndOfTrack{}';
}

class SleepTimerNone implements SleepTimer {
  const SleepTimerNone();

  static SleepTimerNone create() => const SleepTimerNone();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SleepTimerNone);

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SleepTimer.None{}';
}

class SleepTimerTimestamp implements SleepTimer {
  final int timestamp;

  const SleepTimerTimestamp(this.timestamp);

  static SleepTimerTimestamp create(int timestamp) =>
      SleepTimerTimestamp(timestamp);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SleepTimerTimestamp && other.timestamp == timestamp);

  @override
  int get hashCode => Object.hash(runtimeType, timestamp);

  @override
  String toString() => 'SleepTimer.Timestamp{timestamp=$timestamp}';
}
