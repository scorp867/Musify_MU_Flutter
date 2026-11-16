// 1:1 replica of p199p/s77.java, p199p/C2086nd.java (lines 26, 51, 86),
// p199p/c8k.java (line 101), p199p/v8k.java, p199p/fx3.java, p199p/d7g.java,
// p199p/c8r.java, p199p/dmf.java, p199p/asq.java,
// ConnectServiceImpl.cpp (lines 184–858), and liborbit-jni-spotify_memdump.so
// (0x1a2b68 `spotify.connect.esperanto.proto.ConnectService`,
// 0x3a5024 `connect_messages.proto`).

import 'dart:async';
import 'dart:typed_data';

import 'package:musify_mu/features/connect/data/mappers/connect_proto_mappers.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart'
    as common_pb;
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pb.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/domain/models/connect_cluster.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    as empty_pb;

/// Pure Esperanto RPC and stream adapter for
/// `spotify.connect.esperanto.proto.ConnectService` (18 RPCs).
///
/// Delegates protobuf serialization/deserialization to [ConnectProtoMappers]
/// and retains zero cached cluster or transfer state (`NativeEsperantoTransport`
/// owns replayable broadcast streams and native FFI dispatch).
final class ConnectServiceClient extends EsperantoClientBase {
  static const String serviceName =
      'spotify.connect.esperanto.proto.ConnectService';

  static final RegExp _commandIdHexPattern = RegExp(r'^[0-9a-fA-F]{32}$');
  static const int _maxUint32 = 0xFFFFFFFF;

  final ConnectProtoMappers mappers;

  const ConnectServiceClient(
    super.transport, {
    this.mappers = const ConnectProtoMappers(),
  });

  /// 1:1 with `p199p/s77.java:3743` (`ConnectService.State` `callStream`).
  ///
  /// Accepts valid 0-byte proto3 `StateResponse` payloads (when all bools are
  /// `false` and `devices` is empty) via [ConnectProtoMappers.clusterFromBuffer].
  Stream<ConnectCluster> state({
    bool showOfflineDevicesInCore = false,
    bool showOfflineAmazonDevicesAsOnline = false,
    bool includeLocalDevice = false,
    bool excludeNonLocalDevices = false,
    bool includeUserMatchUnauthenticatedDevices = false,
  }) {
    final request = mappers.buildStateRequest(
      showOfflineDevicesInCore: showOfflineDevicesInCore,
      showOfflineAmazonDevicesAsOnline: showOfflineAmazonDevicesAsOnline,
      includeLocalDevice: includeLocalDevice,
      excludeNonLocalDevices: excludeNonLocalDevices,
      includeUserMatchUnauthenticatedDevices:
          includeUserMatchUnauthenticatedDevices,
    );
    final payload = Uint8List.fromList(request.writeToBuffer());
    return callStream(serviceName, 'State', payload)
        .map(mappers.clusterFromBuffer);
  }

  /// 1:1 with `p199p/s77.java` + `p199p/v8k.java` + `p199p/fx3.java:758–773`
  /// (`ConnectService.Transfer` `callSingle`).
  Future<TransferState> transfer({
    required String connectDeviceIdentifier,
    common_pb.LoggingParams? loggingParams,
    bool? dodo,
  }) async {
    final request = mappers.buildTransferRequest(
      connectDeviceIdentifier: connectDeviceIdentifier,
      loggingParams: loggingParams,
      dodo: dodo,
    );
    final payload = Uint8List.fromList(request.writeToBuffer());
    final responseBytes = await callSingle(serviceName, 'Transfer', payload);
    final String? intentionId;
    if (loggingParams != null &&
        loggingParams.hasCommandId() &&
        loggingParams.commandId.isNotEmpty) {
      intentionId = loggingParams.commandId;
    } else {
      intentionId = null;
    }
    return mappers.transferStateFromStatusBuffer(
      responseBytes,
      targetDeviceId: connectDeviceIdentifier,
      intentionId: intentionId,
    );
  }

