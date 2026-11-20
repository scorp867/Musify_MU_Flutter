import 'package:flutter/services.dart';
import 'package:musify_mu/features/connect/domain/interfaces/system_volume_port.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';

/// Android implementation of [SystemVolumePort] backed by
/// `SystemVolumeBridge.kt` (`um.musify.mu/connect/system_volume_control` and
/// `um.musify.mu/connect/system_volume_events`, `#47 §4.3`).
final class AndroidSystemVolumeAdapter implements SystemVolumePort {
  static const String controlChannelName =
      'um.musify.mu/connect/system_volume_control';
  static const String eventChannelName =
      'um.musify.mu/connect/system_volume_events';

  final MethodChannel _controlChannel;
  final EventChannel _eventChannel;
  Stream<SystemVolumeEvent>? _cachedStream;

  AndroidSystemVolumeAdapter({
    MethodChannel? controlChannel,
    EventChannel? eventChannel,
  })  : _controlChannel = switch (controlChannel) {
          final provided? => provided,
          null => const MethodChannel(controlChannelName),
        },
        _eventChannel = switch (eventChannel) {
          final provided? => provided,
          null => const EventChannel(eventChannelName),
        };

  @override
  Future<SystemVolumeSnapshot> getLocalVolume() async {
    final raw = await _controlChannel.invokeMethod<Object>('getLocalVolume');
    return parseSnapshotMap(raw);
  }

  @override
  Future<bool> setLocalVolume({
    required int volume,
    bool showUi = false,
  }) async {
    _validateWireVolume(volume, 'volume');
    final raw = await _controlChannel.invokeMethod<Object>(
      'setLocalVolume',
      <String, Object>{
        'volume': volume,
        'showUi': showUi,
      },
    );
    return _requireBoolResponse(raw, 'setLocalVolume');
  }

  @override
  Future<bool> configureRemoteHardwareVolume({
    required bool enabled,
    required bool supportsVolume,
    required int volumeSteps,
    required int currentVolume,
  }) async {
    if (volumeSteps < 0) {
      throw RangeError.value(
        volumeSteps,
        'volumeSteps',
        'Must be non-negative',
      );
    }
    _validateWireVolume(currentVolume, 'currentVolume');
    final raw = await _controlChannel.invokeMethod<Object>(
      'configureRemoteHardwareVolume',
      <String, Object>{
        'enabled': enabled,
        'supportsVolume': supportsVolume,
        'volumeSteps': volumeSteps,
        'currentVolume': currentVolume,
      },
    );
    return _requireBoolResponse(raw, 'configureRemoteHardwareVolume');
  }

  @override
  Future<bool> updateRemoteHardwareVolume({
    required int currentVolume,
  }) async {
    _validateWireVolume(currentVolume, 'currentVolume');
    final raw = await _controlChannel.invokeMethod<Object>(
      'updateRemoteHardwareVolume',
      <String, Object>{
        'currentVolume': currentVolume,
      },
    );
    return _requireBoolResponse(raw, 'updateRemoteHardwareVolume');
  }

  @override
  Stream<SystemVolumeEvent> watchEvents() {
    if (_cachedStream case final existing?) {
      return existing;
    }
    final stream = _eventChannel
        .receiveBroadcastStream()
        .map<SystemVolumeEvent>(parseEventMap);
    _cachedStream = stream;
    return stream;
  }

  /// Fail-fast boundary parser for `SystemVolumeBridge.getLocalVolume()`
  /// (`{volume: Int (0..65535), steps: Int, currentStep: Int}`, `#47 §4.3`).
  static SystemVolumeSnapshot parseSnapshotMap(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      throw FormatException(
        'Expected Map from $controlChannelName.getLocalVolume, got ${raw.runtimeType}',
        raw,
      );
    }
    final volume = _requireBoundedInt(
      raw,
      'volume',
      minValue: 0,
      maxValue: kMaxConnectVolumeWire,
    );
    final steps = _requireBoundedInt(
      raw,
      'steps',
      minValue: 0,
      maxValue: kMaxConnectVolumeWire,
    );
    final currentStep = _requireBoundedInt(
      raw,
      'currentStep',
      minValue: 0,
      maxValue: kMaxConnectVolumeWire,
    );
    return SystemVolumeSnapshot(
      volume: volume,
      steps: steps,
      currentStep: currentStep,
    );
  }

  /// Fail-fast boundary parser for `SystemVolumeBridge` event stream maps
  /// (`#47 §4.3`):
  /// - `{type: "local_volume_changed", volume, steps, currentStep}`
  /// - `{type: "remote_volume_adjust", direction: -1|+1}`
  /// - `{type: "remote_volume_set", volume: Int (0..65535)}`
  static SystemVolumeEvent parseEventMap(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      throw FormatException(
        'Expected Map from $eventChannelName, got ${raw.runtimeType}',
        raw,
      );
    }

    final type = raw['type'];
    if (type is! String || type.trim().isEmpty) {
      throw FormatException(
        'SystemVolumeEvent.type must be a non-empty String, got ${type.runtimeType}',
        raw,
      );
    }

    switch (type) {
      case 'local_volume_changed':
        final volume = _requireBoundedInt(
          raw,
          'volume',
          minValue: 0,
          maxValue: kMaxConnectVolumeWire,
        );
        final steps = _requireBoundedInt(
          raw,
          'steps',
          minValue: 0,
          maxValue: kMaxConnectVolumeWire,
        );
        final currentStep = _requireBoundedInt(
          raw,
          'currentStep',
          minValue: 0,
          maxValue: kMaxConnectVolumeWire,
        );
        return LocalVolumeChanged(
          volume: volume,
          steps: steps,
          currentStep: currentStep,
        );
      case 'remote_volume_adjust':
        final direction = raw['direction'];
        if (direction is! int || (direction != -1 && direction != 1)) {
          throw FormatException(
            'SystemVolumeEvent(remote_volume_adjust).direction must be -1 or +1, got $direction',
            raw,
          );
        }
        return RemoteVolumeAdjust(direction: direction);
      case 'remote_volume_set':
        final volume = _requireBoundedInt(
          raw,
          'volume',
          minValue: 0,
          maxValue: kMaxConnectVolumeWire,
        );
        return RemoteVolumeSet(volume: volume);
      default:
        throw FormatException(
          'Unsupported SystemVolumeEvent.type: $type',
          raw,
        );
    }
  }

  static void _validateWireVolume(int volume, String name) {
    if (volume < 0 || volume > kMaxConnectVolumeWire) {
      throw RangeError.range(
        volume,
        0,
        kMaxConnectVolumeWire,
        name,
        'Must be within [0, $kMaxConnectVolumeWire]',
      );
    }
  }

  static bool _requireBoolResponse(Object? raw, String methodName) {
    if (raw is! bool) {
      throw FormatException(
        'Expected bool from $controlChannelName.$methodName, got ${raw.runtimeType}',
        raw,
      );
    }
    return raw;
  }

  static int _requireBoundedInt(
    Map<Object?, Object?> map,
    String key, {
    required int minValue,
    required int maxValue,
  }) {
    final value = map[key];
    if (value is! int) {
      throw FormatException(
        'SystemVolumeBridge.$key must be an int, got ${value.runtimeType}',
        map,
      );
    }
    if (value < minValue || value > maxValue) {
      throw FormatException(
        'SystemVolumeBridge.$key must be within [$minValue, $maxValue], got $value',
        map,
      );
    }
    return value;
  }
}
