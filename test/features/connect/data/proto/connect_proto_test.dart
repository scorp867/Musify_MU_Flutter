import 'dart:convert';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/data/proto/es_cast_messages.pb.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart';
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pb.dart';
import 'package:musify_mu/features/connect/data/proto/es_dodos_messages.pb.dart';
import 'package:musify_mu/features/connect/data/proto/es_volume_messages.pb.dart';
import 'package:musify_mu/features/connect/data/proto/group.pb.dart';

void main() {
  group('Phase 12B Protobuf Wire Codecs Roundtrip Tests', () {
    test('CommonMessages: LoggingParams and StatusResponse wire serialization roundtrip', () {
      final original = LoggingParams(
        commandInitiatedTime: Int64(1700000000000),
        commandReceivedTime: Int64(1700000000100),
        pageInstanceIds: ['page_1', 'page_2'],
        interactionIds: ['inter_1', 'inter_2'],
        commandId: 'cmd_123',
        featureIdentifier: 'connect_transfer',
      );

      final bytes = original.writeToBuffer();
      final decoded = LoggingParams.fromBuffer(bytes);

      expect(decoded.commandInitiatedTime, equals(Int64(1700000000000)));
      expect(decoded.commandReceivedTime, equals(Int64(1700000000100)));
      expect(decoded.pageInstanceIds, equals(['page_1', 'page_2']));
      expect(decoded.interactionIds, equals(['inter_1', 'inter_2']));
      expect(decoded.commandId, equals('cmd_123'));
      expect(decoded.featureIdentifier, equals('connect_transfer'));

      final statusResp = StatusResponse(status: Status.OK);
      final statusBytes = statusResp.writeToBuffer();
      final decodedStatus = StatusResponse.fromBuffer(statusBytes);
      expect(decodedStatus.status, equals(Status.OK));
    });

    test('Group: GroupData, GroupDevice and capabilities wire serialization roundtrip', () {
      final groupDevice = GroupDevice(
        identifiers: GroupDeviceIdentifiers(
          groupDeviceIdentifier: 'grp_dev_1',
          localIdentifier: 'local_1',
          deduplicationId: 'dedup_1',
          connectStateIdentifier: 'cs_1',
        ),
        name: 'Living Room Speaker',
        type: 'speaker',
        modelDisplayName: 'Sonos One',
        capabilities: GroupDeviceCapabilities(
          removable: true,
          removalDissolvesGroup: false,
        ),
        groupingStatus: GroupingStatus.GROUPED,
        volume: GroupDeviceVolume(
          volume: 32768,
          volumeSteps: 64,
        ),
      );

      final groupData = GroupData(
        devices: [groupDevice],
        capabilities: GroupCapabilities(maxDevices: 8),
      );

      final bytes = groupData.writeToBuffer();
      final decoded = GroupData.fromBuffer(bytes);

      expect(decoded.devices.length, equals(1));
      expect(decoded.capabilities.maxDevices, equals(8));
      final dev = decoded.devices.first;
      expect(dev.name, equals('Living Room Speaker'));
      expect(dev.type, equals('speaker'));
      expect(dev.modelDisplayName, equals('Sonos One'));
      expect(dev.groupingStatus, equals(GroupingStatus.GROUPED));
      expect(dev.volume.volume, equals(32768));
      expect(dev.volume.volumeSteps, equals(64));
      expect(dev.capabilities.removable, isTrue);
      expect(dev.capabilities.removalDissolvesGroup, isFalse);
      expect(dev.identifiers.groupDeviceIdentifier, equals('grp_dev_1'));
      expect(dev.identifiers.localIdentifier, equals('local_1'));
      expect(dev.identifiers.deduplicationId, equals('dedup_1'));
      expect(dev.identifiers.connectStateIdentifier, equals('cs_1'));
    });

    test('VolumeMessages: VolumeResponse and requests wire serialization roundtrip', () {
      final volumeResponse = VolumeResponse(
        volume: 45000,
        status: Status.OK,
        activeDeviceConnectStateIdentifier: 'active_dev_99',
        groupDeviceVolumes: const [
          MapEntry('dev_a', 40000),
          MapEntry('dev_b', 50000),
        ],
      );

      final bytes = volumeResponse.writeToBuffer();
      final decoded = VolumeResponse.fromBuffer(bytes);

      expect(decoded.volume, equals(45000));
      expect(decoded.status, equals(Status.OK));
      expect(decoded.activeDeviceConnectStateIdentifier, equals('active_dev_99'));
      expect(decoded.groupDeviceVolumes['dev_a'], equals(40000));
      expect(decoded.groupDeviceVolumes['dev_b'], equals(50000));

      final setReq = VolumeSetRequest(
        volume: 30000,
        loggingParams: LoggingParams(commandId: 'vol_set_1'),
        groupDeviceIdentifier: 'dev_a',
      );
      final setBytes = setReq.writeToBuffer();
      final decodedSet = VolumeSetRequest.fromBuffer(setBytes);
      expect(decodedSet.volume, equals(30000));
      expect(decodedSet.loggingParams.commandId, equals('vol_set_1'));
      expect(decodedSet.groupDeviceIdentifier, equals('dev_a'));

      final upReq = VolumeUpRequest(
        loggingParams: LoggingParams(commandId: 'vol_up_1'),
        groupDeviceIdentifier: 'grp_1',
      );
      expect(VolumeUpRequest.fromBuffer(upReq.writeToBuffer()).groupDeviceIdentifier, equals('grp_1'));

      final downReq = VolumeDownRequest(
        loggingParams: LoggingParams(commandId: 'vol_down_1'),
      );
      expect(VolumeDownRequest.fromBuffer(downReq.writeToBuffer()).loggingParams.commandId, equals('vol_down_1'));
    });

    test('CastMessages: DeviceId, PutDeviceRequest and Response wire serialization roundtrip', () {
      final jsonBytes = utf8.encode('{"model":"Chromecast Audio","ip":"192.168.1.50"}');
      final putReq = PutDeviceRequest(
        deviceId: 'cast_dev_1',
        json: jsonBytes,
      );

      final bytes = putReq.writeToBuffer();
      final decoded = PutDeviceRequest.fromBuffer(bytes);
      expect(decoded.deviceId, equals('cast_dev_1'));
      expect(utf8.decode(decoded.json), equals('{"model":"Chromecast Audio","ip":"192.168.1.50"}'));

      final connError = ConnectionErrorRequest(
        deviceId: 'cast_dev_2',
        error: 404,
        platformErrorCode: 12,
      );
      final connBytes = connError.writeToBuffer();
      final decodedConn = ConnectionErrorRequest.fromBuffer(connBytes);
      expect(decodedConn.deviceId, equals('cast_dev_2'));
      expect(decodedConn.error, equals(404));
      expect(decodedConn.platformErrorCode, equals(12));

      final connectReq = ConnectRequest(
        deviceId: 'cast_dev_3',
        interactionIds: ['cast_inter_1'],
      );
      final connectBytes = connectReq.writeToBuffer();
      final decodedConnect = ConnectRequest.fromBuffer(connectBytes);
      expect(decodedConnect.deviceId, equals('cast_dev_3'));
      expect(decodedConnect.interactionIds, equals(['cast_inter_1']));

      final resp = Response(result: CastResult.CAST_RESULT_OK);
      expect(Response.fromBuffer(resp.writeToBuffer()).result, equals(CastResult.CAST_RESULT_OK));
    });

    test('ConnectMessages: StateResponse, StateRequest, TransferRequest wire serialization roundtrip', () {
      final stateReq = StateRequest(
        showOfflineDevicesInCore: true,
        showOfflineAmazonDevicesAsOnline: false,
        includeLocalDevice: true,
        excludeNonLocalDevices: false,
        includeUserMatchUnauthenticatedDevices: true,
      );

      final reqBytes = stateReq.writeToBuffer();
      final decodedReq = StateRequest.fromBuffer(reqBytes);
      expect(decodedReq.showOfflineDevicesInCore, isTrue);
      expect(decodedReq.showOfflineAmazonDevicesAsOnline, isFalse);
      expect(decodedReq.includeLocalDevice, isTrue);
      expect(decodedReq.excludeNonLocalDevices, isFalse);
      expect(decodedReq.includeUserMatchUnauthenticatedDevices, isTrue);

      final device = StateResponse_Device(
        isSelf: true,
        localIdentifier: 'local_musify_1',
        deduplicationId: 'dedup_musify_1',
        connectStateIdentifier: 'cs_musify_1',
        name: 'Musify Local Player',
        type: 'smartphone',
        state: 'ready',
        isDisabled: false,
        isActive: true,
        isBeingActivated: false,
        isZeroconf: false,
        isWebapp: false,
        isLocal: true,
        isGroup: false,
        isOffline: false,
        isSocialConnect: false,
        creationTimeMs: Int64(1700000000000),
        volume: 65535,
        hifi: StateResponse_Hifi(
          fullySupported: true,
          userEligible: true,
          deviceSupported: true,
        ),
        license: 'premium',
        supportsOnDemand: true,
        supportsVolume: true,
        supportsLogout: false,
        supportsRename: false,
        supportsAlarm: false,
        isVoiceEnabled: false,
        isNewlyDiscovered: false,
        supportedMediaTypes: ['audio/episode', 'audio/track'],
        brandDisplayName: 'Musify',
        modelDisplayName: 'Audio Engine',
        volumeSteps: 64,
        capabilities: 'gaia_connect',
        incarnations: [
          StateResponse_Incarnation(
            loginType: LoginType.CONNECT,
            identifier: 'inc_1',
            preferred: true,
            preferredReason: ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_USER_SELECTED,
            connectStateIdentifier: 'cs_musify_1',
          ),
        ],
        aliasId: 1,
        supportsDj: true,
        libraryVersion: '1.0.0',
        outputPeripheral: OutputPeripheral(
          name: 'Internal Speaker',
          category: OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_SPEAKER,
          connectionType: OutputPeripheralConnectionType.OUTPUT_PERIPHERAL_CONNECTION_TYPE_BUILT_IN_SPEAKER,
        ),
        localIp: '127.0.0.1',
        discoveryMethod: 0,
        supportsRemoteSleepTimer: true,
        supportsPlaylistMixing: true,
        groupData: GroupData(capabilities: GroupCapabilities(maxDevices: 4)),
        isPublic: false,
        supportsRemoteAudioQualityControl: true,
        isAuthenticatedWithCurrentUser: true,
        supportsZephyr: true,
        supportsGapless: true,
        supportsCrossfade: true,
      );

      final stateResp = StateResponse(
        isRunning: true,
        isConnected: true,
        localName: 'Musify Local Player',
        shouldUseLocalPlayback: true,
        devices: [device],
        isActive: true,
        isActiveOnSameDevice: true,
        isSyncedWithBackend: true,
      );

      final respBytes = stateResp.writeToBuffer();
      final decodedResp = StateResponse.fromBuffer(respBytes);

      expect(decodedResp.isRunning, isTrue);
      expect(decodedResp.isConnected, isTrue);
      expect(decodedResp.localName, equals('Musify Local Player'));
      expect(decodedResp.devices.length, equals(1));

      final decodedDev = decodedResp.devices.first;
      expect(decodedDev.name, equals('Musify Local Player'));
      expect(decodedDev.type, equals('smartphone'));
      expect(decodedDev.isActive, isTrue);
      expect(decodedDev.volume, equals(65535));
      expect(decodedDev.volumeSteps, equals(64));
      expect(decodedDev.hifi.fullySupported, isTrue);
      expect(decodedDev.incarnations.length, equals(1));
      expect(decodedDev.incarnations.first.preferredReason, equals(ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_USER_SELECTED));
      expect(decodedDev.outputPeripheral.connectionType, equals(OutputPeripheralConnectionType.OUTPUT_PERIPHERAL_CONNECTION_TYPE_BUILT_IN_SPEAKER));
      expect(decodedDev.groupData.capabilities.maxDevices, equals(4));

      final transferReq = TransferRequest(
        loggingParams: LoggingParams(commandId: 'xfer_1'),
        connectDeviceIdentifier: 'remote_device_77',
        dodo: true,
      );
      final xferBytes = transferReq.writeToBuffer();
      final decodedXfer = TransferRequest.fromBuffer(xferBytes);
      expect(decodedXfer.connectDeviceIdentifier, equals('remote_device_77'));
      expect(decodedXfer.dodo, isTrue);
      expect(decodedXfer.loggingParams.commandId, equals('xfer_1'));

      final addGrpResp = AddDeviceToGroupResponse(
        success: false,
        error: GroupError.MAX_NUMBER_OF_DEVICES_REACHED,
      );
      final addGrpBytes = addGrpResp.writeToBuffer();
      final decodedAddGrp = AddDeviceToGroupResponse.fromBuffer(addGrpBytes);
      expect(decodedAddGrp.success, isFalse);
      expect(decodedAddGrp.error, equals(GroupError.MAX_NUMBER_OF_DEVICES_REACHED));

      final clusterUpdateResp = ClusterUpdateAfterBackendConnectionResponse(
        hasReceivedClusterUpdateAfterBackendConnection: true,
      );
      final clusterBytes = clusterUpdateResp.writeToBuffer();
      expect(
        ClusterUpdateAfterBackendConnectionResponse.fromBuffer(clusterBytes).hasReceivedClusterUpdateAfterBackendConnection,
        isTrue,
      );
    });

    test('VolumeMessages: LocalVolumeResponse wire serialization roundtrip', () {
      final userLocal = LocalVolumeResponse(
        volume: 32768,
        reason: LocalVolumeResponse_Reason.USER,
      );
      final decodedUser = LocalVolumeResponse.fromBuffer(userLocal.writeToBuffer());
      expect(decodedUser.volume, equals(32768));
      expect(decodedUser.reason, equals(LocalVolumeResponse_Reason.USER));

      final sysLocal = LocalVolumeResponse(
        volume: 16384,
        reason: LocalVolumeResponse_Reason.SYSTEM,
      );
      final decodedSys = LocalVolumeResponse.fromBuffer(sysLocal.writeToBuffer());
      expect(decodedSys.volume, equals(16384));
      expect(decodedSys.reason, equals(LocalVolumeResponse_Reason.SYSTEM));
    });

    test('ConnectMessages: SendCommand, Rename, and DeleteGroup wire serialization roundtrip', () {
      final cmdReq = SendCommandRequest(
        loggingParams: LoggingParams(commandId: '0123456789abcdef0123456789abcdef'),
        connectDeviceIdentifier: 'dev_remote',
        commandJson: '{"endpoint":"play"}',
      );
      final decodedCmdReq = SendCommandRequest.fromBuffer(cmdReq.writeToBuffer());
      expect(decodedCmdReq.connectDeviceIdentifier, equals('dev_remote'));
      expect(decodedCmdReq.commandJson, equals('{"endpoint":"play"}'));
      expect(decodedCmdReq.loggingParams.commandId, equals('0123456789abcdef0123456789abcdef'));

      final cmdResp = SendCommandResponse(contextPlayerError: 404);
      expect(SendCommandResponse.fromBuffer(cmdResp.writeToBuffer()).contextPlayerError, equals(404));

      final renameReq = RenameRequest(deviceId: 'dev_1', newName: 'Living Room');
      final decodedRename = RenameRequest.fromBuffer(renameReq.writeToBuffer());
      expect(decodedRename.deviceId, equals('dev_1'));
      expect(decodedRename.newName, equals('Living Room'));

      final delResp = DeleteGroupResponse(
        success: false,
        error: DeleteGroupError.DELETE_BUSY,
      );
      final decodedDel = DeleteGroupResponse.fromBuffer(delResp.writeToBuffer());
      expect(decodedDel.success, isFalse);
      expect(decodedDel.error, equals(DeleteGroupError.DELETE_BUSY));
    });

    test('DodosMessages: SingleDodo, SwitchToDodoRequest, and DodoSubResponse roundtrip', () {
      final sub = DodoSubResponse(
        dodos: [
          SingleDodo(
            dodoId: 'dodo-1',
            csId: 'cs-1',
            isPrimary: true,
            isBeingObserved: true,
          ),
          SingleDodo(
            dodoId: 'dodo-2',
            csId: 'cs-2',
            isPrimary: false,
            isBeingObserved: false,
          ),
        ],
      );
      final decodedSub = DodoSubResponse.fromBuffer(sub.writeToBuffer());
      expect(decodedSub.dodos.length, equals(2));
      expect(decodedSub.dodos.first.dodoId, equals('dodo-1'));
      expect(decodedSub.dodos.first.csId, equals('cs-1'));
      expect(decodedSub.dodos.first.isPrimary, isTrue);
      expect(decodedSub.dodos.first.isBeingObserved, isTrue);
      expect(decodedSub.dodos[1].isPrimary, isFalse);

      final switchReq = SwitchToDodoRequest(csId: 'cs-2');
      expect(SwitchToDodoRequest.fromBuffer(switchReq.writeToBuffer()).csId, equals('cs-2'));

      expect(CreateNewDodoRequest.fromBuffer(CreateNewDodoRequest().writeToBuffer()), isNotNull);
      expect(EndDodoRequest.fromBuffer(EndDodoRequest().writeToBuffer()), isNotNull);
    });
  });
}