  /// 1:1 with `ConnectServiceImpl.cpp:484–515` (`ConnectService.SendCommand`
  /// `callSingle`).
  ///
  /// Validates non-blank [connectDeviceIdentifier] and [commandJson], and
  /// validates `loggingParams.commandId` (empty or 32 hex chars) before sending.
  Future<connect_pb.SendCommandResponse> sendCommand({
    required String connectDeviceIdentifier,
    required String commandJson,
    common_pb.LoggingParams? loggingParams,
  }) async {
    _requireNonBlankIdentifier(
      connectDeviceIdentifier,
      'connectDeviceIdentifier',
    );
    _requireNonBlankIdentifier(commandJson, 'commandJson');
    _validateLoggingParamsCommandId(loggingParams);

    final request = connect_pb.SendCommandRequest(
      connectDeviceIdentifier: connectDeviceIdentifier,
      commandJson: commandJson,
      loggingParams: loggingParams,
    );
    final payload = Uint8List.fromList(request.writeToBuffer());
    final responseBytes = await callSingle(serviceName, 'SendCommand', payload);
    return connect_pb.SendCommandResponse.fromBuffer(responseBytes)..freeze();
  }

  /// 1:1 with `p199p/s77.java:1372` (`ConnectService.Pull` `callSingle`).
  Future<common_pb.Status> pull({
    common_pb.LoggingParams? loggingParams,
  }) async {
    final request = mappers.buildPullRequest(loggingParams: loggingParams);
    final payload = Uint8List.fromList(request.writeToBuffer());
    final responseBytes = await callSingle(serviceName, 'Pull', payload);
    return common_pb.StatusResponse.fromBuffer(responseBytes).status;
  }

  /// 1:1 with `ConnectServiceImpl.cpp:541–563` (`ConnectService.Rename`
  /// `callSingle`).
  Future<common_pb.Status> rename({
    required String deviceId,
    required String newName,
  }) async {
    _requireNonBlankIdentifier(deviceId, 'deviceId');
    _requireNonBlankIdentifier(newName, 'newName');

    final request = connect_pb.RenameRequest(
      deviceId: deviceId,
      newName: newName,
    );
    final payload = Uint8List.fromList(request.writeToBuffer());
    final responseBytes = await callSingle(serviceName, 'Rename', payload);
    return common_pb.StatusResponse.fromBuffer(responseBytes).status;
  }

  /// 1:1 with `p199p/s77.java:801` (`ConnectService.Logout` `callSingle`).
  Future<common_pb.Status> logout({
    required String connectDeviceIdentifier,
  }) async {
    final request = mappers.buildLogoutRequest(
      connectDeviceIdentifier: connectDeviceIdentifier,
    );
    final payload = Uint8List.fromList(request.writeToBuffer());
    final responseBytes = await callSingle(serviceName, 'Logout', payload);
    return common_pb.StatusResponse.fromBuffer(responseBytes).status;
  }

  /// 1:1 with `p199p/s77.java:1107–1114` + `p199p/d7g.java:744`
  /// (`ConnectService.NotifyAudioRouteChanged` `callSingle`).
  Future<void> notifyAudioRouteChanged({
    String? audioOutputDeviceName,
    OutputPeripheralConnectionType? connectionType,
    String? audioOutputDeviceBrand,
    String? audioOutputDeviceModel,
    OutputPeripheralCategory? category,
  }) async {
    final request = mappers.buildNotifyAudioRouteChangedRequest(
      audioOutputDeviceName: audioOutputDeviceName,
      connectionType: connectionType,
      audioOutputDeviceBrand: audioOutputDeviceBrand,
      audioOutputDeviceModel: audioOutputDeviceModel,
      category: category,
    );
    final payload = Uint8List.fromList(request.writeToBuffer());
    final responseBytes = await callSingle(
      serviceName,
      'NotifyAudioRouteChanged',
      payload,
    );
    empty_pb.Empty.fromBuffer(responseBytes);
  }

