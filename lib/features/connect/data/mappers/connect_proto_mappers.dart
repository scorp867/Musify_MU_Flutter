// 1:1 replica of p199p/n8d.java (lines 514–1050), p199p/v8k.java (lines 32–51),
// p199p/s77.java, p199p/C2086nd.java, p199p/yld1.java, and ConnectServiceImpl.cpp.

import 'dart:typed_data';

import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:musify_mu/features/connect/data/mappers/cluster_mapper.dart';
import 'package:musify_mu/features/connect/data/mappers/device_info_mapper.dart';
import 'package:musify_mu/features/connect/data/mappers/group_mapper.dart';
import 'package:musify_mu/features/connect/data/mappers/volume_mapper.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart'
    as common_pb;
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pb.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/data/proto/es_volume_messages.pb.dart'
    as volume_pb;
import 'package:musify_mu/features/connect/data/proto/group.pb.dart'
    as group_pb;
import 'package:musify_mu/features/connect/domain/models/connect_capabilities.dart';
import 'package:musify_mu/features/connect/domain/models/connect_cluster.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/connect_group_data.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/domain/models/hifi_status.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';

/// Master coordinator for Spotify Connect Esperanto wire-to-domain mappers,
/// delegating cluster, device, volume, and group mapping to dedicated
/// sub-mappers while providing cross-cutting status, logging, and request
/// serialization helpers (`p199p/s77.java`, `p199p/C2086nd.java`, `p199p/v8k.java`).
final class ConnectProtoMappers {
  static final RegExp _commandIdHexPattern = RegExp(r'^[0-9a-fA-F]{32}$');

  final ClusterMapper clusterMapper;
  final DeviceInfoMapper deviceInfoMapper;
  final VolumeMapper volumeMapper;
  final GroupMapper groupMapper;

  const ConnectProtoMappers({
    this.clusterMapper = const ClusterMapper(),
    this.deviceInfoMapper = const DeviceInfoMapper(),
    this.volumeMapper = const VolumeMapper(),
    this.groupMapper = const GroupMapper(),
  });

  /// Delegates `StateResponse` wire bytes to [ClusterMapper].
  ConnectCluster clusterFromBuffer(Uint8List bytes) =>
      clusterMapper.clusterFromBuffer(bytes);

  /// Delegates `StateResponse` to [ClusterMapper].
  ConnectCluster mapCluster(connect_pb.StateResponse pb) =>
      clusterMapper.mapCluster(pb);

  /// Delegates `StateResponse_Device` wire bytes to [DeviceInfoMapper].
  ConnectDevice deviceFromBuffer(Uint8List bytes) =>
      deviceInfoMapper.deviceFromBuffer(bytes);

  /// Delegates `StateResponse_Device` to [DeviceInfoMapper].
  ConnectDevice mapDevice(connect_pb.StateResponse_Device pb) =>
      deviceInfoMapper.mapDevice(pb);

  /// Delegates `OutputPeripheral` to [DeviceInfoMapper].
  OutputPeripheral mapOutputPeripheral(connect_pb.OutputPeripheral pb) =>
      deviceInfoMapper.mapOutputPeripheral(pb);

  /// Delegates `StateResponse_Incarnation` to [DeviceInfoMapper].
  Incarnation mapIncarnation(connect_pb.StateResponse_Incarnation pb) =>
      deviceInfoMapper.mapIncarnation(pb);

  /// Delegates `StateResponse_Hifi` to [DeviceInfoMapper].
  ConnectHifiStatus mapHifiStatus(connect_pb.StateResponse_Hifi pb) =>
      deviceInfoMapper.mapHifiStatus(pb);

  /// Delegates `capabilities` JSON parsing to [DeviceInfoMapper].
  List<ConnectCapabilityEntry> parseCapabilitiesJson(String rawJson) =>
      deviceInfoMapper.parseCapabilitiesJson(rawJson);

  /// Delegates `GroupData` wire bytes to [GroupMapper].
  ConnectGroupData groupDataFromBuffer(Uint8List bytes) =>
      groupMapper.groupDataFromBuffer(bytes);

  /// Delegates `GroupData` to [GroupMapper].
  ConnectGroupData mapGroupData(group_pb.GroupData pb) =>
      groupMapper.mapGroupData(pb);

  /// Delegates `VolumeResponse` wire bytes to [VolumeMapper].
  ConnectVolumeState volumeResponseFromBuffer(
    Uint8List bytes, {
    ConnectDevice? activeDevice,
    VolumeOutputMode outputMode = VolumeOutputMode.remote,
    double? localVolume,
    bool isChangingVolume = false,
    Set<String> pendingGroupDeviceIds = const <String>{},
  }) =>
      volumeMapper.volumeResponseFromBuffer(
        bytes,
        activeDevice: activeDevice,
        outputMode: outputMode,
        localVolume: localVolume,
        isChangingVolume: isChangingVolume,
        pendingGroupDeviceIds: pendingGroupDeviceIds,
      );

