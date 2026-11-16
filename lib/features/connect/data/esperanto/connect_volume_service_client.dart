// 1:1 replica of p199p/C2086nd.java (lines 80–82), p199p/a0f1.java (lines 409–422),
// p199p/lw51.java (lines 306–330), ConnectVolumeServiceImpl.cpp (lines 17–206),
// and liborbit-jni-spotify_memdump.so (0x1434d6
// `spotify.connect.esperanto.proto.ConnectVolumeService`, 0x36a7bc `volume_messages.proto`).

import 'dart:async';
import 'dart:typed_data';

import 'package:musify_mu/features/connect/data/mappers/volume_mapper.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart'
    as common_pb;
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    as empty_pb;

/// Pure Esperanto RPC and stream adapter for
/// `spotify.connect.esperanto.proto.ConnectVolumeService` (5 RPCs).
///
/// Delegates volume normalization, bounds checking, `LoggingParams` validation,
/// and protobuf mapping to [VolumeMapper] with zero cached volume state.
final class ConnectVolumeServiceClient extends EsperantoClientBase {
  static const String serviceName =
      'spotify.connect.esperanto.proto.ConnectVolumeService';

  final VolumeMapper volumeMapper;

  const ConnectVolumeServiceClient(
    super.transport, {
    this.volumeMapper = const VolumeMapper(),
  });

  /// 1:1 with `p199p/C2086nd.java:80–82` (`ConnectVolumeService.Volume`
  /// `callStream`).
  Stream<ConnectVolumeState> volume() {
    final payload = Uint8List.fromList(empty_pb.Empty().writeToBuffer());
    return callStream(serviceName, 'Volume', payload)
        .map(volumeMapper.volumeResponseFromBuffer);
  }

  /// 1:1 with `ConnectVolumeServiceImpl.cpp:87–105`
  /// (`ConnectVolumeService.LocalVolume` `callStream`).
  Stream<LocalVolumeEvent> localVolume() {
    final payload = Uint8List.fromList(empty_pb.Empty().writeToBuffer());
    return callStream(serviceName, 'LocalVolume', payload)
        .map(volumeMapper.localVolumeFromBuffer);
  }

  /// 1:1 with `p199p/a0f1.java:409–422` (`ConnectVolumeService.VolumeSet`
  /// `callSingle`).
  ///
  /// [volume] is normalized `[0.0, 1.0]` (never clamped; throws [RangeError]
  /// if non-finite or outside `[0.0, 1.0]`).
  Future<ConnectVolumeStatus> volumeSet({
    required double volume,
    common_pb.LoggingParams? loggingParams,
    String? groupDeviceIdentifier,
  }) async {
    final request = volumeMapper.toVolumeSetRequest(
      volume: volume,
      loggingParams: loggingParams,
      groupDeviceIdentifier: groupDeviceIdentifier,
    );
    final payload = Uint8List.fromList(request.writeToBuffer());
    final responseBytes = await callSingle(serviceName, 'VolumeSet', payload);
    return volumeMapper.statusResponseFromBuffer(responseBytes);
  }

  /// 1:1 with `p199p/lw51.java:306–315` (`ConnectVolumeService.VolumeUp`
  /// `callSingle`).
  Future<ConnectVolumeStatus> volumeUp({
    common_pb.LoggingParams? loggingParams,
    String? groupDeviceIdentifier,
  }) async {
    final request = volumeMapper.toVolumeUpRequest(
      loggingParams: loggingParams,
      groupDeviceIdentifier: groupDeviceIdentifier,
    );
    final payload = Uint8List.fromList(request.writeToBuffer());
    final responseBytes = await callSingle(serviceName, 'VolumeUp', payload);
    return volumeMapper.statusResponseFromBuffer(responseBytes);
  }

  /// 1:1 with `p199p/lw51.java:321–330` (`ConnectVolumeService.VolumeDown`
  /// `callSingle`).
  Future<ConnectVolumeStatus> volumeDown({
    common_pb.LoggingParams? loggingParams,
    String? groupDeviceIdentifier,
  }) async {
    final request = volumeMapper.toVolumeDownRequest(
      loggingParams: loggingParams,
      groupDeviceIdentifier: groupDeviceIdentifier,
    );
    final payload = Uint8List.fromList(request.writeToBuffer());
    final responseBytes = await callSingle(serviceName, 'VolumeDown', payload);
    return volumeMapper.statusResponseFromBuffer(responseBytes);
  }
}
