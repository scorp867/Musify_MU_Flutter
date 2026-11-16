// 1:1 replica of p199p/of40.java (lines 6–35), p199p/te40.java (lines 4–25),
// p199p/n8d.java (lines 759–873), and protos/spotify/connect/group.proto (lines 22–24, 53–56).

import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/connect/domain/models/connect_group_device.dart';

/// Capabilities of a Connect audio speaker group (`p199p/te40.java`).
@immutable
final class ConnectGroupCapabilities extends Equatable {
  /// Maximum number of devices allowed in the group (`te40.f228718a`).
  final int maxDevices;

  ConnectGroupCapabilities({required this.maxDevices}) {
    if (maxDevices < 0) {
      throw RangeError.value(
        maxDevices,
        'maxDevices',
        'Must be non-negative',
      );
    }
  }

  ConnectGroupCapabilities copyWith({int? maxDevices}) {
    return ConnectGroupCapabilities(
      maxDevices: switch (maxDevices) {
        final value? => value,
        null => this.maxDevices,
      },
    );
  }

  @override
  List<Object?> get props => [maxDevices];
}

/// Connect speaker group audio session payload matching `p199p/of40.java`.
@immutable
final class ConnectGroupData extends Equatable {
  /// Member devices in the group (`of40.f172443a`).
  final UnmodifiableListView<ConnectGroupDevice> devices;

  /// Group-level capabilities (`of40.f172444b`).
  final ConnectGroupCapabilities capabilities;

  ConnectGroupData({
    required List<ConnectGroupDevice> devices,
    required this.capabilities,
  }) : devices = UnmodifiableListView<ConnectGroupDevice>(
          List<ConnectGroupDevice>.of(devices),
        );

  ConnectGroupData copyWith({
    List<ConnectGroupDevice>? devices,
    ConnectGroupCapabilities? capabilities,
  }) {
    return ConnectGroupData(
      devices: switch (devices) {
        final value? => value,
        null => this.devices,
      },
      capabilities: switch (capabilities) {
        final value? => value,
        null => this.capabilities,
      },
    );
  }

  @override
  List<Object?> get props => [devices, capabilities];
}