  /// Delegates `VolumeResponse` to [VolumeMapper].
  ConnectVolumeState mapVolumeResponse(
    volume_pb.VolumeResponse pb, {
    ConnectDevice? activeDevice,
    VolumeOutputMode outputMode = VolumeOutputMode.remote,
    double? localVolume,
    bool isChangingVolume = false,
    Set<String> pendingGroupDeviceIds = const <String>{},
  }) =>
      volumeMapper.mapVolumeResponse(
        pb,
        activeDevice: activeDevice,
        outputMode: outputMode,
        localVolume: localVolume,
        isChangingVolume: isChangingVolume,
        pendingGroupDeviceIds: pendingGroupDeviceIds,
      );

  /// Delegates `LocalVolumeResponse` wire bytes to [VolumeMapper].
  LocalVolumeEvent localVolumeFromBuffer(Uint8List bytes) =>
      volumeMapper.localVolumeFromBuffer(bytes);

  /// Delegates `LocalVolumeResponse` to [VolumeMapper].
  LocalVolumeEvent mapLocalVolume(volume_pb.LocalVolumeResponse pb) =>
      volumeMapper.mapLocalVolume(pb);

  /// Delegates `Status` mapping to [VolumeMapper].
  ConnectVolumeStatus mapVolumeStatus(common_pb.Status status) =>
      volumeMapper.mapStatus(status);

  /// Delegates `StatusResponse` wire bytes to [VolumeMapper].
  ConnectVolumeStatus volumeStatusResponseFromBuffer(Uint8List bytes) =>
      volumeMapper.statusResponseFromBuffer(bytes);

  /// Maps `CommonMessages$Status` to [TransferFailureReason], returning `null`
  /// for `Status.OK` (`p199p/v8k.java:32–51`, `p199p/yld1.java`).
  TransferFailureReason? mapStatusToTransferFailureReason(
    common_pb.Status status,
  ) {
    if (status == common_pb.Status.OK) {
      return null;
    } else if (status == common_pb.Status.NOT_FOUND) {
      return TransferFailureReason.notFound;
    } else if (status == common_pb.Status.INVALID_ARGUMENTS) {
      return TransferFailureReason.invalidArguments;
    } else if (status == common_pb.Status.BACKEND_FAILURE) {
      return TransferFailureReason.backendFailure;
    } else if (status == common_pb.Status.UNIMPLEMENTED) {
      return TransferFailureReason.unknown;
    } else {
      throw FormatException(
        'Unsupported Status proto enum: ${status.value} (${status.name})',
      );
    }
  }

  /// Decodes raw `StatusResponse` bytes into terminal [TransferState].
  TransferState transferStateFromStatusBuffer(
    Uint8List bytes, {
    required String targetDeviceId,
    String? intentionId,
    String? ackId,
  }) {
    final response = common_pb.StatusResponse.fromBuffer(bytes);
    return mapStatusResponseToTransferState(
      response,
      targetDeviceId: targetDeviceId,
      intentionId: intentionId,
      ackId: ackId,
    );
  }

  /// Maps [common_pb.StatusResponse] into [TransferSucceeded] or [TransferFailed].
  TransferState mapStatusResponseToTransferState(
    common_pb.StatusResponse response, {
    required String targetDeviceId,
    String? intentionId,
    String? ackId,
  }) {
    if (targetDeviceId.trim().isEmpty) {
      throw ArgumentError.value(
        targetDeviceId,
        'targetDeviceId',
        'Must be non-empty',
      );
    }
    final failureReason = mapStatusToTransferFailureReason(response.status);
    if (failureReason == null) {
      return TransferSucceeded(
        targetDeviceId: targetDeviceId,
        intentionId: intentionId,
        ackId: ackId,
      );
    }
    return TransferFailed(
      targetDeviceId: targetDeviceId,
      reason: failureReason,
      intentionId: intentionId,
    );
  }

