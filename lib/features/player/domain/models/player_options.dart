// 1:1 replica of com.spotify.player.model.PlayerOptions

class PlayerOptions {
  static final PlayerOptions empty = builder().build();

  final bool shufflingContext;
  final bool repeatingContext;
  final bool repeatingTrack;
  final double? playbackSpeed;
  final Map<String, String> modes;

  const PlayerOptions({
    this.shufflingContext = false,
    this.repeatingContext = false,
    this.repeatingTrack = false,
    this.playbackSpeed,
    this.modes = const <String, String>{},
  });

  static PlayerOptionsBuilder builder() => PlayerOptionsBuilder();

  PlayerOptionsBuilder toBuilder() => PlayerOptionsBuilder(
        shufflingContext: shufflingContext,
        repeatingContext: repeatingContext,
        repeatingTrack: repeatingTrack,
        playbackSpeed: playbackSpeed,
        modes: modes,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerOptions &&
          other.shufflingContext == shufflingContext &&
          other.repeatingContext == repeatingContext &&
          other.repeatingTrack == repeatingTrack &&
          other.playbackSpeed == playbackSpeed &&
          _mapEquals(other.modes, modes));

  @override
  int get hashCode => Object.hash(
        shufflingContext,
        repeatingContext,
        repeatingTrack,
        playbackSpeed,
        Object.hashAll(modes.entries.map((e) => Object.hash(e.key, e.value))),
      );

  @override
  String toString() =>
      'PlayerOptions{shufflingContext=$shufflingContext, repeatingContext=$repeatingContext, repeatingTrack=$repeatingTrack, playbackSpeed=$playbackSpeed, modes=$modes}';

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (b[key] != a[key]) return false;
    }
    return true;
  }
}

class PlayerOptionsBuilder {
  bool _shufflingContext;
  bool _repeatingContext;
  bool _repeatingTrack;
  double? _playbackSpeed;
  Map<String, String> _modes;

  PlayerOptionsBuilder({
    bool shufflingContext = false,
    bool repeatingContext = false,
    bool repeatingTrack = false,
    double? playbackSpeed,
    Map<String, String> modes = const <String, String>{},
  })  : _shufflingContext = shufflingContext,
        _repeatingContext = repeatingContext,
        _repeatingTrack = repeatingTrack,
        _playbackSpeed = playbackSpeed,
        _modes = Map<String, String>.from(modes);

  PlayerOptionsBuilder shufflingContext(bool val) {
    _shufflingContext = val;
    return this;
  }

  PlayerOptionsBuilder repeatingContext(bool val) {
    _repeatingContext = val;
    return this;
  }

  PlayerOptionsBuilder repeatingTrack(bool val) {
    _repeatingTrack = val;
    return this;
  }

  PlayerOptionsBuilder playbackSpeed(double val) {
    _playbackSpeed = val;
    return this;
  }

  PlayerOptionsBuilder modes(Map<String, String> val) {
    _modes = Map<String, String>.from(val);
    return this;
  }

  PlayerOptions build() => PlayerOptions(
        shufflingContext: _shufflingContext,
        repeatingContext: _repeatingContext,
        repeatingTrack: _repeatingTrack,
        playbackSpeed: _playbackSpeed,
        modes: Map<String, String>.unmodifiable(_modes),
      );
}
