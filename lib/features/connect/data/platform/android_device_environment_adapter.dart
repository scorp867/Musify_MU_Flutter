import 'package:flutter/services.dart';
import 'package:musify_mu/features/connect/domain/interfaces/device_environment_port.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Android implementation of [DeviceEnvironmentPort] backed by
/// `DeviceEnvironmentBridge.kt` (`um.musify.mu/connect/device_environment`)
/// and `permission_handler` (`#47 §4.1`, `#47 §5`).
final class AndroidDeviceEnvironmentAdapter implements DeviceEnvironmentPort {
  static const String channelName = 'um.musify.mu/connect/device_environment';

  final MethodChannel _channel;
  final Future<ConnectPermissionStatus> Function()? _permissionRequester;
  final Future<bool> Function()? _appSettingsOpener;

  AndroidDeviceEnvironmentAdapter({
    MethodChannel? channel,
    Future<ConnectPermissionStatus> Function()? permissionRequester,
    Future<bool> Function()? appSettingsOpener,
  })  : _channel = switch (channel) {
          final provided? => provided,
          null => const MethodChannel(channelName),
        },
        _permissionRequester = permissionRequester,
        _appSettingsOpener = appSettingsOpener;

  @override
  Future<DeviceEnvironmentInfo> getDeviceEnvironment() async {
    final raw = await _channel.invokeMethod<Object>('getDeviceEnvironment');
    return parseEnvironmentMap(raw);
  }

  @override
  Future<ConnectPermissionStatus> requestConnectPermissions() async {
    if (_permissionRequester case final customRequester?) {
      return customRequester();
    }

    final statuses = await <ph.Permission>[
      ph.Permission.bluetoothConnect,
      ph.Permission.nearbyWifiDevices,
    ].request();

    final btGranted = switch (statuses[ph.Permission.bluetoothConnect]) {
      final ph.PermissionStatus status => status.isGranted,
      null => await ph.Permission.bluetoothConnect.isGranted,
    };
    final wifiGranted = switch (statuses[ph.Permission.nearbyWifiDevices]) {
      final ph.PermissionStatus status => status.isGranted,
      null => await ph.Permission.nearbyWifiDevices.isGranted,
    };

    try {
      final refreshed = await getDeviceEnvironment();
      return refreshed.permissionStatus;
    } on Object {
      return ConnectPermissionStatus(
        bluetoothConnect: btGranted,
        nearbyWifi: wifiGranted,
      );
    }
  }

  @override
  Future<bool> openAppSettings() {
    if (_appSettingsOpener case final customOpener?) {
      return customOpener();
    }
    return ph.openAppSettings();
  }

  /// Fail-fast boundary parser for `DeviceEnvironmentBridge.getDeviceEnvironment()`
  /// platform maps (`#47 §4.1`).
  static DeviceEnvironmentInfo parseEnvironmentMap(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      throw FormatException(
        'Expected Map from $channelName.getDeviceEnvironment, got ${raw.runtimeType}',
        raw,
      );
    }

    final androidId = _requireString(raw, 'androidId', allowEmpty: true);
    final deviceName = _requireString(raw, 'deviceName', allowEmpty: false);
    final brand = _requireString(raw, 'brand', allowEmpty: false);
    final model = _requireString(raw, 'model', allowEmpty: false);
    final osVersion = _requireString(raw, 'osVersion', allowEmpty: false);
    final sdkInt = _requireInt(raw, 'sdkInt', minValue: 1);
    final appVersionName =
        _requireString(raw, 'appVersionName', allowEmpty: false);
    final appVersionCode = _requireInt(raw, 'appVersionCode', minValue: 0);
    final deviceTypeWire =
        _requireString(raw, 'deviceTypeWire', allowEmpty: false);

    // Fail-fast verify that deviceTypeWire is a valid wire identifier.
    DeviceType.fromWireName(deviceTypeWire);

    final maxMusicVolumeSteps =
        _requireInt(raw, 'maxMusicVolumeSteps', minValue: 1);
    final currentMusicVolumeRatio = _requireDouble(
      raw,
      'currentMusicVolumeRatio',
      minValue: 0.0,
      maxValue: 1.0,
    );
    final hasBluetoothConnectPermission =
        _requireBool(raw, 'hasBluetoothConnectPermission');
    final hasNearbyWifiPermission =
        _requireBool(raw, 'hasNearbyWifiPermission');

    return DeviceEnvironmentInfo(
      androidId: androidId,
      deviceName: deviceName,
      brand: brand,
      model: model,
      osVersion: osVersion,
      sdkInt: sdkInt,
      appVersionName: appVersionName,
      appVersionCode: appVersionCode,
      deviceTypeWire: deviceTypeWire,
      maxMusicVolumeSteps: maxMusicVolumeSteps,
      currentMusicVolumeRatio: currentMusicVolumeRatio,
      hasBluetoothConnectPermission: hasBluetoothConnectPermission,
      hasNearbyWifiPermission: hasNearbyWifiPermission,
    );
  }

  static String _requireString(
    Map<Object?, Object?> map,
    String key, {
    required bool allowEmpty,
  }) {
    final value = map[key];
    if (value is! String) {
      throw FormatException(
        'DeviceEnvironmentInfo.$key must be a String, got ${value.runtimeType}',
        map,
      );
    }
    final trimmed = value.trim();
    if (!allowEmpty && trimmed.isEmpty) {
      throw FormatException(
        'DeviceEnvironmentInfo.$key must be non-empty',
        map,
      );
    }
    return trimmed;
  }

  static int _requireInt(
    Map<Object?, Object?> map,
    String key, {
    required int minValue,
  }) {
    final value = map[key];
    final int intValue;
    if (value is int) {
      intValue = value;
    } else {
      throw FormatException(
        'DeviceEnvironmentInfo.$key must be an int, got ${value.runtimeType}',
        map,
      );
    }
    if (intValue < minValue) {
      throw FormatException(
        'DeviceEnvironmentInfo.$key must be >= $minValue, got $intValue',
        map,
      );
    }
    return intValue;
  }

  static double _requireDouble(
    Map<Object?, Object?> map,
    String key, {
    required double minValue,
    required double maxValue,
  }) {
    final value = map[key];
    final double doubleValue;
    if (value is double) {
      doubleValue = value;
    } else if (value is int) {
      doubleValue = value.toDouble();
    } else {
      throw FormatException(
        'DeviceEnvironmentInfo.$key must be a double/num, got ${value.runtimeType}',
        map,
      );
    }
    if (!doubleValue.isFinite ||
        doubleValue < minValue ||
        doubleValue > maxValue) {
      throw FormatException(
        'DeviceEnvironmentInfo.$key must be finite within [$minValue, $maxValue], got $doubleValue',
        map,
      );
    }
    return doubleValue;
  }

  static bool _requireBool(Map<Object?, Object?> map, String key) {
    final value = map[key];
    if (value is! bool) {
      throw FormatException(
        'DeviceEnvironmentInfo.$key must be a bool, got ${value.runtimeType}',
        map,
      );
    }
    return value;
  }
}