  /// Builds [common_pb.LoggingParams], validating `commandId` (empty or 32
  /// hexadecimal chars per `ConnectEsperantoProtos.h:1329–1345`) and
  /// non-negative timestamps.
  common_pb.LoggingParams buildLoggingParams({
    int? commandInitiatedTimeMs,
    int? commandReceivedTimeMs,
    List<String> pageInstanceIds = const <String>[],
    List<String> interactionIds = const <String>[],
    String? commandId,
    String? featureIdentifier,
  }) {
    if (commandInitiatedTimeMs != null && commandInitiatedTimeMs < 0) {
      throw RangeError.value(
        commandInitiatedTimeMs,
        'commandInitiatedTimeMs',
        'Must be non-negative',
      );
    }
    if (commandReceivedTimeMs != null && commandReceivedTimeMs < 0) {
      throw RangeError.value(
        commandReceivedTimeMs,
        'commandReceivedTimeMs',
        'Must be non-negative',
      );
    }
    if (commandId != null &&
        commandId.isNotEmpty &&
        !_commandIdHexPattern.hasMatch(commandId)) {
      throw FormatException(
        'LoggingParams.commandId must be empty or 32 hexadecimal characters',
        commandId,
      );
    }

    return common_pb.LoggingParams(
      commandInitiatedTime: commandInitiatedTimeMs != null
          ? fixnum.Int64(commandInitiatedTimeMs)
          : null,
      commandReceivedTime: commandReceivedTimeMs != null
          ? fixnum.Int64(commandReceivedTimeMs)
          : null,
      pageInstanceIds: pageInstanceIds.isEmpty ? null : pageInstanceIds,
      interactionIds: interactionIds.isEmpty ? null : interactionIds,
      commandId: commandId,
      featureIdentifier: featureIdentifier,
    );
  }

  /// Builds an outbound [connect_pb.StateRequest] (`p199p/s77.java:3743`,
  /// `p199p/v8k.java`).
  connect_pb.StateRequest buildStateRequest({
    bool showOfflineDevicesInCore = false,
    bool showOfflineAmazonDevicesAsOnline = false,
    bool includeLocalDevice = false,
    bool excludeNonLocalDevices = false,
    bool includeUserMatchUnauthenticatedDevices = false,
  }) {
    return connect_pb.StateRequest(
      showOfflineDevicesInCore: showOfflineDevicesInCore,
      showOfflineAmazonDevicesAsOnline: showOfflineAmazonDevicesAsOnline,
      includeLocalDevice: includeLocalDevice,
      excludeNonLocalDevices: excludeNonLocalDevices,
      includeUserMatchUnauthenticatedDevices:
          includeUserMatchUnauthenticatedDevices,
    );
  }

  /// Builds an outbound [connect_pb.TransferRequest] (`p199p/s77.java:490`).
  connect_pb.TransferRequest buildTransferRequest({
    required String connectDeviceIdentifier,
    common_pb.LoggingParams? loggingParams,
    bool? dodo,
  }) {
    _requireNonBlankIdentifier(
      connectDeviceIdentifier,
      'connectDeviceIdentifier',
    );
    _validateLoggingParamsCommandId(loggingParams);

    return connect_pb.TransferRequest(
      connectDeviceIdentifier: connectDeviceIdentifier,
      loggingParams: loggingParams,
      dodo: dodo,
    );
  }

  /// Builds an outbound [connect_pb.PullRequest] (`p199p/s77.java:1372`).
  connect_pb.PullRequest buildPullRequest({
    common_pb.LoggingParams? loggingParams,
  }) {
    _validateLoggingParamsCommandId(loggingParams);
    return connect_pb.PullRequest(loggingParams: loggingParams);
  }

  /// Builds an outbound [connect_pb.LogoutRequest] (`p199p/s77.java:801`).
  connect_pb.LogoutRequest buildLogoutRequest({
    required String connectDeviceIdentifier,
  }) {
    _requireNonBlankIdentifier(
      connectDeviceIdentifier,
      'connectDeviceIdentifier',
    );
    return connect_pb.LogoutRequest(
      connectDeviceIdentifier: connectDeviceIdentifier,
    );
  }

