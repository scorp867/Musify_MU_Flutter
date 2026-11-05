// 1:1 replica of com.spotify.player.model.command.options.TimerType

sealed class TimerType {
  const TimerType();

  static TimerTypeClear clear() => const TimerTypeClear();
  static TimerTypeDuration duration(int durationSeconds) =>
      TimerTypeDuration(durationSeconds);
  static TimerTypeEndOfTrack endOfTrack() => const TimerTypeEndOfTrack();
}

final class TimerTypeClear extends TimerType {
  const TimerTypeClear();

  static TimerTypeClear create() => const TimerTypeClear();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TimerTypeClear);

  @override
  int get hashCode => 1;

  @override
  String toString() => 'Clear{}';
}

final class TimerTypeDuration extends TimerType {
  final int durationSeconds;

  const TimerTypeDuration(this.durationSeconds);

  static TimerTypeDuration create(int durationSeconds) =>
      TimerTypeDuration(durationSeconds);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimerTypeDuration && other.durationSeconds == durationSeconds);

  @override
  int get hashCode => (durationSeconds ^ (durationSeconds >> 32)) ^ 1000003;

  @override
  String toString() => 'Duration{durationSeconds=$durationSeconds}';
}

final class TimerTypeEndOfTrack extends TimerType {
  const TimerTypeEndOfTrack();

  static TimerTypeEndOfTrack create() => const TimerTypeEndOfTrack();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TimerTypeEndOfTrack);

  @override
  int get hashCode => 1;

  @override
  String toString() => 'EndOfTrack{}';
}
