import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/data/mappers/cluster_mapper.dart';
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pb.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';

void main() {
  const mapper = ClusterMapper();

  connect_pb.StateResponse_Device buildProtoDevice({
    required String id,
    required String name,
    bool isSelf = false,
    bool isActive = false,
    String state = 'LOGGED_IN',
    String type = 'SPEAKER',
  }) {
    return connect_pb.StateResponse_Device(
      localIdentifier: id,
      connectStateIdentifier: 'cs-$id',
      name: name,
      isSelf: isSelf,
      isActive: isActive,
      state: state,
      type: type,
    );
  }

  group('ClusterMapper', () {
    test('maps multi-device StateResponse via wire-byte roundtrip and ignores core fields', () {
      final pb = connect_pb.StateResponse(
        isActive: true,
        shouldUseLocalPlayback: false,
        isRunning: true,
        isConnected: true,
        devices: [
          buildProtoDevice(
            id: 'phone-1',
            name: 'My Phone',
            isSelf: true,
            isActive: false,
            type: 'SMARTPHONE',
          ),
          buildProtoDevice(
            id: 'speaker-1',
            name: 'Kitchen Speaker',
            isSelf: false,
            isActive: true,
            type: 'SPEAKER',
          ),
        ],
        localName: 'Ignored Local Name',
        isActiveOnSameDevice: false,
        isSyncedWithBackend: true,
      );

      final Uint8List wireBytes = pb.writeToBuffer();
      final cluster = mapper.clusterFromBuffer(wireBytes);

      expect(cluster.isActive, isTrue);
      expect(cluster.shouldUseLocalPlayback, isFalse);
      expect(cluster.isActiveOnSameDevice, isFalse);
      expect(cluster.isSyncedWithBackend, isTrue);
      expect(cluster.devices, hasLength(2));
      expect(cluster.localDevice?.localIdentifier, 'phone-1');
      expect(cluster.localDevice?.type, DeviceType.smartphone);
      expect(cluster.activeDevice?.localIdentifier, 'speaker-1');
      expect(cluster.activeDevice?.state, ConnectDeviceState.loggedIn);
    });

    test('maps empty/offline proto3 StateResponse cleanly (all booleans omitted on wire)', () {
      final emptyPb = connect_pb.StateResponse();
      final cluster = mapper.clusterFromBuffer(emptyPb.writeToBuffer());

      expect(cluster.isActive, isFalse);
      expect(cluster.shouldUseLocalPlayback, isFalse);
      expect(cluster.devices, isEmpty);
      expect(cluster.isActiveOnSameDevice, isFalse);
      expect(cluster.isSyncedWithBackend, isFalse);
      expect(cluster.activeDevice, isNull);
      expect(cluster.localDevice, isNull);
    });

    test('fails fast when more than one device is marked active', () {
      final invalidCluster = connect_pb.StateResponse(
        isActive: true,
        devices: [
          buildProtoDevice(id: 'dev-1', name: 'Dev 1', isActive: true),
          buildProtoDevice(id: 'dev-2', name: 'Dev 2', isActive: true),
        ],
      );

      expect(
        () => mapper.mapCluster(invalidCluster),
        throwsArgumentError,
      );
    });
  });
}
