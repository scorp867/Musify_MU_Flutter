// 1:1 replica of p199p/n8d.java (lines 555–562, 935–942), p199p/tck.java,
// and ConnectServiceImpl.cpp (lines 353–434).

import 'dart:typed_data';

import 'package:musify_mu/features/connect/data/mappers/device_info_mapper.dart';
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pb.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/domain/models/connect_cluster.dart';

/// Pure deterministic mapper from `ConnectMessages$StateResponse` to
/// [ConnectCluster].
final class ClusterMapper {
  final DeviceInfoMapper deviceInfoMapper;

  const ClusterMapper({this.deviceInfoMapper = const DeviceInfoMapper()});

  /// Decodes raw `StateResponse` wire bytes and maps to [ConnectCluster].
  ConnectCluster clusterFromBuffer(Uint8List bytes) {
    final pb = connect_pb.StateResponse.fromBuffer(bytes);
    return mapCluster(pb);
  }

  /// Maps [connect_pb.StateResponse] to [ConnectCluster].
  ///
  /// Proto3 implicit-presence boolean fields (`isActive`,
  /// `shouldUseLocalPlayback`, `isActiveOnSameDevice`, `isSyncedWithBackend`)
  /// are read directly so offline/empty responses with `false` omitted on the
  /// wire map cleanly. Enforces at most one active device via [ConnectCluster].
  ConnectCluster mapCluster(connect_pb.StateResponse pb) {
    final devices =
        pb.devices.map(deviceInfoMapper.mapDevice).toList(growable: false);

    return ConnectCluster(
      isActive: pb.isActive,
      shouldUseLocalPlayback: pb.shouldUseLocalPlayback,
      devices: devices,
      isActiveOnSameDevice: pb.isActiveOnSameDevice,
      isSyncedWithBackend: pb.isSyncedWithBackend,
    );
  }
}
