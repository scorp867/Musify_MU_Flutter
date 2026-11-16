// 1:1 replica of p199p/a0f1.java (lines 409–422), p199p/lw51.java (lines 295–333),
// p199p/a170.java (lines 335–360), p199p/m88.java (lines 1230–1233),
// p199p/krb.java (line 194), p199p/efa1.java (line 177), p199p/gsk1.java (lines 291–297),
// p199p/xsh1.java, and ConnectVolumeServiceImpl.cpp (lines 32–206).

import 'dart:typed_data';

import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart'
    as common_pb;
import 'package:musify_mu/features/connect/data/proto/es_volume_messages.pb.dart'
    as volume_pb;
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';

/// Origin reason for a local hardware volume change (`LocalVolumeResponse.Reason`).
enum LocalVolumeReason {
  user,
  system,
}

/// Decoded `LocalVolumeResponse` event emitted by `ConnectVolumeService.LocalVolume`.
typedef LocalVolumeEvent = ({double volume, LocalVolumeReason reason});

/// Pure deterministic mapper for `spotify.connect.esperanto.proto.ConnectVolumeService`
/// inbound responses and outbound volume requests.
final class VolumeMapper {
  static final RegExp _commandIdHexPattern = RegExp(r'^[0-9a-fA-F]{32}$');

  const VolumeMapper();

  /// Normalizes a `0..65535` Connect wire volume integer to `[0.0, 1.0]`
  /// (`p199p/krb.java:194`, `p199p/gsk1.java:296`).
  double wireToNormalized(int rawVolume) {
    if (rawVolume < 0 || rawVolume > kMaxConnectVolumeWire) {
      throw RangeError.range(
        rawVolume,
        0,
        kMaxConnectVolumeWire,
        'rawVolume',
        'Must be within [0, $kMaxConnectVolumeWire]',
      );
    }
    return rawVolume / kMaxConnectVolumeWire;
  }

  /// Converts a finite normalized `[0.0, 1.0]` volume to a `0..65535` Connect
  /// wire integer (`p199p/efa1.java:177`).
  int normalizedToWire(double volume) {
    if (!volume.isFinite) {
      throw RangeError.value(
        volume,
        'volume',
        'Must be a finite value within [0.0, 1.0]',
      );
    }
    if (volume < 0.0 || volume > 1.0) {
      throw RangeError.range(
        volume,
        0,
        1,
        'volume',
        'Must be within [0.0, 1.0]',
      );
    }
    return (volume * kMaxConnectVolumeWire).round();
  }

  /// Maps `spotify.connect.esperanto.proto.Status` to [ConnectVolumeStatus].
  ///
  /// Proto3 omits `Status.OK (0)` on the wire, so callers must read `pb.status`
  /// directly without gating on `hasStatus()`.
  ConnectVolumeStatus mapStatus(common_pb.Status status) {
    if (status == common_pb.Status.OK) {
      return ConnectVolumeStatus.ok;
    } else if (status == common_pb.Status.NOT_FOUND) {
      return ConnectVolumeStatus.notFound;
    } else if (status == common_pb.Status.INVALID_ARGUMENTS) {
      return ConnectVolumeStatus.invalidArguments;
    } else if (status == common_pb.Status.BACKEND_FAILURE) {
      return ConnectVolumeStatus.backendFailure;
    } else if (status == common_pb.Status.UNIMPLEMENTED) {
      return ConnectVolumeStatus.unimplemented;
    } else {
      throw FormatException(
        'Unsupported Status proto enum: ${status.value} (${status.name})',
      );
    }
  }

  /// Decodes raw `StatusResponse` wire bytes to [ConnectVolumeStatus].
  ///
  /// Note: `ConnectEsperantoProtos.h:233–239` encodes `Status.OK` as 0 bytes.
  ConnectVolumeStatus statusResponseFromBuffer(Uint8List bytes) {
    final pb = common_pb.StatusResponse.fromBuffer(bytes);
    return statusResponseFromProto(pb);
  }

  /// Maps [common_pb.StatusResponse] to [ConnectVolumeStatus].
  ConnectVolumeStatus statusResponseFromProto(common_pb.StatusResponse pb) {
    return mapStatus(pb.status);
  }

  /// Maps raw `VolumeResponse.groupDeviceVolumes` (`map<string, uint32>`)
  /// entries to [GroupDeviceVolume] instances, validating non-empty keys and
  /// `0..65535` raw volumes.
  Map<String, GroupDeviceVolume> mapGroupDeviceVolumes(
    Map<String, int> rawVolumes,
  ) {
    final result = <String, GroupDeviceVolume>{};
    for (final entry in rawVolumes.entries) {
      if (entry.key.trim().isEmpty) {
        throw FormatException(
          'VolumeResponse.groupDeviceVolumes keys must be non-empty',
          entry.key,
        );
      }
      result[entry.key] = GroupDeviceVolume.fromWire(rawVolume: entry.value);
    }
    return result;
  }

  /// Decodes raw `VolumeResponse` wire bytes into [ConnectVolumeState].
  ConnectVolumeState volumeResponseFromBuffer(
    Uint8List bytes, {
    ConnectDevice? activeDevice,
    VolumeOutputMode outputMode = VolumeOutputMode.remote,
    double? localVolume,
    bool isChangingVolume = false,
    Set<String> pendingGroupDeviceIds = const <String>{},
  }) {
    final pb = volume_pb.VolumeResponse.fromBuffer(bytes);
    return mapVolumeResponse(
      pb,
      activeDevice: activeDevice,
      outputMode: outputMode,
      localVolume: localVolume,
      isChangingVolume: isChangingVolume,
      pendingGroupDeviceIds: pendingGroupDeviceIds,
    );
  }

