import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_service_client.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart'
    as common_pb;
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pb.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    as empty_pb;

final class _RecordedCall {
  final String kind;
  final String service;
  final String method;
  final Uint8List payload;

  const _RecordedCall({
    required this.kind,
    required this.service,
    required this.method,
    required this.payload,
  });
}

final class _RecordingEsperantoTransport implements EsperantoTransport {
  final List<_RecordedCall> calls = <_RecordedCall>[];

  Future<Uint8List> Function(
    String service,
    String method,
    Uint8List payload,
  )? onCallSingle;

  Stream<Uint8List> Function(
    String service,
    String method,
    Uint8List payload,
  )? onCallStream;

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    calls.add(
      _RecordedCall(
        kind: 'single',
        service: service,
        method: method,
        payload: Uint8List.fromList(payload),
      ),
    );
    final handler = onCallSingle;
    if (handler != null) {
      return handler(service, method, payload);
    }
    return Uint8List(0);
  }

  @override
  Stream<Uint8List> callStream(
    String service,
    String method,
    Uint8List payload,
  ) {
    calls.add(
      _RecordedCall(
        kind: 'stream',
        service: service,
        method: method,
        payload: Uint8List.fromList(payload),
      ),
    );
    final handler = onCallStream;
    if (handler != null) {
      return handler(service, method, payload);
    }
    return const Stream<Uint8List>.empty();
  }

  @override
  Uint8List callSync(
    String service,
    String method,
    Uint8List payload,
  ) {
    calls.add(
      _RecordedCall(
        kind: 'sync',
        service: service,
        method: method,
        payload: Uint8List.fromList(payload),
      ),
    );
    return Uint8List(0);
  }
}

