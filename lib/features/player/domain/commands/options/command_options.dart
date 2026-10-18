// 1:1 replica of com.spotify.player.model.command.options.CommandOptions

class CommandOptions {
  static final CommandOptions empty = builder().build();

  final bool? overrideRestrictions;
  final String? onlyForPlaybackId;
  final bool? systemInitiated;
  final bool? onlyForLocalDevice;

  const CommandOptions({
    this.overrideRestrictions,
    this.onlyForPlaybackId,
    this.systemInitiated,
    this.onlyForLocalDevice,
  });

  static CommandOptionsBuilder builder() => CommandOptionsBuilder();

  CommandOptionsBuilder toBuilder() => CommandOptionsBuilder(
        overrideRestrictions: overrideRestrictions,
        onlyForPlaybackId: onlyForPlaybackId,
        systemInitiated: systemInitiated,
        onlyForLocalDevice: onlyForLocalDevice,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CommandOptions &&
          other.overrideRestrictions == overrideRestrictions &&
          other.onlyForPlaybackId == onlyForPlaybackId &&
          other.systemInitiated == systemInitiated &&
          other.onlyForLocalDevice == onlyForLocalDevice);

  @override
  int get hashCode => Object.hash(
        overrideRestrictions,
        onlyForPlaybackId,
        systemInitiated,
        onlyForLocalDevice,
      );

  @override
  String toString() =>
      'CommandOptions{overrideRestrictions=$overrideRestrictions, onlyForPlaybackId=$onlyForPlaybackId, systemInitiated=$systemInitiated, onlyForLocalDevice=$onlyForLocalDevice}';
}

class CommandOptionsBuilder {
  bool? _overrideRestrictions;
  String? _onlyForPlaybackId;
  bool? _systemInitiated;
  bool? _onlyForLocalDevice;

  CommandOptionsBuilder({
    bool? overrideRestrictions,
    String? onlyForPlaybackId,
    bool? systemInitiated,
    bool? onlyForLocalDevice,
  })  : _overrideRestrictions = overrideRestrictions,
        _onlyForPlaybackId = onlyForPlaybackId,
        _systemInitiated = systemInitiated,
        _onlyForLocalDevice = onlyForLocalDevice;

  CommandOptionsBuilder overrideRestrictions(bool val) {
    _overrideRestrictions = val;
    return this;
  }

  CommandOptionsBuilder onlyForPlaybackId(String val) {
    _onlyForPlaybackId = val;
    return this;
  }

  CommandOptionsBuilder systemInitiated(bool val) {
    _systemInitiated = val;
    return this;
  }

  CommandOptionsBuilder onlyForLocalDevice(bool val) {
    _onlyForLocalDevice = val;
    return this;
  }

  CommandOptions build() => CommandOptions(
        overrideRestrictions: _overrideRestrictions,
        onlyForPlaybackId: _onlyForPlaybackId,
        systemInitiated: _systemInitiated,
        onlyForLocalDevice: _onlyForLocalDevice,
      );
}