  /// Builds an outbound [connect_pb.NotifyAudioRouteChangedRequest]
  /// (`p199p/s77.java:1107`).
  connect_pb.NotifyAudioRouteChangedRequest buildNotifyAudioRouteChangedRequest({
    String? audioOutputDeviceName,
    OutputPeripheralConnectionType? connectionType,
    String? audioOutputDeviceBrand,
    String? audioOutputDeviceModel,
    OutputPeripheralCategory? category,
  }) {
    final connect_pb.OutputPeripheralConnectionType? protoConnectionType;
    if (connectionType == null) {
      protoConnectionType = null;
    } else {
      protoConnectionType = switch (connectionType) {
        OutputPeripheralConnectionType.unknown => connect_pb
            .OutputPeripheralConnectionType
            .OUTPUT_PERIPHERAL_CONNECTION_TYPE_UNKNOWN,
        OutputPeripheralConnectionType.wired => connect_pb
            .OutputPeripheralConnectionType
            .OUTPUT_PERIPHERAL_CONNECTION_TYPE_WIRED,
        OutputPeripheralConnectionType.carProjected => connect_pb
            .OutputPeripheralConnectionType
            .OUTPUT_PERIPHERAL_CONNECTION_TYPE_CAR_PROJECTED,
        OutputPeripheralConnectionType.bluetooth => connect_pb
            .OutputPeripheralConnectionType
            .OUTPUT_PERIPHERAL_CONNECTION_TYPE_BLUETOOTH,
        OutputPeripheralConnectionType.airplay => connect_pb
            .OutputPeripheralConnectionType
            .OUTPUT_PERIPHERAL_CONNECTION_TYPE_AIRPLAY,
        OutputPeripheralConnectionType.builtInSpeaker => connect_pb
            .OutputPeripheralConnectionType
            .OUTPUT_PERIPHERAL_CONNECTION_TYPE_BUILT_IN_SPEAKER,
      };
    }

    final connect_pb.OutputPeripheralCategory? protoCategory;
    if (category == null) {
      protoCategory = null;
    } else {
      protoCategory = switch (category) {
        OutputPeripheralCategory.unknown => connect_pb
            .OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_UNKNOWN,
        OutputPeripheralCategory.car =>
          connect_pb.OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_CAR,
        OutputPeripheralCategory.headphones => connect_pb
            .OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_HEADPHONES,
        OutputPeripheralCategory.speaker => connect_pb
            .OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_SPEAKER,
        OutputPeripheralCategory.wearable => connect_pb
            .OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_WEARABLE,
        OutputPeripheralCategory.glasses => connect_pb
            .OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_GLASSES,
        OutputPeripheralCategory.app =>
          connect_pb.OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_APP,
      };
    }

    return connect_pb.NotifyAudioRouteChangedRequest(
      audioOutputDeviceName: audioOutputDeviceName,
      audioOutputDeviceConnectionType: protoConnectionType,
      audioOutputDeviceBrand: audioOutputDeviceBrand,
      audioOutputDeviceModel: audioOutputDeviceModel,
      audioOutputDeviceCategory: protoCategory,
    );
  }

  /// Builds an outbound [connect_pb.AddDeviceToGroupRequest]
  /// (`p199p/s77.java:1576`).
  connect_pb.AddDeviceToGroupRequest buildAddDeviceToGroupRequest({
    required String connectDeviceIdentifier,
    required String groupDeviceIdentifier,
    common_pb.LoggingParams? loggingParams,
  }) {
    _requireNonBlankIdentifier(
      connectDeviceIdentifier,
      'connectDeviceIdentifier',
    );
    _requireNonBlankIdentifier(
      groupDeviceIdentifier,
      'groupDeviceIdentifier',
    );
    _validateLoggingParamsCommandId(loggingParams);

    return connect_pb.AddDeviceToGroupRequest(
      connectDeviceIdentifier: connectDeviceIdentifier,
      groupDeviceIdentifier: groupDeviceIdentifier,
      loggingParams: loggingParams,
    );
  }

  /// Builds an outbound [connect_pb.RemoveDeviceFromGroupRequest]
  /// (`p199p/s77.java:1933`).
  connect_pb.RemoveDeviceFromGroupRequest buildRemoveDeviceFromGroupRequest({
    required String connectDeviceIdentifier,
    required String groupDeviceIdentifier,
    common_pb.LoggingParams? loggingParams,
  }) {
    _requireNonBlankIdentifier(
      connectDeviceIdentifier,
      'connectDeviceIdentifier',
    );
    _requireNonBlankIdentifier(
      groupDeviceIdentifier,
      'groupDeviceIdentifier',
    );
    _validateLoggingParamsCommandId(loggingParams);

    return connect_pb.RemoveDeviceFromGroupRequest(
      connectDeviceIdentifier: connectDeviceIdentifier,
      groupDeviceIdentifier: groupDeviceIdentifier,
      loggingParams: loggingParams,
    );
  }

  /// Builds an outbound [connect_pb.SetPreferredIncarnationRequest]
  /// (`p199p/s77.java:3259`).
  connect_pb.SetPreferredIncarnationRequest buildSetPreferredIncarnationRequest({
    required String deviceId,
    IncarnationLoginType? preferredLoginType,
    common_pb.LoggingParams? loggingParams,
  }) {
    _requireNonBlankIdentifier(deviceId, 'deviceId');
    _validateLoggingParamsCommandId(loggingParams);

    final connect_pb.LoginType? protoLoginType;
    if (preferredLoginType == null) {
      protoLoginType = null;
    } else {
      protoLoginType = switch (preferredLoginType) {
        IncarnationLoginType.connect => connect_pb.LoginType.CONNECT,
        IncarnationLoginType.cast => connect_pb.LoginType.CAST,
        IncarnationLoginType.castJs => throw ArgumentError.value(
            preferredLoginType,
            'preferredLoginType',
            'LoginType proto enum supports only CONNECT and CAST',
          ),
      };
    }

    return connect_pb.SetPreferredIncarnationRequest(
      deviceId: deviceId,
      preferredLoginType: protoLoginType,
      loggingParams: loggingParams,
    );
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
