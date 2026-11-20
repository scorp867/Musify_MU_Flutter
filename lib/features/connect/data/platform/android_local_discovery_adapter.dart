import 'package:flutter/services.dart';
import 'package:musify_mu/features/connect/domain/interfaces/local_discovery_port.dart';

/// Android implementation of [LocalDiscoveryPort] backed by
/// `ConnectNsdDiscovery.kt` (`um.musify.mu/connect/nsd_control` and
/// `um.musify.mu/connect/nsd_events`, `#47 §4.4`).
final class AndroidLocalDiscoveryAdapter implements LocalDiscoveryPort {
  static const String controlChannelName = 'um.musify.mu/connect/nsd_control';
  static const String eventChannelName = 'um.musify.mu/connect/nsd_events';

  final MethodChannel _controlChannel;
  final EventChannel _eventChannel;
  Stream<List<DiscoveredNsdService>>? _cachedStream;

  AndroidLocalDiscoveryAdapter({
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
  Future<void> startDiscovery() async {
    await _controlChannel.invokeMethod<Object>('startDiscovery');
  }

  @override
  Future<void> stopDiscovery() async {
    await _controlChannel.invokeMethod<Object>('stopDiscovery');
  }

  @override
  Future<List<DiscoveredNsdService>> getDiscoveredServices() async {
    final raw =
        await _controlChannel.invokeMethod<Object>('getDiscoveredServices');
    return parseServiceList(raw);
  }

  @override
  Stream<List<DiscoveredNsdService>> watchDiscoveredServices() {
    if (_cachedStream case final existing?) {
      return existing;
    }
    final stream = _eventChannel
        .receiveBroadcastStream()
        .map<List<DiscoveredNsdService>>(parseServiceList);
    _cachedStream = stream;
    return stream;
  }

  /// Fail-fast boundary parser for `ConnectNsdDiscovery` service lists
  /// (`List<Map>` of `{serviceName, host, port, cPath, version, stack}`,
  /// `#47 §4.4`).
  static List<DiscoveredNsdService> parseServiceList(Object? raw) {
    if (raw is! List<Object?>) {
      throw FormatException(
        'Expected List of NSD service maps from $controlChannelName, got ${raw.runtimeType}',
        raw,
      );
    }

    final services = <DiscoveredNsdService>[];
    for (var i = 0; i < raw.length; i++) {
      services.add(parseServiceMap(raw[i], index: i));
    }
    return List<DiscoveredNsdService>.unmodifiable(services);
  }

  /// Fail-fast boundary parser for a single discovered NSD service map.
  static DiscoveredNsdService parseServiceMap(
    Object? rawItem, {
    int index = 0,
  }) {
    if (rawItem is! Map<Object?, Object?>) {
      throw FormatException(
        'ConnectNsdDiscovery service[$index] must be a Map, got ${rawItem.runtimeType}',
        rawItem,
      );
    }

    final serviceName =
        _requireString(rawItem, 'serviceName', index, allowEmpty: false);
    final host = _requireString(rawItem, 'host', index, allowEmpty: false);
    final port = _requirePort(rawItem, 'port', index);
    final cPath = _requireString(rawItem, 'cPath', index, allowEmpty: false);
    final version = _requireString(rawItem, 'version', index, allowEmpty: true);
    final stack = _optionalStringToEmpty(rawItem, 'stack', index);

    return DiscoveredNsdService(
      serviceName: serviceName,
      host: host,
      port: port,
      cPath: cPath,
      version: version,
      stack: stack,
    );
  }

  static String _requireString(
    Map<Object?, Object?> map,
    String key,
    int index, {
    required bool allowEmpty,
  }) {
    final value = map[key];
    if (value is! String) {
      throw FormatException(
        'ConnectNsdDiscovery service[$index].$key must be a String, got ${value.runtimeType}',
        map,
      );
    }
    final trimmed = value.trim();
    if (!allowEmpty && trimmed.isEmpty) {
      throw FormatException(
        'ConnectNsdDiscovery service[$index].$key must be non-empty',
        map,
      );
    }
    return trimmed;
  }

  static String _optionalStringToEmpty(
    Map<Object?, Object?> map,
    String key,
    int index,
  ) {
    final value = map[key];
    if (value == null) {
      return '';
    }
    if (value is! String) {
      throw FormatException(
        'ConnectNsdDiscovery service[$index].$key must be String?, got ${value.runtimeType}',
        map,
      );
    }
    return value.trim();
  }

  static int _requirePort(
    Map<Object?, Object?> map,
    String key,
    int index,
  ) {
    final value = map[key];
    if (value is! int) {
      throw FormatException(
        'ConnectNsdDiscovery service[$index].$key must be an int, got ${value.runtimeType}',
        map,
      );
    }
    if (value <= 0 || value > 65535) {
      throw FormatException(
        'ConnectNsdDiscovery service[$index].$key must be within [1, 65535], got $value',
        map,
      );
    }
    return value;
  }
}
