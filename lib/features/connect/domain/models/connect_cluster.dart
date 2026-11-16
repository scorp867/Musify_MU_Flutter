// 1:1 replica of p199p/tck.java (lines 6–47), p199p/n8d.java (lines 555–942),
// p199p/hea.java (lines 347–362), and p199p/wxu0.java (lines 1473–1484).

import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';

/// Immutable Connect cluster snapshot matching the exact 5 stored fields of
/// `p199p/tck.java`, with derived lookup getters serving as a single source
/// of truth.
@immutable
final class ConnectCluster extends Equatable {
  /// Whether playback is active in the Connect cluster (`tck.f228260a`).
  final bool isActive;

  /// Whether local playback should be used (`tck.f228261b`).
  final bool shouldUseLocalPlayback;

  /// Available devices in the cluster (`tck.f228262c`).
  final UnmodifiableListView<ConnectDevice> devices;

  /// Whether the active device is the local device (`tck.f228263d`).
  final bool isActiveOnSameDevice;

  /// Whether the cluster snapshot is synchronized with the backend (`tck.f228264e`).
  final bool isSyncedWithBackend;

  ConnectCluster({
    required this.isActive,
    required this.shouldUseLocalPlayback,
    required List<ConnectDevice> devices,
    required this.isActiveOnSameDevice,
    required this.isSyncedWithBackend,
  }) : devices = UnmodifiableListView<ConnectDevice>(
          List<ConnectDevice>.of(devices),
        ) {
    var activeCount = 0;
    for (final device in this.devices) {
      if (device.isActive) {
        activeCount += 1;
        if (activeCount > 1) {
          throw ArgumentError.value(
            devices,
            'devices',
            'At most one device in ConnectCluster may have isActive == true',
          );
        }
      }
    }
  }

  /// Active device in the cluster, or `null` when none is active.
  ConnectDevice? get activeDevice {
    for (final device in devices) {
      if (device.isActive) {
        return device;
      }
    }
    return null;
  }

  /// Active remote device matching `p199p/hea.java:355` (`isActive && !isSelf`).
  ConnectDevice? get activeRemoteDevice {
    for (final device in devices) {
      if (device.isActive && !device.isSelf) {
        return device;
      }
    }
    return null;
  }

  /// Local (self) device matching `p199p/wxu0.java:1478` (`isSelf`).
  ConnectDevice? get localDevice {
    for (final device in devices) {
      if (device.isSelf) {
        return device;
      }
    }
    return null;
  }

  /// Identifier of [activeDevice]: non-empty `connectStateIdentifier`, else
  /// non-empty `localIdentifier`, else `null`.
  String? get activeDeviceId {
    final active = activeDevice;
    if (active == null) {
      return null;
    }
    if (active.connectStateIdentifier.isNotEmpty) {
      return active.connectStateIdentifier;
    }
    if (active.localIdentifier.isNotEmpty) {
      return active.localIdentifier;
    }
    return null;
  }

  /// Derived lookup map keyed by `connectStateIdentifier` (or `localIdentifier`
  /// when `connectStateIdentifier` is empty) for devices with a non-empty key.
  UnmodifiableMapView<String, ConnectDevice> get devicesById {
    final entries = <String, ConnectDevice>{};
    for (final device in devices) {
      final key = device.connectStateIdentifier.isNotEmpty
          ? device.connectStateIdentifier
          : device.localIdentifier;
      if (key.isNotEmpty) {
        entries[key] = device;
      }
    }
    return UnmodifiableMapView<String, ConnectDevice>(entries);
  }

  ConnectCluster copyWith({
    bool? isActive,
    bool? shouldUseLocalPlayback,
    List<ConnectDevice>? devices,
    bool? isActiveOnSameDevice,
    bool? isSyncedWithBackend,
  }) {
    return ConnectCluster(
      isActive: switch (isActive) {
        final value? => value,
        null => this.isActive,
      },
      shouldUseLocalPlayback: switch (shouldUseLocalPlayback) {
        final value? => value,
        null => this.shouldUseLocalPlayback,
      },
      devices: switch (devices) {
        final value? => value,
        null => this.devices,
      },
      isActiveOnSameDevice: switch (isActiveOnSameDevice) {
        final value? => value,
        null => this.isActiveOnSameDevice,
      },
      isSyncedWithBackend: switch (isSyncedWithBackend) {
        final value? => value,
        null => this.isSyncedWithBackend,
      },
    );
  }

  @override
  List<Object?> get props => [
        isActive,
        shouldUseLocalPlayback,
        devices,
        isActiveOnSameDevice,
        isSyncedWithBackend,
      ];
}
