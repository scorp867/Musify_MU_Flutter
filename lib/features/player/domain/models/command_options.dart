/// 1:1 with com.spotify.player.model.command.options.CommandOptions
class CommandOptions {
  const CommandOptions({
    this.overrideRestrictions = false,
    this.onlyForLocalDevice = false,
    this.onlyForPlaybackId,
    this.systemInitiated = false,
  });

  static const CommandOptions empty = CommandOptions();

  final bool overrideRestrictions;
  final bool onlyForLocalDevice;
  final String? onlyForPlaybackId;
  final bool systemInitiated;

  CommandOptions copyWith({
    bool? overrideRestrictions,
    bool? onlyForLocalDevice,
    String? onlyForPlaybackId,
    bool? systemInitiated,
  }) {
    return CommandOptions(
      overrideRestrictions: overrideRestrictions ?? this.overrideRestrictions,
      onlyForLocalDevice: onlyForLocalDevice ?? this.onlyForLocalDevice,
      onlyForPlaybackId: onlyForPlaybackId ?? this.onlyForPlaybackId,
      systemInitiated: systemInitiated ?? this.systemInitiated,
    );
  }

  Map<String, dynamic> toJson() => {
        'override_restrictions': overrideRestrictions,
        'only_for_local_device': onlyForLocalDevice,
        if (onlyForPlaybackId != null) 'only_for_playback_id': onlyForPlaybackId,
        'system_initiated': systemInitiated,
      };

  factory CommandOptions.fromJson(Map<String, dynamic> json) {
    return CommandOptions(
      overrideRestrictions: json['override_restrictions'] as bool? ?? false,
      onlyForLocalDevice: json['only_for_local_device'] as bool? ?? false,
      onlyForPlaybackId: json['only_for_playback_id'] as String?,
      systemInitiated: json['system_initiated'] as bool? ?? false,
    );
  }
}
