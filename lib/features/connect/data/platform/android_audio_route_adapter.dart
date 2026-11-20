import 'package:flutter/services.dart';
import 'package:musify_mu/features/connect/domain/interfaces/audio_route_port.dart';

/// Android implementation of [AudioRoutePort] backed by `AudioRouteMonitor.kt`
/// (`um.musify.mu/connect/audio_route_control` and
/// `um.musify.mu/connect/audio_route_events`, `#47 §4.2`).
final class AndroidAudioRouteAdapter implements AudioRoutePort {
  static const String controlChannelName =
      'um.musify.mu/connect/audio_route_control';
  static const String eventChannelName =
      'um.musify.mu/connect/audio_route_events';

  final MethodChannel _controlChannel;
  final EventChannel _eventChannel;
  Stream<List<LocalAudioPeripheral>>? _cachedStream;

  AndroidAudioRouteAdapter({
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
  Future<List<LocalAudioPeripheral>> getPeripherals() async {
    final raw = await _controlChannel.invokeMethod<Object>('getPeripherals');
    return parsePeripheralList(raw);
  }

  @override
  Stream<List<LocalAudioPeripheral>> watchPeripherals() {
    if (_cachedStream case final existing?) {
      return existing;
    }
    final stream = _eventChannel
        .receiveBroadcastStream()
        .map<List<LocalAudioPeripheral>>(parsePeripheralList);
    _cachedStream = stream;
    return stream;
  }

  @override
  Future<bool> openSystemOutputSwitcher() async {
    final raw = await _controlChannel
        .invokeMethod<Object>('openSystemOutputSwitcher');
    if (raw is! bool) {
      throw FormatException(
        'Expected bool from $controlChannelName.openSystemOutputSwitcher, got ${raw.runtimeType}',
        raw,
      );
    }
    return raw;
  }

  /// Fail-fast boundary parser for `AudioRouteMonitor` peripheral lists
  /// (`#47 §4.2`).
  ///
  /// Schema per element:
  /// `{id, name, isActive, isConnected, connectionTypeIndex, categoryIndex, brand, model}`
  /// where `connectionTypeIndex` is strictly in `0..5`
  /// ([OutputPeripheralConnectionType]) and `categoryIndex` is in `0..6`
  /// ([OutputPeripheralCategory]) or `null`/`-1` when unset.
  static List<LocalAudioPeripheral> parsePeripheralList(Object? raw) {
    if (raw is! List<Object?>) {
      throw FormatException(
        'Expected List of peripheral maps from AudioRouteMonitor, got ${raw.runtimeType}',
        raw,
      );
    }

    final peripherals = <LocalAudioPeripheral>[];
    for (var i = 0; i < raw.length; i++) {
      peripherals.add(parsePeripheralMap(raw[i], index: i));
    }
    return List<LocalAudioPeripheral>.unmodifiable(peripherals);
  }

  /// Fail-fast boundary parser for a single peripheral map from
  /// `AudioRouteMonitor.kt`.
  static LocalAudioPeripheral parsePeripheralMap(
    Object? rawItem, {
    int index = 0,
  }) {
    if (rawItem is! Map<Object?, Object?>) {
      throw FormatException(
        'AudioRouteMonitor peripheral[$index] must be a Map, got ${rawItem.runtimeType}',
        rawItem,
      );
    }

    final id = _requireNonEmptyString(rawItem, 'id', index);
    final name = _requireNonEmptyString(rawItem, 'name', index);
    final isActive = _requireBool(rawItem, 'isActive', index);
    final isConnected = _requireBool(rawItem, 'isConnected', index);
    final connectionTypeIndex =
        _requireInt(rawItem, 'connectionTypeIndex', index);

    final OutputPeripheralConnectionType connectionType;
    try {
      connectionType =
          OutputPeripheralConnectionType.fromProtoIndex(connectionTypeIndex);
    } on RangeError catch (e) {
      throw FormatException(
        'AudioRouteMonitor peripheral[$index].connectionTypeIndex out of range (0..5): ${e.message}',
        rawItem,
      );
    }

    final rawCategoryIndex = rawItem['categoryIndex'];
    final OutputPeripheralCategory? category;
    if (rawCategoryIndex == null) {
      category = null;
    } else if (rawCategoryIndex is int) {
      if (rawCategoryIndex == -1) {
        category = null;
      } else {
        try {
          category =
              OutputPeripheralCategory.fromProtoIndex(rawCategoryIndex);
        } on RangeError catch (e) {
          throw FormatException(
            'AudioRouteMonitor peripheral[$index].categoryIndex out of range (0..6): ${e.message}',
            rawItem,
          );
        }
      }
    } else {
      throw FormatException(
        'AudioRouteMonitor peripheral[$index].categoryIndex must be int? or -1, got ${rawCategoryIndex.runtimeType}',
        rawItem,
      );
    }

    final brand = _optionalNonEmptyString(rawItem, 'brand', index);
    final model = _optionalNonEmptyString(rawItem, 'model', index);

    return LocalAudioPeripheral(
      id: id,
      name: name,
      isActive: isActive,
      isConnected: isConnected,
      connectionType: connectionType,
      category: category,
      brand: brand,
      model: model,
    );
  }

  static String _requireNonEmptyString(
    Map<Object?, Object?> map,
    String key,
    int index,
  ) {
    final value = map[key];
    if (value is! String) {
      throw FormatException(
        'AudioRouteMonitor peripheral[$index].$key must be a String, got ${value.runtimeType}',
        map,
      );
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw FormatException(
        'AudioRouteMonitor peripheral[$index].$key must be non-empty',
        map,
      );
    }
    return trimmed;
  }

  static String? _optionalNonEmptyString(
    Map<Object?, Object?> map,
    String key,
    int index,
  ) {
    final value = map[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException(
        'AudioRouteMonitor peripheral[$index].$key must be String?, got ${value.runtimeType}',
        map,
      );
    }
    final trimmed = value.trim();
    return trimmed.isNotEmpty ? trimmed : null;
  }

  static bool _requireBool(
    Map<Object?, Object?> map,
    String key,
    int index,
  ) {
    final value = map[key];
    if (value is! bool) {
      throw FormatException(
        'AudioRouteMonitor peripheral[$index].$key must be a bool, got ${value.runtimeType}',
        map,
      );
    }
    return value;
  }

  static int _requireInt(
    Map<Object?, Object?> map,
    String key,
    int index,
  ) {
    final value = map[key];
    if (value is! int) {
      throw FormatException(
        'AudioRouteMonitor peripheral[$index].$key must be an int, got ${value.runtimeType}',
        map,
      );
    }
    return value;
  }
}
