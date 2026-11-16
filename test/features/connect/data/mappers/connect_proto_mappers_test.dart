import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/data/mappers/connect_proto_mappers.dart';
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
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';

void main() {
  const mappers = ConnectProtoMappers();

  group('ConnectProtoMappers', () {
    test('delegates cluster, device, group, and volume mapping cleanly', () {
      final statePb = connect_pb.StateResponse(
        isActive: true,
        isSyncedWithBackend: true,
        devices: [
          connect_pb.StateResponse_Device(
            localIdentifier: 'dev-1',
            connectStateIdentifier: 'cs-1',
            name: 'Office Speaker',
            isActive: true,
            state: 'LOGGED_IN',
            type: 'SPEAKER',
          ),
        ],
      );
      final cluster = mappers.clusterFromBuffer(statePb.writeToBuffer());
      expect(cluster.activeDevice?.name, 'Office Speaker');

      final device = mappers.deviceFromBuffer(statePb.devices.single.writeToBuffer());
      expect(device.localIdentifier, 'dev-1');

      final groupPb = group_pb.GroupData(
        capabilities: group_pb.GroupCapabilities(maxDevices: 6),
      );
      final groupData = mappers.groupDataFromBuffer(groupPb.writeToBuffer());
      expect(groupData.capabilities.maxDevices, 6);

      final volumePb = volume_pb.VolumeResponse(
        status: common_pb.Status.OK,
        volume: 65535,
      );
      final volumeState = mappers.volumeResponseFromBuffer(
        volumePb.writeToBuffer(),
      );
      expect(volumeState.status, ConnectVolumeStatus.ok);
      expect(volumeState.remoteVolume, 1.0);

      final localVolPb = volume_pb.LocalVolumeResponse(
        volume: 16384,
        reason: volume_pb.LocalVolumeResponse_Reason.SYSTEM,
      );
      final localEvent = mappers.localVolumeFromBuffer(localVolPb.writeToBuffer());
      expect(localEvent.volume, closeTo(16384 / 65535.0, 1e-12));
      expect(localEvent.reason, LocalVolumeReason.system);

      expect(
        mappers.volumeStatusResponseFromBuffer(Uint8List(0)),
        ConnectVolumeStatus.ok,
      );
      expect(
        mappers.parseCapabilitiesJson('[{"id":"alexa"}]'),
        equals([ConnectCapabilityEntry(id: 'alexa')]),
      );
    });

    test('maps Status enum and StatusResponse to TransferFailureReason and TransferState', () {
      expect(
        mappers.mapStatusToTransferFailureReason(common_pb.Status.OK),
        isNull,
      );
      expect(
        mappers.mapStatusToTransferFailureReason(common_pb.Status.NOT_FOUND),
        TransferFailureReason.notFound,
      );
      expect(
        mappers.mapStatusToTransferFailureReason(
          common_pb.Status.INVALID_ARGUMENTS,
        ),
        TransferFailureReason.invalidArguments,
      );
      expect(
        mappers.mapStatusToTransferFailureReason(
          common_pb.Status.BACKEND_FAILURE,
        ),
        TransferFailureReason.backendFailure,
      );
      expect(
        mappers.mapStatusToTransferFailureReason(
          common_pb.Status.UNIMPLEMENTED,
        ),
        TransferFailureReason.unknown,
      );

      final okState = mappers.transferStateFromStatusBuffer(
        Uint8List(0),
        targetDeviceId: 'dev-target',
        intentionId: 'int-1',
        ackId: 'ack-1',
      );
      expect(
        okState,
        TransferSucceeded(
          targetDeviceId: 'dev-target',
          intentionId: 'int-1',
          ackId: 'ack-1',
        ),
      );

      final failedPb = common_pb.StatusResponse(
        status: common_pb.Status.BACKEND_FAILURE,
      );
      final failedState = mappers.transferStateFromStatusBuffer(
        failedPb.writeToBuffer(),
        targetDeviceId: 'dev-target',
        intentionId: 'int-2',
      );
      expect(
        failedState,
        TransferFailed(
          targetDeviceId: 'dev-target',
          reason: TransferFailureReason.backendFailure,
          intentionId: 'int-2',
        ),
      );

      expect(
        () => mappers.mapStatusResponseToTransferState(
          common_pb.StatusResponse(),
          targetDeviceId: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('builds and validates LoggingParams including 32-hex commandId', () {
      const validHexId = '0123456789abcdef0123456789ABCDEF';
      final params = mappers.buildLoggingParams(
        commandInitiatedTimeMs: 1000,
        commandReceivedTimeMs: 1020,
        pageInstanceIds: ['page-1'],
        interactionIds: ['interaction-1'],
        commandId: validHexId,
        featureIdentifier: 'connect_picker',
      );
      final roundtrip = common_pb.LoggingParams.fromBuffer(params.writeToBuffer());
      expect(roundtrip.commandInitiatedTime.toInt(), 1000);
      expect(roundtrip.commandReceivedTime.toInt(), 1020);
      expect(roundtrip.pageInstanceIds, equals(['page-1']));
      expect(roundtrip.interactionIds, equals(['interaction-1']));
      expect(roundtrip.commandId, validHexId);
      expect(roundtrip.featureIdentifier, 'connect_picker');

      final emptyCmdId = mappers.buildLoggingParams(commandId: '');
      expect(emptyCmdId.commandId, '');

      expect(
        () => mappers.buildLoggingParams(commandInitiatedTimeMs: -1),
        throwsRangeError,
      );
      expect(
        () => mappers.buildLoggingParams(commandReceivedTimeMs: -5),
        throwsRangeError,
      );
      expect(
        () => mappers.buildLoggingParams(commandId: 'bad-hex'),
        throwsFormatException,
      );
    });

    test('builds outbound StateRequest, TransferRequest, PullRequest, LogoutRequest', () {
      final stateReq = mappers.buildStateRequest(
        showOfflineDevicesInCore: true,
        showOfflineAmazonDevicesAsOnline: true,
        includeLocalDevice: true,
        excludeNonLocalDevices: false,
        includeUserMatchUnauthenticatedDevices: true,
      );
      final stateRoundtrip = connect_pb.StateRequest.fromBuffer(
        stateReq.writeToBuffer(),
      );
      expect(stateRoundtrip.showOfflineDevicesInCore, isTrue);
      expect(stateRoundtrip.showOfflineAmazonDevicesAsOnline, isTrue);
      expect(stateRoundtrip.includeLocalDevice, isTrue);
      expect(stateRoundtrip.excludeNonLocalDevices, isFalse);
      expect(stateRoundtrip.includeUserMatchUnauthenticatedDevices, isTrue);

      final logging = mappers.buildLoggingParams(
        commandId: 'abcdef0123456789abcdef0123456789',
      );
      final transferReq = mappers.buildTransferRequest(
        connectDeviceIdentifier: 'cs-dev-1',
        loggingParams: logging,
        dodo: true,
      );
      final transferRoundtrip = connect_pb.TransferRequest.fromBuffer(
        transferReq.writeToBuffer(),
      );
      expect(transferRoundtrip.connectDeviceIdentifier, 'cs-dev-1');
      expect(transferRoundtrip.dodo, isTrue);
      expect(
        transferRoundtrip.loggingParams.commandId,
        'abcdef0123456789abcdef0123456789',
      );

      final pullReq = mappers.buildPullRequest(loggingParams: logging);
      expect(
        connect_pb.PullRequest.fromBuffer(pullReq.writeToBuffer())
            .loggingParams
            .commandId,
        'abcdef0123456789abcdef0123456789',
      );

      final logoutReq = mappers.buildLogoutRequest(
        connectDeviceIdentifier: 'cs-dev-2',
      );
      expect(
        connect_pb.LogoutRequest.fromBuffer(logoutReq.writeToBuffer())
            .connectDeviceIdentifier,
        'cs-dev-2',
      );

      expect(
        () => mappers.buildTransferRequest(connectDeviceIdentifier: ''),
        throwsArgumentError,
      );
      expect(
        () => mappers.buildLogoutRequest(connectDeviceIdentifier: '  '),
        throwsArgumentError,
      );
      expect(
        () => mappers.buildPullRequest(
          loggingParams: common_pb.LoggingParams(commandId: 'invalid'),
        ),
        throwsFormatException,
      );
    });

    test(
      'builds NotifyAudioRouteChangedRequest, group requests, and SetPreferredIncarnationRequest',
      () {
        final routeReq = mappers.buildNotifyAudioRouteChangedRequest(
          audioOutputDeviceName: 'AirPods Pro',
          connectionType: OutputPeripheralConnectionType.bluetooth,
          audioOutputDeviceBrand: 'Apple',
          audioOutputDeviceModel: 'A2931',
          category: OutputPeripheralCategory.headphones,
        );
        final routeRoundtrip =
            connect_pb.NotifyAudioRouteChangedRequest.fromBuffer(
          routeReq.writeToBuffer(),
        );
        expect(routeRoundtrip.audioOutputDeviceName, 'AirPods Pro');
        expect(
          routeRoundtrip.audioOutputDeviceConnectionType,
          connect_pb.OutputPeripheralConnectionType
              .OUTPUT_PERIPHERAL_CONNECTION_TYPE_BLUETOOTH,
        );
        expect(routeRoundtrip.audioOutputDeviceBrand, 'Apple');
        expect(routeRoundtrip.audioOutputDeviceModel, 'A2931');
        expect(
          routeRoundtrip.audioOutputDeviceCategory,
          connect_pb
              .OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_HEADPHONES,
        );

        final addReq = mappers.buildAddDeviceToGroupRequest(
          connectDeviceIdentifier: 'cs-1',
          groupDeviceIdentifier: 'grp-1',
        );
        expect(addReq.connectDeviceIdentifier, 'cs-1');
        expect(addReq.groupDeviceIdentifier, 'grp-1');

        final removeReq = mappers.buildRemoveDeviceFromGroupRequest(
          connectDeviceIdentifier: 'cs-1',
          groupDeviceIdentifier: 'grp-1',
        );
        expect(removeReq.connectDeviceIdentifier, 'cs-1');
        expect(removeReq.groupDeviceIdentifier, 'grp-1');

        final prefReq = mappers.buildSetPreferredIncarnationRequest(
          deviceId: 'dev-1',
          preferredLoginType: IncarnationLoginType.cast,
        );
        final prefRoundtrip =
            connect_pb.SetPreferredIncarnationRequest.fromBuffer(
          prefReq.writeToBuffer(),
        );
        expect(prefRoundtrip.deviceId, 'dev-1');
        expect(prefRoundtrip.preferredLoginType, connect_pb.LoginType.CAST);

        expect(
          () => mappers.buildSetPreferredIncarnationRequest(
            deviceId: 'dev-1',
            preferredLoginType: IncarnationLoginType.castJs,
          ),
          throwsArgumentError,
        );
        expect(
          () => mappers.buildSetPreferredIncarnationRequest(deviceId: '  '),
          throwsArgumentError,
        );
        expect(
          () => mappers.buildAddDeviceToGroupRequest(
            connectDeviceIdentifier: '',
            groupDeviceIdentifier: 'grp-1',
          ),
          throwsArgumentError,
        );
        expect(
          () => mappers.buildRemoveDeviceFromGroupRequest(
            connectDeviceIdentifier: 'cs-1',
            groupDeviceIdentifier: '',
          ),
          throwsArgumentError,
        );
      },
    );
  });
}