  /// 1:1 with `p199p/s77.java:3259` + `p199p/c8r.java:218`
  /// (`ConnectService.SetPreferredIncarnation` `callSingle`).
  Future<common_pb.Status> setPreferredIncarnation({
    required String deviceId,
    IncarnationLoginType? preferredLoginType,
    common_pb.LoggingParams? loggingParams,
  }) async {
    final request = mappers.buildSetPreferredIncarnationRequest(
      deviceId: deviceId,
      preferredLoginType: preferredLoginType,
      loggingParams: loggingParams,
    );
    final payload = Uint8List.fromList(request.writeToBuffer());
    final responseBytes = await callSingle(
      serviceName,
      'SetPreferredIncarnation',
      payload,
    );
    return common_pb.StatusResponse.fromBuffer(responseBytes).status;
  }

  /// 1:1 with `ConnectServiceImpl.cpp:647–660`
  /// (`ConnectService.CreateStaticGroup` `callSingle`).
  Future<void> createStaticGroup() async {
    final payload = Uint8List.fromList(
      connect_pb.CreateStaticGroupRequest().writeToBuffer(),
    );
    final responseBytes = await callSingle(
      serviceName,
      'CreateStaticGroup',
      payload,
    );
    connect_pb.CreateStaticGroupResponse.fromBuffer(responseBytes);
  }

  /// 1:1 with `ConnectServiceImpl.cpp:662–675`
  /// (`ConnectService.RenameGroup` `callSingle`).
  Future<void> renameGroup() async {
    final payload = Uint8List.fromList(
      connect_pb.RenameGroupRequest().writeToBuffer(),
    );
    final responseBytes = await callSingle(
      serviceName,
      'RenameGroup',
      payload,
    );
    connect_pb.RenameGroupResponse.fromBuffer(responseBytes);
  }

  /// 1:1 with `p199p/s77.java:1576` (`ConnectService.AddDeviceToGroup`
  /// `callSingle`).
  Future<connect_pb.AddDeviceToGroupResponse> addDeviceToGroup({
    required String connectDeviceIdentifier,
    required String groupDeviceIdentifier,
    common_pb.LoggingParams? loggingParams,
  }) async {
    final request = mappers.buildAddDeviceToGroupRequest(
      connectDeviceIdentifier: connectDeviceIdentifier,
      groupDeviceIdentifier: groupDeviceIdentifier,
      loggingParams: loggingParams,
    );
    final payload = Uint8List.fromList(request.writeToBuffer());
    final responseBytes = await callSingle(
      serviceName,
      'AddDeviceToGroup',
      payload,
    );
    return connect_pb.AddDeviceToGroupResponse.fromBuffer(responseBytes)
      ..freeze();
  }

  /// 1:1 with `p199p/s77.java:1933` (`ConnectService.RemoveDeviceFromGroup`
  /// `callSingle`).
  Future<connect_pb.RemoveDeviceFromGroupResponse> removeDeviceFromGroup({
    required String connectDeviceIdentifier,
    required String groupDeviceIdentifier,
    common_pb.LoggingParams? loggingParams,
  }) async {
    final request = mappers.buildRemoveDeviceFromGroupRequest(
      connectDeviceIdentifier: connectDeviceIdentifier,
      groupDeviceIdentifier: groupDeviceIdentifier,
      loggingParams: loggingParams,
    );
    final payload = Uint8List.fromList(request.writeToBuffer());
    final responseBytes = await callSingle(
      serviceName,
      'RemoveDeviceFromGroup',
      payload,
    );
    return connect_pb.RemoveDeviceFromGroupResponse.fromBuffer(responseBytes)
      ..freeze();
  }

  /// 1:1 with `ConnectServiceImpl.cpp:743–775` (`ConnectService.DeleteGroup`
  /// `callSingle`).
  Future<connect_pb.DeleteGroupResponse> deleteGroup({
    required String connectDeviceIdentifier,
    common_pb.LoggingParams? loggingParams,
  }) async {
    _requireNonBlankIdentifier(
      connectDeviceIdentifier,
      'connectDeviceIdentifier',
    );
    _validateLoggingParamsCommandId(loggingParams);

    final request = connect_pb.DeleteGroupRequest(
      connectDeviceIdentifier: connectDeviceIdentifier,
      loggingParams: loggingParams,
    );
    final payload = Uint8List.fromList(request.writeToBuffer());
    final responseBytes = await callSingle(
      serviceName,
      'DeleteGroup',
      payload,
    );
    return connect_pb.DeleteGroupResponse.fromBuffer(responseBytes)..freeze();
  }

