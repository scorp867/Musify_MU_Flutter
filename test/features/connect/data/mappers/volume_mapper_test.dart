import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/data/mappers/volume_mapper.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart'
    as common_pb;
import 'package:musify_mu/features/connect/data/proto/es_volume_messages.pb.dart'
    as volume_pb;
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';

void main() {
  const mapper = VolumeMapper();
  const validHexCommandId = '0123456789abcdef0123456789ABCDEF';

  group('VolumeMapper', () {
    test('wireToNormalized and normalizedToWire boundary conversions', () {
      expect(mapper.wireToNormalized(0), 0.0);
      expect(mapper.wireToNormalized(kMaxConnectVolumeWire), 1.0);
      expect(mapper.wireToNormalized(32768), closeTo(32768 / 65535.0, 1e-12));

      expect(mapper.normalizedToWire(0.0), 0);
      expect(mapper.normalizedToWire(1.0), kMaxConnectVolumeWire);
      expect(mapper.normalizedToWire(0.5), 32768);
    });

    test('wireToNormalized and normalizedToWire reject invalid bounds', () {
      expect(() => mapper.wireToNormalized(-1), throwsRangeError);
      expect(() => mapper.wireToNormalized(65536), throwsRangeError);

      expect(() => mapper.normalizedToWire(-0.0001), throwsRangeError);
      expect(() => mapper.normalizedToWire(1.0001), throwsRangeError);
      expect(() => mapper.normalizedToWire(double.nan), throwsRangeError);
      expect(() => mapper.normalizedToWire(double.infinity), throwsRangeError);
      expect(
        () => mapper.normalizedToWire(double.negativeInfinity),
        throwsRangeError,
      );
    });

    test('VolumeResponse roundtrip with Status.OK omitted on proto3 wire', () {
      // Proto3 C++ VolumeResponse omits Status.OK (0) on the wire.
      final proto = volume_pb.VolumeResponse(
        volume: 32768,
        activeDeviceConnectStateIdentifier: 'cs-active-1',
        groupDeviceVolumes: <String, int>{
          'gd-1': 0,
          'gd-2': 65535,
        }.entries,
      );

      final bytes = Uint8List.fromList(proto.writeToBuffer());
      final decodedProto = volume_pb.VolumeResponse.fromBuffer(bytes);
      expect(decodedProto.hasStatus(), isFalse);

      final mapped = mapper.volumeResponseFromBuffer(bytes);
      expect(mapped.status, ConnectVolumeStatus.ok);
      expect(mapped.remoteVolume, closeTo(32768 / 65535.0, 1e-12));
      expect(mapped.activeDeviceConnectStateIdentifier, 'cs-active-1');
      expect(mapped.groupDeviceVolumes['gd-1']?.volume, 0.0);
      expect(mapped.groupDeviceVolumes['gd-2']?.volume, 1.0);
      expect(mapped.outputMode, VolumeOutputMode.remote);
    });

    test('VolumeResponse handles Status.OK with scalar 0 omitted on wire', () {
      // C++ proto3 omits both status (OK=0) and volume (0) when muted.
      final bytes = Uint8List.fromList(
        volume_pb.VolumeResponse(
          activeDeviceConnectStateIdentifier: 'cs-muted',
        ).writeToBuffer(),
      );
      final mapped = mapper.volumeResponseFromBuffer(bytes);
      expect(mapped.status, ConnectVolumeStatus.ok);
      expect(mapped.remoteVolume, 0.0);
      expect(mapped.isMuted, isTrue);
      expect(mapped.activeDeviceConnectStateIdentifier, 'cs-muted');
    });

    test('VolumeResponse handles C++ NOT_FOUND with unset volume -> null', () {
      // ConnectVolumeServiceImpl.cpp:36-38 leaves volume unset on NOT_FOUND.
      final proto = volume_pb.VolumeResponse(
        status: common_pb.Status.NOT_FOUND,
      );
      final mapped = mapper.volumeResponseFromBuffer(
        Uint8List.fromList(proto.writeToBuffer()),
      );

      expect(mapped.status, ConnectVolumeStatus.notFound);
      expect(mapped.remoteVolume, isNull);
      expect(mapped.activeDeviceConnectStateIdentifier, isNull);
      expect(mapped.groupDeviceVolumes, isEmpty);
    });

    test('VolumeResponse rejects out-of-range volume and empty group keys', () {
      expect(
        () => mapper.mapVolumeResponse(
          volume_pb.VolumeResponse(volume: 65536, status: common_pb.Status.OK),
        ),
        throwsRangeError,
      );
      expect(
        () => mapper.mapVolumeResponse(
          volume_pb.VolumeResponse(
            volume: -1,
            status: common_pb.Status.NOT_FOUND,
          ),
        ),
        throwsRangeError,
      );
      expect(
        () => mapper.mapGroupDeviceVolumes(<String, int>{'  ': 100}),
        throwsFormatException,
      );
      expect(
        () => mapper.mapGroupDeviceVolumes(<String, int>{'gd-1': 65536}),
        throwsRangeError,
      );
    });

    test('StatusResponse decodes 0-byte OK and all 5 Status enum variants', () {
      // ConnectEsperantoProtos.h:233-239 encodes Status.OK as 0 bytes.
      expect(mapper.statusResponseFromBuffer(Uint8List(0)), ConnectVolumeStatus.ok);

      final pairs = <(common_pb.Status, ConnectVolumeStatus)>[
        (common_pb.Status.OK, ConnectVolumeStatus.ok),
        (common_pb.Status.NOT_FOUND, ConnectVolumeStatus.notFound),
        (
          common_pb.Status.INVALID_ARGUMENTS,
          ConnectVolumeStatus.invalidArguments,
        ),
        (common_pb.Status.BACKEND_FAILURE, ConnectVolumeStatus.backendFailure),
        (common_pb.Status.UNIMPLEMENTED, ConnectVolumeStatus.unimplemented),
      ];
      for (final (protoStatus, domainStatus) in pairs) {
        final bytes = Uint8List.fromList(
          common_pb.StatusResponse(status: protoStatus).writeToBuffer(),
        );
        expect(mapper.statusResponseFromBuffer(bytes), domainStatus);
      }
    });

    test('LocalVolumeResponse roundtrip handles omitted USER/0 and SYSTEM', () {
      final userZeroBytes = Uint8List.fromList(
        volume_pb.LocalVolumeResponse(
          volume: 0,
          reason: volume_pb.LocalVolumeResponse_Reason.USER,
        ).writeToBuffer(),
      );
      final userEvent = mapper.localVolumeFromBuffer(userZeroBytes);
      expect(userEvent.volume, 0.0);
      expect(userEvent.reason, LocalVolumeReason.user);

      final systemBytes = Uint8List.fromList(
        volume_pb.LocalVolumeResponse(
          volume: 65535,
          reason: volume_pb.LocalVolumeResponse_Reason.SYSTEM,
        ).writeToBuffer(),
      );
      final systemEvent = mapper.localVolumeFromBuffer(systemBytes);
      expect(systemEvent.volume, 1.0);
      expect(systemEvent.reason, LocalVolumeReason.system);

      expect(
        () => mapper.mapLocalVolume(volume_pb.LocalVolumeResponse(volume: 70000)),
        throwsRangeError,
      );
    });

    test('outbound VolumeSet/Up/Down requests validate volume, commandId, groupId',
        () {
      final logging = common_pb.LoggingParams(commandId: validHexCommandId);
      final setReq = mapper.toVolumeSetRequest(
        volume: 0.5,
        loggingParams: logging,
        groupDeviceIdentifier: 'gd-1',
      );
      expect(setReq.volume, 32768);
      expect(setReq.loggingParams.commandId, validHexCommandId);
      expect(setReq.groupDeviceIdentifier, 'gd-1');

      final upReq = mapper.toVolumeUpRequest(
        loggingParams: common_pb.LoggingParams(commandId: ''),
      );
      expect(upReq.hasGroupDeviceIdentifier(), isFalse);

      final downReq = mapper.toVolumeDownRequest(
        loggingParams: logging,
        groupDeviceIdentifier: 'gd-2',
      );
      expect(downReq.groupDeviceIdentifier, 'gd-2');

      expect(
        () => mapper.toVolumeSetRequest(volume: 1.5),
        throwsRangeError,
      );
      expect(
        () => mapper.toVolumeSetRequest(
          volume: 0.5,
          loggingParams: common_pb.LoggingParams(commandId: 'bad-cmd-id'),
        ),
        throwsFormatException,
      );
      expect(
        () => mapper.toVolumeUpRequest(
          loggingParams: common_pb.LoggingParams(
            commandId: '0123456789abcdef0123456789abcdeg',
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => mapper.toVolumeDownRequest(groupDeviceIdentifier: '   '),
        throwsArgumentError,
      );
    });
  });
}