  /// Maps [volume_pb.VolumeResponse] into [ConnectVolumeState].
  ///
  /// Handles C++ proto3 wire semantics (`ConnectVolumeServiceImpl.cpp:32–53`,
  /// `ConnectEsperantoProtos.h:1190–1208`):
  /// - Does NOT gate on `pb.hasStatus()` because `Status.OK (0)` is omitted.
  /// - When `status == ConnectVolumeStatus.ok`, reads `pb.volume` (`0` when
  ///   omitted as proto3 scalar `0`) and validates `0..65535`.
  /// - When `status != ConnectVolumeStatus.ok` (e.g. `NOT_FOUND`), preserves
  ///   `remoteVolume: null` when `!pb.hasVolume()`.
  ConnectVolumeState mapVolumeResponse(
    volume_pb.VolumeResponse pb, {
    ConnectDevice? activeDevice,
    VolumeOutputMode outputMode = VolumeOutputMode.remote,
    double? localVolume,
    bool isChangingVolume = false,
    Set<String> pendingGroupDeviceIds = const <String>{},
  }) {
    final status = mapStatus(pb.status);
    final double? remoteVolume;
    if (status == ConnectVolumeStatus.ok) {
      remoteVolume = wireToNormalized(pb.volume);
    } else {
      remoteVolume = pb.hasVolume() ? wireToNormalized(pb.volume) : null;
    }

    final activeIdentifier = pb.hasActiveDeviceConnectStateIdentifier() &&
            pb.activeDeviceConnectStateIdentifier.isNotEmpty
        ? pb.activeDeviceConnectStateIdentifier
        : null;

    final groupVolumes = mapGroupDeviceVolumes(pb.groupDeviceVolumes);

    return ConnectVolumeState(
      remoteVolume: remoteVolume,
      localVolume: localVolume,
      activeDevice: activeDevice,
      outputMode: outputMode,
      isChangingVolume: isChangingVolume,
      status: status,
      activeDeviceConnectStateIdentifier: activeIdentifier,
      groupDeviceVolumes: groupVolumes,
      pendingGroupDeviceIds: pendingGroupDeviceIds,
    );
  }

  /// Decodes raw `LocalVolumeResponse` wire bytes into [LocalVolumeEvent].
  LocalVolumeEvent localVolumeFromBuffer(Uint8List bytes) {
    final pb = volume_pb.LocalVolumeResponse.fromBuffer(bytes);
    return mapLocalVolume(pb);
  }

  /// Maps [volume_pb.LocalVolumeResponse] into [LocalVolumeEvent].
  ///
  /// Proto3 omits `volume == 0` and `reason == USER (0)` on the wire.
  LocalVolumeEvent mapLocalVolume(volume_pb.LocalVolumeResponse pb) {
    final volume = wireToNormalized(pb.volume);
    final LocalVolumeReason reason;
    if (pb.reason == volume_pb.LocalVolumeResponse_Reason.USER) {
      reason = LocalVolumeReason.user;
    } else if (pb.reason == volume_pb.LocalVolumeResponse_Reason.SYSTEM) {
      reason = LocalVolumeReason.system;
    } else {
      throw FormatException(
        'Unsupported LocalVolumeResponse_Reason proto enum: '
        '${pb.reason.value} (${pb.reason.name})',
      );
    }
    return (volume: volume, reason: reason);
  }

  /// Builds an outbound [volume_pb.VolumeSetRequest].
  ///
  /// Validates [volume] within `[0.0, 1.0]` finite (never clamps), validates
  /// `loggingParams.commandId` (empty or 32 hex chars), and rejects empty
  /// [groupDeviceIdentifier] when non-null.
  volume_pb.VolumeSetRequest toVolumeSetRequest({
    required double volume,
    common_pb.LoggingParams? loggingParams,
    String? groupDeviceIdentifier,
  }) {
    final wireVolume = normalizedToWire(volume);
    _validateLoggingParams(loggingParams);
    _validateOptionalGroupDeviceId(groupDeviceIdentifier);

    return volume_pb.VolumeSetRequest(
      volume: wireVolume,
      loggingParams: loggingParams,
      groupDeviceIdentifier: groupDeviceIdentifier,
    );
  }

  /// Builds an outbound [volume_pb.VolumeUpRequest].
  volume_pb.VolumeUpRequest toVolumeUpRequest({
    common_pb.LoggingParams? loggingParams,
    String? groupDeviceIdentifier,
  }) {
    _validateLoggingParams(loggingParams);
    _validateOptionalGroupDeviceId(groupDeviceIdentifier);

    return volume_pb.VolumeUpRequest(
      loggingParams: loggingParams,
      groupDeviceIdentifier: groupDeviceIdentifier,
    );
  }

  /// Builds an outbound [volume_pb.VolumeDownRequest].
  volume_pb.VolumeDownRequest toVolumeDownRequest({
    common_pb.LoggingParams? loggingParams,
    String? groupDeviceIdentifier,
  }) {
    _validateLoggingParams(loggingParams);
    _validateOptionalGroupDeviceId(groupDeviceIdentifier);

    return volume_pb.VolumeDownRequest(
      loggingParams: loggingParams,
      groupDeviceIdentifier: groupDeviceIdentifier,
    );
  }

  static void _validateLoggingParams(common_pb.LoggingParams? loggingParams) {
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

  static void _validateOptionalGroupDeviceId(String? groupDeviceIdentifier) {
    if (groupDeviceIdentifier != null && groupDeviceIdentifier.trim().isEmpty) {
      throw ArgumentError.value(
        groupDeviceIdentifier,
        'groupDeviceIdentifier',
        'Must be non-empty when provided',
      );
    }
  }
}
