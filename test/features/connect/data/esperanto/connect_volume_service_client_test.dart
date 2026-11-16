import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_volume_service_client.dart';
import 'package:musify_mu/features/connect/data/mappers/volume_mapper.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart'
    as common_pb;
import 'package:musify_mu/features/connect/data/proto/es_volume_messages.pb.dart'
    as volume_pb;
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:protobuf/protobuf.dart';

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

  group('ConnectVolumeServiceClient (Item 134 — all 5 RPCs)', () {
    test('uses exact ConnectVolumeService Esperanto serviceName', () {
      expect(
        ConnectVolumeServiceClient.serviceName,
        'spotify.connect.esperanto.proto.ConnectVolumeService',
      );
    });

    test('Volume RPC streams 0-byte proto3 OK, populated VolumeResponse, and NOT_FOUND', () async {
      final transport = _RecordingEsperantoTransport();
      final controller = StreamController<Uint8List>();
      addTearDown(controller.close);
      transport.onCallStream = (service, method, payload) => controller.stream;

      final client = ConnectVolumeServiceClient(transport);
      final states = <ConnectVolumeState>[];
      final errors = <Object>[];
      final sub = client.volume().listen(states.add, onError: errors.add);
      addTearDown(sub.cancel);

      expect(transport.calls, hasLength(1));
      expect(transport.calls.single.kind, 'stream');
      expect(
        transport.calls.single.service,
        ConnectVolumeServiceClient.serviceName,
      );
      expect(transport.calls.single.method, 'Volume');
      expect(transport.calls.single.payload, isEmpty);

      controller.add(Uint8List(0));
      controller.add(
        Uint8List.fromList(
          volume_pb.VolumeResponse(
            volume: 32768,
            activeDeviceConnectStateIdentifier: 'cs-speaker',
            groupDeviceVolumes: <String, int>{'gd-1': 65535}.entries,
          ).writeToBuffer(),
        ),
      );
      controller.add(
        Uint8List.fromList(
          volume_pb.VolumeResponse(
            status: common_pb.Status.NOT_FOUND,
          ).writeToBuffer(),
        ),
      );
      controller.add(malformedBytes);
      await pumpEventQueue();

      expect(states, hasLength(3));
      expect(states[0].status, ConnectVolumeStatus.ok);
      expect(states[0].remoteVolume, 0.0);

      expect(states[1].status, ConnectVolumeStatus.ok);
      expect(states[1].remoteVolume, closeTo(32768 / 65535.0, 1e-12));
      expect(states[1].activeDeviceConnectStateIdentifier, 'cs-speaker');
      expect(states[1].groupDeviceVolumes['gd-1']?.volume, 1.0);

      expect(states[2].status, ConnectVolumeStatus.notFound);
      expect(states[2].remoteVolume, isNull);

      expect(errors.single, isA<InvalidProtocolBufferException>());
    });

    test('LocalVolume RPC streams 0-byte USER/0 and SYSTEM events', () async {
      final transport = _RecordingEsperantoTransport();
      final controller = StreamController<Uint8List>();
      addTearDown(controller.close);
      transport.onCallStream = (service, method, payload) => controller.stream;

      final client = ConnectVolumeServiceClient(transport);
      final events = <LocalVolumeEvent>[];
      final errors = <Object>[];
      final sub = client.localVolume().listen(events.add, onError: errors.add);
      addTearDown(sub.cancel);

      expect(transport.calls, hasLength(1));
      expect(transport.calls.single.kind, 'stream');
      expect(
        transport.calls.single.service,
        ConnectVolumeServiceClient.serviceName,
      );
      expect(transport.calls.single.method, 'LocalVolume');
      expect(transport.calls.single.payload, isEmpty);

      controller.add(Uint8List(0));
      controller.add(
        Uint8List.fromList(
          volume_pb.LocalVolumeResponse(
            volume: 65535,
            reason: volume_pb.LocalVolumeResponse_Reason.SYSTEM,
          ).writeToBuffer(),
        ),
      );
      controller.add(malformedBytes);
      await pumpEventQueue();

      expect(events, hasLength(2));
      expect(events[0].volume, 0.0);
      expect(events[0].reason, LocalVolumeReason.user);
      expect(events[1].volume, 1.0);
      expect(events[1].reason, LocalVolumeReason.system);
      expect(errors.single, isA<InvalidProtocolBufferException>());
    });

    test('VolumeSet RPC serializes wire volume, loggingParams, groupId and decodes all Status variants', () async {
      final transport = _RecordingEsperantoTransport();
      final client = ConnectVolumeServiceClient(transport);
      final logging = common_pb.LoggingParams(commandId: validHexCommandId);

      final okStatus = await client.volumeSet(
        volume: 0.5,
        loggingParams: logging,
        groupDeviceIdentifier: 'gd-1',
      );
      expect(okStatus, ConnectVolumeStatus.ok);
      expect(transport.calls.last.kind, 'single');
      expect(
        transport.calls.last.service,
        ConnectVolumeServiceClient.serviceName,
      );
      expect(transport.calls.last.method, 'VolumeSet');
      final sentReq = volume_pb.VolumeSetRequest.fromBuffer(
        transport.calls.last.payload,
      );
      expect(sentReq.volume, 32768);
      expect(sentReq.loggingParams.commandId, validHexCommandId);
      expect(sentReq.groupDeviceIdentifier, 'gd-1');

      final pairs = <(common_pb.Status, ConnectVolumeStatus)>[
        (common_pb.Status.NOT_FOUND, ConnectVolumeStatus.notFound),
        (
          common_pb.Status.INVALID_ARGUMENTS,
          ConnectVolumeStatus.invalidArguments,
        ),
        (common_pb.Status.BACKEND_FAILURE, ConnectVolumeStatus.backendFailure),
        (common_pb.Status.UNIMPLEMENTED, ConnectVolumeStatus.unimplemented),
      ];
      for (final (protoStatus, domainStatus) in pairs) {
        transport.onCallSingle = (service, method, payload) async =>
            Uint8List.fromList(
              common_pb.StatusResponse(status: protoStatus).writeToBuffer(),
            );
        expect(await client.volumeSet(volume: 1.0), domainStatus);
      }

      final countBefore = transport.calls.length;
      await expectLater(
        () => client.volumeSet(volume: -0.01),
        throwsRangeError,
      );
      await expectLater(
        () => client.volumeSet(volume: 1.01),
        throwsRangeError,
      );
      await expectLater(
        () => client.volumeSet(volume: double.nan),
        throwsRangeError,
      );
      await expectLater(
        () => client.volumeSet(
          volume: 0.5,
          loggingParams: common_pb.LoggingParams(commandId: 'bad'),
        ),
        throwsFormatException,
      );
      await expectLater(
        () => client.volumeSet(volume: 0.5, groupDeviceIdentifier: '  '),
        throwsArgumentError,
      );
      expect(transport.calls.length, countBefore);
    });

    test('VolumeUp and VolumeDown RPCs serialize requests, validate params, and decode StatusResponse', () async {
      final transport = _RecordingEsperantoTransport();
      final client = ConnectVolumeServiceClient(transport);
      final logging = common_pb.LoggingParams(commandId: validHexCommandId);

      expect(
        await client.volumeUp(
          loggingParams: logging,
          groupDeviceIdentifier: 'gd-up',
        ),
        ConnectVolumeStatus.ok,
      );
      expect(transport.calls.last.method, 'VolumeUp');
      final upReq = volume_pb.VolumeUpRequest.fromBuffer(
        transport.calls.last.payload,
      );
      expect(upReq.loggingParams.commandId, validHexCommandId);
      expect(upReq.groupDeviceIdentifier, 'gd-up');

      transport.onCallSingle = (service, method, payload) async =>
          Uint8List.fromList(
            common_pb.StatusResponse(status: common_pb.Status.BACKEND_FAILURE)
                .writeToBuffer(),
          );
      expect(
        await client.volumeDown(
          loggingParams: logging,
          groupDeviceIdentifier: 'gd-down',
        ),
        ConnectVolumeStatus.backendFailure,
      );
      expect(transport.calls.last.method, 'VolumeDown');
      final downReq = volume_pb.VolumeDownRequest.fromBuffer(
        transport.calls.last.payload,
      );
      expect(downReq.loggingParams.commandId, validHexCommandId);
      expect(downReq.groupDeviceIdentifier, 'gd-down');

      final countBefore = transport.calls.length;
      await expectLater(
        () => client.volumeUp(
          loggingParams: common_pb.LoggingParams(commandId: 'bad'),
        ),
        throwsFormatException,
      );
      await expectLater(
        () => client.volumeDown(groupDeviceIdentifier: ''),
        throwsArgumentError,
      );
      expect(transport.calls.length, countBefore);
    });

    test('propagates transport exceptions and malformed response wire bytes', () async {
      final transport = _RecordingEsperantoTransport();
      final client = ConnectVolumeServiceClient(transport);

      transport.onCallSingle = (service, method, payload) async =>
          throw StateError('transport destroyed');
      await expectLater(() => client.volumeSet(volume: 0.2), throwsStateError);

      transport.onCallSingle = (service, method, payload) async =>
          throw UnsupportedError('unknown method');
      await expectLater(client.volumeUp, throwsUnsupportedError);

      transport.onCallSingle = (service, method, payload) async =>
          throw const FormatException('decode error');
      await expectLater(client.volumeDown, throwsFormatException);

      transport.onCallSingle = (service, method, payload) async => malformedBytes;
      await expectLater(
        () => client.volumeSet(volume: 0.5),
        throwsA(isA<InvalidProtocolBufferException>()),
      );
    });
  });
}
