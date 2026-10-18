// 1:1 replica of com.spotify.player.model.command.options.PlayerOptionOverrides

class PlayerOptionOverrides {
  static final PlayerOptionOverrides empty = builder().build();

  final Map<String, String> modes;
  final double? playbackSpeed;
  final bool? repeatingContext;
  final bool? repeatingTrack;
  final bool? shufflingContext;

  const PlayerOptionOverrides({
    this.modes = const <String, String>{},
    this.playbackSpeed,
    this.repeatingContext,
    this.repeatingTrack,
    this.shufflingContext,
  });

  static PlayerOptionOverridesBuilder builder() =>
      PlayerOptionOverridesBuilder();

  PlayerOptionOverridesBuilder toBuilder() => PlayerOptionOverridesBuilder(
        modes: modes,
        playbackSpeed: playbackSpeed,
        repeatingContext: repeatingContext,
        repeatingTrack: repeatingTrack,
        shufflingContext: shufflingContext,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerOptionOverrides &&
          other.playbackSpeed == playbackSpeed &&
          other.repeatingContext == repeatingContext &&
          other.repeatingTrack == repeatingTrack &&
          other.shufflingContext == shufflingContext &&
          _mapEquals(other.modes, modes));

  @override
  int get hashCode => Object.hash(
        playbackSpeed,
        repeatingContext,
        repeatingTrack,
        shufflingContext,
        Object.hashAll(modes.entries.map((e) => Object.hash(e.key, e.value))),
      );

  @override
  String toString() =>
      'PlayerOptionOverrides{modes=$modes, playbackSpeed=$playbackSpeed, repeatingContext=$repeatingContext, repeatingTrack=$repeatingTrack, shufflingContext=$shufflingContext}';

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (b[key] != a[key]) return false;
    }
    return true;
  }
}

class PlayerOptionOverridesBuilder {
  Map<String, String> _modes;
  double? _playbackSpeed;
  bool? _repeatingContext;
  bool? _repeatingTrack;
  bool? _shufflingContext;

  PlayerOptionOverridesBuilder({
    Map<String, String> modes = const <String, String>{},
    double? playbackSpeed,
    bool? repeatingContext,
    bool? repeatingTrack,
    bool? shufflingContext,
  })  : _modes = Map<String, String>.from(modes),
        _playbackSpeed = playbackSpeed,
        _repeatingContext = repeatingContext,
        _repeatingTrack = repeatingTrack,
        _shufflingContext = shufflingContext;

  PlayerOptionOverridesBuilder modes(Map<String, String> val) {
    _modes = Map<String, String>.from(val);
    return this;
  }

  PlayerOptionOverridesBuilder playbackSpeed(double val) {
    _playbackSpeed = val;
    return this;
  }

  PlayerOptionOverridesBuilder repeatingContext(bool val) {
    _repeatingContext = val;
    return this;
  }

  PlayerOptionOverridesBuilder repeatingTrack(bool val) {
    _repeatingTrack = val;
    return this;
  }

  PlayerOptionOverridesBuilder shufflingContext(bool val) {
    _shufflingContext = val;
    return this;
  }

  PlayerOptionOverrides build() => PlayerOptionOverrides(
        modes: Map<String, String>.unmodifiable(_modes),
        playbackSpeed: _playbackSpeed,
        repeatingContext: _repeatingContext,
        repeatingTrack: _repeatingTrack,
        shufflingContext: _shufflingContext,
      );
}
