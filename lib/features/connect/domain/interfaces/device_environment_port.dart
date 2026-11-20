import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';

/// Immutable snapshot of Bluetooth and Local Network runtime permissions
/// required for full Spotify Connect discovery and naming (`#47 §4.1`, `#47 §5`).
@immutable
final class ConnectPermissionStatus extends Equatable {
  final bool bluetoothConnect;
  final bool nearbyWifi;

  const ConnectPermissionStatus({
    required this.bluetoothConnect,
    required this.nearbyWifi,
  });

  /// Whether both `BLUETOOTH_CONNECT` and `NEARBY_WIFI_DEVICES` are granted.
  bool get allGranted => bluetoothConnect && nearbyWifi;

  /// Whether either permission is missing.
  bool get anyMissing => !bluetoothConnect || !nearbyWifi;

  @override
  List<Object?> get props => [bluetoothConnect, nearbyWifi];
}

/// Immutable Android hardware, OS, volume, and permission environment snapshot
/// returned by `DeviceEnvironmentBridge.kt` (`#47 §4.1`).
@immutable
final class DeviceEnvironmentInfo extends Equatable {
  final String androidId;
  final String deviceName;
  final String brand;
  final String model;
  final String osVersion;
  final int sdkInt;
  final String appVersionName;
  final int appVersionCode;
  final String deviceTypeWire;
  final int maxMusicVolumeSteps;
  final double currentMusicVolumeRatio;
  final bool hasBluetoothConnectPermission;
  final bool hasNearbyWifiPermission;

  DeviceEnvironmentInfo({
    required this.androidId,
    required this.deviceName,
    required this.brand,
    required this.model,
    required this.osVersion,
    required this.sdkInt,
    required this.appVersionName,
    required this.appVersionCode,
    required this.deviceTypeWire,
    required this.maxMusicVolumeSteps,
    required this.currentMusicVolumeRatio,
    required this.hasBluetoothConnectPermission,
    required this.hasNearbyWifiPermission,
  }) {
    if (deviceName.trim().isEmpty) {
      throw ArgumentError.value(
        deviceName,
        'deviceName',
        'Must be non-empty',
      );
    }
    if (brand.trim().isEmpty) {
      throw ArgumentError.value(brand, 'brand', 'Must be non-empty');
    }
    if (model.trim().isEmpty) {
      throw ArgumentError.value(model, 'model', 'Must be non-empty');
    }
    if (sdkInt <= 0) {
      throw RangeError.value(sdkInt, 'sdkInt', 'Must be positive');
    }
    if (appVersionName.trim().isEmpty) {
      throw ArgumentError.value(
        appVersionName,
        'appVersionName',
        'Must be non-empty',
      );
    }
    if (deviceTypeWire.trim().isEmpty) {
      throw ArgumentError.value(
        deviceTypeWire,
        'deviceTypeWire',
        'Must be non-empty',
      );
    }
    if (maxMusicVolumeSteps <= 0) {
      throw RangeError.value(
        maxMusicVolumeSteps,
        'maxMusicVolumeSteps',
        'Must be positive',
      );
    }
    if (!currentMusicVolumeRatio.isFinite ||
        currentMusicVolumeRatio < 0.0 ||
        currentMusicVolumeRatio > 1.0) {
      throw RangeError.range(
        currentMusicVolumeRatio,
        0,
        1,
        'currentMusicVolumeRatio',
        'Must be a finite value within [0.0, 1.0]',
      );
    }
  }

  /// Domain [DeviceType] resolved from [deviceTypeWire].
  DeviceType get deviceType => DeviceType.fromWireName(deviceTypeWire);

  /// Initial system volume scaled to Connect wire units (`0..65535`).
  int get initialWireVolume => (currentMusicVolumeRatio * 65535.0).round();

  /// Structured runtime permission snapshot.
  ConnectPermissionStatus get permissionStatus => ConnectPermissionStatus(
        bluetoothConnect: hasBluetoothConnectPermission,
        nearbyWifi: hasNearbyWifiPermission,
      );

  @override
  List<Object?> get props => [
        androidId,
        deviceName,
        brand,
        model,
        osVersion,
        sdkInt,
        appVersionName,
        appVersionCode,
        deviceTypeWire,
        maxMusicVolumeSteps,
        currentMusicVolumeRatio,
        hasBluetoothConnectPermission,
        hasNearbyWifiPermission,
      ];
}

/// Domain port for reading Android device hardware identity, OS music stream
/// volume capabilities, and requesting Bluetooth / Local Network permissions
/// (`#47 §4.1`, `#47 §5`).
abstract class DeviceEnvironmentPort {
  /// Queries the current Android device hardware and permission snapshot.
  Future<DeviceEnvironmentInfo> getDeviceEnvironment();

  /// Prompts the user for `BLUETOOTH_CONNECT` and `NEARBY_WIFI_DEVICES`
  /// runtime permissions and returns the updated [ConnectPermissionStatus].
  Future<ConnectPermissionStatus> requestConnectPermissions();

  /// Opens the OS application settings screen when permissions are permanently
  /// denied.
  Future<bool> openAppSettings();
}
