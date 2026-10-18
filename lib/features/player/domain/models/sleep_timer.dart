// 1:1 replica of com.spotify.player.model.SleepTimer

abstract class SleepTimer {
  const SleepTimer();
}

class SleepTimerNone extends SleepTimer {
  const SleepTimerNone();

  static SleepTimerNone create() => const SleepTimerNone();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SleepTimerNone);

  @override
  int get hashCode => runtimeType.hashCode;
}

class SleepTimerEndOfTrack extends SleepTimer {
  const SleepTimerEndOfTrack();

  static SleepTimerEndOfTrack create() => const SleepTimerEndOfTrack();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SleepTimerEndOfTrack);

  @override
  int get hashCode => runtimeType.hashCode;
}

class SleepTimerTimestamp extends SleepTimer {
  final int timestamp;

  const SleepTimerTimestamp(this.timestamp);

  static SleepTimerTimestamp create(int timestamp) =>
      SleepTimerTimestamp(timestamp);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SleepTimerTimestamp && other.timestamp == timestamp);

  @override
  int get hashCode => timestamp.hashCode;
}
