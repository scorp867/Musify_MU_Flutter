// 1:1 replica of com.spotify.player.model.command.options.TimerType

abstract class TimerType {
  const TimerType();

  static TimerTypeClear clear() => const TimerTypeClear();
  static TimerTypeDuration duration(int durationSeconds) =>
      TimerTypeDuration(durationSeconds);
  static TimerTypeEndOfTrack endOfTrack() => const TimerTypeEndOfTrack();
}

class TimerTypeClear extends TimerType {
  const TimerTypeClear();

  static TimerTypeClear create() => const TimerTypeClear();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TimerTypeClear);

  @override
  int get hashCode => runtimeType.hashCode;
}

class TimerTypeDuration extends TimerType {
  final int durationSeconds;

  const TimerTypeDuration(this.durationSeconds);

  static TimerTypeDuration create(int durationSeconds) =>
      TimerTypeDuration(durationSeconds);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimerTypeDuration && other.durationSeconds == durationSeconds);

  @override
  int get hashCode => durationSeconds.hashCode;
}

class TimerTypeEndOfTrack extends TimerType {
  const TimerTypeEndOfTrack();

  static TimerTypeEndOfTrack create() => const TimerTypeEndOfTrack();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TimerTypeEndOfTrack);

  @override
  int get hashCode => runtimeType.hashCode;
}