  /// 1:1 with `p199p/dmf.java:407–412`
  /// (`ConnectService.ClusterUpdateAfterBackendConnection` `callSingle`).
  Future<bool> clusterUpdateAfterBackendConnection() async {
    final payload = Uint8List.fromList(empty_pb.Empty().writeToBuffer());
    final responseBytes = await callSingle(
      serviceName,
      'ClusterUpdateAfterBackendConnection',
      payload,
    );
    return connect_pb.ClusterUpdateAfterBackendConnectionResponse.fromBuffer(
      responseBytes,
    ).hasReceivedClusterUpdateAfterBackendConnection;
  }

  /// 1:1 with `p199p/c8k.java:101` (`ConnectService.InstallSpotify`
  /// `callStream`).
  ///
  /// Validates non-blank [connectDeviceIdentifier], unsigned 32-bit [port]
  /// range (`0..0xFFFFFFFF`), and `loggingParams.commandId`.
  Stream<connect_pb.InstallSpotifyState> installSpotify({
    required String connectDeviceIdentifier,
    required int port,
    common_pb.LoggingParams? loggingParams,
  }) {
    _requireNonBlankIdentifier(
      connectDeviceIdentifier,
      'connectDeviceIdentifier',
    );
    if (port < 0 || port > _maxUint32) {
      throw RangeError.range(
        port,
        0,
        _maxUint32,
        'port',
        'Must be within [0, $_maxUint32]',
      );
    }
    _validateLoggingParamsCommandId(loggingParams);

    final request = connect_pb.InstallSpotifyRequest(
      connectDeviceIdentifier: connectDeviceIdentifier,
      port: port,
      loggingParams: loggingParams,
    );
    final payload = Uint8List.fromList(request.writeToBuffer());
    return callStream(serviceName, 'InstallSpotify', payload).map(
      (bytes) => connect_pb.InstallSpotifyStatusUpdate.fromBuffer(bytes)
          .currentState,
    );
  }

  /// 1:1 with `p199p/C2086nd.java:26` + `p199p/asq.java:130`
  /// (`ConnectService.PerformDiscovery` `callSingle`).
  Future<void> performDiscovery() async {
    final payload = Uint8List.fromList(empty_pb.Empty().writeToBuffer());
    final responseBytes = await callSingle(
      serviceName,
      'PerformDiscovery',
      payload,
    );
    empty_pb.Empty.fromBuffer(responseBytes);
  }

  /// 1:1 with `p199p/C2086nd.java:51` + `p199p/asq.java:140`
  /// (`ConnectService.RefreshCluster` `callSingle`).
  Future<void> refreshCluster() async {
    final payload = Uint8List.fromList(empty_pb.Empty().writeToBuffer());
    final responseBytes = await callSingle(
      serviceName,
      'RefreshCluster',
      payload,
    );
    empty_pb.Empty.fromBuffer(responseBytes);
  }

  /// 1:1 with `p199p/C2086nd.java:86` + `p199p/asq.java:141`
  /// (`ConnectService.WakeSleepingClusterDevices` `callSingle`).
  Future<void> wakeSleepingClusterDevices() async {
    final payload = Uint8List.fromList(empty_pb.Empty().writeToBuffer());
    final responseBytes = await callSingle(
      serviceName,
      'WakeSleepingClusterDevices',
      payload,
    );
    empty_pb.Empty.fromBuffer(responseBytes);
  }

  static void _requireNonBlankIdentifier(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'Must be non-empty');
    }
  }

  static void _validateLoggingParamsCommandId(
    common_pb.LoggingParams? loggingParams,
  ) {
    if (loggingParams != null &&
        loggingParams.hasCommandId() &&
        loggingParams.commandId.isNotEmpty &&
        !_commandIdHexPattern.hasMatch(loggingParams.commandId)) {
      throw FormatException(
        'LoggingParams.commandId must be empty or 32 hexadecimal characters',
        loggingParams.commandId,
      );
    }
  }
}
