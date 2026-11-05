// 1:1 replica of com.spotify.player.model.command.options.CommandOptions

class CommandOptions {
  static final CommandOptions empty = builder().build();

  final bool? overrideRestrictions;
  final bool? onlyForLocalDevice;
  final bool? systemInitiated;
  final String? onlyForPlaybackId;

  const CommandOptions({
    this.overrideRestrictions,
    this.onlyForLocalDevice,
    this.systemInitiated,
    this.onlyForPlaybackId,
  });

  static CommandOptionsBuilder builder() => CommandOptionsBuilder();

  CommandOptionsBuilder toBuilder() => CommandOptionsBuilder(
        overrideRestrictions: overrideRestrictions,
        onlyForLocalDevice: onlyForLocalDevice,
        systemInitiated: systemInitiated,
        onlyForPlaybackId: onlyForPlaybackId,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CommandOptions &&
          other.overrideRestrictions == overrideRestrictions &&
          other.onlyForLocalDevice == onlyForLocalDevice &&
          other.systemInitiated == systemInitiated &&
          other.onlyForPlaybackId == onlyForPlaybackId);

  @override
  int get hashCode => Object.hash(
        overrideRestrictions,
        onlyForLocalDevice,
        systemInitiated,
        onlyForPlaybackId,
      );

  @override
  String toString() =>
      'CommandOptions{overrideRestrictions=$overrideRestrictions, onlyForLocalDevice=$onlyForLocalDevice, systemInitiated=$systemInitiated, onlyForPlaybackId=$onlyForPlaybackId}';
}

class CommandOptionsBuilder {
  bool? _overrideRestrictions;
  bool? _onlyForLocalDevice;
  bool? _systemInitiated;
  String? _onlyForPlaybackId;

  CommandOptionsBuilder({
    bool? overrideRestrictions,
    bool? onlyForLocalDevice,
    bool? systemInitiated,
    String? onlyForPlaybackId,
  })  : _overrideRestrictions = overrideRestrictions,
        _onlyForLocalDevice = onlyForLocalDevice,
        _systemInitiated = systemInitiated,
        _onlyForPlaybackId = onlyForPlaybackId;

  static CommandOptionsBuilder builder() => CommandOptions.builder();

  CommandOptionsBuilder overrideRestrictions(bool val) {
    _overrideRestrictions = val;
    return this;
  }

  CommandOptionsBuilder onlyForLocalDevice(bool val) {
    _onlyForLocalDevice = val;
    return this;
  }

  CommandOptionsBuilder systemInitiated(bool val) {
    _systemInitiated = val;
    return this;
  }

  CommandOptionsBuilder onlyForPlaybackId(String val) {
    _onlyForPlaybackId = val;
    return this;
  }

  CommandOptions build() => CommandOptions(
        overrideRestrictions: _overrideRestrictions,
        onlyForLocalDevice: _onlyForLocalDevice,
        systemInitiated: _systemInitiated,
        onlyForPlaybackId: _onlyForPlaybackId,
      );
}