void main() {
  const validHexCommandId = '0123456789abcdef0123456789ABCDEF';
  final malformedBytes = Uint8List.fromList(<int>[0xFF, 0xFF, 0xFF, 0x7F]);

  group('ConnectServiceClient (Item 133 — all 18 RPCs)', () {
    test('uses exact ConnectService Esperanto serviceName', () {
      expect(
        ConnectServiceClient.serviceName,
        'spotify.connect.esperanto.proto.ConnectService',
      );
    });

    test('State RPC serializes StateRequest and decodes 0-byte and populated clusters', () async {
      final transport = _RecordingEsperantoTransport();
      final controller = StreamController<Uint8List>();
      addTearDown(controller.close);
      transport.onCallStream = (service, method, payload) => controller.stream;

      final client = ConnectServiceClient(transport);
      final emitted = <Object>[];
      final errors = <Object>[];
      final sub = client
          .state(
            showOfflineDevicesInCore: true,
            showOfflineAmazonDevicesAsOnline: true,
            includeLocalDevice: true,
            excludeNonLocalDevices: true,
            includeUserMatchUnauthenticatedDevices: true,
          )
          .listen(emitted.add, onError: errors.add);
      addTearDown(sub.cancel);

      expect(transport.calls, hasLength(1));
      expect(transport.calls.single.kind, 'stream');
      expect(
        transport.calls.single.service,
        ConnectServiceClient.serviceName,
      );
      expect(transport.calls.single.method, 'State');

      final sentReq =
          connect_pb.StateRequest.fromBuffer(transport.calls.single.payload);
      expect(sentReq.showOfflineDevicesInCore, isTrue);
      expect(sentReq.showOfflineAmazonDevicesAsOnline, isTrue);
      expect(sentReq.includeLocalDevice, isTrue);
      expect(sentReq.excludeNonLocalDevices, isTrue);
      expect(sentReq.includeUserMatchUnauthenticatedDevices, isTrue);

      controller.add(Uint8List(0));
      controller.add(
        Uint8List.fromList(
          connect_pb.StateResponse(
            isActive: true,
            isSyncedWithBackend: true,
            devices: <connect_pb.StateResponse_Device>[
              connect_pb.StateResponse_Device(
                localIdentifier: 'dev-1',
                connectStateIdentifier: 'cs-1',
                name: 'Living Room Speaker',
                isActive: true,
                state: 'LOGGED_IN',
                type: 'SPEAKER',
              ),
            ],
          ).writeToBuffer(),
        ),
      );
      controller.add(malformedBytes);
      await pumpEventQueue();

      expect(emitted, hasLength(2));
      final firstCluster = client.mappers.clusterFromBuffer(Uint8List(0));
      expect(emitted[0], firstCluster);
      final secondCluster = client.mappers.clusterFromBuffer(
        Uint8List.fromList(
          connect_pb.StateResponse(
            isActive: true,
            isSyncedWithBackend: true,
            devices: <connect_pb.StateResponse_Device>[
              connect_pb.StateResponse_Device(
                localIdentifier: 'dev-1',
                connectStateIdentifier: 'cs-1',
                name: 'Living Room Speaker',
                isActive: true,
                state: 'LOGGED_IN',
                type: 'SPEAKER',
              ),
            ],
          ).writeToBuffer(),
        ),
      );
      expect(emitted[1], secondCluster);
      expect(errors.single, isA<InvalidProtocolBufferException>());
    });

    test('Transfer RPC maps 0-byte OK and all failure statuses and validates inputs', () async {
      final transport = _RecordingEsperantoTransport();
      final client = ConnectServiceClient(transport);

      final logging = client.mappers.buildLoggingParams(
        commandId: validHexCommandId,
      );

      final okState = await client.transfer(
        connectDeviceIdentifier: 'dev-target',
        loggingParams: logging,
        dodo: true,
      );
      expect(
        okState,
        TransferSucceeded(
          targetDeviceId: 'dev-target',
          intentionId: validHexCommandId,
        ),
      );
      final sentReq =
          connect_pb.TransferRequest.fromBuffer(transport.calls.last.payload);
      expect(transport.calls.last.method, 'Transfer');
      expect(sentReq.connectDeviceIdentifier, 'dev-target');
      expect(sentReq.loggingParams.commandId, validHexCommandId);
      expect(sentReq.dodo, isTrue);

      final statusPairs = <(common_pb.Status, TransferFailureReason)>[
        (common_pb.Status.NOT_FOUND, TransferFailureReason.notFound),
        (
          common_pb.Status.INVALID_ARGUMENTS,
          TransferFailureReason.invalidArguments,
        ),
        (
          common_pb.Status.BACKEND_FAILURE,
          TransferFailureReason.backendFailure,
        ),
        (common_pb.Status.UNIMPLEMENTED, TransferFailureReason.unknown),
      ];

      for (final (protoStatus, expectedReason) in statusPairs) {
        transport.onCallSingle = (service, method, payload) async =>
            Uint8List.fromList(
              common_pb.StatusResponse(status: protoStatus).writeToBuffer(),
            );
        final failed = await client.transfer(
          connectDeviceIdentifier: 'dev-target',
          loggingParams: common_pb.LoggingParams(commandId: ''),
        );
        expect(
          failed,
          TransferFailed(
            targetDeviceId: 'dev-target',
            reason: expectedReason,
          ),
        );
      }

      final callCountBeforeInvalid = transport.calls.length;
      await expectLater(
        () => client.transfer(connectDeviceIdentifier: '  '),
        throwsArgumentError,
      );
      await expectLater(
        () => client.transfer(
          connectDeviceIdentifier: 'dev-target',
          loggingParams: common_pb.LoggingParams(commandId: 'bad-id'),
        ),
        throwsFormatException,
      );
      expect(transport.calls.length, callCountBeforeInvalid);
    });

    test('SendCommand RPC handles 0-byte, non-zero error payloads, and validation', () async {
      final transport = _RecordingEsperantoTransport();
      final client = ConnectServiceClient(transport);

      final logging = common_pb.LoggingParams(commandId: validHexCommandId);
      final zeroResp = await client.sendCommand(
        connectDeviceIdentifier: 'dev-1',
        commandJson: '{"endpoint":"pause"}',
        loggingParams: logging,
      );
      expect(zeroResp.contextPlayerError, 0);
      expect(zeroResp.isFrozen, isTrue);
      expect(transport.calls.last.method, 'SendCommand');
      final sentReq =
          connect_pb.SendCommandRequest.fromBuffer(transport.calls.last.payload);
      expect(sentReq.connectDeviceIdentifier, 'dev-1');
      expect(sentReq.commandJson, '{"endpoint":"pause"}');
      expect(sentReq.loggingParams.commandId, validHexCommandId);

      transport.onCallSingle = (service, method, payload) async =>
          Uint8List.fromList(
            connect_pb.SendCommandResponse(contextPlayerError: -1)
                .writeToBuffer(),
          );
      final errResp = await client.sendCommand(
        connectDeviceIdentifier: 'dev-1',
        commandJson: '{"endpoint":"resume"}',
      );
      expect(errResp.contextPlayerError, -1);

      final countBefore = transport.calls.length;
      await expectLater(
        () => client.sendCommand(
          connectDeviceIdentifier: '',
          commandJson: '{"endpoint":"pause"}',
        ),
        throwsArgumentError,
      );
      await expectLater(
        () => client.sendCommand(
          connectDeviceIdentifier: 'dev-1',
          commandJson: '   ',
        ),
        throwsArgumentError,
      );
      await expectLater(
        () => client.sendCommand(
          connectDeviceIdentifier: 'dev-1',
          commandJson: '{"endpoint":"pause"}',
          loggingParams: common_pb.LoggingParams(commandId: 'not-32-hex'),
        ),
        throwsFormatException,
      );
      expect(transport.calls.length, countBefore);
    });

    test('Pull, Rename, Logout, SetPreferredIncarnation RPCs serialize and decode StatusResponse', () async {
      final transport = _RecordingEsperantoTransport();
      final client = ConnectServiceClient(transport);
      final logging = common_pb.LoggingParams(commandId: validHexCommandId);

      expect(await client.pull(loggingParams: logging), common_pb.Status.OK);
      expect(transport.calls.last.method, 'Pull');
      expect(
        connect_pb.PullRequest.fromBuffer(transport.calls.last.payload)
            .loggingParams
            .commandId,
        validHexCommandId,
      );

      transport.onCallSingle = (service, method, payload) async =>
          Uint8List.fromList(
            common_pb.StatusResponse(status: common_pb.Status.BACKEND_FAILURE)
                .writeToBuffer(),
          );
      expect(
        await client.rename(deviceId: 'dev-2', newName: 'Kitchen'),
        common_pb.Status.BACKEND_FAILURE,
      );
      expect(transport.calls.last.method, 'Rename');
      final renameReq =
          connect_pb.RenameRequest.fromBuffer(transport.calls.last.payload);
      expect(renameReq.deviceId, 'dev-2');
      expect(renameReq.newName, 'Kitchen');

      transport.onCallSingle = (service, method, payload) async =>
          Uint8List.fromList(
            common_pb.StatusResponse(status: common_pb.Status.NOT_FOUND)
                .writeToBuffer(),
          );
      expect(
        await client.logout(connectDeviceIdentifier: 'dev-3'),
        common_pb.Status.NOT_FOUND,
      );
      expect(transport.calls.last.method, 'Logout');
      expect(
        connect_pb.LogoutRequest.fromBuffer(transport.calls.last.payload)
            .connectDeviceIdentifier,
        'dev-3',
      );

      transport.onCallSingle = (service, method, payload) async => Uint8List(0);
      expect(
        await client.setPreferredIncarnation(
          deviceId: 'dev-4',
          preferredLoginType: IncarnationLoginType.cast,
          loggingParams: logging,
        ),
        common_pb.Status.OK,
      );
      expect(transport.calls.last.method, 'SetPreferredIncarnation');
      final prefReq = connect_pb.SetPreferredIncarnationRequest.fromBuffer(
        transport.calls.last.payload,
      );
      expect(prefReq.deviceId, 'dev-4');
      expect(prefReq.preferredLoginType, connect_pb.LoginType.CAST);
      expect(prefReq.loggingParams.commandId, validHexCommandId);

      final countBefore = transport.calls.length;
      await expectLater(
        () => client.pull(
          loggingParams: common_pb.LoggingParams(commandId: 'invalid'),
        ),
        throwsFormatException,
      );
      await expectLater(
        () => client.rename(deviceId: ' ', newName: 'Kitchen'),
        throwsArgumentError,
      );
      await expectLater(
        () => client.rename(deviceId: 'dev-2', newName: ''),
        throwsArgumentError,
      );
      await expectLater(
        () => client.logout(connectDeviceIdentifier: ''),
        throwsArgumentError,
      );
      await expectLater(
        () => client.setPreferredIncarnation(deviceId: '  '),
        throwsArgumentError,
      );
      await expectLater(
        () => client.setPreferredIncarnation(
          deviceId: 'dev-4',
          preferredLoginType: IncarnationLoginType.castJs,
        ),
        throwsArgumentError,
      );
      expect(transport.calls.length, countBefore);
    });

    test('NotifyAudioRouteChanged, CreateStaticGroup, RenameGroup, PerformDiscovery, RefreshCluster, WakeSleepingClusterDevices RPCs', () async {
      final transport = _RecordingEsperantoTransport();
      final client = ConnectServiceClient(transport);

      await client.notifyAudioRouteChanged(
        audioOutputDeviceName: 'Studio Buds',
        connectionType: OutputPeripheralConnectionType.bluetooth,
        audioOutputDeviceBrand: 'Acme',
        audioOutputDeviceModel: 'B1',
        category: OutputPeripheralCategory.headphones,
      );
      expect(transport.calls.last.method, 'NotifyAudioRouteChanged');
      final routeReq = connect_pb.NotifyAudioRouteChangedRequest.fromBuffer(
        transport.calls.last.payload,
      );
      expect(routeReq.audioOutputDeviceName, 'Studio Buds');
      expect(
        routeReq.audioOutputDeviceConnectionType,
        connect_pb.OutputPeripheralConnectionType
            .OUTPUT_PERIPHERAL_CONNECTION_TYPE_BLUETOOTH,
      );
      expect(routeReq.audioOutputDeviceBrand, 'Acme');
      expect(routeReq.audioOutputDeviceModel, 'B1');
      expect(
        routeReq.audioOutputDeviceCategory,
        connect_pb.OutputPeripheralCategory
            .OUTPUT_PERIPHERAL_CATEGORY_HEADPHONES,
      );

      await client.createStaticGroup();
      expect(transport.calls.last.method, 'CreateStaticGroup');
      expect(transport.calls.last.payload, isEmpty);

      await client.renameGroup();
      expect(transport.calls.last.method, 'RenameGroup');
      expect(transport.calls.last.payload, isEmpty);

      await client.performDiscovery();
      expect(transport.calls.last.method, 'PerformDiscovery');
      expect(transport.calls.last.payload, isEmpty);

      await client.refreshCluster();
      expect(transport.calls.last.method, 'RefreshCluster');
      expect(transport.calls.last.payload, isEmpty);

      await client.wakeSleepingClusterDevices();
      expect(transport.calls.last.method, 'WakeSleepingClusterDevices');
      expect(transport.calls.last.payload, isEmpty);

      transport.onCallSingle = (service, method, payload) async => malformedBytes;
      await expectLater(
        () => client.notifyAudioRouteChanged(),
        throwsA(isA<InvalidProtocolBufferException>()),
      );
      await expectLater(
        client.createStaticGroup,
        throwsA(isA<InvalidProtocolBufferException>()),
      );
      await expectLater(
        client.renameGroup,
        throwsA(isA<InvalidProtocolBufferException>()),
      );
      await expectLater(
        client.performDiscovery,
        throwsA(isA<InvalidProtocolBufferException>()),
      );
      await expectLater(
        client.refreshCluster,
        throwsA(isA<InvalidProtocolBufferException>()),
      );
      await expectLater(
        client.wakeSleepingClusterDevices,
        throwsA(isA<InvalidProtocolBufferException>()),
      );
    });

    test('AddDeviceToGroup, RemoveDeviceFromGroup, DeleteGroup RPCs decode frozen responses and validate inputs', () async {
      final transport = _RecordingEsperantoTransport();
      final client = ConnectServiceClient(transport);
      final logging = common_pb.LoggingParams(commandId: validHexCommandId);

      // 0-byte proto3 default responses
      final zeroAdd = await client.addDeviceToGroup(
        connectDeviceIdentifier: 'c-1',
        groupDeviceIdentifier: 'g-1',
        loggingParams: logging,
      );
      expect(zeroAdd.success, isFalse);
      expect(zeroAdd.isFrozen, isTrue);
      expect(transport.calls.last.method, 'AddDeviceToGroup');
      final addReq = connect_pb.AddDeviceToGroupRequest.fromBuffer(
        transport.calls.last.payload,
      );
      expect(addReq.connectDeviceIdentifier, 'c-1');
      expect(addReq.groupDeviceIdentifier, 'g-1');
      expect(addReq.loggingParams.commandId, validHexCommandId);

      transport.onCallSingle = (service, method, payload) async {
        if (method == 'AddDeviceToGroup') {
          return Uint8List.fromList(
            connect_pb.AddDeviceToGroupResponse(
              success: false,
              error: connect_pb.GroupError.BUSY,
            ).writeToBuffer(),
          );
        }
        if (method == 'RemoveDeviceFromGroup') {
          return Uint8List.fromList(
            connect_pb.RemoveDeviceFromGroupResponse(
              success: true,
              error: connect_pb.RemoveGroupError.REMOVE_TARGET_NOT_FOUND,
            ).writeToBuffer(),
          );
        }
        return Uint8List.fromList(
          connect_pb.DeleteGroupResponse(
            success: false,
            error: connect_pb.DeleteGroupError.DELETE_TARGET_NOT_FOUND,
          ).writeToBuffer(),
        );
      };

      final addErr = await client.addDeviceToGroup(
        connectDeviceIdentifier: 'c-1',
        groupDeviceIdentifier: 'g-1',
      );
      expect(addErr.error, connect_pb.GroupError.BUSY);

      final removeResp = await client.removeDeviceFromGroup(
        connectDeviceIdentifier: 'c-1',
        groupDeviceIdentifier: 'g-1',
        loggingParams: logging,
      );
      expect(transport.calls.last.method, 'RemoveDeviceFromGroup');
      expect(removeResp.success, isTrue);
      expect(
        removeResp.error,
        connect_pb.RemoveGroupError.REMOVE_TARGET_NOT_FOUND,
      );
      expect(removeResp.isFrozen, isTrue);

      final deleteResp = await client.deleteGroup(
        connectDeviceIdentifier: 'g-1',
        loggingParams: logging,
      );
      expect(transport.calls.last.method, 'DeleteGroup');
      final delReq = connect_pb.DeleteGroupRequest.fromBuffer(
        transport.calls.last.payload,
      );
      expect(delReq.connectDeviceIdentifier, 'g-1');
      expect(delReq.loggingParams.commandId, validHexCommandId);
      expect(deleteResp.success, isFalse);
      expect(
        deleteResp.error,
        connect_pb.DeleteGroupError.DELETE_TARGET_NOT_FOUND,
      );
      expect(deleteResp.isFrozen, isTrue);

      final countBefore = transport.calls.length;
      await expectLater(
        () => client.addDeviceToGroup(
          connectDeviceIdentifier: '',
          groupDeviceIdentifier: 'g-1',
        ),
        throwsArgumentError,
      );
      await expectLater(
        () => client.removeDeviceFromGroup(
          connectDeviceIdentifier: 'c-1',
          groupDeviceIdentifier: '  ',
        ),
        throwsArgumentError,
      );
      await expectLater(
        () => client.deleteGroup(connectDeviceIdentifier: ''),
        throwsArgumentError,
      );
      await expectLater(
        () => client.deleteGroup(
          connectDeviceIdentifier: 'g-1',
          loggingParams: common_pb.LoggingParams(commandId: 'bad'),
        ),
        throwsFormatException,
      );
      expect(transport.calls.length, countBefore);
    });

    test('ClusterUpdateAfterBackendConnection RPC decodes 0-byte false and true', () async {
      final transport = _RecordingEsperantoTransport();
      final client = ConnectServiceClient(transport);

      expect(await client.clusterUpdateAfterBackendConnection(), isFalse);
      expect(
        transport.calls.last.method,
        'ClusterUpdateAfterBackendConnection',
      );
      expect(
        empty_pb.Empty.fromBuffer(transport.calls.last.payload).writeToBuffer(),
        isEmpty,
      );

      transport.onCallSingle = (service, method, payload) async =>
          Uint8List.fromList(
            connect_pb.ClusterUpdateAfterBackendConnectionResponse(
              hasReceivedClusterUpdateAfterBackendConnection: true,
            ).writeToBuffer(),
          );
      expect(await client.clusterUpdateAfterBackendConnection(), isTrue);
    });

    test('InstallSpotify RPC streams 0-byte CONNECTING and state updates, validating port & IDs', () async {
      final transport = _RecordingEsperantoTransport();
      final controller = StreamController<Uint8List>();
      addTearDown(controller.close);
      transport.onCallStream = (service, method, payload) => controller.stream;

      final client = ConnectServiceClient(transport);
      final logging = common_pb.LoggingParams(commandId: validHexCommandId);
      final states = <connect_pb.InstallSpotifyState>[];
      final errors = <Object>[];

      final sub = client
          .installSpotify(
            connectDeviceIdentifier: 'tv-1',
            port: 0xFFFFFFFF,
            loggingParams: logging,
          )
          .listen(states.add, onError: errors.add);
      addTearDown(sub.cancel);

      expect(transport.calls.single.kind, 'stream');
      expect(transport.calls.single.method, 'InstallSpotify');
      final sentReq = connect_pb.InstallSpotifyRequest.fromBuffer(
        transport.calls.single.payload,
      );
      expect(sentReq.connectDeviceIdentifier, 'tv-1');
      expect(sentReq.port, 0xFFFFFFFF);
      expect(sentReq.loggingParams.commandId, validHexCommandId);

      controller.add(Uint8List(0));
      controller.add(
        Uint8List.fromList(
          connect_pb.InstallSpotifyStatusUpdate(
            currentState: connect_pb.InstallSpotifyState.PAIRING,
          ).writeToBuffer(),
        ),
      );
      controller.add(
        Uint8List.fromList(
          connect_pb.InstallSpotifyStatusUpdate(
            currentState: connect_pb.InstallSpotifyState.SUCCESS,
          ).writeToBuffer(),
        ),
      );
      controller.add(malformedBytes);
      await pumpEventQueue();

      expect(states, <connect_pb.InstallSpotifyState>[
        connect_pb.InstallSpotifyState.CONNECTING,
        connect_pb.InstallSpotifyState.PAIRING,
        connect_pb.InstallSpotifyState.SUCCESS,
      ]);
      expect(errors.single, isA<InvalidProtocolBufferException>());

      final countBefore = transport.calls.length;
      expect(
        () => client.installSpotify(
          connectDeviceIdentifier: '  ',
          port: 8080,
        ),
        throwsArgumentError,
      );
      expect(
        () => client.installSpotify(
          connectDeviceIdentifier: 'tv-1',
          port: -1,
        ),
        throwsRangeError,
      );
      expect(
        () => client.installSpotify(
          connectDeviceIdentifier: 'tv-1',
          port: 0x100000000,
        ),
        throwsRangeError,
      );
      expect(
        () => client.installSpotify(
          connectDeviceIdentifier: 'tv-1',
          port: 0,
          loggingParams: common_pb.LoggingParams(commandId: 'xyz'),
        ),
        throwsFormatException,
      );
      expect(transport.calls.length, countBefore);
    });

    test('propagates transport exceptions and malformed wire responses untouched', () async {
      final transport = _RecordingEsperantoTransport();
      final client = ConnectServiceClient(transport);

      transport.onCallSingle = (service, method, payload) async =>
          throw StateError('transport invalidated');
      await expectLater(client.refreshCluster, throwsStateError);

      transport.onCallSingle = (service, method, payload) async =>
          throw UnsupportedError('unknown method');
      await expectLater(client.performDiscovery, throwsUnsupportedError);

      transport.onCallSingle = (service, method, payload) async =>
          throw const FormatException('native decode error');
      await expectLater(client.pull, throwsFormatException);

      transport.onCallSingle = (service, method, payload) async =>
          throw ArgumentError('native invalid args');
      await expectLater(
        () => client.logout(connectDeviceIdentifier: 'dev-1'),
        throwsArgumentError,
      );

      transport.onCallSingle = (service, method, payload) async => malformedBytes;
      await expectLater(
        () => client.pull(),
        throwsA(isA<InvalidProtocolBufferException>()),
      );
      await expectLater(
        () => client.sendCommand(
          connectDeviceIdentifier: 'dev-1',
          commandJson: '{}',
        ),
        throwsA(isA<InvalidProtocolBufferException>()),
      );
      await expectLater(
        () => client.deleteGroup(connectDeviceIdentifier: 'g-1'),
        throwsA(isA<InvalidProtocolBufferException>()),
      );
      await expectLater(
        client.clusterUpdateAfterBackendConnection,
        throwsA(isA<InvalidProtocolBufferException>()),
      );
    });
  });
}
